/*
  t_dcomplex.c
  Ruby/Numo::NArray - Numerical Array class for Ruby

  created on: 2017-03-11
  Copyright (C) 2017-2020 Masahiro Tanaka
*/
#include <assert.h>
#include <ruby.h>

#include "SFMT.h"
#include "numo/narray.h"
#include "numo/template.h"

#define m_map(x) m_num_to_data(rb_yield(m_data_to_num(x)))

#ifdef __SSE2__
#include <emmintrin.h>
#define SIMD_ALIGNMENT_SIZE 16
#endif

static ID id_pow;
static ID id_cast;
static ID id_copysign;
static ID id_eq;
static ID id_imag;
static ID id_mulsum;
static ID id_ne;
static ID id_nearly_eq;
static ID id_real;
static ID id_to_a;

#include <numo/types/dcomplex.h>

/*
  class definition: Numo::DComplex
*/
VALUE cT;
extern VALUE cRT;

#include "mh/store.h"
#include "mh/s_cast.h"
#include "mh/extract.h"
#include "mh/aref.h"
#include "mh/aset.h"
#include "mh/coerce_cast.h"
#include "mh/to_a.h"
#include "mh/fill.h"
#include "mh/format.h"
#include "mh/format_to_a.h"
#include "mh/inspect.h"
#include "mh/each.h"
#include "mh/map.h"
#include "mh/each_with_index.h"
#include "mh/map_with_index.h"
#include "mh/abs.h"
#include "mh/op/add.h"
#include "mh/op/sub.h"
#include "mh/op/mul.h"
#include "mh/op/div.h"
#include "mh/pow.h"
#include "mh/minus.h"
#include "mh/reciprocal.h"
#include "mh/sign.h"
#include "mh/square.h"
#include "mh/conj.h"
#include "mh/im.h"
#include "mh/real.h"
#include "mh/imag.h"
#include "mh/arg.h"
#include "mh/set_imag.h"
#include "mh/set_real.h"
#include "mh/comp/eq.h"
#include "mh/comp/ne.h"
#include "mh/comp/nearly_eq.h"
#include "mh/round/floor.h"
#include "mh/round/round.h"
#include "mh/round/ceil.h"
#include "mh/round/trunc.h"
#include "mh/round/rint.h"
#include "mh/copysign.h"
#include "mh/isnan.h"
#include "mh/isinf.h"
#include "mh/isposinf.h"
#include "mh/isneginf.h"
#include "mh/isfinite.h"
#include "mh/sum.h"
#include "mh/prod.h"
#include "mh/kahan_sum.h"
#include "mh/mean.h"
#include "mh/var.h"
#include "mh/stddev.h"
#include "mh/rms.h"
#include "mh/cumsum.h"
#include "mh/cumprod.h"
#include "mh/mulsum.h"
#include "mh/seq.h"
#include "mh/logseq.h"
#include "mh/eye.h"
#include "mh/rand.h"
#include "mh/rand_norm.h"
#include "mh/poly.h"
#include "mh/math/sqrt.h"
#include "mh/math/cbrt.h"
#include "mh/math/log.h"
#include "mh/math/log2.h"
#include "mh/math/log10.h"
#include "mh/math/exp.h"
#include "mh/math/exp2.h"
#include "mh/math/exp10.h"
#include "mh/math/sin.h"
#include "mh/math/cos.h"
#include "mh/math/tan.h"
#include "mh/math/asin.h"
#include "mh/math/acos.h"
#include "mh/math/atan.h"
#include "mh/math/sinh.h"
#include "mh/math/cosh.h"
#include "mh/math/tanh.h"
#include "mh/math/asinh.h"
#include "mh/math/acosh.h"
#include "mh/math/atanh.h"
#include "mh/math/sinc.h"

