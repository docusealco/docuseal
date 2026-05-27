# frozen_string_literal: true

require 'rbconfig'
require 'mkmf'

def d(file)
  File.join(__dir__, file)
end

rm_f d('numo/extconf.h')

$INCFLAGS = "-Itypes #{$INCFLAGS}"
$VPATH << '$(srcdir)/src'

$INSTALLFILES = Dir.glob(%w[numo/*.h numo/types/*.h]).map { |x| [x, '$(archdir)/../'] }
$INSTALLFILES << ['numo/extconf.h', '$(archdir)/../']
if /cygwin|mingw/.match?(RUBY_PLATFORM)
  $DLDFLAGS << ' -Wl,--export-all,--out-implib=libnarray.a'
  $INSTALLFILES << ['./libnarray.a', '$(archdir)']
end

srcs = %w[
  narray
  array
  step
  index
  ndloop
  data
  t_bit
  t_int8
  t_int16
  t_int32
  t_int64
  t_uint8
  t_uint16
  t_uint32
  t_uint64
  t_sfloat
  t_dfloat
  t_scomplex
  t_dcomplex
  t_robject
  math
  SFMT
  struct
  rand
]

stdbool = ('stdbool.h' if have_header('stdbool.h'))

stdint = if have_header('stdint.h')
           'stdint.h'
         elsif have_header('sys/types.h')
           'sys/types.h'
         end

have_type('bool', stdbool)
have_type('uint8_t', stdint) unless have_type('u_int8_t', stdint)
have_type('uint16_t', stdint) unless have_type('u_int16_t', stdint)
have_type('int32_t', stdint)
have_type('uint32_t', stdint) unless have_type('u_int32_t', stdint)
have_type('int64_t', stdint)
have_type('uint64_t', stdint) unless have_type('u_int64_t', stdint)
have_func('exp10')
have_func('RTYPEDDATA_GET_DATA')

have_var('rb_cComplex')

$objs = srcs.collect { |i| "#{i}.o" }

create_header d('numo/extconf.h')

create_makefile('numo/narray/narray')
