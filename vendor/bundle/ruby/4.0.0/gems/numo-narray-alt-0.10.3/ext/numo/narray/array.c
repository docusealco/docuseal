/*
  array.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#include <ruby.h>

#include "numo/narray.h"

// mdai: Multi-Dimensional Array Investigation
typedef struct {
  size_t shape;
  VALUE val;
} na_mdai_item_t;

typedef struct {
  int capa;
  na_mdai_item_t* item;
  int type;      // Ruby numeric type - investigated separately
  VALUE na_type; // NArray type
  VALUE int_max;
} na_mdai_t;

// Order of Ruby object.
enum {
  NA_NONE,
  NA_BIT,
  NA_INT32,
  NA_INT64,
  NA_RATIONAL,
  NA_DFLOAT,
  NA_DCOMPLEX,
  NA_ROBJ,
  NA_NTYPES
};

static ID id_begin;
static ID id_end;
static ID id_step;
static ID id_abs;
static ID id_cast;
static ID id_le;
#if SIZEOF_LONG <= 4
static ID id_ge;
#endif
static ID id_Complex;
static VALUE int32_max = Qnil;
static VALUE int32_min = Qnil;

static VALUE na_object_type(int type, VALUE v) {
  switch (TYPE(v)) {

  case T_TRUE:
  case T_FALSE:
    if (type < NA_BIT) return NA_BIT;
    return type;

#if SIZEOF_LONG <= 4
  case T_FIXNUM:
    if (type < NA_INT32) return NA_INT32;
    return type;
  case T_BIGNUM:
    if (type < NA_INT64) {
      if (RTEST(rb_funcall(v, id_le, 1, int32_max)) &&
          RTEST(rb_funcall(v, id_ge, 1, int32_min))) {
        if (type < NA_INT32) return NA_INT32;
      } else {
        return NA_INT64;
      }
    }
    return type;
#else
  case T_FIXNUM:
    if (type < NA_INT64) {
      long x = NUM2LONG(v);
      if (x <= 2147483647L && x >= -2147483648L) {
        if (type < NA_INT32) return NA_INT32;
      } else {
        return NA_INT64;
      }
    }
    return type;
  case T_BIGNUM:
    if (type < NA_INT64) return NA_INT64;
    return type;
#endif

  case T_FLOAT:
    if (type < NA_DFLOAT) return NA_DFLOAT;
    return type;

  case T_NIL:
    return type;

  default:
    if (rb_obj_class(v) == rb_const_get(rb_cObject, id_Complex)) {
      return NA_DCOMPLEX;
    }
  }
  return NA_ROBJ;
}

static int na_mdai_object_type(int type, VALUE v) {
  if (rb_obj_is_kind_of(v, rb_cRange)) {
    type = (int)na_object_type(type, rb_funcall(v, id_begin, 0));
    type = (int)na_object_type(type, rb_funcall(v, id_end, 0));
  } else if (rb_obj_is_kind_of(v, rb_cArithSeq)) {
    type = (int)na_object_type(type, rb_funcall(v, id_begin, 0));
    type = (int)na_object_type(type, rb_funcall(v, id_end, 0));
    type = (int)na_object_type(type, rb_funcall(v, id_step, 0));
  } else {
    type = (int)na_object_type(type, v);
  }
  return type;
}

static na_mdai_t* na_mdai_alloc(VALUE ary) {
  int i, n = 4;
  na_mdai_t* mdai;

  mdai = ALLOC(na_mdai_t);
  mdai->capa = n;
  mdai->item = ALLOC_N(na_mdai_item_t, n);
  for (i = 0; i < n; i++) {
    mdai->item[i].shape = 0;
    mdai->item[i].val = Qnil;
  }
  mdai->item[0].val = ary;
  mdai->type = NA_NONE;
  mdai->na_type = Qnil;

  return mdai;
}

static void na_mdai_realloc(na_mdai_t* mdai, int n_extra) {
  int i, n;

  i = mdai->capa;
  mdai->capa += n_extra;
  n = mdai->capa;
  REALLOC_N(mdai->item, na_mdai_item_t, n);
  for (; i < n; i++) {
    mdai->item[i].shape = 0;
    mdai->item[i].val = Qnil;
  }
}

static void na_mdai_free(void* ptr) {
  na_mdai_t* mdai = (na_mdai_t*)ptr;
  xfree(mdai->item);
  xfree(mdai);
}

/* investigate ndim, shape, type of Array */
static int na_mdai_investigate(na_mdai_t* mdai, int ndim) {
  ssize_t i;
  int j;
  size_t len, length;
  double dbeg, dstep;
  VALUE v;
  VALUE val;

  val = mdai->item[ndim - 1].val;
  len = RARRAY_LEN(val);

  for (i = 0; i < RARRAY_LEN(val); i++) {
    v = RARRAY_AREF(val, i);

    if (TYPE(v) == T_ARRAY) {
      /* check recursive array */
      for (j = 0; j < ndim; j++) {
        if (mdai->item[j].val == v)
          rb_raise(rb_eStandardError, "cannot convert from a recursive Array to NArray");
      }
      if (ndim >= mdai->capa) {
        na_mdai_realloc(mdai, 4);
      }
      mdai->item[ndim].val = v;
      if (na_mdai_investigate(mdai, ndim + 1)) {
        len--; /* Array is empty */
      }
    } else if (rb_obj_is_kind_of(v, rb_cRange) || rb_obj_is_kind_of(v, rb_cArithSeq)) {
      nary_step_sequence(v, &length, &dbeg, &dstep);
      len += length - 1;
      mdai->type = na_mdai_object_type(mdai->type, v);
    } else if (IsNArray(v)) {
      int r;
      narray_t* na;
      GetNArray(v, na);
      if (na->ndim == 0) {
        len--; /* NArray is empty */
      } else {
        if (ndim + na->ndim > mdai->capa) {
          na_mdai_realloc(mdai, ((na->ndim - 1) / 4 + 1) * 4);
        }
        for (j = 0, r = ndim; j < na->ndim; j++, r++) {
          if (mdai->item[r].shape < na->shape[j]) mdai->item[r].shape = na->shape[j];
        }
      }
      // type
      if (NIL_P(mdai->na_type)) {
        mdai->na_type = rb_obj_class(v);
      } else {
        mdai->na_type = na_upcast(rb_obj_class(v), mdai->na_type);
      }
    } else {
      mdai->type = na_mdai_object_type(mdai->type, v);
    }
  }

  if (len == 0) return 1; /* this array is empty */
  if (mdai->item[ndim - 1].shape < len) {
    mdai->item[ndim - 1].shape = len;
  }
  return 0;
}

