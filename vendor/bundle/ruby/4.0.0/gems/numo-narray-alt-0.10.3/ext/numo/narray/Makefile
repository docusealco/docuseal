
SHELL = /bin/sh

# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
V0 = $(V:0=)
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@ :)
ECHO = $(ECHO1:0=@ echo)
NULLCMD = :

#### Start of system configuration section. ####

srcdir = .
topdir = /usr/local/include/ruby-4.0.0
hdrdir = $(topdir)
arch_hdrdir = /usr/local/include/ruby-4.0.0/x86_64-linux-musl
PATH_SEPARATOR = :
VPATH = $(srcdir):$(arch_hdrdir)/ruby:$(hdrdir)/ruby:$(srcdir)/src
prefix = $(DESTDIR)/usr/local
rubysitearchprefix = $(rubylibprefix)/$(sitearch)
rubyarchprefix = $(rubylibprefix)/$(arch)
rubylibprefix = $(libdir)/$(RUBY_BASE_NAME)
exec_prefix = $(prefix)
vendorarchhdrdir = $(vendorhdrdir)/$(sitearch)
sitearchhdrdir = $(sitehdrdir)/$(sitearch)
rubyarchhdrdir = $(rubyhdrdir)/$(arch)
vendorhdrdir = $(rubyhdrdir)/vendor_ruby
sitehdrdir = $(rubyhdrdir)/site_ruby
rubyhdrdir = $(includedir)/$(RUBY_VERSION_NAME)
vendorarchdir = $(vendorlibdir)/$(sitearch)
vendorlibdir = $(vendordir)/$(ruby_version)
vendordir = $(rubylibprefix)/vendor_ruby
sitearchdir = $(sitelibdir)/$(sitearch)
sitelibdir = $(sitedir)/$(ruby_version)
sitedir = $(rubylibprefix)/site_ruby
rubyarchdir = $(rubylibdir)/$(arch)
rubylibdir = $(rubylibprefix)/$(ruby_version)
sitearchincludedir = $(includedir)/$(sitearch)
archincludedir = $(includedir)/$(arch)
sitearchlibdir = $(libdir)/$(sitearch)
archlibdir = $(libdir)/$(arch)
ridir = $(datarootdir)/$(RI_BASE_NAME)
modular_gc_dir = $(DESTDIR)
mandir = $(datarootdir)/man
localedir = $(datarootdir)/locale
libdir = $(exec_prefix)/lib
psdir = $(docdir)
pdfdir = $(docdir)
dvidir = $(docdir)
htmldir = $(docdir)
infodir = $(datarootdir)/info
docdir = $(datarootdir)/doc/$(PACKAGE)
oldincludedir = $(DESTDIR)/usr/include
includedir = $(prefix)/include
runstatedir = $(localstatedir)/run
localstatedir = $(prefix)/var
sharedstatedir = $(prefix)/com
sysconfdir = $(prefix)/etc
datadir = $(datarootdir)
datarootdir = $(prefix)/share
libexecdir = $(exec_prefix)/libexec
sbindir = $(exec_prefix)/sbin
bindir = $(exec_prefix)/bin
archdir = $(rubyarchdir)


CC_WRAPPER = 
CC = gcc
CXX = g++
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -Wl,-rpath,$(libdir) -L$(libdir) -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -Wl,-rpath,$(libdir) -L$(libdir) -l$(RUBY_SO_NAME)-static $(MAINLIBS)
empty =
OUTFLAG = -o $(empty)
COUTFLAG = -o $(empty)
CSRCFLAG = $(empty)

