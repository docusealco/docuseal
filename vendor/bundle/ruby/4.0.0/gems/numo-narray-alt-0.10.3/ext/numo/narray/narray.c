/*
  narray.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#define NARRAY_C
#include <assert.h>
#include <ruby.h>

#ifndef RBASIC_FLAGS
#define RBASIC_FLAGS(obj) (RBASIC(obj)->flags)
#endif

#ifndef RBASIC_SET_FLAGS
#define RBASIC_SET_FLAGS(obj, flags_to_set) (RBASIC(obj)->flags = (flags_to_set))
#endif

/* global variables within this module */
VALUE numo_cNArray;
VALUE rb_mNumo;
VALUE nary_eCastError;
VALUE nary_eShapeError;
VALUE nary_eOperationError;
VALUE nary_eDimensionError;
VALUE nary_eValueError;

static ID id_contiguous_stride;
static ID id_allocate;
static ID id_element_byte_size;
static ID id_fill;
static ID id_seq;
static ID id_logseq;
static ID id_eye;
static ID id_UPCAST;
static ID id_cast;
static ID id_dup;
static ID id_to_host;
static ID id_bracket;
static ID id_shift_left;
static ID id_eq;
static ID id_count_false;
static ID id_axis;
static ID id_nan;
static ID id_keepdims;
static ID id_source;

VALUE cPointer;

VALUE sym_reduce;
VALUE sym_option;
VALUE sym_loop_opt;
VALUE sym_init;

#ifndef HAVE_RB_CCOMPLEX
VALUE rb_cComplex;
#endif
VALUE rb_cArithSeq;

int numo_na_inspect_rows = 20;
int numo_na_inspect_cols = 80;

void Init_nary_data();
void Init_nary_ndloop();
void Init_nary_index();
void Init_numo_bit();
void Init_numo_int8();
void Init_numo_int16();
void Init_numo_int32();
void Init_numo_int64();
void Init_numo_uint8();
void Init_numo_uint16();
void Init_numo_uint32();
void Init_numo_uint64();
void Init_numo_sfloat();
void Init_numo_scomplex();
void Init_numo_dfloat();
void Init_numo_dcomplex();
void Init_numo_robject();
void Init_nary_math();
void Init_nary_rand();
void Init_nary_array();
void Init_nary_struct();

const rb_data_type_t na_data_type = {
  "Numo::NArray",
  {
    0,
    0,
    0,
  },
  0,
  0,
  0,
};
#include "numo/narray.h"

static void nary_debug_info_nadata(VALUE self) {
  narray_data_t* na;
  GetNArrayData(self, na);

  printf("  ptr    = 0x%" SZF "x\n", (size_t)(na->ptr));
}

static VALUE nary_debug_info_naview(VALUE self) {
  int i;
  narray_view_t* na;
  size_t* idx;
  size_t j;
  GetNArrayView(self, na);

  printf("  data   = 0x%" SZF "x\n", (size_t)na->data);
  printf("  offset = %" SZF "d\n", (size_t)na->offset);
  printf("  stridx = 0x%" SZF "x\n", (size_t)na->stridx);

  if (na->stridx) {
    printf("  stridx = [");
    for (i = 0; i < na->base.ndim; i++) {
      if (SDX_IS_INDEX(na->stridx[i])) {

        idx = SDX_GET_INDEX(na->stridx[i]);
        printf("  index[%d]=[", i);
        for (j = 0; j < na->base.shape[i]; j++) {
          printf(" %" SZF "d", idx[j]);
        }
        printf(" ] ");

      } else {
        printf(" %" SZF "d", SDX_GET_STRIDE(na->stridx[i]));
      }
    }
    printf(" ]\n");
  }
  return Qnil;
}

VALUE
nary_debug_info(VALUE self) {
  int i;
  narray_t* na;
  GetNArray(self, na);

  printf("%s:\n", rb_class2name(rb_obj_class(self)));
  printf("  id     = 0x%" PRI_VALUE_PREFIX "x\n", self);
  printf("  type   = %d\n", na->type);
  printf("  flag   = [%d,%d]\n", na->flag[0], na->flag[1]);
  printf("  size   = %" SZF "d\n", na->size);
  printf("  ndim   = %d\n", na->ndim);
  printf("  shape  = 0x%" SZF "x\n", (size_t)na->shape);
  if (na->shape) {
    printf("  shape  = [");
    for (i = 0; i < na->ndim; i++) printf(" %" SZF "d", na->shape[i]);
    printf(" ]\n");
  }

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    nary_debug_info_nadata(self);
    break;
  case NARRAY_VIEW_T:
    nary_debug_info_naview(self);
    break;
  }
  return Qnil;
}

static size_t na_view_memsize(const void* ptr) {
  int i;
  size_t size = sizeof(narray_view_t);
  const narray_view_t* na = ptr;

  assert(na->base.type == NARRAY_VIEW_T);

  if (na->stridx != NULL) {
    for (i = 0; i < na->base.ndim; i++) {
      if (SDX_IS_INDEX(na->stridx[i])) {
        size += sizeof(size_t) * na->base.shape[i];
      }
    }
    size += sizeof(stridx_t) * na->base.ndim;
  }
  if (na->base.size > 0) {
    if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
      size += sizeof(size_t) * na->base.ndim;
    }
  }
  return size;
}

static void na_view_free(void* ptr) {
  int i;
  narray_view_t* na = (narray_view_t*)ptr;

  assert(na->base.type == NARRAY_VIEW_T);

  if (na->stridx != NULL) {
    for (i = 0; i < na->base.ndim; i++) {
      if (SDX_IS_INDEX(na->stridx[i])) {
        xfree(SDX_GET_INDEX(na->stridx[i]));
      }
    }
    xfree(na->stridx);
    na->stridx = NULL;
  }
  if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
    xfree(na->base.shape);
    na->base.shape = NULL;
  }
  xfree(na);
}

static void na_view_gc_mark(void* na) {
  if (((narray_t*)na)->type == NARRAY_VIEW_T) {
    rb_gc_mark(((narray_view_t*)na)->data);
  }
}

const rb_data_type_t na_data_type_view = {
  "Numo::NArrayView",
  {
    na_view_gc_mark,
    na_view_free,
    na_view_memsize,
  },
  &na_data_type,
  0,
  0,
};

VALUE
na_s_allocate_view(VALUE klass) {
  narray_view_t* na = ALLOC(narray_view_t);

  na->base.ndim = 0;
  na->base.type = NARRAY_VIEW_T;
  na->base.flag[0] = NA_FL0_INIT;
  na->base.flag[1] = NA_FL1_INIT;
  na->base.size = 0;
  na->base.shape = NULL;
  na->base.reduce = INT2FIX(0);
  na->data = Qnil;
  na->offset = 0;
  na->stridx = NULL;
  return TypedData_Wrap_Struct(klass, &na_data_type_view, (void*)na);
}

// static const size_t zero=0;

void na_array_to_internal_shape(VALUE self, VALUE ary, size_t* shape) {
  size_t i, n, c, s;
  ssize_t x;
  VALUE v;
  int flag = 0;

  n = RARRAY_LEN(ary);

  if (RTEST(self)) {
    flag = TEST_COLUMN_MAJOR(self);
  }
  if (flag) {
    c = n - 1;
    s = -1;
  } else {
    c = 0;
    s = 1;
  }
  for (i = 0; i < n; i++) {
    v = RARRAY_AREF(ary, i);
    x = NUM2SSIZET(v);
    if (x < 0) {
      rb_raise(rb_eArgError, "size must be non-negative");
    }
    shape[c] = x;
    c += s;
  }
}