static inline int na_mdai_ndim(na_mdai_t* mdai) {
  int i;
  // Dimension
  for (i = 0; i < mdai->capa && mdai->item[i].shape > 0; i++);
  return i;
}

static inline void na_mdai_shape(na_mdai_t* mdai, int ndim, size_t* shape) {
  int i;
  for (i = 0; i < ndim; i++) {
    shape[i] = mdai->item[i].shape;
  }
}

static VALUE na_mdai_dtype_numeric(int type) {
  VALUE tp;
  // DataType
  switch (type) {
  case NA_BIT:
    tp = numo_cBit;
    break;
  case NA_INT32:
    tp = numo_cInt32;
    break;
  case NA_INT64:
    tp = numo_cInt64;
    break;
  case NA_DFLOAT:
    tp = numo_cDFloat;
    break;
  case NA_DCOMPLEX:
    tp = numo_cDComplex;
    break;
  case NA_ROBJ:
    tp = numo_cRObject;
    break;
  default:
    tp = Qnil;
  }
  return tp;
}

static VALUE na_mdai_dtype(na_mdai_t* mdai) {
  VALUE tp;

  tp = na_mdai_dtype_numeric(mdai->type);

  if (!NIL_P(mdai->na_type)) {
    if (NIL_P(tp)) {
      tp = mdai->na_type;
    } else {
      tp = na_upcast(mdai->na_type, tp);
    }
  }
  return tp;
}

static inline VALUE update_type(VALUE* ptype, VALUE dtype) {
  if (ptype) {
    if (*ptype == cNArray || !RTEST(*ptype)) {
      *ptype = dtype;
    } else {
      dtype = *ptype;
    }
  }
  return dtype;
}

static inline void check_subclass_of_narray(VALUE dtype) {
  if (RTEST(rb_obj_is_kind_of(dtype, rb_cClass))) {
    if (RTEST(rb_funcall(dtype, id_le, 1, cNArray))) {
      return;
    }
  }
  rb_raise(nary_eCastError, "cannot convert to NArray");
}

static size_t na_mdai_memsize(const void* ptr) {
  const na_mdai_t* mdai = (const na_mdai_t*)ptr;

  return sizeof(na_mdai_t) + mdai->capa * sizeof(na_mdai_item_t);
}

static const rb_data_type_t mdai_data_type = { "Numo::NArray/mdai",
                                               {
                                                 NULL,
                                                 na_mdai_free,
                                                 na_mdai_memsize,
                                               },
                                               0,
                                               0,
                                               RUBY_TYPED_FREE_IMMEDIATELY |
                                                 RUBY_TYPED_WB_PROTECTED };

