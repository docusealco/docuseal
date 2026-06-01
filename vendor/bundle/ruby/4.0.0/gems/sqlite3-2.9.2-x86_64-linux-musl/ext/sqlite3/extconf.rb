require "mkmf"
require "yaml"

module Sqlite3
  module ExtConf
    ENV_ALLOWLIST = ["CC", "CFLAGS", "LDFLAGS", "LIBS", "CPPFLAGS", "LT_SYS_LIBRARY_PATH", "CPP"]

    class << self
      def configure
        configure_cross_compiler

        if system_libraries?
          message "Building sqlite3-ruby using system #{libname}.\n"
          configure_system_libraries
        else
          message "Building sqlite3-ruby using packaged sqlite3.\n"
          configure_packaged_libraries
        end

        configure_extension

        create_makefile("sqlite3/sqlite3_native")
      end

      def configure_cross_compiler
        RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"] if ENV["CC"]
        ENV["CC"] = RbConfig::CONFIG["CC"]
      end

      def system_libraries?
        sqlcipher? || enable_config("system-libraries")
      end

      def libname
        sqlcipher? ? "sqlcipher" : "sqlite3"
      end

      def sqlcipher?
        with_config("sqlcipher") ||
          with_config("sqlcipher-dir") ||
          with_config("sqlcipher-include") ||
          with_config("sqlcipher-lib")
      end

      def configure_system_libraries
        pkg_config(libname)
        append_cppflags("-DUSING_SQLCIPHER") if sqlcipher?
      end

      def configure_packaged_libraries
        minimal_recipe.tap do |recipe|
          recipe.configure_options += [
            "--disable-shared",
            "--enable-static",
            "--enable-fts5"
          ]
          ENV.to_h.tap do |env|
            user_cflags = with_config("sqlite-cflags")
            more_cflags = [
              "-fPIC", # needed for linking the static library into a shared library
              "-O2", # see https://github.com/sparklemotion/sqlite3-ruby/issues/335 for some benchmarks
              "-fvisibility=hidden", # see https://github.com/rake-compiler/rake-compiler-dock/issues/87
              "-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
              "-DSQLITE_USE_URI=1",
              "-DSQLITE_ENABLE_DBPAGE_VTAB=1",
              "-DSQLITE_ENABLE_DBSTAT_VTAB=1"
            ]
            env["CFLAGS"] = [user_cflags, env["CFLAGS"], more_cflags].flatten.join(" ")
            recipe.configure_options += env.select { |k, v| ENV_ALLOWLIST.include?(k) }
              .map { |key, value| "#{key}=#{value.strip}" }
          end

          unless File.exist?(File.join(recipe.target, recipe.host, recipe.name, recipe.version))
            recipe.cook
          end
          recipe.activate

          # on macos, pkg-config will not return --cflags without this
          ENV["PKG_CONFIG_ALLOW_SYSTEM_CFLAGS"] = "t"

          # only needed for Ruby 3.1.3, see https://bugs.ruby-lang.org/issues/19233
          RbConfig::CONFIG["PKG_CONFIG"] = config_string("PKG_CONFIG") || "pkg-config"

          lib_path = File.join(recipe.path, "lib")
          pcfile = File.join(lib_path, "pkgconfig", "sqlite3.pc")
          abort_pkg_config("pkg_config") unless pkg_config(pcfile)

          # see https://bugs.ruby-lang.org/issues/18490
          ldflags = xpopen(["pkg-config", "--libs", "--static", pcfile], err: [:child, :out], &:read)
          abort_pkg_config("xpopen") unless $?.success?
          ldflags = ldflags.split

          # see https://github.com/flavorjones/mini_portile/issues/118
          "-L#{lib_path}".tap do |lib_path_flag|
            ldflags.prepend(lib_path_flag) unless ldflags.include?(lib_path_flag)
          end

          ldflags.each { |ldflag| append_ldflags(ldflag) }

          append_cppflags("-DUSING_PACKAGED_LIBRARIES")
          append_cppflags("-DUSING_PRECOMPILED_LIBRARIES") if cross_build?
        end
      end

      def configure_extension
        append_cflags("-fvisibility=hidden") # see https://github.com/rake-compiler/rake-compiler-dock/issues/87

        if find_header("sqlite3.h")
          # noop
        elsif sqlcipher? && find_header("sqlcipher/sqlite3.h")
          append_cppflags("-DUSING_SQLCIPHER_INC_SUBDIR")
        else
          abort_could_not_find("sqlite3.h")
        end

        abort_could_not_find(libname) unless find_library(libname, "sqlite3_libversion_number", "sqlite3.h")

        # Truffle Ruby doesn't support this yet:
        # https://github.com/oracle/truffleruby/issues/3408
        have_func("rb_enc_interned_str_cstr")

        # Functions defined in 1.9 but not 1.8
        have_func("rb_proc_arity")

        # Functions defined in 2.1 but not 2.0
        have_func("rb_integer_pack")

        # These functions may not be defined
        have_func("sqlite3_initialize")
        have_func("sqlite3_backup_init")
        have_func("sqlite3_column_database_name")
        have_func("sqlite3_enable_load_extension")
        have_func("sqlite3_load_extension")

        unless have_func("sqlite3_open_v2") # https://www.sqlite.org/releaselog/3_5_0.html
          abort("\nPlease use a version of SQLite3 >= 3.5.0\n\n")
        end

        have_func("sqlite3_prepare_v2")
        have_func("sqlite3_db_name", "sqlite3.h") # v3.39.0
        have_func("sqlite3_error_offset", "sqlite3.h") # v3.38.0

        have_type("sqlite3_int64", "sqlite3.h")
        have_type("sqlite3_uint64", "sqlite3.h")
      end

      def minimal_recipe
        require "mini_portile2"

        MiniPortile.new(libname, sqlite3_config[:version]).tap do |recipe|
          if sqlite_source_dir
            recipe.source_directory = sqlite_source_dir
          else
            recipe.files = sqlite3_config[:files]
            recipe.target = File.join(package_root_dir, "ports")
            recipe.patch_files = Dir[File.join(package_root_dir, "patches", "*.patch")].sort
          end
        end
      end

      def package_root_dir
        File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
      end

      def sqlite3_config
        mini_portile_config[:sqlite3]
      end

      def mini_portile_config
        YAML.load_file(File.join(package_root_dir, "dependencies.yml"), symbolize_names: true)
      end

      def abort_could_not_find(missing)
        abort("\nCould not find #{missing}.\nPlease visit https://github.com/sparklemotion/sqlite3-ruby for installation instructions.\n\n")
      end

      def abort_pkg_config(id)
        abort("\nCould not configure the build properly (#{id}). Please install the `pkg-config` utility.\n\n")
      end

      def cross_build?
        enable_config("cross-build")
      end

      def sqlite_source_dir
        arg_config("--with-sqlite-source-dir")
      end

      def download
        minimal_recipe.download
      end

      def darwin?
        RbConfig::CONFIG["target_os"].include?("darwin")
      end

      def windows?
        RbConfig::CONFIG["target_os"].match?(/mingw|mswin/)
      end

      def print_help
        print(<<~TEXT)
          USAGE: ruby #{$PROGRAM_NAME} [options]

            Flags that are always valid:

                --disable-system-libraries
                    Use the packaged libraries, and ignore the system libraries.
                    (This is the default behavior.)

                --enable-system-libraries
                    Use system libraries instead of building and using the packaged libraries.

                --with-sqlcipher
                    Use libsqlcipher instead of libsqlite3.
                    (Implies `--enable-system-libraries`.)

                --with-sqlite-source-dir=DIRECTORY
                    (dev only) Build sqlite from the source code in DIRECTORY

                --help
                    Display this message.


            Flags only used when using system libraries:

                General (applying to all system libraries):

                    --with-opt-dir=DIRECTORY
                        Look for headers and libraries in DIRECTORY.

                    --with-opt-lib=DIRECTORY
                        Look for libraries in DIRECTORY.

                    --with-opt-include=DIRECTORY
                        Look for headers in DIRECTORY.

                Related to sqlcipher:

                    --with-sqlcipher-dir=DIRECTORY
                        Look for sqlcipher headers and library in DIRECTORY.
                        (Implies `--with-sqlcipher` and `--enable-system-libraries`.)

                    --with-sqlcipher-lib=DIRECTORY
                        Look for sqlcipher library in DIRECTORY.
                        (Implies `--with-sqlcipher` and `--enable-system-libraries`.)

                    --with-sqlcipher-include=DIRECTORY
                        Look for sqlcipher headers in DIRECTORY.
                        (Implies `--with-sqlcipher` and `--enable-system-libraries`.)


            Flags only used when building and using the packaged libraries:

                --with-sqlite-cflags=CFLAGS
                    Explicitly pass compiler flags to the sqlite library build. These flags will
                    appear on the commandline before any flags set in the CFLAGS environment
                    variable. This is useful for setting compilation options in your project's
                    bundler config. See INSTALLATION.md for more information.

                --enable-cross-build
                    Enable cross-build mode. (You probably do not want to set this manually.)


            Environment variables used for compiling the gem's C extension:

                CC
                    Use this path to invoke the compiler instead of `RbConfig::CONFIG['CC']`


            Environment variables passed through to the compilation of sqlite:

                CC
                CPPFLAGS
                CFLAGS
                LDFLAGS
                LIBS
                LT_SYS_LIBRARY_PATH
                CPP

        TEXT
      end
    end
  end
end

if arg_config("--help")
  Sqlite3::ExtConf.print_help
  exit!(0)
end

if arg_config("--download-dependencies")
  Sqlite3::ExtConf.download
  exit!(0)
end

Sqlite3::ExtConf.configure