void na_alloc_shape(narray_t* na, int ndim) {
  na->ndim = ndim;
  na->size = 0;
  if (na->shape != NULL && na->shape != &(na->size)) {
    xfree(na->shape);
    na->shape = NULL;
  }
  switch (ndim) {
  case 0:
  case 1:
    na->shape = &(na->size);
    break;
  default:
    if (ndim < 0) {
      rb_raise(nary_eDimensionError, "ndim=%d is negative", ndim);
    }
    if (ndim > NA_MAX_DIMENSION) {
      rb_raise(nary_eDimensionError, "ndim=%d is too many", ndim);
    }
    na->shape = ALLOC_N(size_t, ndim);
  }
}

void na_setup_shape(narray_t* na, int ndim, size_t* shape) {
  int i;
  size_t size;

  na_alloc_shape(na, ndim);

  if (ndim == 0) {
    na->size = 1;
  } else if (ndim == 1) {
    na->size = shape[0];
  } else {
    for (i = 0, size = 1; i < ndim; i++) {
      na->shape[i] = shape[i];
      size *= shape[i];
    }
    na->size = size;
  }
}

static void na_setup(VALUE self, int ndim, size_t* shape) {
  narray_t* na;
  GetNArray(self, na);
  na_setup_shape(na, ndim, shape);
}

/*
  @overload initialize(shape)
  @overload initialize(size0, size1, ...)
    @param [Array] shape (array of sizes along each dimension)
    @param [Integer] sizeN (size along Nth-dimension)
    @return [Numo::NArray] unallocated narray.

  Constructs an instance of NArray class using the given
  and <i>shape</i> or <i>sizes</i>.
  Note that NArray itself is an abstract super class and
  not suitable to create instances.
  Use Typed Subclasses of NArray (DFloat, Int32, etc) to create instances.
  This method does not allocate memory for array data.
  Memory is allocated on write method such as #fill, #store, #seq, etc.

  @example
    i = Numo::Int64.new([2,4,3])
    # => Numo::Int64#shape=[2,4,3](empty)

    f = Numo::DFloat.new(3,4)
    # => Numo::DFloat#shape=[3,4](empty)

    f.fill(2)
    # => Numo::DFloat#shape=[3,4]
    # [[2, 2, 2, 2],
    #  [2, 2, 2, 2],
    #  [2, 2, 2, 2]]

    x = Numo::NArray.new(5)
    # => in `new': allocator undefined for Numo::NArray (TypeError)
    #   	from t.rb:9:in `<main>'

*/
static VALUE na_initialize(VALUE self, VALUE args) {
  VALUE v;
  size_t* shape = NULL;
  int ndim;

  if (RARRAY_LEN(args) == 1) {
    v = RARRAY_AREF(args, 0);
    if (TYPE(v) != T_ARRAY) {
      v = args;
    }
  } else {
    v = args;
  }
  ndim = (int)RARRAY_LEN(v);
  if (ndim > NA_MAX_DIMENSION) {
    rb_raise(rb_eArgError, "ndim=%d exceeds maximum dimension", ndim);
  }
  shape = ALLOCA_N(size_t, ndim);
  // setup size_t shape[] from VALUE shape argument
  na_array_to_internal_shape(self, v, shape);
  na_setup(self, ndim, shape);

  return self;
}

VALUE
nary_new(VALUE klass, int ndim, size_t* shape) {
  volatile VALUE obj;

  obj = rb_funcall(klass, id_allocate, 0);
  na_setup(obj, ndim, shape);
  return obj;
}

VALUE
nary_view_new(VALUE klass, int ndim, size_t* shape) {
  volatile VALUE obj;

  obj = na_s_allocate_view(klass);
  na_setup(obj, ndim, shape);
  return obj;
}

/*
  Replaces the contents of self with the contents of other narray.
  Used in dup and clone method.
  @overload initialize_copy(other)
    @param [Numo::NArray] other
    @return [Numo::NArray] self
 */
static VALUE na_initialize_copy(VALUE self, VALUE orig) {
  narray_t* na;
  GetNArray(orig, na);

  na_setup(self, NA_NDIM(na), NA_SHAPE(na));
  na_store(self, orig);
  na_copy_flags(orig, self);
  return self;
}

/*
 *  call-seq:
 *     zeros(shape)  => narray
 *     zeros(size1,size2,...)  => narray
 *
 *  Returns a zero-filled narray with <i>shape</i>.
 *  This singleton method is valid not for NArray class itself
 *  but for typed NArray subclasses, e.g., DFloat, Int64.
 *  @example
 *    a = Numo::DFloat.zeros(3,5)
 *    # => Numo::DFloat#shape=[3,5]
 *    # [[0, 0, 0, 0, 0],
 *    #  [0, 0, 0, 0, 0],
 *    #  [0, 0, 0, 0, 0]]
 */
static VALUE na_s_zeros(int argc, VALUE* argv, VALUE klass) {
  VALUE obj;
  obj = rb_class_new_instance(argc, argv, klass);
  return rb_funcall(obj, id_fill, 1, INT2FIX(0));
}

/*
 *  call-seq:
 *     ones(shape)  => narray
 *     ones(size1,size2,...)  => narray
 *
 *  Returns a one-filled narray with <i>shape</i>.
 *  This singleton method is valid not for NArray class itself
 *  but for typed NArray subclasses, e.g., DFloat, Int64.
 *  @example
 *    a = Numo::DFloat.ones(3,5)
 *    # => Numo::DFloat#shape=[3,5]
 *    # [[1, 1, 1, 1, 1],
 *    #  [1, 1, 1, 1, 1],
 *    #  [1, 1, 1, 1, 1]]
 */
static VALUE na_s_ones(int argc, VALUE* argv, VALUE klass) {
  VALUE obj;
  obj = rb_class_new_instance(argc, argv, klass);
  return rb_funcall(obj, id_fill, 1, INT2FIX(1));
}

/*
  Returns an array of N linearly spaced points between x1 and x2.
  This singleton method is valid not for NArray class itself
  but for typed NArray subclasses, e.g., DFloat, Int64.

  @overload linspace(x1, x2, [n])
    @param [Numeric] x1   The start value
    @param [Numeric] x2   The end value
    @param [Integer] n    The number of elements. (default is 100).
    @return [Numo::NArray]  result array.

  @example
    a = Numo::DFloat.linspace(-5,5,7)
    # => Numo::DFloat#shape=[7]
    # [-5, -3.33333, -1.66667, 0, 1.66667, 3.33333, 5]
 */
static VALUE na_s_linspace(int argc, VALUE* argv, VALUE klass) {
  VALUE obj, vx1, vx2, vstep, vsize;
  double n;
  int narg;

  narg = rb_scan_args(argc, argv, "21", &vx1, &vx2, &vsize);
  if (narg == 3) {
    n = NUM2DBL(vsize);
  } else {
    n = 100;
    vsize = INT2FIX(100);
  }

  obj = rb_funcall(vx2, '-', 1, vx1);
  vstep = rb_funcall(obj, '/', 1, DBL2NUM(n - 1));

  obj = rb_class_new_instance(1, &vsize, klass);
  return rb_funcall(obj, id_seq, 2, vx1, vstep);
}

/*
  Returns an array of N logarithmically spaced points between 10^a and 10^b.
  This singleton method is valid not for NArray having +logseq+ method,
  i.e., DFloat, SFloat, DComplex, and SComplex.

  @overload logspace(a, b, [n, base])
    @param [Numeric] a  The start value
    @param [Numeric] b  The end value
    @param [Integer] n  The number of elements. (default is 50)
    @param [Numeric] base  The base of log space. (default is 10)
    @return [Numo::NArray]  result array.

  @example
    Numo::DFloat.logspace(4,0,5,2)
    # => Numo::DFloat#shape=[5]
    # [16, 8, 4, 2, 1]

    Numo::DComplex.logspace(0,1i*Math::PI,5,Math::E)
    # => Numo::DComplex#shape=[5]
    # [1+4.44659e-323i, 0.707107+0.707107i, 6.12323e-17+1i, -0.707107+0.707107i, ...]
 */
