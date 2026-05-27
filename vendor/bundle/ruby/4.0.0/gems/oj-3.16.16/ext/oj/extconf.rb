# frozen_string_literal: true

require 'mkmf'
require 'rbconfig'

extension_name = 'oj'
dir_config(extension_name)

parts = RUBY_DESCRIPTION.split(' ')
type = parts[0]
type = type[4..] if type.start_with?('tcs-')
is_windows = RbConfig::CONFIG['host_os'] =~ /(mingw|mswin)/
platform = RUBY_PLATFORM
version = RUBY_VERSION.split('.')
puts ">>>>> Creating Makefile for #{type} version #{RUBY_VERSION} on #{platform} <<<<<"

dflags = {
  'RUBY_TYPE' => type,
  (type.upcase + '_RUBY') => nil,
  'RUBY_VERSION' => RUBY_VERSION,
  'RUBY_VERSION_MAJOR' => version[0],
  'RUBY_VERSION_MINOR' => version[1],
  'RUBY_VERSION_MICRO' => version[2],
  'IS_WINDOWS' => is_windows ? 1 : 0,
  'RSTRUCT_LEN_RETURNS_INTEGER_OBJECT' => ('ruby' == type && '2' == version[0] && '4' == version[1] && '1' >= version[2]) ? 1 : 0,
}

# Support for compaction.
have_func('rb_gc_mark_movable')
have_func('stpcpy')
have_func('pthread_mutex_init')
have_func('getrlimit', 'sys/resource.h')
have_func('rb_enc_interned_str')
have_func('rb_ext_ractor_safe', 'ruby.h')

dflags['OJ_DEBUG'] = true unless ENV['OJ_DEBUG'].nil?

# SIMD optimizations use runtime CPU detection and function-level target attributes
# We do NOT add global -msse4.2/-msse2 flags here because:
# 1. It would cause illegal instruction errors on CPUs without SSE4.2
# 2. The code uses __attribute__((target("sse4.2"))) for SSE4.2 functions
# 3. Runtime detection in oj_get_simd_implementation() selects the right path
#
# We only add -msse2 if available, since SSE2 is baseline for all x86_64 CPUs
# and needed for compiling the SSE2 fallback code on 32-bit x86
if try_cflags('-msse2')
  $CPPFLAGS += ' -msse2'
end

if enable_config('trace-log', false)
  dflags['OJ_ENABLE_TRACE_LOG'] = 1
end

dflags.each do |k, v|
  if v.nil?
    $CPPFLAGS += " -D#{k}"
  else
    $CPPFLAGS += " -D#{k}=#{v}"
  end
end

$CPPFLAGS += ' -Wall'
# puts "*** $CPPFLAGS: #{$CPPFLAGS}"
# Adding the __attribute__ flag only works with gcc compilers and even then it
# does not work to check args with varargs so just remove the check.
CONFIG['warnflags'].slice!(/ -Wsuggest-attribute=format/)
CONFIG['warnflags'].slice!(/ -Wdeclaration-after-statement/)
CONFIG['warnflags'].slice!(/ -Wmissing-noreturn/)

create_makefile(File.join(extension_name, extension_name))

%x{make clean}