static void na_composition3_ary(VALUE ary, VALUE* ptype, VALUE* pshape, VALUE* pnary) {
  VALUE vmdai;
  na_mdai_t* mdai;
  int i, ndim;
  size_t* shape;
  VALUE dtype, dshape;

  mdai = na_mdai_alloc(ary);
  vmdai = TypedData_Wrap_Struct(rb_cObject, &mdai_data_type, (void*)mdai);
  if (na_mdai_investigate(mdai, 1)) {
    // empty
    dtype = update_type(ptype, numo_cInt32);
    if (pshape) {
      *pshape = rb_ary_new3(1, INT2FIX(0));
    }
    if (pnary) {
      check_subclass_of_narray(dtype);
      shape = ALLOCA_N(size_t, 1);
      shape[0] = 0;
      *pnary = nary_new(dtype, 1, shape);
    }
  } else {
    ndim = na_mdai_ndim(mdai);
    shape = ALLOCA_N(size_t, ndim);
    na_mdai_shape(mdai, ndim, shape);
    dtype = update_type(ptype, na_mdai_dtype(mdai));
    if (pshape) {
      dshape = rb_ary_new2(ndim);
      for (i = 0; i < ndim; i++) {
        rb_ary_push(dshape, SIZET2NUM(shape[i]));
      }
      *pshape = dshape;
    }
    if (pnary) {
      check_subclass_of_narray(dtype);
      *pnary = nary_new(dtype, ndim, shape);
    }
  }
  RB_GC_GUARD(vmdai);
}

static void na_composition3(VALUE obj, VALUE* ptype, VALUE* pshape, VALUE* pnary) {
  VALUE dtype, dshape;

  if (TYPE(obj) == T_ARRAY) {
    na_composition3_ary(obj, ptype, pshape, pnary);
  } else if (RTEST(rb_obj_is_kind_of(obj, rb_cNumeric))) {
    dtype = na_mdai_dtype_numeric(na_mdai_object_type(NA_NONE, obj));
    dtype = update_type(ptype, dtype);
    if (pshape) {
      *pshape = rb_ary_new();
    }
    if (pnary) {
      check_subclass_of_narray(dtype);
      *pnary = nary_new(dtype, 0, 0);
    }
  } else if (IsNArray(obj)) {
    int i, ndim;
    narray_t* na;
    GetNArray(obj, na);
    ndim = na->ndim;
    dtype = update_type(ptype, rb_obj_class(obj));
    if (pshape) {
      dshape = rb_ary_new2(ndim);
      for (i = 0; i < ndim; i++) {
        rb_ary_push(dshape, SIZET2NUM(na->shape[i]));
      }
      *pshape = dshape;
    }
    if (pnary) {
      *pnary = nary_new(dtype, ndim, na->shape);
    }
  } else {
    rb_raise(rb_eTypeError, "invalid type for NArray: %s", rb_class2name(rb_obj_class(obj)));
  }
}

static VALUE na_s_array_shape(VALUE mod, VALUE ary) {
  VALUE shape;

  if (TYPE(ary) != T_ARRAY) {
    // 0-dimension
    return rb_ary_new();
  }
  na_composition3(ary, 0, &shape, 0);
  return shape;
}

/*
  Generate new unallocated NArray instance with shape and type defined from obj.
  Numo::NArray.new_like(obj) returns instance whose type is defined from obj.
  Numo::DFloat.new_like(obj) returns DFloat instance.

  @overload new_like(obj)
  @param [Numeric,Array,Numo::NArray] obj
  @return [Numo::NArray]
  @example
    Numo::NArray.new_like([[1,2,3],[4,5,6]])
    # => Numo::Int32#shape=[2,3](empty)

    Numo::DFloat.new_like([[1,2],[3,4]])
    # => Numo::DFloat#shape=[2,2](empty)

    Numo::NArray.new_like([1,2i,3])
    # => Numo::DComplex#shape=[3](empty)
*/
VALUE
na_s_new_like(VALUE type, VALUE obj) {
  VALUE newary;

  na_composition3(obj, &type, 0, &newary);
  return newary;
}

VALUE
na_ary_composition_dtype(VALUE ary) {
  VALUE type = Qnil;

  na_composition3(ary, &type, 0, 0);
  return type;
}

static VALUE na_s_array_type(VALUE mod, VALUE ary) {
  return na_ary_composition_dtype(ary);
}

/*
  Generate NArray object. NArray datatype is automatically selected.
  @overload [](elements)
    @param [Numeric,Array] elements
    @return [NArray]
*/
static VALUE nary_s_bracket(VALUE klass, VALUE ary) {
  VALUE dtype = Qnil;

  if (TYPE(ary) != T_ARRAY) {
    rb_bug("Argument is not array");
  }
  dtype = na_ary_composition_dtype(ary);
  check_subclass_of_narray(dtype);
  return rb_funcall(dtype, id_cast, 1, ary);
}