static VALUE na_s_logspace(int argc, VALUE* argv, VALUE klass) {
  VALUE obj, vx1, vx2, vstep, vsize, vbase;
  double n;

  rb_scan_args(argc, argv, "22", &vx1, &vx2, &vsize, &vbase);
  if (vsize == Qnil) {
    vsize = INT2FIX(50);
    n = 50;
  } else {
    n = NUM2DBL(vsize);
  }
  if (vbase == Qnil) {
    vbase = DBL2NUM(10);
  }

  obj = rb_funcall(vx2, '-', 1, vx1);
  vstep = rb_funcall(obj, '/', 1, DBL2NUM(n - 1));

  obj = rb_class_new_instance(1, &vsize, klass);
  return rb_funcall(obj, id_logseq, 3, vx1, vstep, vbase);
}

/*
  Returns a NArray with shape=(n,n) whose diagonal elements are 1, otherwise 0.
  @overload  eye(n)
    @param [Integer] n  Size of NArray. Creates 2-D NArray with shape=(n,n)
    @return [Numo::NArray]  created NArray.
  @example
    a = Numo::DFloat.eye(3)
    # => Numo::DFloat#shape=[3,3]
    # [[1, 0, 0],
    #  [0, 1, 0],
    #  [0, 0, 1]]
*/
static VALUE na_s_eye(int argc, VALUE* argv, VALUE klass) {
  VALUE obj;
  VALUE tmp[2];

  if (argc == 0) {
    rb_raise(rb_eArgError, "No argument");
  } else if (argc == 1) {
    tmp[0] = tmp[1] = argv[0];
    argv = tmp;
    argc = 2;
  }
  obj = rb_class_new_instance(argc, argv, klass);
  return rb_funcall(obj, id_eye, 0);
}

#define READ 1
#define WRITE 2

static void na_set_pointer(VALUE self, char* ptr, size_t byte_size) {
  VALUE obj;
  narray_t* na;

  if (OBJ_FROZEN(self)) {
    rb_raise(rb_eRuntimeError, "cannot write to frozen NArray.");
  }

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    if (NA_SIZE(na) > 0) {
      if (NA_DATA_PTR(na) != NULL && NA_DATA_OWNED(na)) {
        xfree(NA_DATA_PTR(na));
      }
      NA_DATA_PTR(na) = ptr;
      NA_DATA_OWNED(na) = FALSE;
    }
    return;
  case NARRAY_VIEW_T:
    obj = NA_VIEW_DATA(na);
    if (OBJ_FROZEN(obj)) {
      rb_raise(rb_eRuntimeError, "cannot write to frozen NArray.");
    }
    GetNArray(obj, na);
    switch (NA_TYPE(na)) {
    case NARRAY_DATA_T:
      if (NA_SIZE(na) > 0) {
        if (NA_DATA_PTR(na) != NULL && NA_DATA_OWNED(na)) {
          xfree(NA_DATA_PTR(na));
        }
        NA_DATA_PTR(na) = ptr;
        NA_DATA_OWNED(na) = FALSE;
      }
      return;
    default:
      rb_raise(rb_eRuntimeError, "invalid NA_TYPE of view: %d", NA_TYPE(na));
    }
  default:
    rb_raise(rb_eRuntimeError, "invalid NA_TYPE: %d", NA_TYPE(na));
  }
}

static void na_pointer_copy_on_write(VALUE self) {
  narray_t* na;
  void* ptr;
  VALUE velmsz;
  size_t byte_size;

  GetNArray(self, na);
  if (NA_TYPE(na) == NARRAY_VIEW_T) {
    self = NA_VIEW_DATA(na);
    GetNArray(self, na);
  }

  ptr = NA_DATA_PTR(na);
  if (ptr == NULL) {
    return;
  }

  if (NA_DATA_OWNED(na)) {
    return;
  }

  velmsz = rb_const_get(rb_obj_class(self), id_element_byte_size);
  if (FIXNUM_P(velmsz)) {
    byte_size = NA_SIZE(na) * NUM2SIZET(velmsz);
  } else {
    byte_size = ceil(NA_SIZE(na) * NUM2DBL(velmsz));
  }
  NA_DATA_PTR(na) = NULL;
  rb_funcall(self, id_allocate, 0);
  memcpy(NA_DATA_PTR(na), ptr, byte_size);
  rb_ivar_set(self, id_source, Qnil);
}

static char* na_get_pointer_for_rw(VALUE self, int flag) {
  char* ptr;
  VALUE obj;
  narray_t* na;

  if ((flag & WRITE) && OBJ_FROZEN(self)) {
    rb_raise(rb_eRuntimeError, "cannot write to frozen NArray.");
  }

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    if (flag & WRITE) {
      na_pointer_copy_on_write(self);
    }
    ptr = NA_DATA_PTR(na);
    if (NA_SIZE(na) > 0 && ptr == NULL) {
      if (flag & READ) {
        rb_raise(rb_eRuntimeError, "cannot read unallocated NArray");
      }
      if (flag & WRITE) {
        rb_funcall(self, id_allocate, 0);
        ptr = NA_DATA_PTR(na);
      }
    }
    return ptr;
  case NARRAY_VIEW_T:
    obj = NA_VIEW_DATA(na);
    if ((flag & WRITE) && OBJ_FROZEN(obj)) {
      rb_raise(rb_eRuntimeError, "cannot write to frozen NArray.");
    }
    if (flag & WRITE) {
      na_pointer_copy_on_write(self);
    }
    GetNArray(obj, na);
    switch (NA_TYPE(na)) {
    case NARRAY_DATA_T:
      ptr = NA_DATA_PTR(na);
      if (flag & (READ | WRITE)) {
        if (NA_SIZE(na) > 0 && ptr == NULL) {
          rb_raise(rb_eRuntimeError, "cannot read/write unallocated NArray");
        }
      }
      return ptr;
    default:
      rb_raise(rb_eRuntimeError, "invalid NA_TYPE of view: %d", NA_TYPE(na));
    }
  default:
    rb_raise(rb_eRuntimeError, "invalid NA_TYPE: %d", NA_TYPE(na));
  }

  return NULL;
}

char* na_get_pointer_for_read(VALUE self) {
  return na_get_pointer_for_rw(self, READ);
}

char* na_get_pointer_for_write(VALUE self) {
  return na_get_pointer_for_rw(self, WRITE);
}

char* na_get_pointer_for_read_write(VALUE self) {
  return na_get_pointer_for_rw(self, READ | WRITE);
}

char* na_get_pointer(VALUE self) {
  return na_get_pointer_for_rw(self, 0);
}

void na_release_lock(VALUE self) {
  narray_t* na;

  UNSET_LOCK(self);
  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_VIEW_T:
    na_release_lock(NA_VIEW_DATA(na));
    break;
  }
}

/* method: size() -- returns the total number of typeents */
static VALUE na_size(VALUE self) {
  narray_t* na;
  GetNArray(self, na);
  return SIZET2NUM(na->size);
}

/* method: size() -- returns the total number of typeents */
static VALUE na_ndim(VALUE self) {
  narray_t* na;
  GetNArray(self, na);
  return INT2NUM(na->ndim);
}

/*
  Returns true if self.size == 0.
  @overload empty?
*/
static VALUE na_empty_p(VALUE self) {
  narray_t* na;
  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    return Qtrue;
  }
  return Qfalse;
}

/*
  Release memory for array data. Ignored for NArray-view.
  This method is useful to free memory of referenced (i.e., GC does not work)
  but unused NArray object.
  @overload free
*/
static VALUE na_free(VALUE self) {
  narray_t* na;
  char* ptr;

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    ptr = NA_DATA_PTR(na);
    if (ptr != NULL) {
      NA_DATA_PTR(na) = NULL;
      xfree(ptr);
    }
    break;
  case NARRAY_VIEW_T:
    break;
  case NARRAY_FILEMAP_T:
  default:
    rb_bug("invalid narray type : %d", NA_TYPE(na));
  }
  return self;
}