RUBY_EXTCONF_H = /app/vendor/bundle/ruby/4.0.0/gems/numo-narray-alt-0.10.3/ext/numo/narray/numo/extconf.h
cflags   = $(hardenflags)  $(optflags) $(debugflags) $(warnflags)
cxxflags = 
optflags = -O3 -fno-fast-math
debugflags = -ggdb3
warnflags = -Wall -Wextra -Wdeprecated-declarations -Wdiv-by-zero -Wduplicated-cond -Wimplicit-function-declaration -Wimplicit-int -Wpointer-arith -Wwrite-strings -Wold-style-definition -Wimplicit-fallthrough=0 -Wmissing-noreturn -Wno-cast-function-type -Wno-constant-logical-operand -Wno-long-long -Wno-missing-field-initializers -Wno-overlength-strings -Wno-packed-bitfield-compat -Wno-parentheses-equality -Wno-self-assign -Wno-tautological-compare -Wno-unused-parameter -Wno-unused-value -Wsuggest-attribute=format -Wsuggest-attribute=noreturn -Wunused-variable -Wmisleading-indentation -Wundef
cppflags = 
CCDLFLAGS = -fPIC
CFLAGS   = $(CCDLFLAGS) $(cflags)  -fPIC $(ARCH_FLAG)
INCFLAGS = -I. -Itypes -I$(arch_hdrdir) -I$(hdrdir)/ruby/backward -I$(hdrdir) -I$(srcdir)
DEFS     = 
CPPFLAGS = -DRUBY_EXTCONF_H=\"$(RUBY_EXTCONF_H)\"  $(DEFS) $(cppflags)
CXXFLAGS = $(CCDLFLAGS)  $(ARCH_FLAG)
ldflags  = -L. -fstack-protector-strong -rdynamic -Wl,-export-dynamic -Wl,--no-as-needed
dldflags = -Wl,--compress-debug-sections=zlib 
ARCH_FLAG = 
DLDFLAGS = $(ldflags) $(dldflags) $(ARCH_FLAG)
LDSHARED = $(CC) -shared
LDSHAREDXX = $(CXX) -shared
POSTLINK = :
AR = gcc-ar
LD = ld
EXEEXT = 

RUBY_INSTALL_NAME = $(RUBY_BASE_NAME)
RUBY_SO_NAME = ruby
RUBYW_INSTALL_NAME = 
RUBY_VERSION_NAME = $(RUBY_BASE_NAME)-$(ruby_version)
RUBYW_BASE_NAME = rubyw
RUBY_BASE_NAME = ruby

arch = x86_64-linux-musl
sitearch = $(arch)
ruby_version = 4.0.0
ruby = $(bindir)/$(RUBY_BASE_NAME)
RUBY = $(ruby)
BUILTRUBY = $(bindir)/$(RUBY_BASE_NAME)
ruby_headers = $(hdrdir)/ruby.h $(hdrdir)/ruby/backward.h $(hdrdir)/ruby/ruby.h $(hdrdir)/ruby/defines.h $(hdrdir)/ruby/missing.h $(hdrdir)/ruby/intern.h $(hdrdir)/ruby/st.h $(hdrdir)/ruby/subst.h $(arch_hdrdir)/ruby/config.h $(RUBY_EXTCONF_H)

RM = rm -f
RM_RF = rm -fr
RMDIRS = rmdir --ignore-fail-on-non-empty -p
MAKEDIRS = /bin/mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp
TOUCH = exit >

#### End of system configuration section. ####

preload = 
libpath = . $(libdir)
LIBPATH = -L. -L$(libdir) -Wl,-rpath,$(libdir)
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 
DISTCLEANDIRS = 

extout = 
extout_prefix = 
target_prefix = /numo/narray
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED)  -lm -lpthread  -lc
ORIG_SRCS = SFMT.c array.c data.c index.c math.c narray.c ndloop.c rand.c step.c struct.c
SRCS = $(ORIG_SRCS) narray.c array.c step.c index.c ndloop.c data.c t_bit.c t_int8.c t_int16.c t_int32.c t_int64.c t_uint8.c t_uint16.c t_uint32.c t_uint64.c t_sfloat.c t_dfloat.c t_scomplex.c t_dcomplex.c t_robject.c math.c SFMT.c struct.c rand.c
OBJS = narray.o array.o step.o index.o ndloop.o data.o t_bit.o t_int8.o t_int16.o t_int32.o t_int64.o t_uint8.o t_uint16.o t_uint32.o t_uint64.o t_sfloat.o t_dfloat.o t_scomplex.o t_dcomplex.o t_robject.o math.o SFMT.o struct.o rand.o
HDRS = $(srcdir)/SFMT-params.h $(srcdir)/SFMT-params19937.h $(srcdir)/SFMT.h
LOCAL_HDRS = 
TARGET = narray
TARGET_NAME = narray
TARGET_ENTRY = Init_$(TARGET_NAME)
DLLIB = $(TARGET).so
EXTSTATIC = 
STATIC_LIB = 