DEF_NARRAY_CMP_STORE_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_S_CAST_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_EXTRACT_METHOD_FUNC(dcomplex)
DEF_NARRAY_AREF_METHOD_FUNC(dcomplex)
DEF_CMP_EXTRACT_DATA_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_ASET_METHOD_FUNC(dcomplex)
DEF_NARRAY_COERCE_CAST_METHOD_FUNC(dcomplex)
DEF_NARRAY_TO_A_METHOD_FUNC(dcomplex)
DEF_NARRAY_FILL_METHOD_FUNC(dcomplex)
DEF_NARRAY_FORMAT_METHOD_FUNC(dcomplex)
DEF_NARRAY_FORMAT_TO_A_METHOD_FUNC(dcomplex)
DEF_NARRAY_INSPECT_METHOD_FUNC(dcomplex)
DEF_NARRAY_EACH_METHOD_FUNC(dcomplex)
DEF_NARRAY_MAP_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_EACH_WITH_INDEX_METHOD_FUNC(dcomplex)
DEF_NARRAY_MAP_WITH_INDEX_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_ABS_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_ADD_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_SUB_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_MUL_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_DIV_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_POW_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_MINUS_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_RECIPROCAL_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_SIGN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_SQUARE_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_CONJ_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_IM_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_REAL_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_IMAG_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_ARG_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_SET_IMAG_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_SET_REAL_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_EQ_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_NE_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_NEARLY_EQ_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_FLOOR_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ROUND_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_CEIL_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_TRUNC_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_RINT_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_COPYSIGN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ISNAN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ISINF_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ISPOSINF_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ISNEGINF_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ISFINITE_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SUM_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_PROD_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_KAHAN_SUM_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_MEAN_METHOD_FUNC(dcomplex, numo_cDComplex, dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_VAR_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_FLT_STDDEV_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_FLT_RMS_METHOD_FUNC(dcomplex, numo_cDComplex, double, numo_cDFloat)
DEF_NARRAY_FLT_CUMSUM_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_CUMPROD_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_MULSUM_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SEQ_METHOD_FUNC(dcomplex)
DEF_NARRAY_FLT_LOGSEQ_METHOD_FUNC(dcomplex)
DEF_NARRAY_EYE_METHOD_FUNC(dcomplex)
DEF_NARRAY_CMP_RAND_METHOD_FUNC(dcomplex)
DEF_NARRAY_CMP_RAND_NORM_METHOD_FUNC(dcomplex, double)
DEF_NARRAY_POLY_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SQRT_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_CBRT_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_LOG_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_LOG2_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_LOG10_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_EXP_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_EXP2_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_EXP10_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SIN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_COS_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_TAN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ASIN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ACOS_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ATAN_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SINH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_COSH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_TANH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ASINH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ACOSH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_ATANH_METHOD_FUNC(dcomplex, numo_cDComplex)
DEF_NARRAY_FLT_SINC_METHOD_FUNC(dcomplex, numo_cDComplex)

static size_t dcomplex_memsize(const void* ptr) {
  size_t size = sizeof(narray_data_t);
  const narray_data_t* na = (const narray_data_t*)ptr;

  assert(na->base.type == NARRAY_DATA_T);

  if (na->ptr != NULL) {

    size += na->base.size * sizeof(dtype);
  }
  if (na->base.size > 0) {
    if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
      size += sizeof(size_t) * na->base.ndim;
    }
  }
  return size;
}

static void dcomplex_free(void* ptr) {
  narray_data_t* na = (narray_data_t*)ptr;

  assert(na->base.type == NARRAY_DATA_T);

  if (na->ptr != NULL) {
    if (na->owned) {
      xfree(na->ptr);
    }
    na->ptr = NULL;
  }
  if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
    xfree(na->base.shape);
    na->base.shape = NULL;
  }
  xfree(na);
}

static narray_type_info_t dcomplex_info = {

  0,             // element_bits
  sizeof(dtype), // element_bytes
  sizeof(dtype), // element_stride (in bytes)

};

static const rb_data_type_t dcomplex_data_type = {
  "Numo::DComplex",
  {
    0,
    dcomplex_free,
    dcomplex_memsize,
  },
  &na_data_type,
  &dcomplex_info,
  RUBY_TYPED_FROZEN_SHAREABLE, // flags
};

static VALUE dcomplex_s_alloc_func(VALUE klass) {
  narray_data_t* na = ALLOC(narray_data_t);

  na->base.ndim = 0;
  na->base.type = NARRAY_DATA_T;
  na->base.flag[0] = NA_FL0_INIT;
  na->base.flag[1] = NA_FL1_INIT;
  na->base.size = 0;
  na->base.shape = NULL;
  na->base.reduce = INT2FIX(0);
  na->ptr = NULL;
  na->owned = FALSE;
  return TypedData_Wrap_Struct(klass, &dcomplex_data_type, (void*)na);
}