/* method: shape() -- returns shape, array of the size of dimensions */
static VALUE na_shape(VALUE self) {
  volatile VALUE v;
  narray_t* na;
  size_t i, n, c, s;

  GetNArray(self, na);
  n = NA_NDIM(na);
  if (TEST_COLUMN_MAJOR(self)) {
    c = n - 1;
    s = -1;
  } else {
    c = 0;
    s = 1;
  }
  v = rb_ary_new2(n);
  for (i = 0; i < n; i++) {
    rb_ary_push(v, SIZET2NUM(na->shape[c]));
    c += s;
  }
  return v;
}

unsigned int nary_element_stride(VALUE v) {
  narray_type_info_t* info;
  narray_t* na;

  GetNArray(v, na);
  if (na->type == NARRAY_VIEW_T) {
    v = NA_VIEW_DATA(na);
    GetNArray(v, na);
  }
  assert(na->type == NARRAY_DATA_T);

  info = (narray_type_info_t*)(RTYPEDDATA_TYPE(v)->data);
  return info->element_stride;
}

size_t na_dtype_elmsz(VALUE klass) {
  return NUM2SIZET(rb_const_get(klass, id_contiguous_stride));
}

size_t na_get_offset(VALUE self) {
  narray_t* na;
  GetNArray(self, na);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    return 0;
  case NARRAY_VIEW_T:
    return NA_VIEW_OFFSET(na);
  }
  return 0;
}

void na_index_arg_to_internal_order(int argc, VALUE* argv, VALUE self) {
  int i, j;
  VALUE tmp;

  if (TEST_COLUMN_MAJOR(self)) {
    for (i = 0, j = argc - 1; i < argc / 2; i++, j--) {
      tmp = argv[i];
      argv[i] = argv[j];
      argv[j] = tmp;
    }
  }
}

void na_copy_flags(VALUE src, VALUE dst) {
  narray_t *na1, *na2;

  GetNArray(src, na1);
  GetNArray(dst, na2);

  na2->flag[0] = na1->flag[0];
  // na2->flag[1] = NA_FL1_INIT;

  RBASIC_SET_FLAGS(
    dst, RBASIC_FLAGS(dst) | (RBASIC_FLAGS(src) & (FL_USER1 | FL_USER2 | FL_USER3 | FL_USER4 |
                                                   FL_USER5 | FL_USER6 | FL_USER7))
  );
}

// fix name, ex, allow_stride_for_flatten_view
VALUE
na_check_ladder(VALUE self, int start_dim) {
  int i;
  ssize_t st0, st1;
  narray_t* na;
  GetNArray(self, na);

  if (start_dim < -na->ndim || start_dim >= na->ndim) {
    rb_bug("start_dim (%d) out of range", start_dim);
  }

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    return Qtrue;
  case NARRAY_VIEW_T:
    // negative dim -> position from last dim
    if (start_dim < 0) {
      start_dim += NA_NDIM(na);
    }
    // not ladder if it has index
    for (i = start_dim; i < NA_NDIM(na); i++) {
      if (NA_IS_INDEX_AT(na, i)) return Qfalse;
    }
    // check stride
    st0 = NA_STRIDE_AT(na, start_dim);
    for (i = start_dim + 1; i < NA_NDIM(na); i++) {
      st1 = NA_STRIDE_AT(na, i);
      if (st0 != (ssize_t)(st1 * NA_SHAPE(na)[i])) {
        return Qfalse;
      }
      st0 = st1;
    }
  }
  return Qtrue;
}

VALUE
na_check_contiguous(VALUE self) {
  ssize_t elmsz;
  narray_t* na;
  GetNArray(self, na);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    return Qtrue;
  case NARRAY_VIEW_T:
    if (NA_VIEW_STRIDX(na) == 0) {
      return Qtrue;
    }
    if (na_check_ladder(self, 0) == Qtrue) {
      elmsz = nary_element_stride(self);
      if (elmsz == NA_STRIDE_AT(na, NA_NDIM(na) - 1)) {
        return Qtrue;
      }
    }
  }
  return Qfalse;
}

VALUE
na_check_fortran_contiguous(VALUE self) {
  int i;
  ssize_t st0;
  narray_t* na;

  switch (RNARRAY_TYPE(self)) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    return Qfalse;
  case NARRAY_VIEW_T:
    GetNArray(self, na);

    // not contiguous if it has index
    for (i = 0; i < NA_NDIM(na); i++) {
      if (NA_IS_INDEX_AT(na, i)) return Qfalse;
    }

    // check f-contiguous
    st0 = nary_element_stride(self); // elmsz
    for (i = 0; i < NA_NDIM(na); i++) {
      if (NA_SHAPE(na)[i] == 1) continue;
      if (NA_STRIDE_AT(na, i) != st0) return Qfalse;
      st0 *= NA_SHAPE(na)[i];
    }
  }
  return Qtrue;
}

//----------------------------------------------------------------------

/*
 *  call-seq:
 *     narray.view => narray
 *
 *  Return view of NArray
 */
VALUE
na_make_view(VALUE self) {
  int i, nd;
  size_t j;
  size_t *idx1, *idx2;
  ssize_t stride;
  narray_t* na;
  narray_view_t *na1, *na2;
  volatile VALUE view;

  GetNArray(self, na);
  nd = na->ndim;

  view = na_s_allocate_view(rb_obj_class(self));

  na_copy_flags(self, view);
  GetNArrayView(view, na2);

  na_setup_shape((narray_t*)na2, nd, na->shape);
  na2->stridx = ALLOC_N(stridx_t, nd);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    stride = nary_element_stride(self);
    for (i = nd; i--;) {
      SDX_SET_STRIDE(na2->stridx[i], stride);
      stride *= na->shape[i];
    }
    na2->offset = 0;
    na2->data = self;
    break;
  case NARRAY_VIEW_T:
    GetNArrayView(self, na1);
    for (i = 0; i < nd; i++) {
      if (SDX_IS_INDEX(na1->stridx[i])) {
        idx1 = SDX_GET_INDEX(na1->stridx[i]);
        idx2 = ALLOC_N(size_t, na1->base.shape[i]);
        for (j = 0; j < na1->base.shape[i]; j++) {
          idx2[j] = idx1[j];
        }
        SDX_SET_INDEX(na2->stridx[i], idx2);
      } else {
        na2->stridx[i] = na1->stridx[i];
      }
    }
    na2->offset = na1->offset;
    na2->data = na1->data;
    break;
  }

  return view;
}

//----------------------------------------------------------------------

/*
 *  call-seq:
 *     narray.expand_dims(dim) => narray view
 *
 *  Expand the shape of an array. Insert a new axis with size=1
 *  at a given dimension.
 *  @overload expand_dims(dim)
 *    @param [Integer] dim  dimension at which new axis is inserted.
 *    @return [Numo::NArray]  result narray view.
 */
static VALUE na_expand_dims(VALUE self, VALUE vdim) {
  int i, j, nd, dim;
  size_t *shape, *na_shape;
  stridx_t *stridx, *na_stridx;
  narray_t* na;
  narray_view_t* na2;
  VALUE view;

  GetNArray(self, na);
  nd = na->ndim;

  dim = NUM2INT(vdim);
  if (dim < -nd - 1 || dim > nd) {
    rb_raise(nary_eDimensionError, "invalid axis (%d for %dD NArray)", dim, nd);
  }
  if (dim < 0) {
    dim += nd + 1;
  }

  view = na_make_view(self);
  GetNArrayView(view, na2);

  shape = ALLOC_N(size_t, nd + 1);
  stridx = ALLOC_N(stridx_t, nd + 1);
  na_shape = na2->base.shape;
  na_stridx = na2->stridx;

  for (i = j = 0; i <= nd; i++) {
    if (i == dim) {
      shape[i] = 1;
      SDX_SET_STRIDE(stridx[i], 0);
    } else {
      shape[i] = na_shape[j];
      stridx[i] = na_stridx[j];
      j++;
    }
  }

  na2->stridx = stridx;
  xfree(na_stridx);
  na2->base.shape = shape;
  if (na_shape != &(na2->base.size)) {
    xfree(na_shape);
  }
  na2->base.ndim++;
  return view;
}

