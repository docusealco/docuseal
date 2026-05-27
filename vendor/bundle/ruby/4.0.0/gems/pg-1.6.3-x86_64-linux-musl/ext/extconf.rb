require 'pp'
require 'mkmf'

if ENV['MAINTAINER_MODE']
	$stderr.puts "Maintainer mode enabled."
	$CFLAGS <<
		' -Wall' <<
		' -ggdb' <<
		' -DDEBUG' <<
		' -pedantic'
	$LDFLAGS <<
		' -ggdb'
end

if pgdir = with_config( 'pg' )
	ENV['PATH'] = "#{pgdir}/bin" + File::PATH_SEPARATOR + ENV['PATH']
end

if enable_config("gvl-unlock", true)
	$defs.push( "-DENABLE_GVL_UNLOCK" )
	$stderr.puts "Calling libpq with GVL unlocked"
else
	$stderr.puts "Calling libpq with GVL locked"
end

if gem_platform=with_config("cross-build")
	gem 'mini_portile2', '~>2.1'
	require 'mini_portile2'

	OPENSSL_VERSION = ENV['OPENSSL_VERSION'] || '3.6.0'
	OPENSSL_SOURCE_URI = "http://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

	KRB5_VERSION = ENV['KRB5_VERSION'] || '1.22.1'
	KRB5_SOURCE_URI = "http://kerberos.org/dist/krb5/#{KRB5_VERSION[/^(\d+\.\d+)/]}/krb5-#{KRB5_VERSION}.tar.gz"

	POSTGRESQL_VERSION = ENV['POSTGRESQL_VERSION'] || '18.1'
	POSTGRESQL_SOURCE_URI = "http://ftp.postgresql.org/pub/source/v#{POSTGRESQL_VERSION}/postgresql-#{POSTGRESQL_VERSION}.tar.bz2"

	class BuildRecipe < MiniPortile
		def initialize(name, version, files)
			super(name, version)
			self.files = files
			rootdir = File.expand_path('../..', __FILE__)
			self.target = File.join(rootdir, "ports")
			self.patch_files = Dir[File.join(target, "patches", self.name, self.version, "*.patch")].sort
		end

		def port_path
			"#{target}/#{RUBY_PLATFORM}"
		end

		# Add "--prefix=/", to avoid our actual build install path compiled into the binary.
		# Instead use DESTDIR variable of make to set our install path.
		def configure_prefix
			"--prefix="
		end

		def cook_and_activate
			checkpoint = File.join(self.target, "#{self.name}-#{self.version}-#{RUBY_PLATFORM}.installed")
			unless File.exist?(checkpoint)
				self.cook
				FileUtils.touch checkpoint
			end
			self.activate
			self
		end
	end

	openssl_platform = with_config("openssl-platform")
	toolchain = with_config("toolchain")

	openssl_recipe = BuildRecipe.new("openssl", OPENSSL_VERSION, [OPENSSL_SOURCE_URI]).tap do |recipe|
		class << recipe
			attr_accessor :openssl_platform
			def configure
				envs = []
				envs << "CFLAGS=-DDSO_WIN32 -DOPENSSL_THREADS" if RUBY_PLATFORM =~ /mingw|mswin/
				envs << "CFLAGS=-fPIC -DOPENSSL_THREADS" if RUBY_PLATFORM =~ /linux|darwin/
				execute('configure', ['env', *envs, "./Configure", openssl_platform, "threads", "-static", "CROSS_COMPILE=#{host}-", "--prefix=/"], altlog: "config.log")
			end
			def compile
				execute('compile', "#{make_cmd} build_libs")
			end
			def install
				execute('install', "#{make_cmd} install_dev DESTDIR=#{path}")
			end
		end

		recipe.openssl_platform = openssl_platform
		recipe.host = toolchain
		recipe.cook_and_activate
	end

	if RUBY_PLATFORM =~ /linux|darwin/
		krb5_recipe = BuildRecipe.new("krb5", KRB5_VERSION, [KRB5_SOURCE_URI]).tap do |recipe|
			class << recipe
				def work_path
					File.join(super, "src")
				end
				def configure
					if RUBY_PLATFORM=~/darwin/
						ENV["CC"] = host[/^.*[^\.\d]/] + "-clang"
						ENV["CXX"] = host[/^.*[^\.\d]/] + "-c++"

						# Manually set the correct values for configure checks that libkrb5 won't be
						# able to perform because we're cross-compiling.
						ENV["krb5_cv_attr_constructor_destructor"] = "yes"
						ENV["ac_cv_func_regcomp"] = "yes"
						ENV["ac_cv_printf_positional"] = "yes"
					end
					super
				end
				def install
					execute('install', "#{make_cmd} install DESTDIR=#{path}")
				end
			end
			# We specify -fcommon to get around duplicate definition errors in recent gcc.
			# See https://github.com/cockroachdb/cockroach/issues/49734
			recipe.configure_options << "CFLAGS=-fcommon#{" -fPIC" if RUBY_PLATFORM =~ /linux/}"
			recipe.configure_options << "LDFLAGS=-framework Kerberos" if RUBY_PLATFORM =~ /darwin/
			recipe.configure_options << "--without-keyutils"
			recipe.configure_options << "--disable-nls"
			recipe.configure_options << "--disable-silent-rules"
			recipe.configure_options << "--disable-rpath"
			recipe.configure_options << "--without-system-verto"
			recipe.configure_options << "krb5_cv_attr_constructor_destructor=yes"
			recipe.configure_options << "ac_cv_func_regcomp=yes"
			recipe.configure_options << "ac_cv_printf_positional=yes"
			recipe.host = toolchain
			recipe.cook_and_activate
		end
	end

	# We build a libpq library file which static links OpenSSL and krb5.
	# Our builtin libpq is referenced in different ways depending on the OS:
	# - Window: Add the ports directory at runtime per RubyInstaller::Runtime.add_dll_directory
	#     The file is called "libpq.dll"
	# - Linux: Add a rpath to pg_ext.so which references the ports directory.
	#     The file is called "libpq-ruby-pg.so.1" to avoid loading of system libpq by accident.
	# - Macos: Add a reference with relative path in pg_ext.so to the ports directory.
	#     The file is called "libpq-ruby-pg.1.dylib" to avoid loading of other libpq by accident.
	libpq_orig, libpq_rubypg = case RUBY_PLATFORM
	when /linux/ then ["libpq.so.5", "libpq-ruby-pg.so.1"]
	when /darwin/ then ["libpq.5.dylib", "libpq-ruby-pg.1.dylib"]
	# when /mingw/ then ["libpq.dll", "libpq.dll"] # renaming not needed
	end

	postgresql_recipe = BuildRecipe.new("postgresql", POSTGRESQL_VERSION, [POSTGRESQL_SOURCE_URI]).tap do |recipe|
		class << recipe
			def configure_defaults
				[
					"--target=#{host}",
					"--host=#{host}",
					'--with-openssl',
					*(RUBY_PLATFORM=~/linux|darwin/ ? ['--with-gssapi'] : []),
					'--without-zlib',
					'--without-icu',
					'--without-readline',
					'--disable-rpath',
					'ac_cv_search_gss_store_cred_into=',
				]
			end
			def compile
				execute 'compile include', "#{make_cmd} -C src/include install DESTDIR=#{path}"
				execute 'compile interfaces', "#{make_cmd} -C src/interfaces install DESTDIR=#{path}"
			end
			def install
			end
		end

		recipe.host = toolchain
		recipe.configure_options << "CFLAGS=#{" -fPIC" if RUBY_PLATFORM =~ /linux|darwin/}"
		recipe.configure_options << "LDFLAGS=-L#{openssl_recipe.path}/lib -L#{openssl_recipe.path}/lib64 -L#{openssl_recipe.path}/lib-arm64 #{"-Wl,-soname,#{libpq_rubypg} -lgssapi_krb5 -lkrb5 -lk5crypto -lkrb5support -ldl" if RUBY_PLATFORM =~ /linux/} #{"-Wl,-install_name,@loader_path/../../ports/#{gem_platform}/lib/#{libpq_rubypg} -lgssapi_krb5 -lkrb5 -lk5crypto -lkrb5support -lresolv -framework Kerberos" if RUBY_PLATFORM =~ /darwin/}"
		recipe.configure_options << "LIBS=-lkrb5 -lcom_err -lk5crypto -lkrb5support -lresolv" if RUBY_PLATFORM =~ /linux/
		recipe.configure_options << "LIBS=-lssl -lwsock32 -lgdi32 -lws2_32 -lcrypt32" if RUBY_PLATFORM =~ /mingw|mswin/
		recipe.configure_options << "CPPFLAGS=-I#{openssl_recipe.path}/include"
		recipe.cook_and_activate
	end

	# Use our own library name for libpq to avoid loading of system libpq by accident.
	FileUtils.ln_sf File.join(postgresql_recipe.port_path, "lib/#{libpq_orig}"),
			File.join(postgresql_recipe.port_path, "lib/#{libpq_rubypg}")
	# Link to libpq_rubypg in our ports directory without adding it as rpath (like dir_config does)
	$CFLAGS << " -I#{postgresql_recipe.path}/include"
	$LDFLAGS << " -L#{postgresql_recipe.path}/lib"
	# Avoid dependency to external libgcc.dll on x86-mingw32
	$LDFLAGS << " -static-libgcc" if RUBY_PLATFORM =~ /mingw|mswin/
	# Avoid: "libpq.so: undefined reference to `dlopen'" in cross-ruby-2.7.8
	$LDFLAGS << " -Wl,--no-as-needed" if RUBY_PLATFORM !~ /aarch64|arm64|darwin/
	# Find libpq in the ports directory coming from lib/3.x
	# It is shared between all compiled ruby versions.
	$LDFLAGS << " '-Wl,-rpath=$$ORIGIN/../../ports/#{gem_platform}/lib'" if RUBY_PLATFORM =~ /linux/

	$defs.push( "-DPG_IS_BINARY_GEM")