TIMESTAMP_DIR = .
BINDIR        = $(bindir)
RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)
HDRDIR        = $(sitehdrdir)$(target_prefix)
ARCHHDRDIR    = $(sitearchhdrdir)$(target_prefix)
TARGET_SO_DIR =
TARGET_SO     = $(TARGET_SO_DIR)$(DLLIB)
CLEANLIBS     = $(TARGET_SO)
CLEANOBJS     = $(OBJS) *.bak
TARGET_SO_DIR_TIMESTAMP = $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.time

all:    $(DLLIB)
static: $(STATIC_LIB)
.PHONY: all install static install-so install-rb
.PHONY: clean clean-so clean-static clean-rb

clean-static::
clean-rb-default::
clean-rb::
clean-so::
clean: clean-so clean-static clean-rb-default clean-rb
		-$(Q)$(RM_RF) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES) .*.time

distclean-rb-default::
distclean-rb::
distclean-so::
distclean-static::
distclean: clean distclean-so distclean-static distclean-rb-default distclean-rb
		-$(Q)$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		-$(Q)$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)
		-$(Q)$(RMDIRS) $(DISTCLEANDIRS) 2> /dev/null || true

realclean: distclean
install: install-so install-rb

install-so: $(DLLIB) $(TARGET_SO_DIR_TIMESTAMP)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
clean-static::
	-$(Q)$(RM) $(STATIC_LIB)
install-rb: pre-install-rb do-install-rb install-rb-default
install-rb-default: pre-install-rb-default do-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
do-install-rb:
do-install-rb-default:
pre-install-rb-default:
	@$(NULLCMD)