//----------------------------------------------------------------------

/*
 *  call-seq:
 *     narray.reverse([dim0,dim1,..]) => narray
 *
 *  Return reversed view along specified dimeinsion
 */
static VALUE nary_reverse(int argc, VALUE* argv, VALUE self) {
  int i, nd;
  size_t j, n;
  size_t offset;
  size_t *idx1, *idx2;
  ssize_t stride;
  ssize_t sign;
  narray_t* na;
  narray_view_t *na1, *na2;
  VALUE view;
  VALUE reduce;

  reduce = na_reduce_dimension(argc, argv, 1, &self, 0, 0);

  GetNArray(self, na);
  nd = na->ndim;

  view = na_s_allocate_view(rb_obj_class(self));

  na_copy_flags(self, view);
  GetNArrayView(view, na2);

  na_setup_shape((narray_t*)na2, nd, na->shape);
  na2->stridx = ALLOC_N(stridx_t, nd);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    stride = nary_element_stride(self);
    offset = 0;
    for (i = nd; i--;) {
      if (na_test_reduce(reduce, i)) {
        offset += (na->shape[i] - 1) * stride;
        sign = -1;
      } else {
        sign = 1;
      }
      SDX_SET_STRIDE(na2->stridx[i], stride * sign);
      stride *= na->shape[i];
    }
    na2->offset = offset;
    na2->data = self;
    break;
  case NARRAY_VIEW_T:
    GetNArrayView(self, na1);
    offset = na1->offset;
    for (i = 0; i < nd; i++) {
      n = na1->base.shape[i];
      if (SDX_IS_INDEX(na1->stridx[i])) {
        idx1 = SDX_GET_INDEX(na1->stridx[i]);
        idx2 = ALLOC_N(size_t, n);
        if (na_test_reduce(reduce, i)) {
          for (j = 0; j < n; j++) {
            idx2[n - 1 - j] = idx1[j];
          }
        } else {
          for (j = 0; j < n; j++) {
            idx2[j] = idx1[j];
          }
        }
        SDX_SET_INDEX(na2->stridx[i], idx2);
      } else {
        stride = SDX_GET_STRIDE(na1->stridx[i]);
        if (na_test_reduce(reduce, i)) {
          offset += (n - 1) * stride;
          SDX_SET_STRIDE(na2->stridx[i], -stride);
        } else {
          na2->stridx[i] = na1->stridx[i];
        }
      }
    }
    na2->offset = offset;
    na2->data = na1->data;
    break;
  }

  return view;
}

//----------------------------------------------------------------------

