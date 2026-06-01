require 'mkmf'

dir_config("puma_http11")

if $mingw
  append_cflags  '-fstack-protector-strong -D_FORTIFY_SOURCE=2'
  append_ldflags '-fstack-protector-strong -l:libssp.a'
  have_library 'ssp'
end

unless ENV["PUMA_DISABLE_SSL"]
  # don't use pkg_config('openssl') if '--with-openssl-dir' is used
  has_openssl_dir = dir_config('openssl').any? ||
    RbConfig::CONFIG['configure_args']&.include?('openssl')

  found_pkg_config = !has_openssl_dir && pkg_config('openssl')

  found_ssl = if !$mingw && found_pkg_config
    puts '──── Using OpenSSL pkgconfig (openssl.pc) ────'
    true
  elsif have_library('libcrypto', 'BIO_read') && have_library('libssl', 'SSL_CTX_new')
    true
  elsif %w'crypto libeay32'.find {|crypto| have_library(crypto, 'BIO_read')} &&
      %w'ssl ssleay32'.find {|ssl| have_library(ssl, 'SSL_CTX_new')}
    true
  else
    puts '** Puma will be compiled without SSL support'
    false
  end

  if found_ssl
    have_header "openssl/bio.h"

    ssl_h = "openssl/ssl.h".freeze

    puts "\n──── Below are yes for 1.0.2 & later ────"
    have_func "DTLS_method"                            , ssl_h
    have_func "SSL_CTX_set_session_cache_mode(NULL, 0)", ssl_h

    puts "\n──── Below are yes for 1.1.0 & later ────"
    have_func "TLS_server_method"                      , ssl_h
    have_func "SSL_CTX_set_min_proto_version(NULL, 0)" , ssl_h

    puts "\n──── Below is yes for 1.1.0 and later, but isn't documented until 3.0.0 ────"
    # https://github.com/openssl/openssl/blob/OpenSSL_1_1_0/include/openssl/ssl.h#L1159
    have_func "SSL_CTX_set_dh_auto(NULL, 0)"           , ssl_h

    puts "\n──── Below is yes for 1.1.1 & later ────"
    have_func "SSL_CTX_set_ciphersuites(NULL, \"\")"   , ssl_h

    puts "\n──── Below is yes for 3.0.0 & later ────"
    have_func "SSL_get1_peer_certificate"              , ssl_h

    puts ''
  end
end

if ENV["PUMA_MAKE_WARNINGS_INTO_ERRORS"]
  # Make all warnings into errors
  # Except `implicit-fallthrough` since most failures comes from ragel state machine generated code
  append_cflags(config_string('WERRORFLAG') || '-Werror')
  append_cflags '-Wno-implicit-fallthrough'
end

create_makefile("puma/puma_http11")
