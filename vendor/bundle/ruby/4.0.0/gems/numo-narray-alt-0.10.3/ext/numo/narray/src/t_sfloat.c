/*
  t_sfloat.c
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
static ID id_divmod;
static ID id_eq;
static ID id_ge;
static ID id_gt;
static ID id_le;
static ID id_lt;
static ID id_mulsum;
static ID id_nan;
static ID id_ne;
static ID id_nearly_eq;
static ID id_to_a;

#include <numo/types/sfloat.h>

/*
  class definition: Numo::SFloat
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
#include "mh/op/mod.h"
#include "mh/divmod.h"
#include "mh/pow.h"
#include "mh/minus.h"
#include "mh/reciprocal.h"
#include "mh/sign.h"
#include "mh/square.h"
#include "mh/round/floor.h"
#include "mh/round/round.h"
#include "mh/round/ceil.h"
#include "mh/round/trunc.h"
#include "mh/round/rint.h"
#include "mh/copysign.h"
#include "mh/signbit.h"
#include "mh/modf.h"
#include "mh/comp/eq.h"
#include "mh/comp/ne.h"
#include "mh/comp/nearly_eq.h"
#include "mh/comp/gt.h"
#include "mh/comp/ge.h"
#include "mh/comp/lt.h"
#include "mh/comp/le.h"
#include "mh/clip.h"
#include "mh/isnan.h"
#include "mh/isinf.h"
#include "mh/isposinf.h"
#include "mh/isneginf.h"
#include "mh/isfinite.h"
#include "mh/sum.h"
#include "mh/prod.h"
#include "mh/mean.h"
#include "mh/var.h"
#include "mh/stddev.h"
#include "mh/rms.h"
#include "mh/min.h"
#include "mh/max.h"
#include "mh/ptp.h"
#include "mh/max_index.h"
#include "mh/min_index.h"
#include "mh/argmax.h"
#include "mh/argmin.h"
#include "mh/maximum.h"
#include "mh/minimum.h"
#include "mh/minmax.h"
#include "mh/cumsum.h"
#include "mh/cumprod.h"
#include "mh/mulsum.h"
#include "mh/seq.h"
#include "mh/logseq.h"
#include "mh/eye.h"
#include "mh/rand.h"
#include "mh/rand_norm.h"
#include "mh/poly.h"
#include "mh/sort.h"
#include "mh/median.h"
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
#include "mh/math/atan2.h"
#include "mh/math/hypot.h"
#include "mh/math/erf.h"
#include "mh/math/erfc.h"
#include "mh/math/log1p.h"
#include "mh/math/expm1.h"
#include "mh/math/ldexp.h"
#include "mh/math/frexp.h"

typedef float sfloat; // Type aliases for shorter notation
                      // following the codebase naming convention.
DEF_NARRAY_STORE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_S_CAST_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_EXTRACT_METHOD_FUNC(sfloat)
DEF_NARRAY_AREF_METHOD_FUNC(sfloat)
DEF_EXTRACT_DATA_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_ASET_METHOD_FUNC(sfloat)
DEF_NARRAY_COERCE_CAST_METHOD_FUNC(sfloat)
DEF_NARRAY_TO_A_METHOD_FUNC(sfloat)
DEF_NARRAY_FILL_METHOD_FUNC(sfloat)
DEF_NARRAY_FORMAT_METHOD_FUNC(sfloat)
DEF_NARRAY_FORMAT_TO_A_METHOD_FUNC(sfloat)
DEF_NARRAY_INSPECT_METHOD_FUNC(sfloat)
DEF_NARRAY_EACH_METHOD_FUNC(sfloat)
DEF_NARRAY_MAP_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_EACH_WITH_INDEX_METHOD_FUNC(sfloat)
DEF_NARRAY_MAP_WITH_INDEX_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_ABS_METHOD_FUNC(sfloat, numo_cSFloat, sfloat, numo_cSFloat)
#ifdef __SSE2__
DEF_NARRAY_SFLT_ADD_SSE2_METHOD_FUNC()
DEF_NARRAY_SFLT_SUB_SSE2_METHOD_FUNC()
DEF_NARRAY_SFLT_MUL_SSE2_METHOD_FUNC()
DEF_NARRAY_SFLT_DIV_SSE2_METHOD_FUNC()
#else
DEF_NARRAY_ADD_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_SUB_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_MUL_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_DIV_METHOD_FUNC(sfloat, numo_cSFloat)
#endif
DEF_NARRAY_FLT_MOD_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_DIVMOD_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_POW_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_MINUS_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_RECIPROCAL_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_SIGN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_SQUARE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_FLOOR_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ROUND_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_CEIL_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_TRUNC_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_RINT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_COPYSIGN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_SIGNBIT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_MODF_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_EQ_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_NE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_NEARLY_EQ_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_GT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_GE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_LT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_LE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_CLIP_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ISNAN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ISINF_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ISPOSINF_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ISNEGINF_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ISFINITE_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_SUM_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_PROD_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MEAN_METHOD_FUNC(sfloat, numo_cSFloat, float, numo_cSFloat)
DEF_NARRAY_FLT_VAR_METHOD_FUNC(sfloat, numo_cSFloat, float, numo_cSFloat)
DEF_NARRAY_FLT_STDDEV_METHOD_FUNC(sfloat, numo_cSFloat, float, numo_cSFloat)
DEF_NARRAY_FLT_RMS_METHOD_FUNC(sfloat, numo_cSFloat, float, numo_cSFloat)
DEF_NARRAY_FLT_MIN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MAX_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_PTP_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MAX_INDEX_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_MIN_INDEX_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_ARGMAX_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_ARGMIN_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_MAXIMUM_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MINIMUM_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MINMAX_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_CUMSUM_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_CUMPROD_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MULSUM_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_SEQ_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_LOGSEQ_METHOD_FUNC(sfloat)
DEF_NARRAY_EYE_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_RAND_METHOD_FUNC(sfloat)
DEF_NARRAY_FLT_RAND_NORM_METHOD_FUNC(sfloat)
DEF_NARRAY_POLY_METHOD_FUNC(sfloat, numo_cSFloat)
#undef qsort_dtype
#define qsort_dtype sfloat
#undef qsort_cast
#define qsort_cast *(sfloat*)
DEF_NARRAY_FLT_SORT_METHOD_FUNC(sfloat)
#undef qsort_dtype
#define qsort_dtype *sfloat
#undef qsort_cast
#define qsort_cast **(sfloat**)
DEF_NARRAY_FLT_SORT_INDEX_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_MEDIAN_METHOD_FUNC(sfloat)
#ifdef __SSE2__
DEF_NARRAY_FLT_SQRT_SSE2_SGL_METHOD_FUNC(sfloat, numo_cSFloat)
#else
DEF_NARRAY_FLT_SQRT_METHOD_FUNC(sfloat, numo_cSFloat)
#endif
DEF_NARRAY_FLT_CBRT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_LOG_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_LOG2_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_LOG10_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_EXP_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_EXP2_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_EXP10_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_SIN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_COS_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_TAN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ASIN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ACOS_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ATAN_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_SINH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_COSH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_TANH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ASINH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ACOSH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ATANH_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_SINC_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ATAN2_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_HYPOT_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ERF_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_ERFC_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_LOG1P_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_EXPM1_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_LDEXP_METHOD_FUNC(sfloat, numo_cSFloat)
DEF_NARRAY_FLT_FREXP_METHOD_FUNC(sfloat, numo_cSFloat)

static size_t sfloat_memsize(const void* ptr) {
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

static void sfloat_free(void* ptr) {
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

static narray_type_info_t sfloat_info = {

  0,             // element_bits
  sizeof(dtype), // element_bytes
  sizeof(dtype), // element_stride (in bytes)

};

static const rb_data_type_t sfloat_data_type = {
  "Numo::SFloat",
  {
    0,
    sfloat_free,
    sfloat_memsize,
  },
  &na_data_type,
  &sfloat_info,
  RUBY_TYPED_FROZEN_SHAREABLE, // flags
};

static VALUE sfloat_s_alloc_func(VALUE klass) {
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
  return TypedData_Wrap_Struct(klass, &sfloat_data_type, (void*)na);
}

static VALUE sfloat_allocate(VALUE self) {
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

void Init_numo_sfloat(void) {
  VALUE hCast, mNumo;

  mNumo = rb_define_module("Numo");

  id_pow = rb_intern("**");
  id_cast = rb_intern("cast");
  id_copysign = rb_intern("copysign");
  id_divmod = rb_intern("divmod");
  id_eq = rb_intern("eq");
  id_ge = rb_intern("ge");
  id_gt = rb_intern("gt");
  id_le = rb_intern("le");
  id_lt = rb_intern("lt");
  id_mulsum = rb_intern("mulsum");
  id_nan = rb_intern("nan");
  id_ne = rb_intern("ne");
  id_nearly_eq = rb_intern("nearly_eq");
  id_to_a = rb_intern("to_a");

  /**
   * Document-class: Numo::SFloat
   *
   * Single precision floating point number (32-bit float) N-dimensional array class.
   */
  cT = rb_define_class_under(mNumo, "SFloat", cNArray);

  // alias of SFloat
  rb_define_const(mNumo, "Float32", numo_cSFloat);

  hCast = rb_hash_new();
  /* Upcasting rules of SFloat. */
  rb_define_const(cT, "UPCAST", hCast);
  rb_hash_aset(hCast, rb_cArray, cT);

  rb_hash_aset(hCast, rb_cInteger, cT);
  rb_hash_aset(hCast, rb_cFloat, cT);
  rb_hash_aset(hCast, rb_cComplex, numo_cSComplex);
  rb_hash_aset(hCast, numo_cRObject, numo_cRObject);
  rb_hash_aset(hCast, numo_cDComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cSComplex, numo_cSComplex);
  rb_hash_aset(hCast, numo_cDFloat, numo_cDFloat);
  rb_hash_aset(hCast, numo_cSFloat, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt64, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt32, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt16, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt8, numo_cSFloat);
  rb_hash_aset(hCast, numo_cUInt64, numo_cSFloat);
  rb_hash_aset(hCast, numo_cUInt32, numo_cSFloat);
  rb_hash_aset(hCast, numo_cUInt16, numo_cSFloat);
  rb_hash_aset(hCast, numo_cUInt8, numo_cSFloat);
  rb_obj_freeze(hCast);

  /* Element size of SFloat in bits. */
  rb_define_const(cT, "ELEMENT_BIT_SIZE", INT2FIX(sizeof(dtype) * 8));
  /* Element size of SFloat in bytes. */
  rb_define_const(cT, "ELEMENT_BYTE_SIZE", INT2FIX(sizeof(dtype)));
  /* Stride size of contiguous SFloat array. */
  rb_define_const(cT, "CONTIGUOUS_STRIDE", INT2FIX(sizeof(dtype)));
  /* Machine epsilon of SFloat */
  rb_define_const(cT, "EPSILON", M_EPSILON);
  /* The largest respresentable value of SFloat */
  rb_define_const(cT, "MAX", M_MAX);
  /* The smallest respresentable value of SFloat */
  rb_define_const(cT, "MIN", M_MIN);
  rb_define_alloc_func(cT, sfloat_s_alloc_func);
  rb_define_method(cT, "allocate", sfloat_allocate, 0);
  /**
   * Extract an element only if self is a dimensionless NArray.
   * @overload extract
   *   @return [Numeric,Numo::NArray] Extract element value as Ruby Object
   *     if self is a dimensionless NArray, otherwise returns self.
   */
  rb_define_method(cT, "extract", sfloat_extract, 0);
  /**
   * Store elements to Numo::SFloat from other.
   * @overload store(other)
   *   @param [Object] other
   *   @return [Numo::SFloat] self
   */
  rb_define_method(cT, "store", sfloat_store, 1);
  /**
   * Cast object to Numo::SFloat.
   * @overload cast(array)
   *   @param [Numeric,Array] elements
   *   @param [Array] array
   *   @return [Numo::SFloat]
   */
  rb_define_singleton_method(cT, "cast", sfloat_s_cast, 1);
  /**
   * Cast object to Numo::SFloat.
   * @overload [](elements)
   *   @param [Numeric,Array] elements
   *   @param [Array] array
   *   @return [Numo::SFloat]
   */
  rb_define_singleton_method(cT, "[]", sfloat_s_cast, -2);
  /**
   * Multi-dimensional element reference.
   * @overload [](dim0,...,dimL)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,Boolean,Symbol]
   *     dim0,...,dimL  multi-dimensional indices.
   *   @return [Numeric,Numo::SFloat] an element or NArray view.
   * @see Numo::NArray#[]
   * @see #[]=
   */
  rb_define_method(cT, "[]", sfloat_aref, -1);
  /**
   * Multi-dimensional element assignment.
   * @overload []=(dim0,...,dimL,val)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,Boolean,Symbol]
   *     dim0,...,dimL  multi-dimensional indices.
   *   @param [Numeric,Numo::NArray,Array] val  Value(s) to be set to self.
   *   @return [Numeric,Numo::NArray,Array] returns `val` (last argument).
   * @see Numo::NArray#[]=
   * @see #[]
   */
  rb_define_method(cT, "[]=", sfloat_aset, -1);
  /**
   * Return NArray with cast to the type of self.
   * @overload coerce_cast(type)
   *   @return [nil]
   */
  rb_define_method(cT, "coerce_cast", sfloat_coerce_cast, 1);
  /**
   * Convert self to Array.
   * @overload to_a
   *   @return [Array]
   */
  rb_define_method(cT, "to_a", sfloat_to_a, 0);
  /**
   * Fill elements with other.
   * @overload fill other
   *   @param [Numeric] other
   *   @return [Numo::SFloat] self.
   */
  rb_define_method(cT, "fill", sfloat_fill, 1);
  /**
   * Format elements into strings.
   * @overload format format
   *   @param [String] format
   *   @return [Numo::RObject] array of formatted strings.
   */
  rb_define_method(cT, "format", sfloat_format, -1);
  /**
   * Format elements into strings.
   * @overload format_to_a format
   *   @param [String] format
   *   @return [Array] array of formatted strings.
   */
  rb_define_method(cT, "format_to_a", sfloat_format_to_a, -1);
  /**
   * Returns a string containing a human-readable representation of NArray.
   * @overload inspect
   *   @return [String]
   */
  rb_define_method(cT, "inspect", sfloat_inspect, 0);
  /**
   * Calls the given block once for each element in self, passing that element as a parameter.
   * For a block `{|x| ... }`,
   * @overload each
   *   @return [Numo::NArray] self
   *   @yieldparam [Numeric] x  an element of NArray.
   * @see #each_with_index
   * @see #map
   */
  rb_define_method(cT, "each", sfloat_each, 0);
  /**
   * Unary map.
   * @overload map
   *   @return [Numo::SFloat] map of self.
   */
  rb_define_method(cT, "map", sfloat_map, 0);
  /**
   * Invokes the given block once for each element of self, passing that element and
   * indices along each axis as parameters. For a block `{|x,i,j,...| ... }`,
   * @overload each_with_index
   *   @yieldparam [Numeric] x  an element
   *   @yieldparam [Integer] i,j,...  multitimensional indices
   *   @return [Numo::NArray] self
   * @see #each
   * @see #map_with_index
   */
  rb_define_method(cT, "each_with_index", sfloat_each_with_index, 0);
  /**
   * Invokes the given block once for each element of self,
   * passing that element and indices along each axis as parameters.
   * Creates a new NArray containing the values returned by the block.
   * Inplace option is allowed, i.e., `nary.inplace.map` overwrites `nary`.
   * For a block `{|x,i,j,...| ... }`,
   * @overload map_with_index
   *   @yieldparam [Numeric] x  an element
   *   @yieldparam [Integer] i,j,...  multitimensional indices
   *   @return [Numo::NArray] mapped array
   * @see #map
   * @see #each_with_index
   */
  rb_define_method(cT, "map_with_index", sfloat_map_with_index, 0);
  /**
   * abs of self.
   * @overload abs
   *   @return [Numo::SFloat] abs of self.
   */
  rb_define_method(cT, "abs", sfloat_abs, 0);
  /**
   * Binary add.
   * @overload + other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self + other
   */
  rb_define_method(cT, "+", sfloat_add, 1);
  /**
   * Binary sub.
   * @overload - other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self - other
   */
  rb_define_method(cT, "-", sfloat_sub, 1);
  /**
   * Binary mul.
   * @overload * other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self * other
   */
  rb_define_method(cT, "*", sfloat_mul, 1);
  /**
   * Binary div.
   * @overload / other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self / other
   */
  rb_define_method(cT, "/", sfloat_div, 1);
  /**
   * Binary mod.
   * @overload % other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self % other
   */
  rb_define_method(cT, "%", sfloat_mod, 1);
  /**
   * Binary divmod.
   * @overload divmod other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] divmod of self and other.
   */
  rb_define_method(cT, "divmod", sfloat_divmod, 1);
  /**
   * Binary power.
   * @overload ** other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self to the other-th power.
   */
  rb_define_method(cT, "**", sfloat_pow, 1);
  rb_define_alias(cT, "pow", "**");
  /**
   * Unary minus.
   * @overload -@
   *   @return [Numo::SFloat] minus of self.
   */
  rb_define_method(cT, "-@", sfloat_minus, 0);
  /**
   * Unary reciprocal.
   * @overload reciprocal
   *   @return [Numo::SFloat] reciprocal of self.
   */
  rb_define_method(cT, "reciprocal", sfloat_reciprocal, 0);
  /**
   * Unary sign.
   * @overload sign
   *   @return [Numo::SFloat] sign of self.
   */
  rb_define_method(cT, "sign", sfloat_sign, 0);
  /**
   * Unary square.
   * @overload square
   *   @return [Numo::SFloat] square of self.
   */
  rb_define_method(cT, "square", sfloat_square, 0);
  rb_define_alias(cT, "conj", "view");
  rb_define_alias(cT, "im", "view");
  rb_define_alias(cT, "conjugate", "conj");
  /**
   * Comparison eq other.
   * @overload eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self eq other.
   */
  rb_define_method(cT, "eq", sfloat_eq, 1);
  /**
   * Comparison ne other.
   * @overload ne other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ne other.
   */
  rb_define_method(cT, "ne", sfloat_ne, 1);
  /**
   * Comparison nearly_eq other.
   * @overload nearly_eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self nearly_eq other.
   */
  rb_define_method(cT, "nearly_eq", sfloat_nearly_eq, 1);
  rb_define_alias(cT, "close_to", "nearly_eq");
  /**
   * Unary floor.
   * @overload floor
   *   @return [Numo::SFloat] floor of self.
   */
  rb_define_method(cT, "floor", sfloat_floor, 0);
  /**
   * Unary round.
   * @overload round
   *   @return [Numo::SFloat] round of self.
   */
  rb_define_method(cT, "round", sfloat_round, 0);
  /**
   * Unary ceil.
   * @overload ceil
   *   @return [Numo::SFloat] ceil of self.
   */
  rb_define_method(cT, "ceil", sfloat_ceil, 0);
  /**
   * Unary trunc.
   * @overload trunc
   *   @return [Numo::SFloat] trunc of self.
   */
  rb_define_method(cT, "trunc", sfloat_trunc, 0);
  /**
   * Unary rint.
   * @overload rint
   *   @return [Numo::SFloat] rint of self.
   */
  rb_define_method(cT, "rint", sfloat_rint, 0);
  /**
   * Binary copysign.
   * @overload copysign other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self copysign other
   */
  rb_define_method(cT, "copysign", sfloat_copysign, 1);
  /**
   * Condition of signbit.
   * @overload signbit
   *   @return [Numo::Bit] Condition of signbit.
   */
  rb_define_method(cT, "signbit", sfloat_signbit, 0);
  /**
   * modf of self.
   * @overload modf
   *   @return [Numo::SFloat] modf of self.
   */
  rb_define_method(cT, "modf", sfloat_modf, 0);
  /**
   * Comparison gt other.
   * @overload gt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self gt other.
   */
  rb_define_method(cT, "gt", sfloat_gt, 1);
  /**
   * Comparison ge other.
   * @overload ge other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ge other.
   */
  rb_define_method(cT, "ge", sfloat_ge, 1);
  /**
   * Comparison lt other.
   * @overload lt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self lt other.
   */
  rb_define_method(cT, "lt", sfloat_lt, 1);
  /**
   * Comparison le other.
   * @overload le other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self le other.
   */
  rb_define_method(cT, "le", sfloat_le, 1);
  rb_define_alias(cT, ">", "gt");
  rb_define_alias(cT, ">=", "ge");
  rb_define_alias(cT, "<", "lt");
  rb_define_alias(cT, "<=", "le");
  /**
   * Clip array elements by [min,max].
   * If either of min or max is nil, one side is clipped.
   * @overload clip(min,max)
   *   @param [Numo::NArray,Numeric] min
   *   @param [Numo::NArray,Numeric] max
   *   @return [Numo::NArray] result of clip.
   *
   * @example
   *     a = Numo::Int32.new(10).seq
   *     # => Numo::Int32#shape=[10]
   *     # [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
   *
   *     a.clip(1,8)
   *     # => Numo::Int32#shape=[10]
   *     # [1, 1, 2, 3, 4, 5, 6, 7, 8, 8]
   *
   *     a.inplace.clip(3,6)
   *     a
   *     # => Numo::Int32#shape=[10]
   *     # [3, 3, 3, 3, 4, 5, 6, 6, 6, 6]
   *
   *     b = Numo::Int32.new(10).seq
   *     # => Numo::Int32#shape=[10]
   *     # [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
   *
   *     b.clip([3,4,1,1,1,4,4,4,4,4], 8)
   *     # => Numo::Int32#shape=[10]
   *     # [3, 4, 2, 3, 4, 5, 6, 7, 8, 8]
   */
  rb_define_method(cT, "clip", sfloat_clip, 2);
  /**
   * Condition of isnan.
   * @overload isnan
   *   @return [Numo::Bit] Condition of isnan.
   */
  rb_define_method(cT, "isnan", sfloat_isnan, 0);
  /**
   * Condition of isinf.
   * @overload isinf
   *   @return [Numo::Bit] Condition of isinf.
   */
  rb_define_method(cT, "isinf", sfloat_isinf, 0);
  /**
   * Condition of isposinf.
   * @overload isposinf
   *   @return [Numo::Bit] Condition of isposinf.
   */
  rb_define_method(cT, "isposinf", sfloat_isposinf, 0);
  /**
   * Condition of isneginf.
   * @overload isneginf
   *   @return [Numo::Bit] Condition of isneginf.
   */
  rb_define_method(cT, "isneginf", sfloat_isneginf, 0);
  /**
   * Condition of isfinite.
   * @overload isfinite
   *   @return [Numo::Bit] Condition of isfinite.
   */
  rb_define_method(cT, "isfinite", sfloat_isfinite, 0);
  /**
   * sum of self.
   * @overload sum(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs sum along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::SFloat] returns result of sum.
   */
  rb_define_method(cT, "sum", sfloat_sum, -1);
  /**
   * prod of self.
   * @overload prod(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs prod along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::SFloat] returns result of prod.
   */
  rb_define_method(cT, "prod", sfloat_prod, -1);
  /**
   * mean of self.
   * @overload mean(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs mean along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or return NaN for min/max etc).
   *   @return [Numo::SFloat] returns result of mean.
   */
  rb_define_method(cT, "mean", sfloat_mean, -1);
  /**
   * var of self.
   * @overload var(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs var along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::SFloat] returns result of var.
   */
  rb_define_method(cT, "var", sfloat_var, -1);
  /**
   * stddev of self.
   * @overload stddev(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs stddev along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::SFloat] returns result of stddev.
   */
  rb_define_method(cT, "stddev", sfloat_stddev, -1);
  /**
   * rms of self.
   * @overload rms(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs rms along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::SFloat] returns result of rms.
   */
  rb_define_method(cT, "rms", sfloat_rms, -1);
  /**
   * min of self.
   * @overload min(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs min along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::SFloat] returns result of min.
   */
  rb_define_method(cT, "min", sfloat_min, -1);
  /**
   * max of self.
   * @overload max(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs max along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::SFloat] returns result of max.
   */
  rb_define_method(cT, "max", sfloat_max, -1);
  /**
   * ptp of self.
   * @overload ptp(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs ptp along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::SFloat] returns result of ptp.
   */
  rb_define_method(cT, "ptp", sfloat_ptp, -1);
  /**
   * Index of the maximum value.
   * @overload max_index(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (return NaN posision if exist).
   *   @param [Numeric,Array,Range] axis  Finds maximum values along the axis
   *     and returns **flat 1-d indices**.
   *   @return [Integer,Numo::Int] returns result indices.
   * @see #argmax
   * @see #max
   *
   * @example
   *     a = Numo::NArray[3,4,1,2]
   *     a.max_index  #=> 1
   *
   *     b = Numo::NArray[[3,4,1],[2,0,5]]
   *     b.max_index             #=> 5
   *     b.max_index(axis:1)     #=> [1, 5]
   *     b.max_index(axis:0)     #=> [0, 1, 5]
   *     b[b.max_index(axis:0)]  #=> [3, 4, 5]
   */
  rb_define_method(cT, "max_index", sfloat_max_index, -1);
  /**
   * Index of the minimum value.
   * @overload min_index(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (return NaN posision if exist).
   *   @param [Numeric,Array,Range] axis  Finds minimum values along the axis
   *     and returns **flat 1-d indices**.
   *   @return [Integer,Numo::Int] returns result indices.
   * @see #argmin
   * @see #min
   *
   * @example
   *     a = Numo::NArray[3,4,1,2]
   *     a.min_index  #=> 2
   *
   *     b = Numo::NArray[[3,4,1],[2,0,5]]
   *     b.min_index             #=> 4
   *     b.min_index(axis:1)     #=> [2, 4]
   *     b.min_index(axis:0)     #=> [3, 4, 2]
   *     b[b.min_index(axis:0)]  #=> [2, 0, 1]
   */
  rb_define_method(cT, "min_index", sfloat_min_index, -1);
  /**
   * Index of the maximum value.
   * @overload argmax(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (return NaN posision if exist).
   *   @param [Numeric,Array,Range] axis  Finds maximum values along the axis
   *     and returns **indices along the axis**.
   *   @return [Integer,Numo::Int] returns the result indices.
   * @see #max_index
   * @see #max
   *
   * @example
   *     a = Numo::NArray[3,4,1,2]
   *     a.argmax  #=> 1
   *
   *     b = Numo::NArray[[3,4,1],[2,0,5]]
   *     b.argmax                       #=> 5
   *     b.argmax(axis:1)               #=> [1, 2]
   *     b.argmax(axis:0)               #=> [0, 0, 1]
   *     b.at(b.argmax(axis:0), 0..-1)  #=> [3, 4, 5]
   */
  rb_define_method(cT, "argmax", sfloat_argmax, -1);
  /**
   * Index of the minimum value.
   * @overload argmin(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm
   *     (return NaN posision if exist).
   *   @param [Numeric,Array,Range] axis  Finds minimum values along the axis
   *     and returns **indices along the axis**.
   *   @return [Integer,Numo::Int] returns the result indices.
   * @see #min_index
   * @see #min
   *
   * @example
   *     a = Numo::NArray[3,4,1,2]
   *     a.argmin  #=> 2
   *
   *     b = Numo::NArray[[3,4,1],[2,0,5]]
   *     b.argmin                       #=> 4
   *     b.argmin(axis:1)               #=> [2, 1]
   *     b.argmin(axis:0)               #=> [1, 1, 0]
   *     b.at(b.argmin(axis:0), 0..-1)  #=> [2, 0, 1]
   */
  rb_define_method(cT, "argmin", sfloat_argmin, -1);
  /**
   * minmax of self.
   * @overload minmax(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @param [Numeric,Array,Range] axis  Finds min-max along the axis.
   *   @param [Boolean] keepdims (keyword) If true, the reduced axes are left
   *     in the result array as dimensions with size one.
   *   @return [Numo::SFloat,Numo::SFloat] min and max of self.
   */
  rb_define_method(cT, "minmax", sfloat_minmax, -1);
  /**
   * Element-wise maximum of two arrays.
   * @overload maximum(a1, a2, nan:false)
   *   @param [Numo::NArray,Numeric] a1  The array to be compared.
   *   @param [Numo::NArray,Numeric] a2  The array to be compared.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @return [Numo::SFloat]
   */
  rb_define_module_function(cT, "maximum", sfloat_s_maximum, -1);
  /**
   * Element-wise minimum of two arrays.
   * @overload minimum(a1, a2, nan:false)
   *   @param [Numo::NArray,Numeric] a1  The array to be compared.
   *   @param [Numo::NArray,Numeric] a2  The array to be compared.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @return [Numo::SFloat]
   */
  rb_define_module_function(cT, "minimum", sfloat_s_minimum, -1);
  /**
   * cumsum of self.
   * @overload cumsum(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumsum along the axis.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::SFloat] cumsum of self.
   */
  rb_define_method(cT, "cumsum", sfloat_cumsum, -1);
  /**
   * cumprod of self.
   * @overload cumprod(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumprod along the axis.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::SFloat] cumprod of self.
   */
  rb_define_method(cT, "cumprod", sfloat_cumprod, -1);
  /**
   * Binary mulsum.
   * @overload mulsum(other, axis:nil, keepdims:false, nan:false)
   *   @param [Numo::NArray,Numeric] other
   *   @param [Numeric,Array,Range] axis  Performs mulsum along the axis.
   *   @param [Boolean] keepdims (keyword) If true, the reduced axes are left
   *     in the result array as dimensions with size one.
   *   @param [Boolean] nan (keyword) If true, apply NaN-aware algorithm
   *     (avoid NaN if exists).
   *   @return [Numo::NArray] mulsum of self and other.
   */
  rb_define_method(cT, "mulsum", sfloat_mulsum, -1);
  /**
   * Set linear sequence of numbers to self. The sequence is obtained from
   *    beg+i*step
   * where i is 1-dimensional index.
   * @overload seq([beg,[step]])
   *   @param [Numeric] beg  beginning of sequence. (default=0)
   *   @param [Numeric] step  step of sequence. (default=1)
   *   @return [Numo::SFloat] self.
   * @example
   *   Numo::DFloat.new(6).seq(1,-0.2)
   *   # => Numo::DFloat#shape=[6]
   *   # [1, 0.8, 0.6, 0.4, 0.2, 0]
   *
   *   Numo::DComplex.new(6).seq(1,-0.2+0.2i)
   *   # => Numo::DComplex#shape=[6]
   *   # [1+0i, 0.8+0.2i, 0.6+0.4i, 0.4+0.6i, 0.2+0.8i, 0+1i]
   */
  rb_define_method(cT, "seq", sfloat_seq, -1);
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
   *   @return [Numo::SFloat] self.
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
  rb_define_method(cT, "logseq", sfloat_logseq, -1);
  /**
   * Eye: Set a value to diagonal components, set 0 to non-diagonal components.
   * @overload eye([element,offset])
   *   @param [Numeric] element  Diagonal element to be stored. Default is 1.
   *   @param [Integer] offset Diagonal offset from the main diagonal.
   *     The default is 0. k>0 for diagonals above the main diagonal,
   *     and k<0 for diagonals below the main diagonal.
   *   @return [Numo::SFloat] eye of self.
   */
  rb_define_method(cT, "eye", sfloat_eye, -1);
  rb_define_alias(cT, "indgen", "seq");
  /**
   * Generate uniformly distributed random numbers on self narray.
   * @overload rand([[low],high])
   *   @param [Numeric] low  lower inclusive boundary of random numbers. (default=0)
   *   @param [Numeric] high  upper exclusive boundary of random numbers.
   *     (default=1 or 1+1i for complex types)
   *   @return [Numo::SFloat] self.
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
  rb_define_method(cT, "rand", sfloat_rand, -1);
  /**
   * Generates random numbers from the normal distribution on self narray
   *   using Box-Muller Transformation.
   * @overload rand_norm([mu,[sigma]])
   *   @param [Numeric] mu  mean of normal distribution. (default=0)
   *   @param [Numeric] sigma  standard deviation of normal distribution. (default=1)
   *   @return [Numo::SFloat] self.
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
  rb_define_method(cT, "rand_norm", sfloat_rand_norm, -1);
  /**
   * Calculate polynomial.
   *   `x.poly(a0,a1,a2,...,an) = a0 + a1*x + a2*x**2 + ... + an*x**n`
   * @overload poly a0, a1, ..., an
   *   @param [Numo::NArray,Numeric] a0,a1,...,an
   *   @return [Numo::SFloat]
   */
  rb_define_method(cT, "poly", sfloat_poly, -2);
  /**
   * sort of self.
   * @overload sort(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, propagete NaN. If false, ignore NaN.
   *   @param [Numeric,Array,Range] axis  Performs sort along the axis.
   *   @return [Numo::SFloat] returns result of sort.
   * @example
   *   Numo::DFloat[3,4,1,2].sort #=> Numo::DFloat[1,2,3,4]
   */
  rb_define_method(cT, "sort", sfloat_sort, -1);
  /**
   * sort_index. Returns an index array of sort result.
   * @overload sort_index(axis:nil, nan:false)
   *   @param [Boolean] nan  If true, propagete NaN. If false, ignore NaN.
   *   @param [Numeric,Array,Range] axis  Performs sort_index along the axis.
   *   @return [Integer,Numo::Int] returns result index of sort_index.
   * @example
   *   Numo::NArray[3,4,1,2].sort_index #=> Numo::Int32[2,3,0,1]
   */
  rb_define_method(cT, "sort_index", sfloat_sort_index, -1);
  /**
   * median of self.
   * @overload median(axis:nil, keepdims:false, nan:false)
   *   @param [Boolean] nan (keyword) If true, propagete NaN. If false, ignore NaN.
   *   @param [Numeric,Array,Range] axis  Finds median along the axis.
   *   @param [Boolean] keepdims  If true, the reduced axes are left
   *     in the result array as dimensions with size one.
   *   @return [Numo::SFloat] returns median of self.
   */
  rb_define_method(cT, "median", sfloat_median, -1);

  /**
   * Document-module: Numo::SFloat::Math
   *
   * This module contains mathematical functions for Numo::SFloat.
   */
  mTM = rb_define_module_under(cT, "Math");
  /**
   * Calculate sqrt(x).
   * @overload sqrt(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of sqrt(x).
   */
  rb_define_module_function(mTM, "sqrt", sfloat_math_s_sqrt, 1);
  /**
   * Calculate cbrt(x).
   * @overload cbrt(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of cbrt(x).
   */
  rb_define_module_function(mTM, "cbrt", sfloat_math_s_cbrt, 1);
  /**
   * Calculate log(x).
   * @overload log(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of log(x).
   */
  rb_define_module_function(mTM, "log", sfloat_math_s_log, 1);
  /**
   * Calculate log2(x).
   * @overload log2(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of log2(x).
   */
  rb_define_module_function(mTM, "log2", sfloat_math_s_log2, 1);
  /**
   * Calculate log10(x).
   * @overload log10(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of log10(x).
   */
  rb_define_module_function(mTM, "log10", sfloat_math_s_log10, 1);
  /**
   * Calculate exp(x).
   * @overload exp(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of exp(x).
   */
  rb_define_module_function(mTM, "exp", sfloat_math_s_exp, 1);
  /**
   * Calculate exp2(x).
   * @overload exp2(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of exp2(x).
   */
  rb_define_module_function(mTM, "exp2", sfloat_math_s_exp2, 1);
  /**
   * Calculate exp10(x).
   * @overload exp10(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of exp10(x).
   */
  rb_define_module_function(mTM, "exp10", sfloat_math_s_exp10, 1);
  /**
   * Calculate sin(x).
   * @overload sin(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of sin(x).
   */
  rb_define_module_function(mTM, "sin", sfloat_math_s_sin, 1);
  /**
   * Calculate cos(x).
   * @overload cos(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of cos(x).
   */
  rb_define_module_function(mTM, "cos", sfloat_math_s_cos, 1);
  /**
   * Calculate tan(x).
   * @overload tan(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of tan(x).
   */
  rb_define_module_function(mTM, "tan", sfloat_math_s_tan, 1);
  /**
   * Calculate asin(x).
   * @overload asin(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of asin(x).
   */
  rb_define_module_function(mTM, "asin", sfloat_math_s_asin, 1);
  /**
   * Calculate acos(x).
   * @overload acos(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of acos(x).
   */
  rb_define_module_function(mTM, "acos", sfloat_math_s_acos, 1);
  /**
   * Calculate atan(x).
   * @overload atan(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of atan(x).
   */
  rb_define_module_function(mTM, "atan", sfloat_math_s_atan, 1);
  /**
   * Calculate sinh(x).
   * @overload sinh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of sinh(x).
   */
  rb_define_module_function(mTM, "sinh", sfloat_math_s_sinh, 1);
  /**
   * Calculate cosh(x).
   * @overload cosh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of cosh(x).
   */
  rb_define_module_function(mTM, "cosh", sfloat_math_s_cosh, 1);
  /**
   * Calculate tanh(x).
   * @overload tanh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of tanh(x).
   */
  rb_define_module_function(mTM, "tanh", sfloat_math_s_tanh, 1);
  /**
   * Calculate asinh(x).
   * @overload asinh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of asinh(x).
   */
  rb_define_module_function(mTM, "asinh", sfloat_math_s_asinh, 1);
  /**
   * Calculate acosh(x).
   * @overload acosh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of acosh(x).
   */
  rb_define_module_function(mTM, "acosh", sfloat_math_s_acosh, 1);
  /**
   * Calculate atanh(x).
   * @overload atanh(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of atanh(x).
   */
  rb_define_module_function(mTM, "atanh", sfloat_math_s_atanh, 1);
  /**
   * Calculate sinc(x).
   * @overload sinc(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of sinc(x).
   */
  rb_define_module_function(mTM, "sinc", sfloat_math_s_sinc, 1);
  /**
   * Calculate atan2(a1,a2).
   * @overload atan2(a1,a2)
   *   @param [Numo::NArray,Numeric] a1  first value
   *   @param [Numo::NArray,Numeric] a2  second value
   *   @return [Numo::SFloat] atan2(a1,a2).
   */
  rb_define_module_function(mTM, "atan2", sfloat_math_s_atan2, 2);
  /**
   * Calculate hypot(a1,a2).
   * @overload hypot(a1,a2)
   *   @param [Numo::NArray,Numeric] a1  first value
   *   @param [Numo::NArray,Numeric] a2  second value
   *   @return [Numo::SFloat] hypot(a1,a2).
   */
  rb_define_module_function(mTM, "hypot", sfloat_math_s_hypot, 2);
  /**
   * Calculate erf(x).
   * @overload erf(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of erf(x).
   */
  rb_define_module_function(mTM, "erf", sfloat_math_s_erf, 1);
  /**
   * Calculate erfc(x).
   * @overload erfc(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of erfc(x).
   */
  rb_define_module_function(mTM, "erfc", sfloat_math_s_erfc, 1);
  /**
   * Calculate log1p(x).
   * @overload log1p(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of log1p(x).
   */
  rb_define_module_function(mTM, "log1p", sfloat_math_s_log1p, 1);
  /**
   * Calculate expm1(x).
   * @overload expm1(x)
   *   @param [Numo::NArray,Numeric] x  input value
   *   @return [Numo::SFloat] result of expm1(x).
   */
  rb_define_module_function(mTM, "expm1", sfloat_math_s_expm1, 1);
  /**
   * Calculate ldexp(a1,a2).
   * @overload ldexp(a1,a2)
   *   @param [Numo::NArray,Numeric] a1  first value
   *   @param [Numo::NArray,Numeric] a2  second value
   *   @return [Numo::SFloat] ldexp(a1,a2).
   */
  rb_define_module_function(mTM, "ldexp", sfloat_math_s_ldexp, 2);
  /**
   * split the number x into a normalized fraction and an exponent.
   * Returns [mantissa, exponent], where x = mantissa * 2**exponent.
   * @overload frexp(x)
   *   @param [Numo::NArray,Numeric]  x
   *   @return [Numo::SFloat,Numo::Int32]  mantissa and exponent.
   */
  rb_define_module_function(mTM, "frexp", sfloat_math_s_frexp, 1);

  //  how to do this?
  // rb_extend_object(cT, mTM);
}