pre-install-rb: $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
do-install-rb: $(RUBYARCHDIR)/../numo/compat.h
$(RUBYARCHDIR)/../numo/compat.h: $(srcdir)/numo/compat.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/compat.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/intern.h
$(RUBYARCHDIR)/../numo/intern.h: $(srcdir)/numo/intern.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/intern.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/narray.h
$(RUBYARCHDIR)/../numo/narray.h: $(srcdir)/numo/narray.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/narray.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/ndloop.h
$(RUBYARCHDIR)/../numo/ndloop.h: $(srcdir)/numo/ndloop.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/ndloop.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/template.h
$(RUBYARCHDIR)/../numo/template.h: $(srcdir)/numo/template.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/template.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/extconf.h
$(RUBYARCHDIR)/../numo/extconf.h: $(srcdir)/numo/extconf.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/extconf.h $@
pre-install-rb: $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
do-install-rb: $(RUBYARCHDIR)/../numo/types/bit.h
$(RUBYARCHDIR)/../numo/types/bit.h: $(srcdir)/numo/types/bit.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/bit.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/complex.h
$(RUBYARCHDIR)/../numo/types/complex.h: $(srcdir)/numo/types/complex.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/complex.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/complex_macro.h
$(RUBYARCHDIR)/../numo/types/complex_macro.h: $(srcdir)/numo/types/complex_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/complex_macro.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/dcomplex.h
$(RUBYARCHDIR)/../numo/types/dcomplex.h: $(srcdir)/numo/types/dcomplex.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/dcomplex.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/dfloat.h
$(RUBYARCHDIR)/../numo/types/dfloat.h: $(srcdir)/numo/types/dfloat.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/dfloat.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/float_def.h
$(RUBYARCHDIR)/../numo/types/float_def.h: $(srcdir)/numo/types/float_def.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/float_def.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/float_macro.h
$(RUBYARCHDIR)/../numo/types/float_macro.h: $(srcdir)/numo/types/float_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/float_macro.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/int16.h
$(RUBYARCHDIR)/../numo/types/int16.h: $(srcdir)/numo/types/int16.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/int16.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/int32.h
$(RUBYARCHDIR)/../numo/types/int32.h: $(srcdir)/numo/types/int32.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/int32.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/int64.h
$(RUBYARCHDIR)/../numo/types/int64.h: $(srcdir)/numo/types/int64.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/int64.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/int8.h
$(RUBYARCHDIR)/../numo/types/int8.h: $(srcdir)/numo/types/int8.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/int8.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/int_macro.h
$(RUBYARCHDIR)/../numo/types/int_macro.h: $(srcdir)/numo/types/int_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/int_macro.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/real_accum.h
$(RUBYARCHDIR)/../numo/types/real_accum.h: $(srcdir)/numo/types/real_accum.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/real_accum.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/robj_macro.h
$(RUBYARCHDIR)/../numo/types/robj_macro.h: $(srcdir)/numo/types/robj_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/robj_macro.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/robject.h
$(RUBYARCHDIR)/../numo/types/robject.h: $(srcdir)/numo/types/robject.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/robject.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/scomplex.h
$(RUBYARCHDIR)/../numo/types/scomplex.h: $(srcdir)/numo/types/scomplex.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/scomplex.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/sfloat.h
$(RUBYARCHDIR)/../numo/types/sfloat.h: $(srcdir)/numo/types/sfloat.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/sfloat.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/uint16.h
$(RUBYARCHDIR)/../numo/types/uint16.h: $(srcdir)/numo/types/uint16.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/uint16.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/uint32.h
$(RUBYARCHDIR)/../numo/types/uint32.h: $(srcdir)/numo/types/uint32.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/uint32.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/uint64.h
$(RUBYARCHDIR)/../numo/types/uint64.h: $(srcdir)/numo/types/uint64.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/uint64.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/uint8.h
$(RUBYARCHDIR)/../numo/types/uint8.h: $(srcdir)/numo/types/uint8.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/uint8.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/uint_macro.h
$(RUBYARCHDIR)/../numo/types/uint_macro.h: $(srcdir)/numo/types/uint_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/uint_macro.h $@
do-install-rb: $(RUBYARCHDIR)/../numo/types/xint_macro.h
$(RUBYARCHDIR)/../numo/types/xint_macro.h: $(srcdir)/numo/types/xint_macro.h $(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time
	$(Q) $(INSTALL_DATA) $(srcdir)/numo/types/xint_macro.h $@
pre-install-rb:
	$(Q1:0=@$(MAKE) -q do-install-rb || )$(ECHO1:0=echo) installing narray libraries
$(TARGET_SO_DIR_TIMESTAMP):
	$(Q) $(MAKEDIRS) $(@D) $(RUBYARCHDIR)
	$(Q) $(TOUCH) $@
$(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.time:
	$(Q) $(MAKEDIRS) $(@D) $(RUBYARCHDIR)/../numo
	$(Q) $(TOUCH) $@
$(TIMESTAMP_DIR)/.sitearchdir.-.numo.-.narray.-....-.numo.-.types.time:
	$(Q) $(MAKEDIRS) $(@D) $(RUBYARCHDIR)/../numo/types
	$(Q) $(TOUCH) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .mm .cxx .cpp .o .S

.cc.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cc.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.mm.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.mm.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.cxx.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cxx.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.cpp.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cpp.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.c.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.c.S:
	$(ECHO) translating $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.m.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.m.S:
	$(ECHO) translating $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

$(TARGET_SO): $(OBJS) Makefile
	$(ECHO) linking shared-object numo/narray/$(DLLIB)
	-$(Q)$(RM) $(@)
	$(Q) $(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)
	$(Q) $(POSTLINK)



$(OBJS): $(HDRS) $(ruby_headers)