VALUE
numo_na_upcast(VALUE type1, VALUE type2) {
  VALUE upcast_hash;
  VALUE result_type;

  if (type1 == type2) {
    return type1;
  }
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

/*
  Returns an array containing other and self,
  both are converted to upcasted type of NArray.
  Note that NArray has distinct UPCAST mechanism.
  Coerce is used for operation between non-NArray and NArray.
  @overload coerce(other)
    @param [Object] other  numeric object.
    @return [Array]  NArray-casted [other,self]
*/
static VALUE nary_coerce(VALUE x, VALUE y) {
  VALUE type;

  type = numo_na_upcast(rb_obj_class(x), rb_obj_class(y));
  y = rb_funcall(type, id_cast, 1, y);
  return rb_assoc_new(y, x);
}

/*
  Returns total byte size of NArray.
  @return [Integer] byte size.
 */
static VALUE nary_byte_size(VALUE self) {
  VALUE velmsz;
  narray_t* na;

  GetNArray(self, na);
  velmsz = rb_const_get(rb_obj_class(self), id_element_byte_size);
  if (FIXNUM_P(velmsz)) {
    return SIZET2NUM(NUM2SIZET(velmsz) * na->size);
  }
  return SIZET2NUM(ceil(NUM2DBL(velmsz) * na->size));
}

/*
  Returns byte size of one element of NArray.
  @return [Numeric] byte size.
 */
static VALUE nary_s_byte_size(VALUE type) {
  return rb_const_get(type, id_element_byte_size);
}

/*
  Returns a new 1-D array initialized from binary raw data in a string.
  @overload from_binary(string,[shape])
    @param [String] string  Binary raw data.
    @param [Array] shape  array of integers representing array shape.
    @return [Numo::NArray] NArray containing binary data.
 */
static VALUE nary_s_from_binary(int argc, VALUE* argv, VALUE type) {
  size_t len, str_len, byte_size;
  size_t* shape;
  int i, nd, narg;
  VALUE vstr, vshape, vna;
  VALUE velmsz;

  narg = rb_scan_args(argc, argv, "11", &vstr, &vshape);
  Check_Type(vstr, T_STRING);
  str_len = RSTRING_LEN(vstr);
  velmsz = rb_const_get(type, id_element_byte_size);
  if (narg == 2) {
    switch (TYPE(vshape)) {
    case T_FIXNUM:
      nd = 1;
      len = NUM2SIZET(vshape);
      shape = &len;
      break;
    case T_ARRAY:
      nd = (int)RARRAY_LEN(vshape);
      if (nd > NA_MAX_DIMENSION) {
        rb_raise(nary_eDimensionError, "shape exceeds max dimension");
      }
      shape = ALLOCA_N(size_t, nd);
      len = 1;
      for (i = 0; i < nd; ++i) {
        len *= shape[i] = NUM2SIZET(RARRAY_AREF(vshape, i));
      }
      break;
    default:
      rb_raise(rb_eArgError, "second argument must be size or shape");
    }
    if (FIXNUM_P(velmsz)) {
      byte_size = len * NUM2SIZET(velmsz);
    } else {
      byte_size = ceil(len * NUM2DBL(velmsz));
    }
    if (byte_size > str_len) {
      rb_raise(rb_eArgError, "specified size is too large");
    }
  } else {
    nd = 1;
    if (FIXNUM_P(velmsz)) {
      len = str_len / NUM2SIZET(velmsz);
      byte_size = len * NUM2SIZET(velmsz);
    } else {
      len = floor(str_len / NUM2DBL(velmsz));
      byte_size = str_len;
    }
    if (len == 0) {
      rb_raise(rb_eArgError, "string is empty or too short");
    }
    shape = ALLOCA_N(size_t, nd);
    shape[0] = len;
  }

  vna = nary_new(type, nd, shape);
  if (OBJ_FROZEN(vstr)) {
    na_set_pointer(vna, RSTRING_PTR(vstr), byte_size);
    rb_ivar_set(vna, id_source, vstr);
  } else {
    void* ptr = na_get_pointer_for_write(vna);
    memcpy(ptr, RSTRING_PTR(vstr), byte_size);
  }

  return vna;
}

/*
  Returns a new 1-D array initialized from binary raw data in a string.
  @overload store_binary(string,[offset])
    @param [String] string  Binary raw data.
    @param [Integer] (optional) offset  Byte offset in string.
    @return [Integer] stored length.
 */
static VALUE nary_store_binary(int argc, VALUE* argv, VALUE self) {
  size_t size, str_len, byte_size, offset;
  int narg;
  VALUE vstr, voffset;
  VALUE velmsz;
  narray_t* na;

  narg = rb_scan_args(argc, argv, "11", &vstr, &voffset);
  str_len = RSTRING_LEN(vstr);
  if (narg == 2) {
    offset = NUM2SIZET(voffset);
    if (str_len < offset) {
      rb_raise(rb_eArgError, "offset is larger than string length");
    }
    str_len -= offset;
  } else {
    offset = 0;
  }

  GetNArray(self, na);
  size = NA_SIZE(na);
  velmsz = rb_const_get(rb_obj_class(self), id_element_byte_size);
  if (FIXNUM_P(velmsz)) {
    byte_size = size * NUM2SIZET(velmsz);
  } else {
    byte_size = ceil(size * NUM2DBL(velmsz));
  }
  if (byte_size > str_len) {
    rb_raise(rb_eArgError, "string is too short to store");
  }

  if (OBJ_FROZEN(vstr)) {
    na_set_pointer(self, RSTRING_PTR(vstr) + offset, byte_size);
    rb_ivar_set(self, id_source, vstr);
  } else {
    void* ptr = na_get_pointer_for_write(self);
    memcpy(ptr, RSTRING_PTR(vstr) + offset, byte_size);
  }

  return SIZET2NUM(byte_size);
}

/*
  Returns string containing the raw data bytes in NArray.
  @overload to_binary()
    @return [String] String object containing binary raw data.
 */
static VALUE nary_to_binary(VALUE self) {
  size_t len, offset = 0;
  char* ptr;
  VALUE str;
  narray_t* na;

  GetNArray(self, na);
  if (na->type == NARRAY_VIEW_T) {
    if (na_check_contiguous(self) == Qtrue) {
      offset = NA_VIEW_OFFSET(na);
    } else {
      self = rb_funcall(self, id_dup, 0);
    }
  }
  len = NUM2SIZET(nary_byte_size(self));
  ptr = na_get_pointer_for_read(self);
  str = rb_usascii_str_new(ptr + offset, len);
  RB_GC_GUARD(self);
  return str;
}

/*
  Dump marshal data.
  @overload marshal_dump()
    @return [Array] Array containing marshal data.
 */
static VALUE nary_marshal_dump(VALUE self) {
  VALUE a;

  a = rb_ary_new();
  rb_ary_push(a, INT2FIX(1)); // version
  rb_ary_push(a, na_shape(self));
  rb_ary_push(a, INT2FIX(NA_FLAG0(self)));
  if (rb_obj_class(self) == numo_cRObject) {
    narray_t* na;
    VALUE* ptr;
    size_t offset = 0;
    GetNArray(self, na);
    if (na->type == NARRAY_VIEW_T) {
      if (na_check_contiguous(self) == Qtrue) {
        offset = NA_VIEW_OFFSET(na);
      } else {
        self = rb_funcall(self, id_dup, 0);
      }
    }
    ptr = (VALUE*)na_get_pointer_for_read(self);
    rb_ary_push(a, rb_ary_new4(NA_SIZE(na), ptr + offset));
  } else {
    rb_ary_push(a, nary_to_binary(self));
  }
  RB_GC_GUARD(self);
  return a;
}

static VALUE na_inplace(VALUE self);
/*
  Load marshal data.
  @overload marshal_load(data)
    @param [Array] Array containing marshal data.
    @return [nil]
 */
static VALUE nary_marshal_load(VALUE self, VALUE a) {
  VALUE v;

  if (TYPE(a) != T_ARRAY) {
    rb_raise(rb_eArgError, "marshal argument should be array");
  }
  if (RARRAY_LEN(a) != 4) {
    rb_raise(rb_eArgError, "marshal array size should be 4");
  }
  if (RARRAY_AREF(a, 0) != INT2FIX(1)) {
    rb_raise(
      rb_eArgError,
      "NArray marshal version %d is not supported "
      "(only version 1)",
      NUM2INT(RARRAY_AREF(a, 0))
    );
  }
  na_initialize(self, RARRAY_AREF(a, 1));
  NA_FL0_SET(self, FIX2INT(RARRAY_AREF(a, 2)));
  v = RARRAY_AREF(a, 3);
  if (rb_obj_class(self) == numo_cRObject) {
    narray_t* na;
    char* ptr;
    if (TYPE(v) != T_ARRAY) {
      rb_raise(rb_eArgError, "RObject content should be array");
    }
    GetNArray(self, na);
    if (RARRAY_LEN(v) != (long)NA_SIZE(na)) {
      rb_raise(rb_eArgError, "RObject content size mismatch");
    }
    ptr = na_get_pointer_for_write(self);
    memcpy(ptr, RARRAY_PTR(v), NA_SIZE(na) * sizeof(VALUE));
  } else {
    rb_str_freeze(v);
    nary_store_binary(1, &v, self);
    if (TEST_BYTE_SWAPPED(self)) {
      rb_funcall(na_inplace(self), id_to_host, 0);
      REVERSE_ENDIAN(self); // correct behavior??
    }
  }
  RB_GC_GUARD(a);
  return self;
}

/*
  Cast self to another NArray datatype.
  @overload cast_to(datatype)
    @param [Class] datatype NArray datatype.
    @return [Numo::NArray]
 */
static VALUE nary_cast_to(VALUE obj, VALUE type) {
  return rb_funcall(type, id_cast, 1, obj);
}

bool na_test_reduce(VALUE reduce, int dim) {
  size_t m;

  if (!RTEST(reduce)) return 0;
  if (FIXNUM_P(reduce)) {
    m = FIX2LONG(reduce);
    if (m == 0) return 1;
    return (m & (1u << dim)) ? 1 : 0;
  } else {
    return (rb_funcall(reduce, id_bracket, 1, INT2FIX(dim)) == INT2FIX(1)) ? 1 : 0;
  }
}

static VALUE na_get_reduce_flag_from_narray(int naryc, VALUE* naryv, int* max_arg) {
  int ndim, ndim0;
  int rowmaj;
  int i;
  size_t j;
  narray_t* na;
  VALUE reduce;

  if (naryc < 1) {
    rb_raise(rb_eRuntimeError, "must be positive: naryc=%d", naryc);
  }
  GetNArray(naryv[0], na);
  if (na->size == 0) {
    rb_raise(nary_eShapeError, "cannot reduce empty NArray");
  }
  reduce = na->reduce;
  ndim = ndim0 = na->ndim;
  if (max_arg) *max_arg = 0;
  rowmaj = TEST_COLUMN_MAJOR(naryv[0]);
  for (i = 0; i < naryc; i++) {
    GetNArray(naryv[i], na);
    if (na->size == 0) {
      rb_raise(nary_eShapeError, "cannot reduce empty NArray");
    }
    if (TEST_COLUMN_MAJOR(naryv[i]) != rowmaj) {
      rb_raise(nary_eDimensionError, "dimension order is different");
    }
    if (na->ndim > ndim) { // maximum dimension
      ndim = na->ndim;
      if (max_arg) *max_arg = i;
    }
  }
  if (ndim != ndim0) {
    j = NUM2SIZET(reduce) << (ndim - ndim0);
    reduce = SIZET2NUM(j);
  }
  return reduce;
}

static VALUE na_get_reduce_flag_from_axes(VALUE na_obj, VALUE axes) {
  int i, r;
  int ndim, rowmaj;
  long narg;
  size_t j;
  size_t len;
  ssize_t beg, step;
  VALUE v;
  size_t m;
  VALUE reduce;
  narray_t* na;

  GetNArray(na_obj, na);
  ndim = na->ndim;
  rowmaj = TEST_COLUMN_MAJOR(na_obj);

  m = 0;
  reduce = Qnil;
  narg = RARRAY_LEN(axes);
  for (i = 0; i < narg; i++) {
    v = RARRAY_AREF(axes, i);
    if (TYPE(v) == T_FIXNUM) {
      beg = FIX2INT(v);
      if (beg < 0) beg += ndim;
      if (beg >= ndim || beg < 0) {
        rb_raise(nary_eDimensionError, "dimension is out of range");
      }
      len = 1;
      step = 0;
    } else if (rb_obj_is_kind_of(v, rb_cRange) || rb_obj_is_kind_of(v, rb_cArithSeq)) {
      nary_step_array_index(v, ndim, &len, &beg, &step);
    } else {
      rb_raise(nary_eDimensionError, "invalid dimension argument %s", rb_obj_classname(v));
    }
    for (j = 0; j < len; j++) {
      r = (int)(beg + step * j);
      if (rowmaj) {
        r = ndim - 1 - r;
      }
      if (reduce == Qnil) {
        if (r < (ssize_t)sizeof(size_t)) {
          m |= ((size_t)1) << r;
          continue;
        } else {
          reduce = SIZET2NUM(m);
        }
      }
      v = rb_funcall(INT2FIX(1), id_shift_left, 1, INT2FIX(r));
      reduce = rb_funcall(reduce, '|', 1, v);
    }
  }
  if (NIL_P(reduce)) reduce = SIZET2NUM(m);
  return reduce;
}

VALUE
nary_reduce_options(VALUE axes, VALUE* opts, int naryc, VALUE* naryv, ndfunc_t* ndf) {
  int max_arg;
  VALUE reduce;

  // option: axis
  if (opts[0] != Qundef && RTEST(opts[0])) {
    if (!NIL_P(axes)) {
      rb_raise(rb_eArgError, "cannot specify axis-arguments and axis-keyword simultaneously");
    }
    if (TYPE(opts[0]) == T_ARRAY) {
      axes = opts[0];
    } else {
      axes = rb_ary_new3(1, opts[0]);
    }
  }
  if (ndf) {
    // option: keepdims
    if (opts[1] != Qundef) {
      if (RTEST(opts[1])) ndf->flag |= NDF_KEEP_DIM;
    }
  }

  reduce = na_get_reduce_flag_from_narray(naryc, naryv, &max_arg);

  if (NIL_P(axes)) return reduce;

  return na_get_reduce_flag_from_axes(naryv[max_arg], axes);
}

VALUE
nary_reduce_dimension(
  int argc, VALUE* argv, int naryc, VALUE* naryv, ndfunc_t* ndf, na_iter_func_t iter_nan
) {
  long narg;
  VALUE axes;
  VALUE kw_hash = Qnil;
  ID kw_table[3] = { id_axis, id_keepdims, id_nan };
  VALUE opts[3] = { Qundef, Qundef, Qundef };

  narg = rb_scan_args(argc, argv, "*:", &axes, &kw_hash);
  rb_get_kwargs(kw_hash, kw_table, 0, 3, opts);

  if (ndf) {
    // option: nan
    if (iter_nan && opts[2] != Qundef) {
      if (RTEST(opts[2])) ndf->func = iter_nan; // replace to nan-aware iterator function
    }
  }

  return na_reduce_options((narg) ? axes : Qnil, opts, naryc, naryv, ndf);
}

/*
  Return true if column major.
*/
static VALUE na_column_major_p(VALUE self) {
  if (TEST_COLUMN_MAJOR(self))
    return Qtrue;
  else
    return Qfalse;
}

/*
  Return true if row major.
*/
static VALUE na_row_major_p(VALUE self) {
  if (TEST_ROW_MAJOR(self))
    return Qtrue;
  else
    return Qfalse;
}

/*
  Return true if byte swapped.
*/
static VALUE na_byte_swapped_p(VALUE self) {
  if (TEST_BYTE_SWAPPED(self)) return Qtrue;
  return Qfalse;
}

/*
  Return true if not byte swapped.
*/
static VALUE na_host_order_p(VALUE self) {
  if (TEST_BYTE_SWAPPED(self)) return Qfalse;
  return Qtrue;
}

/*
  Returns view of narray with inplace flagged.
  @return [Numo::NArray] view of narray with inplace flag.
*/
static VALUE na_inplace(VALUE self) {
  VALUE view = self;
  view = na_make_view(self);
  SET_INPLACE(view);
  return view;
}

/*
  Set inplace flag to self.
  @return [Numo::NArray] self
*/
static VALUE na_inplace_bang(VALUE self) {
  SET_INPLACE(self);
  return self;
}

/*
  Return true if inplace flagged.
*/
static VALUE na_inplace_p(VALUE self) {
  if (TEST_INPLACE(self))
    return Qtrue;
  else
    return Qfalse;
}

/*
  Unset inplace flag to self.
  @return [Numo::NArray] self
*/
static VALUE na_out_of_place_bang(VALUE self) {
  UNSET_INPLACE(self);
  return self;
}

int na_debug_flag = 0;

static VALUE na_debug_set(VALUE mod, VALUE flag) {
  na_debug_flag = RTEST(flag);
  return Qnil;
}

static double na_profile_value = 0;

static VALUE na_profile(VALUE mod) {
  return rb_float_new(na_profile_value);
}

static VALUE na_profile_set(VALUE mod, VALUE val) {
  na_profile_value = NUM2DBL(val);
  return val;
}

/*
  Returns the number of rows used for NArray#inspect
  @overload inspect_rows
    @return [Integer or nil]  the number of rows.
*/
static VALUE na_inspect_rows(VALUE mod) {
  if (numo_na_inspect_rows > 0) {
    return INT2NUM(numo_na_inspect_rows);
  } else {
    return Qnil;
  }
}

/*
  Set the number of rows used for NArray#inspect
  @overload inspect_rows=(rows)
    @param [Integer or nil] rows  the number of rows
    @return [nil]
*/
static VALUE na_inspect_rows_set(VALUE mod, VALUE num) {
  if (RTEST(num)) {
    numo_na_inspect_rows = NUM2INT(num);
  } else {
    numo_na_inspect_rows = 0;
  }
  return Qnil;
}

/*
  Returns the number of cols used for NArray#inspect
  @overload inspect_cols
    @return [Integer or nil]  the number of cols.
*/
static VALUE na_inspect_cols(VALUE mod) {
  if (numo_na_inspect_cols > 0) {
    return INT2NUM(numo_na_inspect_cols);
  } else {
    return Qnil;
  }
}

/*
  Set the number of cols used for NArray#inspect
  @overload inspect_cols=(cols)
    @param [Integer or nil] cols  the number of cols
    @return [nil]
*/
static VALUE na_inspect_cols_set(VALUE mod, VALUE num) {
  if (RTEST(num)) {
    numo_na_inspect_cols = NUM2INT(num);
  } else {
    numo_na_inspect_cols = 0;
  }
  return Qnil;
}

/*
  Equality of self and other in view of numerical array.
  i.e., both arrays have same shape and corresponding elements are equal.
  @overload == other
    @param [Object] other
    @return [Boolean] true if self and other is equal.
*/
static VALUE na_equal(VALUE self, volatile VALUE other) {
  volatile VALUE vbool;
  narray_t *na1, *na2;
  int i;

  GetNArray(self, na1);

  if (!rb_obj_is_kind_of(other, cNArray)) {
    other = rb_funcall(rb_obj_class(self), id_cast, 1, other);
  }

  GetNArray(other, na2);
  if (na1->ndim != na2->ndim) {
    return Qfalse;
  }
  for (i = 0; i < na1->ndim; i++) {
    if (na1->shape[i] != na2->shape[i]) {
      return Qfalse;
    }
  }
  if (na1->size == 0) {
    return Qtrue;
  }
  vbool = rb_funcall(self, id_eq, 1, other);
  return (rb_funcall(vbool, id_count_false, 0) == INT2FIX(0)) ? Qtrue : Qfalse;
}

/* initialization of NArray Class */
void Init_narray(void) {
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif

  /**
   * Document-module: Numo
   *
   * Ruby/Numo (NUmerical MOdules)
   */
  mNumo = rb_define_module("Numo");

  /**
   * Document-class: Numo::NArray
   *
   * Numo::NArray is the abstract super class for
   * Numerical N-dimensional Array in the Ruby/Numo module.
   * Use Typed Subclasses of NArray (Numo::DFloat, Int32, etc)
   * to create data array instances.
   */
  cNArray = rb_define_class_under(mNumo, "NArray", rb_cObject);

#ifndef HAVE_RB_CCOMPLEX
  rb_require("complex");
  rb_cComplex = rb_const_get(rb_cObject, rb_intern("Complex"));
#endif
  rb_cArithSeq = rb_path2class("Enumerator::ArithmeticSequence");

  /* The version of Numo::NArray Alternative. */
  rb_define_const(cNArray, "VERSION", rb_str_new2(NARRAY_VERSION));

  /**
   * Document-class: Numo::NArray::CastError
   *
   * Exception raised when type casting is not possible.
   */
  nary_eCastError = rb_define_class_under(cNArray, "CastError", rb_eStandardError);
  /**
   * Document-class: Numo::NArray::ShapeError
   *
   * Exception raised when shape is invalid.
   */
  nary_eShapeError = rb_define_class_under(cNArray, "ShapeError", rb_eStandardError);
  /**
   * Document-class: Numo::NArray::OperationError
   *
   * Exception raised when operation is not appropriate.
   */
  nary_eOperationError = rb_define_class_under(cNArray, "OperationError", rb_eStandardError);
  /**
   * Document-class: Numo::NArray::DimensionError
   *
   * Exception raised when dimension is invalid.
   */
  nary_eDimensionError = rb_define_class_under(cNArray, "DimensionError", rb_eStandardError);
  /**
   * Document-class: Numo::NArray::ValueError
   *
   * Exception raised when occurred value error.
   */
  nary_eValueError = rb_define_class_under(cNArray, "ValueError", rb_eStandardError);

  rb_define_singleton_method(cNArray, "debug=", na_debug_set, 1);
  rb_define_singleton_method(cNArray, "profile", na_profile, 0);
  rb_define_singleton_method(cNArray, "profile=", na_profile_set, 1);

  rb_define_singleton_method(cNArray, "inspect_rows", na_inspect_rows, 0);
  rb_define_singleton_method(cNArray, "inspect_rows=", na_inspect_rows_set, 1);
  rb_define_singleton_method(cNArray, "inspect_cols", na_inspect_cols, 0);
  rb_define_singleton_method(cNArray, "inspect_cols=", na_inspect_cols_set, 1);

  /* Ruby allocation framework  */
  rb_undef_alloc_func(cNArray);
  rb_define_method(cNArray, "initialize", na_initialize, -2);
  rb_define_method(cNArray, "initialize_copy", na_initialize_copy, 1);

  rb_define_singleton_method(cNArray, "zeros", na_s_zeros, -1);
  rb_define_singleton_method(cNArray, "ones", na_s_ones, -1);
  rb_define_singleton_method(cNArray, "linspace", na_s_linspace, -1);
  rb_define_singleton_method(cNArray, "logspace", na_s_logspace, -1);
  rb_define_singleton_method(cNArray, "eye", na_s_eye, -1);

  rb_define_method(cNArray, "size", na_size, 0);
  rb_define_alias(cNArray, "length", "size");
  rb_define_alias(cNArray, "total", "size");
  rb_define_method(cNArray, "shape", na_shape, 0);
  rb_define_method(cNArray, "ndim", na_ndim, 0);
  rb_define_alias(cNArray, "rank", "ndim");
  rb_define_method(cNArray, "empty?", na_empty_p, 0);
  rb_define_method(cNArray, "free", na_free, 0);

  rb_define_method(cNArray, "debug_info", nary_debug_info, 0);

  rb_define_method(cNArray, "contiguous?", na_check_contiguous, 0);
  rb_define_method(cNArray, "fortran_contiguous?", na_check_fortran_contiguous, 0);

  rb_define_method(cNArray, "view", na_make_view, 0);
  rb_define_method(cNArray, "expand_dims", na_expand_dims, 1);
  rb_define_method(cNArray, "reverse", nary_reverse, -1);

  rb_define_singleton_method(cNArray, "upcast", numo_na_upcast, 1);
  rb_define_singleton_method(cNArray, "byte_size", nary_s_byte_size, 0);

  rb_define_singleton_method(cNArray, "from_binary", nary_s_from_binary, -1);
  rb_define_alias(rb_singleton_class(cNArray), "from_string", "from_binary");
  rb_define_method(cNArray, "store_binary", nary_store_binary, -1);
  rb_define_method(cNArray, "to_binary", nary_to_binary, 0);
  rb_define_alias(cNArray, "to_string", "to_binary");
  rb_define_method(cNArray, "marshal_dump", nary_marshal_dump, 0);
  rb_define_method(cNArray, "marshal_load", nary_marshal_load, 1);

  rb_define_method(cNArray, "byte_size", nary_byte_size, 0);

  rb_define_method(cNArray, "cast_to", nary_cast_to, 1);

  rb_define_method(cNArray, "coerce", nary_coerce, 1);

  rb_define_method(cNArray, "column_major?", na_column_major_p, 0);
  rb_define_method(cNArray, "row_major?", na_row_major_p, 0);
  rb_define_method(cNArray, "byte_swapped?", na_byte_swapped_p, 0);
  rb_define_method(cNArray, "host_order?", na_host_order_p, 0);

  rb_define_method(cNArray, "inplace", na_inplace, 0);
  rb_define_method(cNArray, "inplace?", na_inplace_p, 0);
  rb_define_method(cNArray, "inplace!", na_inplace_bang, 0);
  rb_define_method(cNArray, "out_of_place!", na_out_of_place_bang, 0);
  rb_define_alias(cNArray, "not_inplace!", "out_of_place!");

  rb_define_method(cNArray, "==", na_equal, 1);

  id_allocate = rb_intern("allocate");
  id_contiguous_stride = rb_intern(CONTIGUOUS_STRIDE);
  // id_element_bit_size = rb_intern(ELEMENT_BIT_SIZE);
  id_element_byte_size = rb_intern(ELEMENT_BYTE_SIZE);

  id_fill = rb_intern("fill");
  id_seq = rb_intern("seq");
  id_logseq = rb_intern("logseq");
  id_eye = rb_intern("eye");
  id_UPCAST = rb_intern("UPCAST");
  id_cast = rb_intern("cast");
  id_dup = rb_intern("dup");
  id_to_host = rb_intern("to_host");
  id_bracket = rb_intern("[]");
  id_shift_left = rb_intern("<<");
  id_eq = rb_intern("eq");
  id_count_false = rb_intern("count_false");
  id_axis = rb_intern("axis");
  id_nan = rb_intern("nan");
  id_keepdims = rb_intern("keepdims");
  id_source = rb_intern("source");

  sym_reduce = ID2SYM(rb_intern("reduce"));
  sym_option = ID2SYM(rb_intern("option"));
  sym_loop_opt = ID2SYM(rb_intern("loop_opt"));
  sym_init = ID2SYM(rb_intern("init"));

  Init_nary_index();

  Init_nary_data();
  Init_nary_ndloop();

  Init_numo_dcomplex();
  Init_numo_dfloat();
  Init_numo_scomplex();
  Init_numo_sfloat();

  Init_numo_int64();
  Init_numo_uint64();
  Init_numo_int32();
  Init_numo_uint32();
  Init_numo_int16();
  Init_numo_uint16();
  Init_numo_int8();
  Init_numo_uint8();

  Init_numo_bit();
  Init_numo_robject();

  Init_nary_math();

  Init_nary_rand();
  Init_nary_array();
  Init_nary_struct();
}