else
	# Native build

	pgconfig = with_config('pg-config') ||
		with_config('pg_config') ||
		find_executable('pg_config')

	if pgconfig && pgconfig != 'ignore'
		$stderr.puts "Using config values from %s" % [ pgconfig ]
		incdir = IO.popen([pgconfig, "--includedir"], &:read).chomp
		libdir = IO.popen([pgconfig, "--libdir"], &:read).chomp
		dir_config 'pg', incdir, libdir

		# Windows traditionally stores DLLs beside executables, not in libdir
		dlldir = RUBY_PLATFORM=~/mingw|mswin/ ? IO.popen([pgconfig, "--bindir"], &:read).chomp : libdir

	elsif checking_for "libpq per pkg-config" do
			_cflags, ldflags, _libs = pkg_config("libpq")
			dlldir = ldflags && ldflags[/-L([^ ]+)/] && $1
		end

	else
		incdir, libdir = dir_config 'pg'
		dlldir = libdir
	end

	# Try to use runtime path linker option, even if RbConfig doesn't know about it.
	# The rpath option is usually set implicit by dir_config(), but so far not
	# on MacOS-X.
	if dlldir && RbConfig::CONFIG["RPATHFLAG"].to_s.empty?
		append_ldflags "-Wl,-rpath,#{dlldir.quote}"
	end

	if /mswin/ =~ RUBY_PLATFORM
		$libs = append_library($libs, 'ws2_32')
	end
