/*
  t_robject.c
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

static ID id_ne;
static ID id_pow;
static ID id_minus;
static ID id_lt;
static ID id_left_shift;
static ID id_le;
static ID id_ufo;
static ID id_eq;
static ID id_gt;
static ID id_ge;
static ID id_right_shift;
static ID id_abs;
static ID id_bit_and;
static ID id_bit_not;
static ID id_bit_or;
static ID id_bit_xor;
static ID id_cast;
static ID id_ceil;
static ID id_copysign;
static ID id_divmod;
static ID id_finite_p;
static ID id_floor;
static ID id_infinite_p;
static ID id_mulsum;
static ID id_nan;
static ID id_nan_p;
static ID id_nearly_eq;
static ID id_reciprocal;
static ID id_round;
static ID id_square;
static ID id_to_a;
static ID id_truncate;

#include <numo/types/robject.h>

/*
  class definition: Numo::RObject
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
#include "mh/comp/eq.h"
#include "mh/comp/ne.h"
#include "mh/comp/nearly_eq.h"
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
#include "mh/poly.h"

typedef VALUE robject; // Type aliases for shorter notation
                       // following the codebase naming convention.
DEF_NARRAY_ROBJ_STORE_METHOD_FUNC()
DEF_NARRAY_ROBJ_S_CAST_METHOD_FUNC()
DEF_NARRAY_EXTRACT_METHOD_FUNC(robject)
DEF_NARRAY_AREF_METHOD_FUNC(robject)
DEF_EXTRACT_DATA_FUNC(robject, numo_cRObject)
DEF_NARRAY_ASET_METHOD_FUNC(robject)
DEF_NARRAY_COERCE_CAST_METHOD_FUNC(robject)
DEF_NARRAY_TO_A_METHOD_FUNC(robject)
DEF_NARRAY_FILL_METHOD_FUNC(robject)
DEF_NARRAY_FORMAT_METHOD_FUNC(robject)
DEF_NARRAY_FORMAT_TO_A_METHOD_FUNC(robject)
DEF_NARRAY_ROBJ_INSPECT_METHOD_FUNC()
DEF_NARRAY_EACH_METHOD_FUNC(robject)
DEF_NARRAY_ROBJ_MAP_METHOD_FUNC()
DEF_NARRAY_EACH_WITH_INDEX_METHOD_FUNC(robject)
DEF_NARRAY_MAP_WITH_INDEX_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_ABS_METHOD_FUNC(robject, numo_cRObject, robject, numo_cRObject)
DEF_NARRAY_ROBJ_ADD_METHOD_FUNC()
DEF_NARRAY_ROBJ_SUB_METHOD_FUNC()
DEF_NARRAY_ROBJ_MUL_METHOD_FUNC()
DEF_NARRAY_ROBJ_DIV_METHOD_FUNC()
DEF_NARRAY_ROBJ_MOD_METHOD_FUNC()
DEF_NARRAY_ROBJ_DIVMOD_METHOD_FUNC()
DEF_NARRAY_ROBJ_POW_METHOD_FUNC()
DEF_NARRAY_ROBJ_MINUS_METHOD_FUNC()
DEF_NARRAY_ROBJ_RECIPROCAL_METHOD_FUNC()
DEF_NARRAY_ROBJ_SIGN_METHOD_FUNC()
DEF_NARRAY_ROBJ_SQUARE_METHOD_FUNC()
DEF_NARRAY_ROBJ_FLOOR_METHOD_FUNC()
DEF_NARRAY_ROBJ_ROUND_METHOD_FUNC()
DEF_NARRAY_ROBJ_CEIL_METHOD_FUNC()
DEF_NARRAY_ROBJ_TRUNC_METHOD_FUNC()
DEF_NARRAY_ROBJ_EQ_METHOD_FUNC()
DEF_NARRAY_ROBJ_NE_METHOD_FUNC()
DEF_NARRAY_ROBJ_NEARLY_EQ_METHOD_FUNC()
DEF_NARRAY_ROBJ_GT_METHOD_FUNC()
DEF_NARRAY_ROBJ_GE_METHOD_FUNC()
DEF_NARRAY_ROBJ_LT_METHOD_FUNC()
DEF_NARRAY_ROBJ_LE_METHOD_FUNC()
DEF_NARRAY_ROBJ_BIT_AND_METHOD_FUNC()
DEF_NARRAY_ROBJ_BIT_OR_METHOD_FUNC()
DEF_NARRAY_ROBJ_BIT_XOR_METHOD_FUNC()
DEF_NARRAY_ROBJ_BIT_NOT_METHOD_FUNC()
DEF_NARRAY_ROBJ_LEFT_SHIFT_METHOD_FUNC()
DEF_NARRAY_ROBJ_RIGHT_SHIFT_METHOD_FUNC()
DEF_NARRAY_CLIP_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_ISNAN_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_ISINF_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_ISPOSINF_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_ISNEGINF_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_ISFINITE_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_SUM_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_PROD_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MEAN_METHOD_FUNC(robject, numo_cRObject, VALUE, numo_cRObject)
DEF_NARRAY_FLT_VAR_METHOD_FUNC(robject, numo_cRObject, VALUE, numo_cRObject)
DEF_NARRAY_FLT_STDDEV_METHOD_FUNC(robject, numo_cRObject, VALUE, numo_cRObject)
DEF_NARRAY_FLT_RMS_METHOD_FUNC(robject, numo_cRObject, VALUE, numo_cRObject)
DEF_NARRAY_FLT_MIN_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MAX_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_PTP_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MAX_INDEX_METHOD_FUNC(robject)
DEF_NARRAY_FLT_MIN_INDEX_METHOD_FUNC(robject)
DEF_NARRAY_FLT_ARGMAX_METHOD_FUNC(robject)
DEF_NARRAY_FLT_ARGMIN_METHOD_FUNC(robject)
DEF_NARRAY_FLT_MAXIMUM_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MINIMUM_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MINMAX_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_CUMSUM_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_CUMPROD_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_MULSUM_METHOD_FUNC(robject, numo_cRObject)
DEF_NARRAY_FLT_SEQ_METHOD_FUNC(robject)
DEF_NARRAY_FLT_LOGSEQ_METHOD_FUNC(robject)
DEF_NARRAY_EYE_METHOD_FUNC(robject)
DEF_NARRAY_FLT_RAND_METHOD_FUNC(robject)
DEF_NARRAY_POLY_METHOD_FUNC(robject, numo_cRObject)

static size_t robject_memsize(const void* ptr) {
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

static void robject_free(void* ptr) {
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

static narray_type_info_t robject_info = {

  0,             // element_bits
  sizeof(dtype), // element_bytes
  sizeof(dtype), // element_stride (in bytes)

};

static void robject_gc_mark(void* ptr) {
  size_t n, i;
  VALUE* a;
  narray_data_t* na = ptr;

  if (na->ptr) {
    a = (VALUE*)(na->ptr);
    n = na->base.size;
    for (i = 0; i < n; i++) {
      rb_gc_mark(a[i]);
    }
  }
}

static const rb_data_type_t robject_data_type = {
  "Numo::RObject",
  {
    robject_gc_mark,
    robject_free,
    robject_memsize,
  },
  &na_data_type,
  &robject_info,
  0, // flags
};

static VALUE robject_s_alloc_func(VALUE klass) {
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
  return TypedData_Wrap_Struct(klass, &robject_data_type, (void*)na);
}

static VALUE robject_allocate(VALUE self) {
  narray_t* na;
  char* ptr;

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    ptr = NA_DATA_PTR(na);
    if (na->size > 0 && ptr == NULL) {
      ptr = xmalloc(sizeof(dtype) * na->size);

      {
        size_t i;
        VALUE* a = (VALUE*)ptr;
        for (i = na->size; i--;) {
          *a++ = Qnil;
        }
      }

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

void Init_numo_robject(void) {
  VALUE hCast, mNumo;

  mNumo = rb_define_module("Numo");

  id_ne = rb_intern("!=");
  id_pow = rb_intern("**");
  id_minus = rb_intern("-@");
  id_lt = rb_intern("<");
  id_left_shift = rb_intern("<<");
  id_le = rb_intern("<=");
  id_ufo = rb_intern("<=>");
  id_eq = rb_intern("==");
  id_gt = rb_intern(">");
  id_ge = rb_intern(">=");
  id_right_shift = rb_intern(">>");
  id_abs = rb_intern("abs");
  id_bit_and = rb_intern("bit_and");
  id_bit_not = rb_intern("bit_not");
  id_bit_or = rb_intern("bit_or");
  id_bit_xor = rb_intern("bit_xor");
  id_cast = rb_intern("cast");
  id_ceil = rb_intern("ceil");
  id_copysign = rb_intern("copysign");
  id_divmod = rb_intern("divmod");
  id_finite_p = rb_intern("finite?");
  id_floor = rb_intern("floor");
  id_infinite_p = rb_intern("infinite?");
  id_mulsum = rb_intern("mulsum");
  id_nan = rb_intern("nan");
  id_nan_p = rb_intern("nan?");
  id_nearly_eq = rb_intern("nearly_eq");
  id_reciprocal = rb_intern("reciprocal");
  id_round = rb_intern("round");
  id_square = rb_intern("square");
  id_to_a = rb_intern("to_a");
  id_truncate = rb_intern("truncate");

  /**
   * Document-class: Numo::RObject
   *
   * Ruby object N-dimensional array class.
   */
  cT = rb_define_class_under(mNumo, "RObject", cNArray);

  hCast = rb_hash_new();
  /* Upcasting rules of RObject. */
  rb_define_const(cT, "UPCAST", hCast);
  rb_hash_aset(hCast, rb_cArray, cT);

  rb_hash_aset(hCast, rb_cInteger, cT);
  rb_hash_aset(hCast, rb_cFloat, cT);
  rb_hash_aset(hCast, rb_cComplex, cT);
  rb_hash_aset(hCast, numo_cDComplex, numo_cRObject);
  rb_hash_aset(hCast, numo_cSComplex, numo_cRObject);
  rb_hash_aset(hCast, numo_cDFloat, numo_cRObject);
  rb_hash_aset(hCast, numo_cSFloat, numo_cRObject);
  rb_hash_aset(hCast, numo_cInt64, numo_cRObject);
  rb_hash_aset(hCast, numo_cInt32, numo_cRObject);
  rb_hash_aset(hCast, numo_cInt16, numo_cRObject);
  rb_hash_aset(hCast, numo_cInt8, numo_cRObject);
  rb_hash_aset(hCast, numo_cUInt64, numo_cRObject);
  rb_hash_aset(hCast, numo_cUInt32, numo_cRObject);
  rb_hash_aset(hCast, numo_cUInt16, numo_cRObject);
  rb_hash_aset(hCast, numo_cUInt8, numo_cRObject);
  rb_obj_freeze(hCast);

  /* Element size of RObject in bits. */
  rb_define_const(cT, "ELEMENT_BIT_SIZE", INT2FIX(sizeof(dtype) * 8));
  /* Element size of RObject in bytes. */
  rb_define_const(cT, "ELEMENT_BYTE_SIZE", INT2FIX(sizeof(dtype)));
  /* Stride size of contiguous RObject array. */
  rb_define_const(cT, "CONTIGUOUS_STRIDE", INT2FIX(sizeof(dtype)));
  rb_undef_method(rb_singleton_class(cT), "from_binary");
  rb_undef_method(cT, "to_binary");
  rb_undef_method(cT, "swap_byte");
  rb_undef_method(cT, "to_network");
  rb_undef_method(cT, "to_vacs");
  rb_undef_method(cT, "to_host");
  rb_undef_method(cT, "to_swapped");
  rb_define_alloc_func(cT, robject_s_alloc_func);
  rb_define_method(cT, "allocate", robject_allocate, 0);
  /**
   * Extract an element only if self is a dimensionless NArray.
   * @overload extract
   *   @return [Numeric,Numo::NArray]
   *   --- Extract element value as Ruby Object if self is a dimensionless NArray,
   *   otherwise returns self.
   */
  rb_define_method(cT, "extract", robject_extract, 0);
  /**
   * Store elements to Numo::RObject from other.
   * @overload store(other)
   *   @param [Object] other
   *   @return [Numo::RObject] self
   */
  rb_define_method(cT, "store", robject_store, 1);
  /**
   * Cast object to Numo::RObject.
   * @overload [](elements)
   * @overload cast(array)
   *   @param [Numeric,Array] elements
   *   @param [Array] array
   *   @return [Numo::RObject]
   */
  rb_define_singleton_method(cT, "cast", robject_s_cast, 1);
  /**
   * Multi-dimensional element reference.
   * @overload [](dim0,...,dimL)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,
   *     Symbol] dim0,...,dimL  multi-dimensional indices.
   *   @return [Numeric,Numo::RObject] an element or NArray view.
   * @see Numo::NArray#[]
   * @see #[]=
   */
  rb_define_method(cT, "[]", robject_aref, -1);
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
  rb_define_method(cT, "[]=", robject_aset, -1);
  /**
   * return NArray with cast to the type of self.
   * @overload coerce_cast(type)
   *   @return [nil]
   */
  rb_define_method(cT, "coerce_cast", robject_coerce_cast, 1);
  /**
   * Convert self to Array.
   * @overload to_a
   *   @return [Array]
   */
  rb_define_method(cT, "to_a", robject_to_a, 0);
  /**
   * Fill elements with other.
   * @overload fill other
   *   @param [Numeric] other
   *   @return [Numo::RObject] self.
   */
  rb_define_method(cT, "fill", robject_fill, 1);
  /**
   * Format elements into strings.
   * @overload format format
   *   @param [String] format
   *   @return [Numo::RObject] array of formatted strings.
   */
  rb_define_method(cT, "format", robject_format, -1);
  /**
   * Format elements into strings.
   * @overload format_to_a format
   *   @param [String] format
   *   @return [Array] array of formatted strings.
   */
  rb_define_method(cT, "format_to_a", robject_format_to_a, -1);
  /**
   * Returns a string containing a human-readable representation of NArray.
   * @overload inspect
   *   @return [String]
   */
  rb_define_method(cT, "inspect", robject_inspect, 0);
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
  rb_define_method(cT, "each", robject_each, 0);
  /**
   * Unary map.
   * @overload map
   *   @return [Numo::RObject] map of self.
   */
  rb_define_method(cT, "map", robject_map, 0);
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
  rb_define_method(cT, "each_with_index", robject_each_with_index, 0);
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
  rb_define_method(cT, "map_with_index", robject_map_with_index, 0);
  /**
   * abs of self.
   * @overload abs
   *   @return [Numo::RObject] abs of self.
   */
  rb_define_method(cT, "abs", robject_abs, 0);
  /**
   * Binary add.
   * @overload + other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self + other
   */
  rb_define_method(cT, "+", robject_add, 1);
  /**
   * Binary sub.
   * @overload - other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self - other
   */
  rb_define_method(cT, "-", robject_sub, 1);
  /**
   * Binary mul.
   * @overload * other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self * other
   */
  rb_define_method(cT, "*", robject_mul, 1);
  /**
   * Binary div.
   * @overload / other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self / other
   */
  rb_define_method(cT, "/", robject_div, 1);
  /**
   * Binary mod.
   * @overload % other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self % other
   */
  rb_define_method(cT, "%", robject_mod, 1);
  /**
   * Binary divmod.
   * @overload divmod other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] divmod of self and other.
   */
  rb_define_method(cT, "divmod", robject_divmod, 1);
  /**
   * Binary power.
   * @overload ** other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self to the other-th power.
   */
  rb_define_method(cT, "**", robject_pow, 1);
  rb_define_alias(cT, "pow", "**");
  /**
   * Unary minus.
   * @overload -@
   *   @return [Numo::RObject] minus of self.
   */
  rb_define_method(cT, "-@", robject_minus, 0);
  /**
   * Unary reciprocal.
   * @overload reciprocal
   *   @return [Numo::RObject] reciprocal of self.
   */
  rb_define_method(cT, "reciprocal", robject_reciprocal, 0);
  /**
   * Unary sign.
   * @overload sign
   *   @return [Numo::RObject] sign of self.
   */
  rb_define_method(cT, "sign", robject_sign, 0);
  /**
   * Unary square.
   * @overload square
   *   @return [Numo::RObject] square of self.
   */
  rb_define_method(cT, "square", robject_square, 0);
  rb_define_alias(cT, "conj", "view");
  rb_define_alias(cT, "im", "view");
  rb_define_alias(cT, "conjugate", "conj");
  /**
   * Comparison eq other.
   * @overload eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self eq other.
   */
  rb_define_method(cT, "eq", robject_eq, 1);
  /**
   * Comparison ne other.
   * @overload ne other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ne other.
   */
  rb_define_method(cT, "ne", robject_ne, 1);
  /**
   * Comparison nearly_eq other.
   * @overload nearly_eq other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self nearly_eq other.
   */
  rb_define_method(cT, "nearly_eq", robject_nearly_eq, 1);
  rb_define_alias(cT, "close_to", "nearly_eq");
  /**
   * Binary bit_and.
   * @overload & other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self & other
   */
  rb_define_method(cT, "&", robject_bit_and, 1);
  /**
   * Binary bit_or.
   * @overload | other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self | other
   */
  rb_define_method(cT, "|", robject_bit_or, 1);
  /**
   * Binary bit_xor.
   * @overload ^ other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self ^ other
   */
  rb_define_method(cT, "^", robject_bit_xor, 1);
  /**
   * Unary bit_not.
   * @overload ~
   *   @return [Numo::RObject] bit_not of self.
   */
  rb_define_method(cT, "~", robject_bit_not, 0);
  /**
   * Binary left_shift.
   * @overload << other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self << other
   */
  rb_define_method(cT, "<<", robject_left_shift, 1);
  /**
   * Binary right_shift.
   * @overload >> other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::NArray] self >> other
   */
  rb_define_method(cT, ">>", robject_right_shift, 1);
  /**
   * Unary floor.
   * @overload floor
   *   @return [Numo::RObject] floor of self.
   */
  rb_define_method(cT, "floor", robject_floor, 0);
  /**
   * Unary round.
   * @overload round
   *   @return [Numo::RObject] round of self.
   */
  rb_define_method(cT, "round", robject_round, 0);
  /**
   * Unary ceil.
   * @overload ceil
   *   @return [Numo::RObject] ceil of self.
   */
  rb_define_method(cT, "ceil", robject_ceil, 0);
  /**
   * Unary trunc.
   * @overload trunc
   *   @return [Numo::RObject] trunc of self.
   */
  rb_define_method(cT, "trunc", robject_trunc, 0);
  /**
   * Comparison gt other.
   * @overload gt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self gt other.
   */
  rb_define_method(cT, "gt", robject_gt, 1);
  /**
   * Comparison ge other.
   * @overload ge other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self ge other.
   */
  rb_define_method(cT, "ge", robject_ge, 1);
  /**
   * Comparison lt other.
   * @overload lt other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self lt other.
   */
  rb_define_method(cT, "lt", robject_lt, 1);
  /**
   * Comparison le other.
   * @overload le other
   *   @param [Numo::NArray,Numeric] other
   *   @return [Numo::Bit] result of self le other.
   */
  rb_define_method(cT, "le", robject_le, 1);
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
  rb_define_method(cT, "clip", robject_clip, 2);
  /**
   * Condition of isnan.
   * @overload isnan
   *   @return [Numo::Bit] Condition of isnan.
   */
  rb_define_method(cT, "isnan", robject_isnan, 0);
  /**
   * Condition of isinf.
   * @overload isinf
   *   @return [Numo::Bit] Condition of isinf.
   */
  rb_define_method(cT, "isinf", robject_isinf, 0);
  /**
   * Condition of isposinf.
   * @overload isposinf
   *   @return [Numo::Bit] Condition of isposinf.
   */
  rb_define_method(cT, "isposinf", robject_isposinf, 0);
  /**
   * Condition of isneginf.
   * @overload isneginf
   *   @return [Numo::Bit] Condition of isneginf.
   */
  rb_define_method(cT, "isneginf", robject_isneginf, 0);
  /**
   * Condition of isfinite.
   * @overload isfinite
   *   @return [Numo::Bit] Condition of isfinite.
   */
  rb_define_method(cT, "isfinite", robject_isfinite, 0);
  /**
   * sum of self.
   * @overload sum(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs sum along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::RObject] returns result of sum.
   */
  rb_define_method(cT, "sum", robject_sum, -1);
  /**
   * prod of self.
   * @overload prod(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs prod along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::RObject] returns result of prod.
   */
  rb_define_method(cT, "prod", robject_prod, -1);
  /**
   * mean of self.
   * @overload mean(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs mean along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::RObject] returns result of mean.
   */
  rb_define_method(cT, "mean", robject_mean, -1);
  /**
   * var of self.
   * @overload var(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs var along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::RObject] returns result of var.
   */
  rb_define_method(cT, "var", robject_var, -1);
  /**
   * stddev of self.
   * @overload stddev(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs stddev along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::RObject] returns result of stddev.
   */
  rb_define_method(cT, "stddev", robject_stddev, -1);
  /**
   * rms of self.
   * @overload rms(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs rms along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::RObject] returns result of rms.
   */
  rb_define_method(cT, "rms", robject_rms, -1);
  /**
   * min of self.
   * @overload min(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs min along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::RObject] returns result of min.
   */
  rb_define_method(cT, "min", robject_min, -1);
  /**
   * max of self.
   * @overload max(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs max along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::RObject] returns result of max.
   */
  rb_define_method(cT, "max", robject_max, -1);
  /**
   * ptp of self.
   * @overload ptp(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @param [Numeric,Array,Range] axis  Performs ptp along the axis.
   *   @param [TrueClass] keepdims  If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @return [Numo::RObject] returns result of ptp.
   */
  rb_define_method(cT, "ptp", robject_ptp, -1);
  /**
   * Index of the maximum value.
   * @overload max_index(axis:nil, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (return
   *     NaN posision if exist).
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
  rb_define_method(cT, "max_index", robject_max_index, -1);
  /**
   * Index of the minimum value.
   * @overload min_index(axis:nil, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (returnNaN posision if exist).
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
  rb_define_method(cT, "min_index", robject_min_index, -1);
  /**
   * Index of the maximum value.
   * @overload argmax(axis:nil, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (return NaN posision
   *     if exist).
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
  rb_define_method(cT, "argmax", robject_argmax, -1);
  /**
   * Index of the minimum value.
   * @overload argmin(axis:nil, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (return
   *     NaN posision if exist).
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
  rb_define_method(cT, "argmin", robject_argmin, -1);
  /**
   * minmax of self.
   * @overload minmax(axis:nil, keepdims:false, nan:false)
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @param [Numeric,Array,Range] axis  Finds min-max along the axis.
   *   @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in
   *     the result array as dimensions with size one.
   *   @return [Numo::RObject,Numo::RObject] min and max of self.
   */
  rb_define_method(cT, "minmax", robject_minmax, -1);
  /**
   * Element-wise maximum of two arrays.
   * @overload maximum(a1, a2, nan:false)
   *   @param [Numo::NArray,Numeric] a1  The array to be compared.
   *   @param [Numo::NArray,Numeric] a2  The array to be compared.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @return [Numo::RObject]
   */
  rb_define_module_function(cT, "maximum", robject_s_maximum, -1);
  /**
   * Element-wise minimum of two arrays.
   * @overload minimum(a1, a2, nan:false)
   *   @param [Numo::NArray,Numeric] a1  The array to be compared.
   *   @param [Numo::NArray,Numeric] a2  The array to be compared.
   *   @param [Boolean] nan  If true, apply NaN-aware algorithm (return NaN if exist).
   *   @return [Numo::RObject]
   */
  rb_define_module_function(cT, "minimum", robject_s_minimum, -1);
  /**
   * cumsum of self.
   * @overload cumsum(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumsum along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::RObject] cumsum of self.
   */
  rb_define_method(cT, "cumsum", robject_cumsum, -1);
  /**
   * cumprod of self.
   * @overload cumprod(axis:nil, nan:false)
   *   @param [Numeric,Array,Range] axis  Performs cumprod along the axis.
   *   @param [TrueClass] nan  If true, apply NaN-aware algorithm (avoid NaN if exists).
   *   @return [Numo::RObject] cumprod of self.
   */
  rb_define_method(cT, "cumprod", robject_cumprod, -1);
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
  rb_define_method(cT, "mulsum", robject_mulsum, -1);
  /**
   * Set linear sequence of numbers to self. The sequence is obtained from
   *    beg+i*step
   * where i is 1-dimensional index.
   * @overload seq([beg,[step]])
   *   @param [Numeric] beg  beginning of sequence. (default=0)
   *   @param [Numeric] step  step of sequence. (default=1)
   *   @return [Numo::RObject] self.
   * @example
   *   Numo::DFloat.new(6).seq(1,-0.2)
   *   # => Numo::DFloat#shape=[6]
   *   # [1, 0.8, 0.6, 0.4, 0.2, 0]
   *
   *   Numo::DComplex.new(6).seq(1,-0.2+0.2i)
   *   # => Numo::DComplex#shape=[6]
   *   # [1+0i, 0.8+0.2i, 0.6+0.4i, 0.4+0.6i, 0.2+0.8i, 0+1i]
   */
  rb_define_method(cT, "seq", robject_seq, -1);
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
   *   @return [Numo::RObject] self.
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
  rb_define_method(cT, "logseq", robject_logseq, -1);
  /**
   * Eye: Set a value to diagonal components, set 0 to non-diagonal components.
   * @overload eye([element,offset])
   *   @param [Numeric] element  Diagonal element to be stored. Default is 1.
   *   @param [Integer] offset Diagonal offset from the main diagonal.  The
   *       default is 0. k>0 for diagonals above the main diagonal, and k<0
   *       for diagonals below the main diagonal.
   *   @return [Numo::RObject] eye of self.
   */
  rb_define_method(cT, "eye", robject_eye, -1);
  rb_define_alias(cT, "indgen", "seq");
  /**
   * Generate uniformly distributed random numbers on self narray.
   * @overload rand([[low],high])
   *   @param [Numeric] low  lower inclusive boundary of random numbers. (default=0)
   *   @param [Numeric] high  upper exclusive boundary of random numbers.
   *     (default=1 or 1+1i for complex types)
   *   @return [Numo::RObject] self.
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
  rb_define_method(cT, "rand", robject_rand, -1);
  /**
   * Calculate polynomial.
   *   `x.poly(a0,a1,a2,...,an) = a0 + a1*x + a2*x**2 + ... + an*x**n`
   * @overload poly a0, a1, ..., an
   *   @param [Numo::NArray,Numeric] a0,a1,...,an
   *   @return [Numo::RObject]
   */
  rb_define_method(cT, "poly", robject_poly, -2);
  rb_define_singleton_method(cT, "[]", robject_s_cast, -2);
}
