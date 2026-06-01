require "mkmf"

# concatenate trilogy library sources to allow the compiler to optimise across
# source files

trilogy_src_dir = File.realpath("src", __dir__)
File.binwrite("trilogy.c",
  Dir["#{trilogy_src_dir}/**/*.c"].map { |src|
    %{#line 1 "#{src}"\n} + File.binread(src)
  }.join)

$objs = %w[trilogy.o cast.o cext.o]
append_cflags(["-I #{__dir__}/inc", "-std=gnu99", "-fvisibility=hidden", "-DTRILOGY_XALLOCATOR", "-g"])

dir_config("openssl").any? || pkg_config("openssl")

have_library("crypto", "CRYPTO_malloc")
have_library("ssl", "SSL_new")
have_func("rb_ractor_local_storage_value_newkey", "ruby.h")
have_func("rb_enc_interned_str", "ruby.h")
have_func("rb_io_descriptor", "ruby.h") # Ruby 3.1+

create_makefile "trilogy/cext"