end

$stderr.puts "Using libpq from #{dlldir}"

File.write("postgresql_lib_path.rb", <<-EOT)
module PG
	POSTGRESQL_LIB_PATH = #{dlldir.inspect}
end
EOT
$INSTALLFILES = {
	"./postgresql_lib_path.rb" => "$(RUBYLIBDIR)/pg/"
}

if /solaris/ =~ RUBY_PLATFORM
	append_cppflags( '-D__EXTENSIONS__' )
end

begin
	find_header( 'libpq-fe.h' ) or abort "Can't find the 'libpq-fe.h header"
	find_header( 'libpq/libpq-fs.h' ) or abort "Can't find the 'libpq/libpq-fs.h header"
	find_header( 'pg_config_manual.h' ) or abort "Can't find the 'pg_config_manual.h' header"

	abort "Can't find the PostgreSQL client library (libpq)" unless
		have_library( 'pq', 'PQconnectdb', ['libpq-fe.h'] ) ||
		have_library( 'libpq', 'PQconnectdb', ['libpq-fe.h'] ) ||
		have_library( 'ms/libpq', 'PQconnectdb', ['libpq-fe.h'] )

rescue SystemExit
	install_text = case RUBY_PLATFORM
	when /linux/
	<<-EOT
Please install libpq or postgresql client package like so:
  sudo apt install libpq-dev
  sudo yum install postgresql-devel
  sudo zypper in postgresql-devel
  sudo pacman -S postgresql-libs
