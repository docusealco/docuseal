/*
  math.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#include <ruby.h>

#include "numo/narray.h"

VALUE numo_mNMath;
extern VALUE numo_mDFloatMath, numo_mDComplexMath;
extern VALUE numo_mSFloatMath, numo_mSComplexMath;
static ID id_send;
static ID id_UPCAST;
static ID id_DISPATCH;
static ID id_extract;

static VALUE nary_type_s_upcast(VALUE type1, VALUE type2) {
  VALUE upcast_hash;
  VALUE result_type;

  if (type1 == type2) return type1;
  upcast_hash = rb_const_get(type1, id_UPCAST);
  result_type = rb_hash_aref(upcast_hash, type2);
  if (NIL_P(result_type)) {
    if (TYPE(type2) == T_CLASS) {
      if (RTEST(rb_class_inherited_p(type2, cNArray))) {
        upcast_hash = rb_const_get(type2, id_UPCAST);
        result_type = rb_hash_aref(upcast_hash, type1);
      }
    }
  }
  return result_type;
}

static VALUE nary_math_cast2(VALUE type1, VALUE type2) {
  if (RTEST(rb_class_inherited_p(type1, cNArray))) {
    return nary_type_s_upcast(type1, type2);
  }
  if (RTEST(rb_class_inherited_p(type2, cNArray))) {
    return nary_type_s_upcast(type2, type1);
  }
  if (RTEST(rb_class_inherited_p(type1, rb_cNumeric)) &&
      RTEST(rb_class_inherited_p(type2, rb_cNumeric))) {
    if (RTEST(rb_class_inherited_p(type1, rb_cComplex)) ||
        RTEST(rb_class_inherited_p(type2, rb_cComplex))) {
      return rb_cComplex;
    }
    return rb_cFloat;
  }
  return type2;
}

VALUE na_ary_composition_dtype(VALUE);

static VALUE nary_mathcast(int argc, VALUE* argv) {
  VALUE type, type2;
  int i;

  type = na_ary_composition_dtype(argv[0]);
  for (i = 1; i < argc; i++) {
    type2 = na_ary_composition_dtype(argv[i]);
    type = nary_math_cast2(type, type2);
    if (NIL_P(type)) {
      rb_raise(rb_eTypeError, "includes unknown DataType for upcast");
    }
  }
  return type;
}

/*
  Dispatches method to Math module of upcasted type,
  eg, Numo::DFloat::Math.
  @overload method_missing(name,x,...)
    @param [Symbol] name  method name.
    @param [NArray,Numeric] x  input array.
    @return [NArray] result.
*/
static VALUE nary_math_method_missing(int argc, VALUE* argv, VALUE mod) {
  VALUE type, ans, typemod, hash;
  if (argc > 1) {
    type = nary_mathcast(argc - 1, argv + 1);

    hash = rb_const_get(mod, id_DISPATCH);
    typemod = rb_hash_aref(hash, type);
    if (NIL_P(typemod)) {
      rb_raise(rb_eTypeError, "%s is unknown for Numo::NMath", rb_class2name(type));
    }

    ans = rb_funcall2(typemod, id_send, argc, argv);

    if (!RTEST(rb_class_inherited_p(type, cNArray)) && IsNArray(ans)) {
      ans = rb_funcall(ans, id_extract, 0);
    }
    return ans;
  }
  rb_raise(rb_eArgError, "argument or method missing");
  return Qnil;
}

void Init_nary_math(void) {
  VALUE hCast;

  /**
   * Document-module: Numo::NMath
   *
   * This module provides mathematical functions for NArray.
   */
  numo_mNMath = rb_define_module_under(mNumo, "NMath");
  rb_define_singleton_method(numo_mNMath, "method_missing", nary_math_method_missing, -1);

  hCast = rb_hash_new();
  rb_hash_aset(hCast, numo_cInt64, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cInt32, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cInt16, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cInt8, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cUInt64, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cUInt32, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cUInt16, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cUInt8, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cDFloat, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cDFloat, numo_mDFloatMath);
  rb_hash_aset(hCast, numo_cDComplex, numo_mDComplexMath);
  rb_hash_aset(hCast, numo_cSFloat, numo_mSFloatMath);
  rb_hash_aset(hCast, numo_cSComplex, numo_mSComplexMath);
  rb_hash_aset(hCast, rb_cInteger, rb_mMath);
  rb_hash_aset(hCast, rb_cFloat, rb_mMath);
  rb_hash_aset(hCast, rb_cComplex, numo_mDComplexMath);
  /* Dispatch table representing the corresponding Math module. */
  rb_define_const(numo_mNMath, "DISPATCH", hCast);

  id_send = rb_intern("send");
  id_UPCAST = rb_intern("UPCAST");
  id_DISPATCH = rb_intern("DISPATCH");
  id_extract = rb_intern("extract");
}