// VALUE
// nst_check_compatibility(VALUE self, VALUE ary);

/* investigate ndim, shape, type of Array */
/*
static int
na_mdai_for_struct(na_mdai_t *mdai, int ndim)
{
    size_t i;
    int j, r;
    size_t len;
    VALUE  v;
    VALUE  val;
    narray_t *na;

    if (ndim>4) { abort(); }
    val = mdai->item[ndim].val;

    //fpintf(stderr,"val = ");    rb_p(val);

    if (rb_obj_class(val) == mdai->na_type) {
        GetNArray(val,na);
        if ( ndim+na->ndim > mdai->capa ) {
            abort();
            na_mdai_realloc(mdai,((na->ndim-1)/4+1)*4);
        }
        for ( j=0,r=ndim; j < na->ndim; j++,r++ ) {
            if ( mdai->item[r].shape < na->shape[j] )
                mdai->item[r].shape = na->shape[j];
        }
        return 1;
    }

    if (TYPE(val) == T_ARRAY) {
        // check recursive array
        for (j=0; j<ndim-1; j++) {
            if (mdai->item[j].val == val)
                rb_raise(rb_eStandardError,
                         "cannot convert from a recursive Array to NArray");
        }
        // val is a Struct recort
        if (RTEST( nst_check_compatibility(mdai->na_type, val) )) {
            //fputs("compati\n",stderr);
            return 1;
        }
        // otherwise, multi-dimension
        if (ndim >= mdai->capa) {
            na_mdai_realloc(mdai,4);
        }
        // finally, multidimension-check
        len = RARRAY_LEN(val);
        for (i=0; i < len; i++) {
            v = RARRAY_AREF(val,i);
            if (TYPE(v) != T_ARRAY) {
                //abort();
                return 0;
            }
        }
        for (i=0; i < len; i++) {
            v = RARRAY_AREF(val,i);
            mdai->item[ndim+1].val = v;
            if ( na_mdai_for_struct( mdai, ndim+1 ) == 0 ) {
                //abort();
                return 0;
            }
        }
        if (mdai->item[ndim].shape < len) {
            mdai->item[ndim].shape = len;
        }
        return 1;
    }

    return 0;
}
*/

/*
VALUE
na_ary_composition_for_struct(VALUE nstruct, VALUE ary)
{
    volatile VALUE vmdai, vnc;
    na_mdai_t *mdai;
    na_compose_t *nc;

    mdai = na_mdai_alloc(ary);
    mdai->na_type = nstruct;
    vmdai = TypedData_Wrap_Struct(rb_cObject, &mdai_data_type, (void*)mdai);
    na_mdai_for_struct(mdai, 0);
    nc = na_compose_alloc();
    vnc = WrapCompose(nc);
    na_mdai_result(mdai, nc);
    rb_gc_force_recycle(vmdai);
    return vnc;
}
*/

void Init_nary_array(void) {
  /**
   * return shape of NArray which would be created from given Array.
   * @overload array_shape(ary)
   *   @param [Array] ary
   *   @return [Array] shape
   * @example
   *   Numo::NArray.array_shape([[1, 2, 3],[4, 5, 6]])
   *   # => [2,3]
   *   Numo::NArray.array_shape(Numo::DFloat[[1, 2, 3], [4, 5, 6]])
   *   # => []
   */
  rb_define_singleton_method(cNArray, "array_shape", na_s_array_shape, 1);
  /**
   * return type of NArray which would be created from given Array.
   * @overload array_type(ary)
   *   @param [Array] ary
   *   @return [Class] NArray class
   * @example
   *  Numo::NArray.array_type([1, 2, 3])
   *  # => Numo::Int32
   *  Numo::NArray.array_type([0, 1, 2i])
   *  # => Numo::DComplex
   *  Numo::NArray.array_type(Numo::DFloat[1, 2, 3])
   *  # => Numo::DFloat
   */
  rb_define_singleton_method(cNArray, "array_type", na_s_array_type, 1);
  rb_define_singleton_method(cNArray, "new_like", na_s_new_like, 1);

  rb_define_singleton_method(cNArray, "[]", nary_s_bracket, -2);

  id_begin = rb_intern("begin");
  id_end = rb_intern("end");
  id_step = rb_intern("step");
  id_cast = rb_intern("cast");
  id_abs = rb_intern("abs");
  id_le = rb_intern("<=");
#if SIZEOF_LONG <= 4
  id_ge = rb_intern(">=");
#endif
  id_Complex = rb_intern("Complex");

  rb_global_variable(&int32_max);
  int32_max = INT2NUM(2147483647);
  rb_global_variable(&int32_min);
  int32_min = INT2NUM(-2147483648);
}