EOT
	when /darwin/
	<<-EOT
Please install libpq or postgresql client package like so:
  brew install libpq
EOT
	when /mingw/
	<<-EOT
Please install libpq or postgresql client package like so:
  ridk exec sh -c "pacman -S ${MINGW_PACKAGE_PREFIX}-postgresql"
EOT
	else
	<<-EOT
Please install libpq or postgresql client package.
EOT
	end

	$stderr.puts <<-EOT
*****************************************************************************

Unable to find PostgreSQL client library.

#{install_text}
or try again with:
  gem install pg -- --with-pg-config=/path/to/pg_config

or set library paths manually with:
  gem install pg -- --with-pg-include=/path/to/libpq-fe.h/ --with-pg-lib=/path/to/libpq.so/

EOT
	raise
end

if /mingw/ =~ RUBY_PLATFORM && RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
	# Work around: https://sourceware.org/bugzilla/show_bug.cgi?id=22504
	checking_for "workaround gcc version with link issue" do
		`#{RbConfig::MAKEFILE_CONFIG['CC']} --version`.chomp =~ /\s(\d+)\.\d+\.\d+(\s|$)/ &&
			$1.to_i >= 6 &&
			have_library(':libpq.lib') # Prefer linking to libpq.lib over libpq.dll if available
	end
end

have_func 'PQencryptPasswordConn', 'libpq-fe.h' or # since PostgreSQL-10
	abort "Your PostgreSQL is too old. Either install an older version " +
	      "of this gem or upgrade your database to at least PostgreSQL-10."
# optional headers/functions
have_func 'PQresultMemorySize', 'libpq-fe.h' # since PostgreSQL-12
have_func 'PQenterPipelineMode', 'libpq-fe.h' do |src| # since PostgreSQL-14
  # Ensure header files fit as well
  src + " int con(){ return PGRES_PIPELINE_SYNC; }"
end
have_func 'PQsetChunkedRowsMode', 'libpq-fe.h' # since PostgreSQL-17
have_func 'timegm'
have_func 'rb_io_wait' # since ruby-3.0
have_func 'rb_io_descriptor' # since ruby-3.1
have_func 'rb_hash_new_capa' # since ruby-3.2

have_header 'inttypes.h'
have_header('ruby/fiber/scheduler.h') if RUBY_PLATFORM=~/mingw|mswin/

checking_for "C99 variable length arrays" do
	$defs.push( "-DHAVE_VARIABLE_LENGTH_ARRAYS" ) if try_compile('void test_vla(int l){ int vla[l]; }')
end

create_header()
create_makefile( "pg_ext" )

if gem_platform
	# exercise the strip command on native binary gems
	# This approach borrowed from
	# https://github.com/rake-compiler/rake-compiler-dock/blob/38066d479050f4fdb3956469255b35a05e5949ef/test/rcd_test/ext/mri/extconf.rb#L97C1-L110C42
	strip_tool = RbConfig::CONFIG['STRIP']
	strip_tool += ' -x' if RUBY_PLATFORM =~ /darwin/
		File.open('Makefile.new', 'w') do |o|
		o.puts 'hijack: all strip'
		o.puts
		o.write(File.read('Makefile'))
		o.puts
		o.puts 'strip: $(DLLIB)'
		o.puts "\t$(ECHO) Stripping $(DLLIB)"
		o.puts "\t$(Q) #{strip_tool} $(DLLIB)"
	end
	File.rename('Makefile.new', 'Makefile')
end
