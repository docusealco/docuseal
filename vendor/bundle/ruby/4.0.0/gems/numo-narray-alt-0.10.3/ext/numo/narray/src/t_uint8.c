/*
  t_uint8.c
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
static ID id_left_shift;
static ID id_right_shift;
static ID id_cast;
static ID id_divmod;
static ID id_eq;
static ID id_ge;
static ID id_gt;
static ID id_le;
static ID id_lt;
static ID id_minlength;
static ID id_mulsum;
static ID id_nan;
static ID id_ne;
static ID id_to_a;

#include <numo/types/uint8.h>

/*
  class definition: Numo::UInt8
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
#include "mh/comp/eq.h"
#include "mh/comp/ne.h"
#include "mh/comp/gt.h"
#include "mh/comp/ge.h"
#include "mh/comp/lt.h"
#include "mh/comp/le.h"
#include "mh/bit/and.h"
#include "mh/bit/or.h"
#include "mh/bit/xor.h"
#include "mh/bit/not.h"
#include "mh/bit/left_shift.h"
#include "mh/bit/right_shift.h"
#include "mh/clip.h"
#include "mh/sum.h"
#include "mh/prod.h"
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
#include "mh/bincount.h"
#include "mh/cumsum.h"
#include "mh/cumprod.h"
#include "mh/mulsum.h"
#include "mh/seq.h"
#include "mh/eye.h"
#include "mh/rand.h"
#include "mh/poly.h"
#include "mh/sort.h"
#include "mh/median.h"
#include "mh/mean.h"
#include "mh/var.h"
#include "mh/stddev.h"
#include "mh/rms.h"

typedef u_int8_t uint8; // Type aliases for shorter notation
                        // following the codebase naming convention.
DEF_NARRAY_STORE_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_S_CAST_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_EXTRACT_METHOD_FUNC(uint8)
DEF_NARRAY_AREF_METHOD_FUNC(uint8)
DEF_EXTRACT_DATA_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_ASET_METHOD_FUNC(uint8)
DEF_NARRAY_COERCE_CAST_METHOD_FUNC(uint8)
DEF_NARRAY_TO_A_METHOD_FUNC(uint8)
DEF_NARRAY_FILL_METHOD_FUNC(uint8)
DEF_NARRAY_FORMAT_METHOD_FUNC(uint8)
DEF_NARRAY_FORMAT_TO_A_METHOD_FUNC(uint8)
DEF_NARRAY_INSPECT_METHOD_FUNC(uint8)
DEF_NARRAY_EACH_METHOD_FUNC(uint8)
DEF_NARRAY_MAP_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_EACH_WITH_INDEX_METHOD_FUNC(uint8)
DEF_NARRAY_MAP_WITH_INDEX_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_ABS_METHOD_FUNC(uint8, numo_cUInt8, uint8, numo_cUInt8)
DEF_NARRAY_INT8_ADD_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_SUB_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_MUL_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_DIV_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_MOD_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_DIVMOD_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_POW_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_MINUS_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_RECIPROCAL_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_SIGN_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_SQUARE_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_EQ_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_NE_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_GT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_GE_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_LT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_LE_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_BIT_AND_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_BIT_OR_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_BIT_XOR_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_BIT_NOT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_LEFT_SHIFT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT8_RIGHT_SHIFT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_CLIP_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_SUM_METHOD_FUNC(uint8, numo_cUInt8, u_int64_t, numo_cUInt64)
DEF_NARRAY_INT_PROD_METHOD_FUNC(uint8, numo_cUInt8, u_int64_t, numo_cUInt64)
DEF_NARRAY_INT_MIN_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MAX_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_PTP_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MAX_INDEX_METHOD_FUNC(uint8)
DEF_NARRAY_INT_MIN_INDEX_METHOD_FUNC(uint8)
DEF_NARRAY_INT_ARGMAX_METHOD_FUNC(uint8)
DEF_NARRAY_INT_ARGMIN_METHOD_FUNC(uint8)
DEF_NARRAY_INT_MAXIMUM_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MINIMUM_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MINMAX_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_UINT_BINCOUNT_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_CUMSUM_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_CUMPROD_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MULSUM_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_SEQ_METHOD_FUNC(uint8)
DEF_NARRAY_EYE_METHOD_FUNC(uint8)
DEF_NARRAY_INT_RAND_METHOD_FUNC(uint8)
DEF_NARRAY_POLY_METHOD_FUNC(uint8, numo_cUInt8)
#undef qsort_dtype
#define qsort_dtype uint8
#undef qsort_cast
#define qsort_cast *(uint8*)
DEF_NARRAY_INT_SORT_METHOD_FUNC(uint8)
#undef qsort_dtype
#define qsort_dtype uint8*
#undef qsort_cast
#define qsort_cast **(uint8**)
DEF_NARRAY_INT_SORT_INDEX_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_MEDIAN_METHOD_FUNC(uint8)
DEF_NARRAY_INT_MEAN_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_VAR_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_STDDEV_METHOD_FUNC(uint8, numo_cUInt8)
DEF_NARRAY_INT_RMS_METHOD_FUNC(uint8, numo_cUInt8)

static size_t uint8_memsize(const void* ptr) {
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

static void uint8_free(void* ptr) {
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

static narray_type_info_t uint8_info = {

  0,             // element_bits
  sizeof(dtype), // element_bytes
  sizeof(dtype), // element_stride (in bytes)

};

static const rb_data_type_t uint8_data_type = {
  "Numo::UInt8",
  {
    0,
    uint8_free,
    uint8_memsize,
  },
  &na_data_type,
  &uint8_info,
  RUBY_TYPED_FROZEN_SHAREABLE, // flags
};

static VALUE uint8_s_alloc_func(VALUE klass) {
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
  return TypedData_Wrap_Struct(klass, &uint8_data_type, (void*)na);
}

static VALUE uint8_allocate(VALUE self) {
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

void Init_numo_uint8(void) {
  VALUE hCast, mNumo;

  mNumo = rb_define_module("Numo");

  id_pow = rb_intern("**");
  id_left_shift = rb_intern("<<");
  id_right_shift = rb_intern(">>");
  id_cast = rb_intern("cast");
  id_divmod = rb_intern("divmod");
  id_eq = rb_intern("eq");
  id_ge = rb_intern("ge");
  id_gt = rb_intern("gt");
  id_le = rb_intern("le");
  id_lt = rb_intern("lt");
  id_minlength = rb_intern("minlength");
  id_mulsum = rb_intern("mulsum");
  id_nan = rb_intern("nan");
  id_ne = rb_intern("ne");
  id_to_a = rb_intern("to_a");

  /**
   * Document-class: Numo::UInt8
   *
   * 8-bit unsigned integer N-dimensional array class.
   */
  cT = rb_define_class_under(mNumo, "UInt8", cNArray);

  hCast = rb_hash_new();
  /* Upcasting rules of UInt8. */
  rb_define_const(cT, "UPCAST", hCast);
  rb_hash_aset(hCast, rb_cArray, cT);

  rb_hash_aset(hCast, rb_cInteger, cT);
  rb_hash_aset(hCast, rb_cFloat, numo_cDFloat);
  rb_hash_aset(hCast, rb_cComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cRObject, numo_cRObject);
  rb_hash_aset(hCast, numo_cDComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cSComplex, numo_cSComplex);
  rb_hash_aset(hCast, numo_cDFloat, numo_cDFloat);
  rb_hash_aset(hCast, numo_cSFloat, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt64, numo_cInt64);
  rb_hash_aset(hCast, numo_cInt32, numo_cInt32);
  rb_hash_aset(hCast, numo_cInt16, numo_cInt16);
  rb_hash_aset(hCast, numo_cInt8, numo_cInt8);
  rb_hash_aset(hCast, numo_cUInt64, numo_cUInt64);
  rb_hash_aset(hCast, numo_cUInt32, numo_cUInt32);
  rb_hash_aset(hCast, numo_cUInt16, numo_cUInt16);
  rb_hash_aset(hCast, numo_cUInt8, cT);
  rb_obj_freeze(hCast);

  /* Element size of UInt8 in bits. */
  rb_define_const(cT, "ELEMENT_BIT_SIZE", INT2FIX(sizeof(dtype) * 8));
  /* Element size of UInt8 in bytes. */
  rb_define_const(cT, "ELEMENT_BYTE_SIZE", INT2FIX(sizeof(dtype)));
  /* Stride size of contiguous UInt8 array. */
  rb_define_const(cT, "CONTIGUOUS_STRIDE", INT2FIX(sizeof(dtype)));
  /* The largest representable value of UInt8. */
  rb_define_const(cT, "MAX", M_MAX);
  /* The smallest representable value of UInt8. */
  rb_define_const(cT, "MIN", M_MIN);
  rb_define_alloc_func(cT, uint8_s_alloc_func);
  rb_define_method(cT, "allocate", uint8_allocate, 0);
  /**
   * Extract an element only if self is a dimensionless NArray.
   * @overload extract
   *   @return [Numeric,Numo::NArray]
   *   --- Extract element value as Ruby Object if self is a dimensionless NArray,
   *   otherwise returns self.
   */
  rb_define_method(cT, "extract", uint8_extract, 0);
  /**
   * Store elements to Numo::UInt8 from other.
   * @overload store(other)
   *   @param [Object] other
   *   @return [Numo::UInt8] self
   */
  rb_define_method(cT, "store", uint8_store, 1);
  /**
   * Cast object to Numo::UInt8.
   * @overload [](elements)
   * @overload cast(array)
   *   @param [Numeric,Array] elements
   *   @param [Array] array
   *   @return [Numo::UInt8]
   */
  rb_define_singleton_method(cT, "cast", uint8_s_cast, 1);
  /**
   * Multi-dimensional element reference.
   * @overload [](dim0,...,dimL)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,
   *     Symbol] dim0,...,dimL  multi-dimensional indices.
   *   @return [Numeric,Numo::UInt8] an element or NArray view.
   * @see Numo::NArray#[]
   * @see #[]=
   */
  rb_define_method(cT, "[]", uint8_aref, -1);
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
  rb_define_method(cT, "[]=", uint8_aset, -1);
  /**
   * return NArray with cast to the type of self.
   * @overload coerce_cast(type)
   *   @return [nil]
   */
  rb_define_method(cT, "coerce_cast", uint8_coerce_cast, 1);
  /**
   * Convert self to Array.
   * @overload to_a
   *   @return [Array]
   */
  rb_define_method(cT, "to_a", uint8_to_a, 0);
  /**
   * Fill elements with other.
   * @overload fill other
   *   @param [Numeric] other
   *   @return [Numo::UInt8] self.
   */
  rb_define_method(cT, "fill", uint8_fill, 1);
  /**
   * Format elements into strings.
   * @overload format format
   *   @param [String] format
   *   @return [Numo::RObject] array of formatted strings.
   */
  rb_define_method(cT, "format", uint8_format, -1);
  /**
   * Format elements into strings.
   * @overload format_to_a format
   *   @param [String] format
   *   @return [Array] array of formatted strings.
   */
  rb_define_method(cT, "format_to_a", uint8_format_to_a, -1);
  /**
   * Returns a string containing a human-readable representation of NArray.
   * @overload inspect
   *   @return [String]
   */
  rb_define_method(cT, "inspect", uint8_inspect, 0);
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
  rb_define_method(cT, "each", uint8_each, 0);
  /**
   * Unary map.
   * @overload map
   *   @return [Numo::UInt8] map of self.
   */
  rb_define_method(cT, "map", uint8_map, 0);
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
  rb_define_method(cT, "each_with_index", uint8_each_with_index, 0);
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
  rb_define_method(cT, "map_with_index", uint8_map_with_index, 0);
  /**
   * abs of self.
   * @overload abs
   *   @return [Numo::UInt8] abs of self.
   */
  rb_define_method(cT, "abs", uint8_abs, 0);
  /**
   * Binary add.
   * @overload + other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self + other
   */
  rb_define_method(cT, "+", uint8_add, 1);
  /**
   * Binary sub.
   * @overload - other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self - other
   */
  rb_define_method(cT, "-", uint8_sub, 1);
  /**
   * Binary mul.
   * @overload * other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self * other
   */
  rb_define_method(cT, "*", uint8_mul, 1);
  /**
   * Binary div.
   * @overload / other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self / other
   */
  rb_define_method(cT, "/", uint8_div, 1);
  /**
   * Binary mod.
   * @overload % other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self % other
   */
  rb_define_method(cT, "%", uint8_mod, 1);
  /**
   * Binary divmod.
   * @overload divmod other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] divmod of self and other.
   */
  rb_define_method(cT, "divmod", uint8_divmod, 1);
  /**
   * Binary power.
   * @overload ** other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self to the other-th power.
   */
  rb_define_method(cT, "**", uint8_pow, 1);
  rb_define_alias(cT, "pow", "**");
  /**
   * Unary minus.
   * @overload -@
   *   @return [Numo::UInt8] minus of self.
   */
  rb_define_method(cT, "-@", uint8_minus, 0);
  /**
   * Unary reciprocal.
   * @overload reciprocal
   *   @return [Numo::UInt8] reciprocal of self.
   */
  rb_define_method(cT, "reciprocal", uint8_reciprocal, 0);
  /**
   * Unary sign.
   * @overload sign
   *   @return [Numo::UInt8] sign of self.
   */
  rb_define_method(cT, "sign", uint8_sign, 0);
  /**
   * Unary square.
   * @overload square
   *   @return [Numo::UInt8] square of self.
   */
  rb_define_method(cT, "square", uint8_square, 0);
  rb_define_alias(cT, "conj", "view");
  rb_define_alias(cT, "im", "view");
  rb_define_alias(cT, "conjugate", "conj");
  /**
   * Comparison eq other.
   * @overload eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self eq other.
   */
  rb_define_method(cT, "eq", uint8_eq, 1);
  /**
   * Comparison ne other.
   * @overload ne other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ne other.
   */
  rb_define_method(cT, "ne", uint8_ne, 1);
  rb_define_alias(cT, "nearly_eq", "eq");
  rb_define_alias(cT, "close_to", "nearly_eq");
  /**
   * Binary bit_and.
   * @overload & other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self & other
   */
  rb_define_method(cT, "&", uint8_bit_and, 1);
  /**
   * Binary bit_or.
   * @overload | other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self | other
   */
  rb_define_method(cT, "|", uint8_bit_or, 1);
  /**
   * Binary bit_xor.
   * @overload ^ other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self ^ other
   */
  rb_define_method(cT, "^", uint8_bit_xor, 1);
  /**
   * Unary bit_not.
   * @overload ~
   *   @return [Numo::UInt8] bit_not of self.
   */
  rb_define_method(cT, "~", uint8_bit_not, 0);
  /**
   * Binary left_shift.
   * @overload << other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self << other
   */
  rb_define_method(cT, "<<", uint8_left_shift, 1);
  /**
   * Binary right_shift.
   * @overload >> other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self >> other
   */
  rb_define_method(cT, ">>", uint8_right_shift, 1);
  rb_define_alias(cT, "floor", "view");
  rb_define_alias(cT, "round", "view");
  rb_define_alias(cT, "ceil", "view");
  rb_define_alias(cT, "trunc", "view");
  rb_define_alias(cT, "rint", "view");
  /**
   * Comparison gt other.
   * @overload gt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self gt other.
   */
  rb_define_method(cT, "gt", uint8_gt, 1);
  /**
   * Comparison ge other.
   * @overload ge other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ge other.
   */
  rb_define_method(cT, "ge", uint8_ge, 1);
  /**
   * Comparison lt other.
   * @overload lt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self lt other.
   */
  rb_define_method(cT, "lt", uint8_lt, 1);
  /**
   * Comparison le other.
   * @overload le other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self le other.
   */
  rb_define_method(cT, "le", uint8_le, 1);
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
  rb_define_method(cT, "clip", uint8_clip, 2);
  /**
   * sum of self.
   * @overload sum(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Performs sum along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::UInt64] returns result of sum.
   */
  rb_define_method(cT, "sum", uint8_sum, -1);
  /**
   * prod of self.
   * @overload prod(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Performs prod along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::UInt64] returns result of prod.
   */
  rb_define_method(cT, "prod", uint8_prod, -1);
  /**
   * min of self.
   * @overload min(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Performs min along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::UInt8] returns result of min.
   */
  rb_define_method(cT, "min", uint8_min, -1);
  /**
   * max of self.
   * @overload max(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Performs max along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::UInt8] returns result of max.
   */
  rb_define_method(cT, "max", uint8_max, -1);
  /**
   * ptp of self.
   * @overload ptp(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Performs ptp along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::UInt8] returns result of ptp.
   */
  rb_define_method(cT, "ptp", uint8_ptp, -1);
  /**
   * Index of the maximum value.
   * @overload max_index(axis:nil)
   *   @param [Numeric,Array,Range] axis  Finds maximum values along the axis and
   *     returns **flat 1-d indices**.
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
  rb_define_method(cT, "max_index", uint8_max_index, -1);
  /**
   * Index of the minimum value.
   * @overload min_index(axis:nil)
   *   @param [Numeric,Array,Range] axis  Finds minimum values along the axis and
   *     returns **flat 1-d indices**.
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
  rb_define_method(cT, "min_index", uint8_min_index, -1);
  /**
   * Index of the maximum value.
   * @overload argmax(axis:nil)
   *   @param [Numeric,Array,Range] axis  Finds maximum values along the axis and
   *     returns **indices along the axis**.
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
  rb_define_method(cT, "argmax", uint8_argmax, -1);
  /**
   * Index of the minimum value.
   * @overload argmin(axis:nil)
   *   @param [Numeric,Array,Range] axis  Finds minimum values along the axis and
   *     returns **indices along the axis**.
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
  rb_define_method(cT, "argmin", uint8_argmin, -1);
  /**
   * minmax of self.
   * @overload minmax(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Finds min-max along the axis.
   *   @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in
   *     the result array as dimensions with size one.
   *   @return [Numo::UInt8,Numo::UInt8] min and max of self.
   */
  rb_define_method(cT, "minmax", uint8_minmax, -1);
  /**
   * Element-wise maximum of two arrays.
   * @overload maximum(a1, a2)
   *   @param [Numo::NArray,Numeric] a1,a2  The arrays holding the elements to be compared.
   *   @return [Numo::UInt8]
   */
  rb_define_module_function(cT, "maximum", uint8_s_maximum, -1);
  /**
   * Element-wise minimum of two arrays.
   * @overload minimum(a1, a2)
   *   @param [Numo::NArray,Numeric] a1,a2  The arrays holding the elements to be compared.
   *   @return [Numo::UInt8]
   */
  rb_define_module_function(cT, "minimum", uint8_s_minimum, -1);
  /**
   * Count the number of occurrences of each non-negative integer value.
   * Only Integer-types has this method.
   *
   * @overload bincount([weight], minlength:nil)
   *   @param [SFloat or DFloat or Array] weight (optional) Array of
   *     float values. Its size along last axis should be same as that of self.
   *   @param [Integer] minlength (keyword, optional) Minimum size along
   *     last axis for the output array.
   *   @return [UInt32 or UInt64 or SFloat or DFloat]
   *     Returns Float NArray if weight array is supplied,
   *     otherwise returns UInt32 or UInt64 depending on the size along last axis.
   * @example
   *   Numo::Int32[0..4].bincount
   *   # => Numo::UInt32#shape=[5]
   *   # [1, 1, 1, 1, 1]
   *
   *   Numo::Int32[0, 1, 1, 3, 2, 1, 7].bincount
   *   # => Numo::UInt32#shape=[8]
   *   # [1, 3, 1, 1, 0, 0, 0, 1]
   *
   *   x = Numo::Int32[0, 1, 1, 3, 2, 1, 7, 23]
   *   x.bincount.size == x.max+1
   *   # => true
   *
   *   w = Numo::DFloat[0.3, 0.5, 0.2, 0.7, 1.0, -0.6]
   *   x = Numo::Int32[0, 1, 1, 2, 2, 2]
   *   x.bincount(w)
   *   # => Numo::DFloat#shape=[3]
   *   # [0.3, 0.7, 1.1]
   */
  rb_define_method(cT, "bincount", uint8_bincount, -1);
  /**
   * cumsum of self.
   * @overload cumsum(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumsum along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::UInt8] cumsum of self.
   */
  rb_define_method(cT, "cumsum", uint8_cumsum, -1);
  /**
   * cumprod of self.
   * @overload cumprod(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumprod along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::UInt8] cumprod of self.
   */
  rb_define_method(cT, "cumprod", uint8_cumprod, -1);
  /**
   * Binary mulsum.
   *
   * @overload mulsum(other, axis:nil, keepdims:false)
   *   @param [Numo::NArray,Numeric] other
   *   @param [Numeric,Array,Range] axis  Performs mulsum along the axis.
   *   @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in
   *     the result array as dimensions with size one.
   *   @return [Numo::NArray] mulsum of self and other.
   */
  rb_define_method(cT, "mulsum", uint8_mulsum, -1);
  /**
   * Set linear sequence of numbers to self. The sequence is obtained from
   *    beg+i*step
   * where i is 1-dimensional index.
   * @overload seq([beg,[step]])
   *   @param [Numeric] beg  beginning of sequence. (default=0)
   *   @param [Numeric] step  step of sequence. (default=1)
   *   @return [Numo::UInt8] self.
   * @example
   *   Numo::DFloat.new(6).seq(1,-0.2)
   *   # => Numo::DFloat#shape=[6]
   *   # [1, 0.8, 0.6, 0.4, 0.2, 0]
   *
   *   Numo::DComplex.new(6).seq(1,-0.2+0.2i)
   *   # => Numo::DComplex#shape=[6]
   *   # [1+0i, 0.8+0.2i, 0.6+0.4i, 0.4+0.6i, 0.2+0.8i, 0+1i]
   */
  rb_define_method(cT, "seq", uint8_seq, -1);
  /**
   * Eye: Set a value to diagonal components, set 0 to non-diagonal components.
   * @overload eye([element,offset])
   *   @param [Numeric] element  Diagonal element to be stored. Default is 1.
   *   @param [Integer] offset Diagonal offset from the main diagonal.  The
   *       default is 0. k>0 for diagonals above the main diagonal, and k<0
   *       for diagonals below the main diagonal.
   *   @return [Numo::UInt8] eye of self.
   */
  rb_define_method(cT, "eye", uint8_eye, -1);
  rb_define_alias(cT, "indgen", "seq");
  /**
   * Generate uniformly distributed random numbers on self narray.
   * @overload rand([[low],high])
   *   @param [Numeric] low  lower inclusive boundary of random numbers. (default=0)
   *   @param [Numeric] high  upper exclusive boundary of random numbers.
   *     (default=1 or 1+1i for complex types)
   *   @return [Numo::UInt8] self.
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
  rb_define_method(cT, "rand", uint8_rand, -1);
  /**
   * Calculate polynomial.
   *   `x.poly(a0,a1,a2,...,an) = a0 + a1*x + a2*x**2 + ... + an*x**n`
   * @overload poly a0, a1, ..., an
   *   @param [Numo::NArray,Numeric] a0,a1,...,an
   *   @return [Numo::UInt8]
   */
  rb_define_method(cT, "poly", uint8_poly, -2);
  /**
   * sort of self.
   * @overload sort(axis:nil)
   *   @param [Numeric,Array,Range] axis  Performs sort along the axis.
   *   @return [Numo::UInt8] returns result of sort.
   * @example
   *     Numo::DFloat[3,4,1,2].sort #=> Numo::DFloat[1,2,3,4]
   */
  rb_define_method(cT, "sort", uint8_sort, -1);
  /**
   * sort_index. Returns an index array of sort result.
   * @overload sort_index(axis:nil)
   *   @param [Numeric,Array,Range] axis  Performs sort_index along the axis.
   *   @return [Integer,Numo::Int] returns result index of sort_index.
   * @example
   *     Numo::NArray[3,4,1,2].sort_index #=> Numo::Int32[2,3,0,1]
   */
  rb_define_method(cT, "sort_index", uint8_sort_index, -1);
  /**
   * median of self.
   * @overload median(axis:nil, keepdims:false)
   *   @param [Numeric,Array,Range] axis  Finds median along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *   dimensions with size one.
   *   @return [Numo::UInt8] returns median of self.
   */
  rb_define_method(cT, "median", uint8_median, -1);
  rb_define_singleton_method(cT, "[]", uint8_s_cast, -2);
  /**
   * mean of self.
   * @overload mean(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs mean along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of mean.
   */
  rb_define_method(cT, "mean", uint8_mean, -1);
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
  rb_define_method(cT, "var", uint8_var, -1);
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
  rb_define_method(cT, "stddev", uint8_stddev, -1);
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
  rb_define_method(cT, "rms", uint8_rms, -1);
}