static VALUE dcomplex_allocate(VALUE self) {
  narray_t* na;
  char* ptr;

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    ptr = NA_DATA_PTR(na);
    if (na->size > 0 && ptr == NULL) {
      ptr = xmalloc(sizeof(dtype) * na->size);

      NA_DATA_PTR(na) = ptr;
      NA_DATA_OWNED(na) = TRUE;
    }
    break;
  case NARRAY_VIEW_T:
    rb_funcall(NA_VIEW_DATA(na), rb_intern("allocate"), 0);
    break;
  case NARRAY_FILEMAP_T:
    // ptr = ((narray_filemap_t*)na)->ptr;
    //  to be implemented
  default:
    rb_bug("invalid narray type : %d", NA_TYPE(na));
  }
  return self;
}

VALUE mTM;

void Init_numo_dcomplex(void) {
  VALUE hCast, mNumo;

  mNumo = rb_define_module("Numo");

  id_pow = rb_intern("**");
  id_cast = rb_intern("cast");
  id_copysign = rb_intern("copysign");
  id_eq = rb_intern("eq");
  id_imag = rb_intern("imag");
  id_mulsum = rb_intern("mulsum");
  id_ne = rb_intern("ne");
  id_nearly_eq = rb_intern("nearly_eq");
  id_real = rb_intern("real");
  id_to_a = rb_intern("to_a");

  /**
   * Document-class: Numo::DComplex
   *
   * Double precision floating point complex number N-dimensional array class.
   */
  cT = rb_define_class_under(mNumo, "DComplex", cNArray);

  // alias of DComplex
  rb_define_const(mNumo, "Complex64", numo_cDComplex);

  hCast = rb_hash_new();
  /* Upcasting rules of DComplex. */
  rb_define_const(cT, "UPCAST", hCast);
  rb_hash_aset(hCast, rb_cArray, cT);

  rb_hash_aset(hCast, rb_cInteger, cT);
  rb_hash_aset(hCast, rb_cFloat, cT);
  rb_hash_aset(hCast, rb_cComplex, cT);
  rb_hash_aset(hCast, numo_cRObject, numo_cRObject);
  rb_hash_aset(hCast, numo_cDComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cSComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cDFloat, numo_cDComplex);
  rb_hash_aset(hCast, numo_cSFloat, numo_cDComplex);
  rb_hash_aset(hCast, numo_cInt64, numo_cDComplex);
  rb_hash_aset(hCast, numo_cInt32, numo_cDComplex);
  rb_hash_aset(hCast, numo_cInt16, numo_cDComplex);
  rb_hash_aset(hCast, numo_cInt8, numo_cDComplex);
  rb_hash_aset(hCast, numo_cUInt64, numo_cDComplex);
  rb_hash_aset(hCast, numo_cUInt32, numo_cDComplex);
  rb_hash_aset(hCast, numo_cUInt16, numo_cDComplex);
  rb_hash_aset(hCast, numo_cUInt8, numo_cDComplex);
  rb_obj_freeze(hCast);

  /* Element size of DComplex in bits. */
  rb_define_const(cT, "ELEMENT_BIT_SIZE", INT2FIX(sizeof(dtype) * 8));
  /* Element size of DComplex in bytes. */
  rb_define_const(cT, "ELEMENT_BYTE_SIZE", INT2FIX(sizeof(dtype)));
  /* Stride size of contiguous DComplex array. */
  rb_define_const(cT, "CONTIGUOUS_STRIDE", INT2FIX(sizeof(dtype)));
  /* Machine epsilon of DComplex. */
  rb_define_const(cT, "EPSILON", M_EPSILON);
  /* The largest representable value of DComplex. */
  rb_define_const(cT, "MAX", M_MAX);
  /* The smallest representable value of DComplex. */
  rb_define_const(cT, "MIN", M_MIN);
  rb_define_alloc_func(cT, dcomplex_s_alloc_func);
  rb_define_method(cT, "allocate", dcomplex_allocate, 0);
  /**
   * Extract an element only if self is a dimensionless NArray.
   * @overload extract
   *   @return [Numeric,Numo::NArray]
   *   --- Extract element value as Ruby Object if self is a dimensionless NArray,
   * otherwise returns self.
   */
  rb_define_method(cT, "extract", dcomplex_extract, 0);
  /**
   * Store elements to Numo::DComplex from other.
   * @overload store(other)
   *   @param [Object] other
   *   @return [Numo::DComplex] self
   */
  rb_define_method(cT, "store", dcomplex_store, 1);
  /**
   * Cast object to Numo::DComplex.
   * @overload [](elements)
   * @overload cast(array)
   *   @param [Numeric,Array] elements
   *   @param [Array] array
   *   @return [Numo::DComplex]
   */
  rb_define_singleton_method(cT, "cast", dcomplex_s_cast, 1);
  /**
   * Multi-dimensional element reference.
   * @overload [](dim0,...,dimL)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,
   *     Symbol] dim0,...,dimL  multi-dimensional indices.
   *   @return [Numeric,Numo::DComplex] an element or NArray view.
   * @see Numo::NArray#[]
   * @see #[]=
   */
  rb_define_method(cT, "[]", dcomplex_aref, -1);
  /**
   * Multi-dimensional element assignment.
   * @overload []=(dim0,...,dimL,val)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,
   *     Symbol] dim0,...,dimL  multi-dimensional indices.
   *   @param [Numeric,Numo::NArray,Array] val  Value(s) to be set to self.
   *   @return [Numeric,Numo::NArray,Array] returns `val` (last argument).
   * @see Numo::NArray#[]=
   * @see #[]
   */
  rb_define_method(cT, "[]=", dcomplex_aset, -1);
  /**
   * return NArray with cast to the type of self.
   * @overload coerce_cast(type)
   *   @return [nil]
   */
  rb_define_method(cT, "coerce_cast", dcomplex_coerce_cast, 1);
  /**
   * Convert self to Array.
   * @overload to_a
   *   @return [Array]
   */
  rb_define_method(cT, "to_a", dcomplex_to_a, 0);
  /**
   * Fill elements with other.
   * @overload fill other
   *   @param [Numeric] other
   *   @return [Numo::DComplex] self.
   */
  rb_define_method(cT, "fill", dcomplex_fill, 1);
  /**
   * Format elements into strings.
   * @overload format format
   *   @param [String] format
   *   @return [Numo::RObject] array of formatted strings.
   */
  rb_define_method(cT, "format", dcomplex_format, -1);
  /**
   * Format elements into strings.
   * @overload format_to_a format
   *   @param [String] format
   *   @return [Array] array of formatted strings.
   */
  rb_define_method(cT, "format_to_a", dcomplex_format_to_a, -1);
  /**
   * Returns a string containing a human-readable representation of NArray.
   * @overload inspect
   *   @return [String]
   */
  rb_define_method(cT, "inspect", dcomplex_inspect, 0);
  /**
   * Calls the given block once for each element in self,
   * passing that element as a parameter.
   * @overload each
   *   @return [Numo::NArray] self
   *   For a block `{|x| ... }`,
   *   @yieldparam [Numeric] x  an element of NArray.
   * @see #each_with_index
   * @see #map
   */
  rb_define_method(cT, "each", dcomplex_each, 0);
  /**
   * Unary map.
   * @overload map
   *   @return [Numo::DComplex] map of self.
   */
  rb_define_method(cT, "map", dcomplex_map, 0);
  /**
   * Invokes the given block once for each element of self,
   * passing that element and indices along each axis as parameters.
   * @overload each_with_index
   *   For a block `{|x,i,j,...| ... }`,
   *   @yieldparam [Numeric] x  an element
   *   @yieldparam [Integer] i,j,...  multitimensional indices
   *   @return [Numo::NArray] self
   * @see #each
   * @see #map_with_index
   */
  rb_define_method(cT, "each_with_index", dcomplex_each_with_index, 0);
  /**
   * Invokes the given block once for each element of self,
   * passing that element and indices along each axis as parameters.
   * Creates a new NArray containing the values returned by the block.
   * Inplace option is allowed, i.e., `nary.inplace.map` overwrites `nary`.
   * @overload map_with_index
   *   For a block `{|x,i,j,...| ... }`,
   *   @yieldparam [Numeric] x  an element
   *   @yieldparam [Integer] i,j,...  multitimensional indices
   *   @return [Numo::NArray] mapped array
   * @see #map
   * @see #each_with_index
   */
  rb_define_method(cT, "map_with_index", dcomplex_map_with_index, 0);
  /**
   * abs of self.
   * @overload abs
   *   @return [Numo::DFloat] abs of self.
   */
  rb_define_method(cT, "abs", dcomplex_abs, 0);
  /**
   * Binary add.
   * @overload + other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self + other
   */
  rb_define_method(cT, "+", dcomplex_add, 1);
  /**
   * Binary sub.
   * @overload - other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self - other
   */
  rb_define_method(cT, "-", dcomplex_sub, 1);
  /**
   * Binary mul.
   * @overload * other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self * other
   */
  rb_define_method(cT, "*", dcomplex_mul, 1);
  /**
   * Binary div.
   * @overload / other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self / other
   */
  rb_define_method(cT, "/", dcomplex_div, 1);
  /**
   * Binary power.
   * @overload ** other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self to the other-th power.
   */
  rb_define_method(cT, "**", dcomplex_pow, 1);
  rb_define_alias(cT, "pow", "**");
  /**
   * Unary minus.
   * @overload -@
   *   @return [Numo::DComplex] minus of self.
   */
  rb_define_method(cT, "-@", dcomplex_minus, 0);
  /**
   * Unary reciprocal.
   * @overload reciprocal
   *   @return [Numo::DComplex] reciprocal of self.
   */
  rb_define_method(cT, "reciprocal", dcomplex_reciprocal, 0);
  /**
   * Unary sign.
   * @overload sign
   *   @return [Numo::DComplex] sign of self.
   */
  rb_define_method(cT, "sign", dcomplex_sign, 0);
  /**
   * Unary square.
   * @overload square
   *   @return [Numo::DComplex] square of self.
   */
  rb_define_method(cT, "square", dcomplex_square, 0);
  /**
   * Unary conj.
   * @overload conj
   *   @return [Numo::DComplex] conj of self.
   */
  rb_define_method(cT, "conj", dcomplex_conj, 0);
  /**
   * Unary im.
   * @overload im
   *   @return [Numo::DComplex] im of self.
   */
  rb_define_method(cT, "im", dcomplex_im, 0);
  /**
   * real of self.
   * @overload real
   *   @return [Numo::DFloat] real of self.
   */
  rb_define_method(cT, "real", dcomplex_real, 0);
  /**
   * imag of self.
   * @overload imag
   *   @return [Numo::DFloat] imag of self.
   */
  rb_define_method(cT, "imag", dcomplex_imag, 0);
  /**
   * arg of self.
   * @overload arg
   *   @return [Numo::DFloat] arg of self.
   */
  rb_define_method(cT, "arg", dcomplex_arg, 0);
  rb_define_alias(cT, "angle", "arg");
  rb_define_method(cT, "set_imag", dcomplex_set_imag, 1);
  rb_define_method(cT, "set_real", dcomplex_set_real, 1);
  rb_define_alias(cT, "imag=", "set_imag");
  rb_define_alias(cT, "real=", "set_real");
  rb_define_alias(cT, "conjugate", "conj");
  /**
   * Comparison eq other.
   * @overload eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self eq other.
   */
  rb_define_method(cT, "eq", dcomplex_eq, 1);
  /**
   * Comparison ne other.
   * @overload ne other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ne other.
   */
  rb_define_method(cT, "ne", dcomplex_ne, 1);
  /**
   * Comparison nearly_eq other.
   * @overload nearly_eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self nearly_eq other.
   */
  rb_define_method(cT, "nearly_eq", dcomplex_nearly_eq, 1);
  rb_define_alias(cT, "close_to", "nearly_eq");
  /**
   * Unary floor.
   * @overload floor
   *   @return [Numo::DComplex] floor of self.
   */
  rb_define_method(cT, "floor", dcomplex_floor, 0);
  /**
   * Unary round.
   * @overload round
   *   @return [Numo::DComplex] round of self.
   */
  rb_define_method(cT, "round", dcomplex_round, 0);
  /**
   * Unary ceil.
   * @overload ceil
   *   @return [Numo::DComplex] ceil of self.
   */
  rb_define_method(cT, "ceil", dcomplex_ceil, 0);
  /**
   * Unary trunc.
   * @overload trunc
   *   @return [Numo::DComplex] trunc of self.
   */
  rb_define_method(cT, "trunc", dcomplex_trunc, 0);
  /**
   * Unary rint.
   * @overload rint
   *   @return [Numo::DComplex] rint of self.
   */
  rb_define_method(cT, "rint", dcomplex_rint, 0);
  /**
   * Binary copysign.
   * @overload copysign other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self copysign other
   */
  rb_define_method(cT, "copysign", dcomplex_copysign, 1);
  /**
   * Condition of isnan.
   * @overload isnan
   *   @return [Numo::Bit] Condition of isnan.
   */
  rb_define_method(cT, "isnan", dcomplex_isnan, 0);
  /**
   * Condition of isinf.
   * @overload isinf
   *   @return [Numo::Bit] Condition of isinf.
   */
  rb_define_method(cT, "isinf", dcomplex_isinf, 0);
  /**
   * Condition of isposinf.
   * @overload isposinf
   *   @return [Numo::Bit] Condition of isposinf.
   */
  rb_define_method(cT, "isposinf", dcomplex_isposinf, 0);
  /**
   * Condition of isneginf.
   * @overload isneginf
   *   @return [Numo::Bit] Condition of isneginf.
   */
  rb_define_method(cT, "isneginf", dcomplex_isneginf, 0);
  /**
   * Condition of isfinite.
   * @overload isfinite
   *   @return [Numo::Bit] Condition of isfinite.
   */
  rb_define_method(cT, "isfinite", dcomplex_isfinite, 0);
  /**
   * sum of self.
   * @overload sum(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs sum along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::DComplex] returns result of sum.
   */
  rb_define_method(cT, "sum", dcomplex_sum, -1);
  /**
   * prod of self.
   * @overload prod(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs prod along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::DComplex] returns result of prod.
   */
  rb_define_method(cT, "prod", dcomplex_prod, -1);
  /**
   * kahan_sum of self.
   * @overload kahan_sum(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN for sum/mean etc,
   *     or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs kahan_sum along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::DComplex] returns result of kahan_sum.
   */
  rb_define_method(cT, "kahan_sum", dcomplex_kahan_sum, -1);
  /**
   * mean of self.
   * @overload mean(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs mean along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or return NaN for min/max etc).
   * @return [Numo::DComplex] returns result of mean.
   */
  rb_define_method(cT, "mean", dcomplex_mean, -1);
  /**
   * var of self.
   * @overload var(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs var along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of var.
   */
  rb_define_method(cT, "var", dcomplex_var, -1);
  /**
   * stddev of self.
   * @overload stddev(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs stddev along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of stddev.
   */
  rb_define_method(cT, "stddev", dcomplex_stddev, -1);
  /**
   * rms of self.
   * @overload rms(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs rms along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of rms.
   */
  rb_define_method(cT, "rms", dcomplex_rms, -1);
  /**
   * cumsum of self.
   * @overload cumsum(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumsum along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::DComplex] cumsum of self.
   */
  rb_define_method(cT, "cumsum", dcomplex_cumsum, -1);
  /**
   * cumprod of self.
   * @overload cumprod(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumprod along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::DComplex] cumprod of self.
   */
  rb_define_method(cT, "cumprod", dcomplex_cumprod, -1);
  /**
   * Binary mulsum.
   *
   * @overload mulsum(other, axis:nil, keepdims:false, nan:false)
   *   @param [Numo::NArray,Numeric] other
   *   @param [Numeric,Array,Range] axis  Performs mulsum along the axis.
   *   @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in
   *     the result array as dimensions with size one.
   *   @param [TrueClass] nan (keyword) If true, apply NaN-aware algorithm
   *     (avoid NaN if exists).
   *   @return [Numo::NArray] mulsum of self and other.
   */
  rb_define_method(cT, "mulsum", dcomplex_mulsum, -1);
  /**
   * Set linear sequence of numbers to self. The sequence is obtained from
   *    beg+i*step
   * where i is 1-dimensional index.
   * @overload seq([beg,[step]])
   *   @param [Numeric] beg  beginning of sequence. (default=0)
   *   @param [Numeric] step  step of sequence. (default=1)
   *   @return [Numo::DComplex] self.
   * @example
   *   Numo::DFloat.new(6).seq(1,-0.2)
   *   # => Numo::DFloat#shape=[6]
   *   # [1, 0.8, 0.6, 0.4, 0.2, 0]
   *
   *   Numo::DComplex.new(6).seq(1,-0.2+0.2i)
   *   # => Numo::DComplex#shape=[6]
   *   # [1+0i, 0.8+0.2i, 0.6+0.4i, 0.4+0.6i, 0.2+0.8i, 0+1i]
   */
  rb_define_method(cT, "seq", dcomplex_seq, -1);
  /**
   * Set logarithmic sequence of numbers to self. The sequence is obtained from
   *    `base**(beg+i*step)`
   * where i is 1-dimensional index.
   * Applicable classes: DFloat, SFloat, DComplex, SCopmplex.
   *
   * @overload logseq(beg,step,[base])
   *   @param [Numeric] beg  The beginning of sequence.
   *   @param [Numeric] step  The step of sequence.
   *   @param [Numeric] base  The base of log space. (default=10)
   *   @return [Numo::DComplex] self.
   *
   * @example
   *   Numo::DFloat.new(5).logseq(4,-1,2)
   *   # => Numo::DFloat#shape=[5]
   *   # [16, 8, 4, 2, 1]
   *
   *   Numo::DComplex.new(5).logseq(0,1i*Math::PI/3,Math::E)
   *   # => Numo::DComplex#shape=[5]
   *   # [1+7.26156e-310i, 0.5+0.866025i, -0.5+0.866025i, -1+1.22465e-16i, ...]
   */
  rb_define_method(cT, "logseq", dcomplex_logseq, -1);
  /**
   * Eye: Set a value to diagonal components, set 0 to non-diagonal components.
   * @overload eye([element,offset])
   *   @param [Numeric] element  Diagonal element to be stored. Default is 1.
   *   @param [Integer] offset Diagonal offset from the main diagonal.  The
   *       default is 0. k>0 for diagonals above the main diagonal, and k<0
   *       for diagonals below the main diagonal.
   *   @return [Numo::DComplex] eye of self.
   */
  rb_define_method(cT, "eye", dcomplex_eye, -1);
  rb_define_alias(cT, "indgen", "seq");
  /**
   * Generate uniformly distributed random numbers on self narray.
   * @overload rand([[low],high])
   *   @param [Numeric] low  lower inclusive boundary of random numbers. (default=0)
   *   @param [Numeric] high  upper exclusive boundary of random numbers.
   *     (default=1 or 1+1i for complex types)
   *   @return [Numo::DComplex] self.
   * @example
   *   Numo::DFloat.new(6).rand
   *   # => Numo::DFloat#shape=[6]
   *   # [0.0617545, 0.373067, 0.794815, 0.201042, 0.116041, 0.344032]
   *
   *   Numo::DComplex.new(6).rand(5+5i)
   *   # => Numo::DComplex#shape=[6]
   *   # [2.69974+3.68908i, 0.825443+0.254414i, 0.540323+0.34354i, 4.52061+2.39322i, ...]
   *
   *   Numo::Int32.new(6).rand(2,5)
   *   # => Numo::Int32#shape=[6]
   *   # [4, 3, 3, 2, 4, 2]
   */
  rb_define_method(cT, "rand", dcomplex_rand, -1);
  /**
   * Generates random numbers from the normal distribution on self narray
   * using Box-Muller Transformation.
   * @overload rand_norm([mu,[sigma]])
   *   @param [Numeric] mu  mean of normal distribution. (default=0)
   *   @param [Numeric] sigma  standard deviation of normal distribution. (default=1)
   *   @return [Numo::DComplex] self.
   * @example
   *   Numo::DFloat.new(5,5).rand_norm
   *   # => Numo::DFloat#shape=[5,5]
   *   # [[-0.581255, -0.168354, 0.586895, -0.595142, -0.802802],
   *   #  [-0.326106, 0.282922, 1.68427, 0.918499, -0.0485384],
   *   #  [-0.464453, -0.992194, 0.413794, -0.60717, -0.699695],
   *   #  [-1.64168, 0.48676, -0.875871, -1.43275, 0.812172],
   *   #  [-0.209975, -0.103612, -0.878617, -1.42495, 1.0968]]
   *
   *   Numo::DFloat.new(5,5).rand_norm(10,0.1)
   *   # => Numo::DFloat#shape=[5,5]
   *   # [[9.9019, 9.90339, 10.0826, 9.98384, 9.72861],
   *   #  [9.81507, 10.0272, 9.91445, 10.0568, 9.88923],
   *   #  [10.0234, 9.97874, 9.96011, 9.9006, 9.99964],
   *   #  [10.0186, 9.94598, 9.92236, 9.99811, 9.97003],
   *   #  [9.79266, 9.95044, 9.95212, 9.93692, 10.2027]]
   *
   *   Numo::DComplex.new(3,3).rand_norm(5+5i)
   *   # => Numo::DComplex#shape=[3,3]
   *   # [[5.84303+4.40052i, 4.00984+6.08982i, 5.10979+5.13215i],
   *   #  [4.26477+3.99655i, 4.90052+5.00763i, 4.46607+2.3444i],
   *   #  [4.5528+7.11003i, 5.62117+6.69094i, 5.05443+5.35133i]]
   */
  rb_define_method(cT, "rand_norm", dcomplex_rand_norm, -1);
  /**
   * Calculate polynomial.
   *   `x.poly(a0,a1,a2,...,an) = a0 + a1*x + a2*x**2 + ... + an*x**n`
   * @overload poly a0, a1, ..., an
   *   @param [Numo::NArray,Numeric] a0,a1,...,an
   *   @return [Numo::DComplex]
   */
  rb_define_method(cT, "poly", dcomplex_poly, -2);
  rb_define_singleton_method(cT, "[]", dcomplex_s_cast, -2);

  /**
   * Document-module: Numo::DComplex::Math
   *
   * This module contains mathematical functions for Numo::DComplex.
   */
  mTM = rb_define_module_under(cT, "Math");
  /**
   * Calculate sqrt(x).
   * @overload sqrt(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of sqrt(x).
   */
  rb_define_module_function(mTM, "sqrt", dcomplex_math_s_sqrt, 1);
  /**
   * Calculate cbrt(x).
   * @overload cbrt(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of cbrt(x).
   */
  rb_define_module_function(mTM, "cbrt", dcomplex_math_s_cbrt, 1);
  /**
   * Calculate log(x).
   * @overload log(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of log(x).
   */
  rb_define_module_function(mTM, "log", dcomplex_math_s_log, 1);
  /**
   * Calculate log2(x).
   * @overload log2(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of log2(x).
   */
  rb_define_module_function(mTM, "log2", dcomplex_math_s_log2, 1);
  /**
   * Calculate log10(x).
   * @overload log10(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of log10(x).
   */
  rb_define_module_function(mTM, "log10", dcomplex_math_s_log10, 1);
  /**
   * Calculate exp(x).
   * @overload exp(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of exp(x).
   */
  rb_define_module_function(mTM, "exp", dcomplex_math_s_exp, 1);
  /**
   * Calculate exp2(x).
   * @overload exp2(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of exp2(x).
   */
  rb_define_module_function(mTM, "exp2", dcomplex_math_s_exp2, 1);
  /**
   * Calculate exp10(x).
   * @overload exp10(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of exp10(x).
   */
  rb_define_module_function(mTM, "exp10", dcomplex_math_s_exp10, 1);
  /**
   * Calculate sin(x).
   * @overload sin(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of sin(x).
   */
  rb_define_module_function(mTM, "sin", dcomplex_math_s_sin, 1);
  /**
   * Calculate cos(x).
   * @overload cos(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of cos(x).
   */
  rb_define_module_function(mTM, "cos", dcomplex_math_s_cos, 1);
  /**
   * Calculate tan(x).
   * @overload tan(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of tan(x).
   */
  rb_define_module_function(mTM, "tan", dcomplex_math_s_tan, 1);
  /**
   * Calculate asin(x).
   * @overload asin(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of asin(x).
   */
  rb_define_module_function(mTM, "asin", dcomplex_math_s_asin, 1);
  /**
   * Calculate acos(x).
   * @overload acos(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of acos(x).
   */
  rb_define_module_function(mTM, "acos", dcomplex_math_s_acos, 1);
  /**
   * Calculate atan(x).
   * @overload atan(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of atan(x).
   */
  rb_define_module_function(mTM, "atan", dcomplex_math_s_atan, 1);
  /**
   * Calculate sinh(x).
   * @overload sinh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of sinh(x).
   */
  rb_define_module_function(mTM, "sinh", dcomplex_math_s_sinh, 1);
  /**
   * Calculate cosh(x).
   * @overload cosh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of cosh(x).
   */
  rb_define_module_function(mTM, "cosh", dcomplex_math_s_cosh, 1);
  /**
   * Calculate tanh(x).
   * @overload tanh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of tanh(x).
   */
  rb_define_module_function(mTM, "tanh", dcomplex_math_s_tanh, 1);
  /**
   * Calculate asinh(x).
   * @overload asinh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of asinh(x).
   */
  rb_define_module_function(mTM, "asinh", dcomplex_math_s_asinh, 1);
  /**
   * Calculate acosh(x).
   * @overload acosh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of acosh(x).
   */
  rb_define_module_function(mTM, "acosh", dcomplex_math_s_acosh, 1);
  /**
   * Calculate atanh(x).
   * @overload atanh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of atanh(x).
   */
  rb_define_module_function(mTM, "atanh", dcomplex_math_s_atanh, 1);
  /**
   * Calculate sinc(x).
   * @overload sinc(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::DComplex] result of sinc(x).
   */
  rb_define_module_function(mTM, "sinc", dcomplex_math_s_sinc, 1);

  //  how to do this?
  // rb_extend_object(cT, mTM);
}
