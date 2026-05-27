/*
  index.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
// #define NARRAY_C
#include <ruby.h>
#include <string.h>

#include "numo/narray.h"
#include "numo/template.h"

#if SIZEOF_VOIDP == 8
#define cIndex numo_cInt64
#elif SIZEOF_VOIDP == 4
#define cIndex numo_cInt32
#endif

// note: the memory refed by this pointer is not freed and causes memory leak.
typedef struct {
  size_t n;     // the number of elements of the dimension
  size_t beg;   // the starting point in the dimension
  ssize_t step; // the step size of the dimension
  size_t* idx;  // list of indices
  int reduce;   // true if the dimension is reduced by addition
  int orig_dim; // the dimension of original array
} na_index_arg_t;

static void print_index_arg(na_index_arg_t* q, int n) {
  int i;
  printf("na_index_arg_t = 0x%" SZF "x {\n", (size_t)q);
  for (i = 0; i < n; i++) {
    printf("  q[%d].n=%" SZF "d\n", i, q[i].n);
    printf("  q[%d].beg=%" SZF "d\n", i, q[i].beg);
    printf("  q[%d].step=%" SZF "d\n", i, q[i].step);
    printf("  q[%d].idx=0x%" SZF "x\n", i, (size_t)q[i].idx);
    printf("  q[%d].reduce=0x%x\n", i, q[i].reduce);
    printf("  q[%d].orig_dim=%d\n", i, q[i].orig_dim);
  }
  printf("}\n");
}

static VALUE sym_ast;
static VALUE sym_all;
// static VALUE sym_reduce;
static VALUE sym_minus;
static VALUE sym_new;
static VALUE sym_reverse;
static VALUE sym_plus;
static VALUE sym_sum;
static VALUE sym_tilde;
static VALUE sym_rest;
static ID id_beg;
static ID id_end;
static ID id_exclude_end;
static ID id_each;
static ID id_step;
static ID id_dup;
static ID id_bracket;
static ID id_shift_left;
static ID id_mask;
static ID id_where;

static void na_index_set_step(na_index_arg_t* q, int i, size_t n, size_t beg, ssize_t step) {
  q->n = n;
  q->beg = beg;
  q->step = step;
  q->idx = NULL;
  q->reduce = 0;
  q->orig_dim = i;
}

static void na_index_set_scalar(na_index_arg_t* q, int i, ssize_t size, ssize_t x) {
  if (x < -size || x >= size)
    rb_raise(
      rb_eRangeError, "array index (%" SZF "d) is out of array size (%" SZF "d)", x, size
    );
  if (x < 0) x += size;
  q->n = 1;
  q->beg = x;
  q->step = 0;
  q->idx = NULL;
  q->reduce = 0;
  q->orig_dim = i;
}

static inline ssize_t na_range_check(ssize_t pos, ssize_t size, int dim) {
  ssize_t idx = pos;

  if (idx < 0) idx += size;
  if (idx < 0 || idx >= size) {
    rb_raise(rb_eIndexError, "index=%" SZF "d out of shape[%d]=%" SZF "d", pos, dim, size);
  }
  return idx;
}

static void na_parse_array(VALUE ary, int orig_dim, ssize_t size, na_index_arg_t* q) {
  int k;
  int n = (int)RARRAY_LEN(ary);
  q->idx = ALLOC_N(size_t, n);
  for (k = 0; k < n; k++) {
    q->idx[k] = na_range_check(NUM2SSIZET(RARRAY_AREF(ary, k)), size, orig_dim);
  }
  q->n = n;
  q->beg = 0;
  q->step = 1;
  q->reduce = 0;
  q->orig_dim = orig_dim;
}

static void na_parse_narray_index(VALUE a, int orig_dim, ssize_t size, na_index_arg_t* q) {
  VALUE idx, cls;
  narray_t *na, *nidx;
  size_t k, n;

  GetNArray(a, na);
  if (NA_NDIM(na) != 1) {
    rb_raise(rb_eIndexError, "should be 1-d NArray");
  }
  cls = rb_obj_class(a);
  if (cls == numo_cBit) {
    if (NA_SIZE(na) != (size_t)size) {
      rb_raise(rb_eIndexError, "Bit-NArray size mismatch");
    }
    idx = rb_funcall(a, id_where, 0);
    GetNArray(idx, nidx);
    n = NA_SIZE(nidx);
    q->idx = ALLOC_N(size_t, n);
    if (na->type != NARRAY_DATA_T) {
      rb_bug("NArray#where returned wrong type of NArray");
    }
    if (rb_obj_class(idx) == numo_cInt32) {
      int32_t* p = (int32_t*)NA_DATA_PTR(nidx);
      for (k = 0; k < n; k++) {
        q->idx[k] = (size_t)p[k];
      }
    } else if (rb_obj_class(idx) == numo_cInt64) {
      int64_t* p = (int64_t*)NA_DATA_PTR(nidx);
      for (k = 0; k < n; k++) {
        q->idx[k] = (size_t)p[k];
      }
    } else {
      rb_bug("NArray#where should return Int32 or Int64");
    }
    RB_GC_GUARD(idx);
  } else {
    n = NA_SIZE(na);
    q->idx = ALLOC_N(size_t, n);
    if (cls == numo_cInt32 && na->type == NARRAY_DATA_T) {
      int32_t* p = (int32_t*)NA_DATA_PTR(na);
      for (k = 0; k < n; k++) {
        q->idx[k] = na_range_check(p[k], size, orig_dim);
      }
    } else if (cls == numo_cInt64 && na->type == NARRAY_DATA_T) {
      int64_t* p = (int64_t*)NA_DATA_PTR(na);
      for (k = 0; k < n; k++) {
        q->idx[k] = na_range_check(p[k], size, orig_dim);
      }
    } else {
      ssize_t* p;
      idx = nary_new(cIndex, 1, &n);
      na_store(idx, a);
      GetNArray(idx, nidx);
      p = (ssize_t*)NA_DATA_PTR(nidx);
      for (k = 0; k < n; k++) {
        q->idx[k] = na_range_check(p[k], size, orig_dim);
      }
      RB_GC_GUARD(idx);
    }
  }
  q->n = n;
  q->beg = 0;
  q->step = 1;
  q->reduce = 0;
  q->orig_dim = orig_dim;
}

static void
na_parse_range(VALUE range, ssize_t step, int orig_dim, ssize_t size, na_index_arg_t* q) {
  int n;
  ssize_t beg, end, beg_orig, end_orig;
  const char *dot = "..", *edot = "...";

  rb_arithmetic_sequence_components_t x;
  rb_arithmetic_sequence_extract(range, &x);
  step = NUM2SSIZET(x.step);

  beg = beg_orig = NUM2SSIZET(x.begin);
  if (beg < 0) {
    beg += size;
  }
  if (T_NIL == TYPE(x.end)) { // endless range
    end = size - 1;
    if (RTEST(x.exclude_end)) {
      dot = edot;
    }
    if (beg < 0 || beg >= size) {
      rb_raise(
        rb_eRangeError, "%" SZF "d%s is out of range for size=%" SZF "d", beg_orig, dot, size
      );
    }
  } else {
    end = end_orig = NUM2SSIZET(x.end);
    if (end < 0) {
      end += size;
    }
    if (RTEST(x.exclude_end)) {
      end--;
      dot = edot;
    }
    if (beg < 0 || beg >= size || end < 0 || end >= size) {
      rb_raise(
        rb_eRangeError, "%" SZF "d%s%" SZF "d is out of range for size=%" SZF "d", beg_orig,
        dot, end_orig, size
      );
    }
  }
  n = (int)((end - beg) / step + 1);
  if (n < 0) n = 0;
  na_index_set_step(q, orig_dim, n, beg, step);
}

void na_parse_enumerator_step(VALUE enum_obj, VALUE* pstep) {
  int len;
  VALUE step;
  struct enumerator* e;

  if (!RB_TYPE_P(enum_obj, T_DATA)) {
    rb_raise(rb_eTypeError, "wrong argument type (not T_DATA)");
  }
  e = RENUMERATOR_PTR(enum_obj);

  if (!rb_obj_is_kind_of(e->obj, rb_cRange)) {
    rb_raise(rb_eTypeError, "not Range object");
  }

  if (e->meth == id_each) {
    step = INT2NUM(1);
  } else if (e->meth == id_step) {
    if (TYPE(e->args) != T_ARRAY) {
      rb_raise(rb_eArgError, "no argument for step");
    }
    len = (int)RARRAY_LEN(e->args);
    if (len != 1) {
      rb_raise(rb_eArgError, "invalid number of step argument (1 for %d)", len);
    }
    step = RARRAY_AREF(e->args, 0);
  } else {
    rb_raise(rb_eTypeError, "unknown Range method: %s", rb_id2name(e->meth));
  }
  if (pstep) *pstep = step;
}

static void na_parse_enumerator(VALUE enum_obj, int orig_dim, ssize_t size, na_index_arg_t* q) {
  VALUE step;
  struct enumerator* e;

  if (!RB_TYPE_P(enum_obj, T_DATA)) {
    rb_raise(rb_eTypeError, "wrong argument type (not T_DATA)");
  }
  na_parse_enumerator_step(enum_obj, &step);
  e = RENUMERATOR_PTR(enum_obj);
  na_parse_range(e->obj, NUM2SSIZET(step), orig_dim, size, q); // e->obj : Range Object
}

// Analyze *a* which is *i*-th index object and store the information to q
//
// a: a ruby object of i-th index
// size: size of i-th dimension of original NArray
// i: parse i-th index
// q: parsed information is stored to *q
static void na_index_parse_each(volatile VALUE a, ssize_t size, int i, na_index_arg_t* q) {
  switch (TYPE(a)) {

  case T_FIXNUM:
    na_index_set_scalar(q, i, size, FIX2LONG(a));
    break;

  case T_BIGNUM:
    na_index_set_scalar(q, i, size, NUM2SSIZET(a));
    break;

  case T_FLOAT:
    na_index_set_scalar(q, i, size, NUM2SSIZET(a));
    break;

  case T_NIL:
  case T_TRUE:
    na_index_set_step(q, i, size, 0, 1);
    break;

  case T_SYMBOL:
    if (a == sym_all || a == sym_ast) {
      na_index_set_step(q, i, size, 0, 1);
    } else if (a == sym_reverse) {
      na_index_set_step(q, i, size, size - 1, -1);
    } else if (a == sym_new) {
      na_index_set_step(q, i, 1, 0, 1);
    } else if (a == sym_reduce || a == sym_sum || a == sym_plus) {
      na_index_set_step(q, i, size, 0, 1);
      q->reduce = 1;
    } else {
      rb_raise(rb_eIndexError, "invalid symbol for index");
    }
    break;

  case T_ARRAY:
    na_parse_array(a, i, size, q);
    break;

  default:
    if (rb_obj_is_kind_of(a, rb_cRange)) {
      na_parse_range(a, 1, i, size, q);
    } else if (rb_obj_is_kind_of(a, rb_cArithSeq)) {
      // na_parse_arith_seq(a, i, size, q);
      na_parse_range(a, 1, i, size, q);
    } else if (rb_obj_is_kind_of(a, rb_cEnumerator)) {
      na_parse_enumerator(a, i, size, q);
    } else if (NA_IsNArray(a)) { // NArray index
      na_parse_narray_index(a, i, size, q);
    } else {
      rb_raise(rb_eIndexError, "not allowed type");
    }
  }
}

static void
na_at_parse_each(volatile VALUE a, ssize_t size, int i, VALUE* idx, ssize_t stride) {
  na_index_arg_t q;
  size_t n, k;
  ssize_t* index;

  // NArray index
  if (NA_IsNArray(a)) {
    VALUE a2;
    narray_t *na, *na2;
    ssize_t* p2;
    GetNArray(a, na);
    if (NA_NDIM(na) != 1) {
      rb_raise(rb_eIndexError, "should be 1-d NArray");
    }
    n = NA_SIZE(na);
    a2 = nary_new(cIndex, 1, &n);
    na_store(a2, a);
    GetNArray(a2, na2);
    p2 = (ssize_t*)NA_DATA_PTR(na2);
    if (*idx == Qnil) {
      *idx = a2;
      for (k = 0; k < n; k++) {
        na_range_check(p2[k], size, i);
      }
    } else {
      narray_t* nidx;
      GetNArray(*idx, nidx);
      index = (ssize_t*)NA_DATA_PTR(nidx);
      if (NA_SIZE(nidx) != n) {
        rb_raise(nary_eShapeError, "index array sizes mismatch");
      }
      for (k = 0; k < n; k++) {
        index[k] += na_range_check(p2[k], size, i) * stride;
      }
    }
    RB_GC_GUARD(a2);
    return;
  } else if (TYPE(a) == T_ARRAY) {
    n = RARRAY_LEN(a);
    if (*idx == Qnil) {
      *idx = nary_new(cIndex, 1, &n);
      index = (ssize_t*)na_get_pointer_for_write(*idx); // allocate memory
      for (k = 0; k < n; k++) {
        index[k] = na_range_check(NUM2SSIZET(RARRAY_AREF(a, k)), size, i);
      }
    } else {
      narray_t* nidx;
      GetNArray(*idx, nidx);
      index = (ssize_t*)NA_DATA_PTR(nidx);
      if (NA_SIZE(nidx) != n) {
        rb_raise(nary_eShapeError, "index array sizes mismatch");
      }
      for (k = 0; k < n; k++) {
        index[k] += na_range_check(NUM2SSIZET(RARRAY_AREF(a, k)), size, i) * stride;
      }
    }
    return;
  } else if (rb_obj_is_kind_of(a, rb_cRange)) {
    na_parse_range(a, 1, i, size, &q);
  } else if (rb_obj_is_kind_of(a, rb_cArithSeq)) {
    na_parse_range(a, 1, i, size, &q);
  } else if (rb_obj_is_kind_of(a, rb_cEnumerator)) {
    na_parse_enumerator(a, i, size, &q);
  } else {
    rb_raise(rb_eIndexError, "not allowed type");
  }

  if (*idx == Qnil) {
    *idx = nary_new(cIndex, 1, &q.n);
    index = (ssize_t*)na_get_pointer_for_write(*idx); // allocate memory
    for (k = 0; k < q.n; k++) {
      index[k] = q.beg + q.step * k;
    }
  } else {
    narray_t* nidx;
    GetNArray(*idx, nidx);
    index = (ssize_t*)NA_DATA_PTR(nidx);
    if (NA_SIZE(nidx) != q.n) {
      rb_raise(nary_eShapeError, "index array sizes mismatch");
    }
    for (k = 0; k < q.n; k++) {
      index[k] += (q.beg + q.step * k) * stride;
    }
  }
}

static size_t na_index_parse_args(VALUE args, narray_t* na, na_index_arg_t* q, int ndim) {
  int i, j, k, l, nidx;
  size_t total = 1;
  VALUE v;

  nidx = (int)RARRAY_LEN(args);

  for (i = j = k = 0; i < nidx; i++) {
    v = RARRAY_AREF(args, i);
    // rest (ellipsis) dimension
    if (v == Qfalse) {
      for (l = ndim - (nidx - 1); l > 0; l--) {
        na_index_parse_each(Qtrue, na->shape[k], k, &q[j]);
        if (q[j].n > 1) {
          total *= q[j].n;
        }
        j++;
        k++;
      }
    }
    // new dimension
    else if (v == sym_new) {
      na_index_parse_each(v, 1, k, &q[j]);
      j++;
    }
    // other dimension
    else {
      na_index_parse_each(v, na->shape[k], k, &q[j]);
      if (q[j].n > 1) {
        total *= q[j].n;
      }
      j++;
      k++;
    }
  }
  return total;
}

static void na_get_strides_nadata(const narray_data_t* na, ssize_t* strides, ssize_t elmsz) {
  int i = na->base.ndim - 1;
  if (i >= 0) {
    strides[i] = elmsz;
    for (; i > 0; i--) {
      strides[i - 1] = strides[i] * na->base.shape[i];
    }
  }
}

static void na_index_aref_nadata(
  narray_data_t* na1, narray_view_t* na2, na_index_arg_t* q, ssize_t elmsz, int ndim,
  int keep_dim
) {
  int i, j;
  ssize_t size, k, total = 1;
  ssize_t stride1;
  ssize_t* strides_na1;
  size_t* index;
  ssize_t beg, step;
  VALUE m;

  strides_na1 = ALLOCA_N(ssize_t, na1->base.ndim);
  na_get_strides_nadata(na1, strides_na1, elmsz);

  for (i = j = 0; i < ndim; i++) {
    stride1 = strides_na1[q[i].orig_dim];

    // numeric index -- trim dimension
    if (!keep_dim && q[i].n == 1 && q[i].step == 0) {
      beg = q[i].beg;
      na2->offset += stride1 * beg;
      continue;
    }

    na2->base.shape[j] = size = q[i].n;

    if (q[i].reduce != 0) {
      m = rb_funcall(INT2FIX(1), id_shift_left, 1, INT2FIX(j));
      na2->base.reduce = rb_funcall(m, '|', 1, na2->base.reduce);
    }

    // array index
    if (q[i].idx != NULL) {
      index = q[i].idx;
      SDX_SET_INDEX(na2->stridx[j], index);
      q[i].idx = NULL;
      for (k = 0; k < size; k++) {
        index[k] = index[k] * stride1;
      }
    } else {
      beg = q[i].beg;
      step = q[i].step;
      na2->offset += stride1 * beg;
      SDX_SET_STRIDE(na2->stridx[j], stride1 * step);
    }
    j++;
    total *= size;
  }
  na2->base.size = total;
}

static void na_index_aref_naview(
  narray_view_t* na1, narray_view_t* na2, na_index_arg_t* q, ssize_t elmsz, int ndim,
  int keep_dim
) {
  int i, j;
  ssize_t total = 1;

  for (i = j = 0; i < ndim; i++) {
    stridx_t sdx1;
    sdx1.stride = 0;
    sdx1.index = NULL;
    const int qi_orig_dim = q[i].orig_dim;
    if (qi_orig_dim < na1->base.ndim) {
      sdx1 = na1->stridx[qi_orig_dim];

      // numeric index -- trim dimension
      if (!keep_dim && q[i].n == 1 && q[i].step == 0) {
        if (SDX_IS_INDEX(sdx1)) {
          na2->offset += SDX_GET_INDEX(sdx1)[q[i].beg];
        } else {
          na2->offset += SDX_GET_STRIDE(sdx1) * q[i].beg;
        }
        continue;
      }
    }

    const ssize_t size = q[i].n;
    na2->base.shape[j] = size;

    if (q[i].reduce != 0) {
      VALUE m = rb_funcall(INT2FIX(1), id_shift_left, 1, INT2FIX(j));
      na2->base.reduce = rb_funcall(m, '|', 1, na2->base.reduce);
    }

    if (qi_orig_dim >= na1->base.ndim) {
      // new dimension
      SDX_SET_STRIDE(na2->stridx[j], elmsz);
    } else if (q[i].idx != NULL && SDX_IS_INDEX(sdx1)) {
      // index <- index
      int k;
      size_t* index = q[i].idx;
      SDX_SET_INDEX(na2->stridx[j], index);
      q[i].idx = NULL;

      for (k = 0; k < size; k++) {
        index[k] = SDX_GET_INDEX(sdx1)[index[k]];
      }
    } else if (q[i].idx != NULL && SDX_IS_STRIDE(sdx1)) {
      // index <- step
      ssize_t stride1 = SDX_GET_STRIDE(sdx1);
      size_t* index = q[i].idx;
      SDX_SET_INDEX(na2->stridx[j], index);
      q[i].idx = NULL;

      if (stride1 < 0) {
        size_t last;
        int k;
        stride1 = -stride1;
        last = na1->base.shape[q[i].orig_dim] - 1;
        if (na2->offset < last * stride1) {
          rb_raise(rb_eStandardError, "bug: negative offset");
        }
        na2->offset -= last * stride1;
        for (k = 0; k < size; k++) {
          index[k] = (last - index[k]) * stride1;
        }
      } else {
        int k;
        for (k = 0; k < size; k++) {
          index[k] = index[k] * stride1;
        }
      }
    } else if (q[i].idx == NULL && SDX_IS_INDEX(sdx1)) {
      // step <- index
      int k;
      size_t beg = q[i].beg;
      ssize_t step = q[i].step;
      size_t* index = ALLOC_N(size_t, size);
      SDX_SET_INDEX(na2->stridx[j], index);
      for (k = 0; k < size; k++) {
        index[k] = SDX_GET_INDEX(sdx1)[beg + step * k];
      }
    } else if (q[i].idx == NULL && SDX_IS_STRIDE(sdx1)) {
      // step <- step
      size_t beg = q[i].beg;
      ssize_t step = q[i].step;
      ssize_t stride1 = SDX_GET_STRIDE(sdx1);
      na2->offset += stride1 * beg;
      SDX_SET_STRIDE(na2->stridx[j], stride1 * step);
    }

    j++;
    total *= size;
  }
  na2->base.size = total;
}

static int na_ndim_new_narray(int ndim, const na_index_arg_t* q) {
  int i, ndim_new = 0;
  for (i = 0; i < ndim; i++) {
    if (q[i].n > 1 || q[i].step != 0) {
      ndim_new++;
    }
  }
  return ndim_new;
}

typedef struct {
  VALUE args, self, store;
  int ndim;
  na_index_arg_t* q;
  narray_t* na1;
  int keep_dim;
} na_aref_md_data_t;

static na_index_arg_t* na_allocate_index_args(int ndim) {
  na_index_arg_t* q = ALLOC_N(na_index_arg_t, ndim);
  int i;

  for (i = 0; i < ndim; i++) {
    q[i].idx = NULL;
  }
  return q;
}

static VALUE na_aref_md_protected(VALUE data_value) {
  na_aref_md_data_t* data = (na_aref_md_data_t*)(data_value);
  VALUE self = data->self;
  VALUE args = data->args;
  VALUE store = data->store;
  int ndim = data->ndim;
  na_index_arg_t* q = data->q;
  narray_t* na1 = data->na1;
  int keep_dim = data->keep_dim;

  int ndim_new;
  VALUE view;
  narray_view_t* na2;
  ssize_t elmsz;

  na_index_parse_args(args, na1, q, ndim);

  if (na_debug_flag) print_index_arg(q, ndim);

  if (keep_dim) {
    ndim_new = ndim;
  } else {
    ndim_new = na_ndim_new_narray(ndim, q);
  }
  view = na_s_allocate_view(rb_obj_class(self));

  na_copy_flags(self, view);
  GetNArrayView(view, na2);

  na_alloc_shape((narray_t*)na2, ndim_new);

  na2->stridx = ZALLOC_N(stridx_t, ndim_new);

  elmsz = nary_element_stride(self);

  switch (na1->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    na_index_aref_nadata((narray_data_t*)na1, na2, q, elmsz, ndim, keep_dim);
    na2->data = self;
    break;
  case NARRAY_VIEW_T:
    na2->offset = ((narray_view_t*)na1)->offset;
    na2->data = ((narray_view_t*)na1)->data;
    na_index_aref_naview((narray_view_t*)na1, na2, q, elmsz, ndim, keep_dim);
    break;
  }
  if (store) {
    na_get_pointer_for_write(store); // allocate memory
    na_store(na_flatten_dim(store, 0), view);
    return store;
  }
  return view;
}

static VALUE na_aref_md_ensure(VALUE data_value) {
  na_aref_md_data_t* data = (na_aref_md_data_t*)(data_value);
  int i;
  for (i = 0; i < data->ndim; i++) {
    xfree(data->q[i].idx);
  }
  xfree(data->q);
  return Qnil;
}

static VALUE na_aref_md(int argc, VALUE* argv, VALUE self, int keep_dim, int result_nd) {
  VALUE args; // should be GC protected
  narray_t* na1;
  na_aref_md_data_t data;
  VALUE store = 0;
  VALUE idx;
  narray_t* nidx;

  GetNArray(self, na1);

  args = rb_ary_new4(argc, argv);

  if (argc == 1 && result_nd == 1) {
    idx = argv[0];
    if (rb_obj_is_kind_of(idx, rb_cArray)) {
      idx = rb_apply(numo_cNArray, id_bracket, idx);
    }
    if (rb_obj_is_kind_of(idx, numo_cNArray)) {
      GetNArray(idx, nidx);
      if (NA_NDIM(nidx) > 1) {
        store = nary_new(rb_obj_class(self), NA_NDIM(nidx), NA_SHAPE(nidx));
        idx = na_flatten(idx);
        RARRAY_ASET(args, 0, idx);
      }
    }
    // flatten should be done only for narray-view with non-uniform stride.
    if (na1->ndim > 1) {
      self = na_flatten(self);
      GetNArray(self, na1);
    }
  }

  data.args = args;
  data.self = self;
  data.store = store;
  data.ndim = result_nd;
  data.q = na_allocate_index_args(result_nd);
  data.na1 = na1;
  data.keep_dim = keep_dim;

  return rb_ensure(na_aref_md_protected, (VALUE)&data, na_aref_md_ensure, (VALUE)&data);
}

/* method: [](idx1,idx2,...,idxN) */
VALUE
na_aref_main(int nidx, VALUE* idx, VALUE self, int keep_dim, int nd) {
  na_index_arg_to_internal_order(nidx, idx, self);

  if (nidx == 0) {
    return rb_funcall(self, id_dup, 0);
  }
  if (nidx == 1) {
    if (rb_obj_class(*idx) == numo_cBit) {
      return rb_funcall(*idx, id_mask, 1, self);
    }
  }
  return na_aref_md(nidx, idx, self, keep_dim, nd);
}

static int check_index_count(int argc, int na_ndim, int count_new, int count_rest) {
  int result_nd = na_ndim + count_new;

  switch (count_rest) {
  case 0:
    if (argc == 1 && count_new == 0) return 1;
    if (argc == result_nd) return result_nd;
    rb_raise(
      rb_eIndexError,
      "# of index(=%i) should be "
      "equal to ndim(=%i) or 1",
      argc, na_ndim
    );
    break;
  case 1:
    if (argc - 1 <= result_nd) return result_nd;
    rb_raise(rb_eIndexError, "# of index(=%i) > ndim(=%i) with :rest", argc, na_ndim);
    break;
  default:
    rb_raise(rb_eIndexError, "multiple rest-dimension is not allowed");
  }
  return -1;
}

int na_get_result_dimension(
  VALUE self, int argc, VALUE* argv, ssize_t stride, size_t* pos_idx
) {
  int i, j;
  int count_new = 0;
  int count_rest = 0;
  ssize_t x, s, m, pos, *idx;
  narray_t* na;
  narray_view_t* nv;
  stridx_t sdx;
  VALUE a;

  GetNArray(self, na);
  if (na->size == 0) {
    rb_raise(nary_eShapeError, "cannot get element of empty array");
  }
  idx = ALLOCA_N(ssize_t, argc);
  for (i = j = 0; i < argc; i++) {
    a = argv[i];
    switch (TYPE(a)) {
    case T_FIXNUM:
      idx[j++] = FIX2LONG(a);
      break;
    case T_BIGNUM:
    case T_FLOAT:
      idx[j++] = NUM2SSIZET(a);
      break;
    case T_FALSE:
    case T_SYMBOL:
      if (a == sym_rest || a == sym_tilde || a == Qfalse) {
        argv[i] = Qfalse;
        count_rest++;
        break;
      } else if (a == sym_new || a == sym_minus) {
        argv[i] = sym_new;
        count_new++;
      }
    }
  }

  if (j != argc) {
    return check_index_count(argc, na->ndim, count_new, count_rest);
  }

  switch (na->type) {
  case NARRAY_VIEW_T:
    GetNArrayView(self, nv);
    pos = nv->offset;
    if (j == na->ndim) {
      for (i = j - 1; i >= 0; i--) {
        x = na_range_check(idx[i], na->shape[i], i);
        sdx = nv->stridx[i];
        if (SDX_IS_INDEX(sdx)) {
          pos += SDX_GET_INDEX(sdx)[x];
        } else {
          pos += SDX_GET_STRIDE(sdx) * x;
        }
      }
      *pos_idx = pos;
      return 0;
    }
    if (j == 1) {
      x = na_range_check(idx[0], na->size, 0);
      for (i = na->ndim - 1; i >= 0; i--) {
        s = na->shape[i];
        m = x % s;
        x = x / s;
        sdx = nv->stridx[i];
        if (SDX_IS_INDEX(sdx)) {
          pos += SDX_GET_INDEX(sdx)[m];
        } else {
          pos += SDX_GET_STRIDE(sdx) * m;
        }
      }
      *pos_idx = pos;
      return 0;
    }
    break;
  default:
    if (!stride) {
      stride = nary_element_stride(self);
    }
    if (j == 1) {
      x = na_range_check(idx[0], na->size, 0);
      *pos_idx = stride * x;
      return 0;
    }
    if (j == na->ndim) {
      pos = 0;
      for (i = j - 1; i >= 0; i--) {
        x = na_range_check(idx[i], na->shape[i], i);
        pos += stride * x;
        stride *= na->shape[i];
      }
      *pos_idx = pos;
      return 0;
    }
  }
  rb_raise(
    rb_eIndexError,
    "# of index(=%i) should be "
    "equal to ndim(=%i) or 1",
    argc, na->ndim
  );
  return -1;
}

static int na_get_result_dimension_for_slice(VALUE self, int argc, VALUE* argv) {
  int i;
  int count_new = 0;
  int count_rest = 0;
  narray_t* na;
  VALUE a;

  GetNArray(self, na);
  if (na->size == 0) {
    rb_raise(nary_eShapeError, "cannot get element of empty array");
  }
  for (i = 0; i < argc; i++) {
    a = argv[i];
    switch (TYPE(a)) {
    case T_FALSE:
    case T_SYMBOL:
      if (a == sym_rest || a == sym_tilde || a == Qfalse) {
        argv[i] = Qfalse;
        count_rest++;
      } else if (a == sym_new || a == sym_minus) {
        argv[i] = sym_new;
        count_new++;
      }
    }
  }

  return check_index_count(argc, na->ndim, count_new, count_rest);
}

/* method: slice(idx1,idx2,...,idxN) */
static VALUE na_slice(int argc, VALUE* argv, VALUE self) {
  int nd;

  nd = na_get_result_dimension_for_slice(self, argc, argv);
  return na_aref_main(argc, argv, self, 1, nd);
}

/*
  Multi-dimensional element reference.
  Returns an element at `dim0`, `dim1`, ... are Numeric indices for each dimension, or returns a
  NArray View as a sliced array if `dim0`, `dim1`, ... includes other than Numeric index, e.g.,
  Range or Array or true.
  @overload [](dim0,...,dimL)
  @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,Symbol]
  dim0,...,dimL  multi-dimensional indices.
  @return [Numeric,Numo::NArray] an element or NArray view.
  @see #[]=
  @see #at

  @example
      a = Numo::DFloat.new(4,5).seq
      # => Numo::DFloat#shape=[4,5]
      # [[0, 1, 2, 3, 4],
      #  [5, 6, 7, 8, 9],
      #  [10, 11, 12, 13, 14],
      #  [15, 16, 17, 18, 19]]

      a[1,1]
      # => 6.0

      a[1..3,1]
      # => Numo::DFloat#shape=[3]
      # [6, 11, 16]

      a[1,[1,3,4]]
      # => Numo::DFloat#shape=[3]
      # [6, 8, 9]

      a[true,2].fill(99)
      a
      # => Numo::DFloat#shape=[4,5]
      # [[0, 1, 99, 3, 4],
      #  [5, 6, 99, 8, 9],
      #  [10, 11, 99, 13, 14],
      #  [15, 16, 99, 18, 19]]
 */
// implemented in subclasses
#define na_aref rb_f_notimplement

/*
  Multi-dimensional element assignment.
  Replace element(s) at `dim0`, `dim1`, ... .
  Broadcasting mechanism is applied.
  @overload []=(dim0,...,dimL,val)
  @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,Symbol]
  dim0,...,dimL  multi-dimensional indices.
  @param [Numeric,Numo::NArray,Array] val  Value(s) to be set to self.
  @return [Numeric,Numo::NArray,Array] returns `val` (last argument).
  @see #[]
  @example
      a = Numo::DFloat.new(3,4).seq
      # => Numo::DFloat#shape=[3,4]
      # [[0, 1, 2, 3],
      #  [4, 5, 6, 7],
      #  [8, 9, 10, 11]]

      a[1,2]=99
      a
      # => Numo::DFloat#shape=[3,4]
      # [[0, 1, 2, 3],
      #  [4, 5, 99, 7],
      #  [8, 9, 10, 11]]

      a[1,[0,2]] = [101,102]
      a
      # => Numo::DFloat#shape=[3,4]
      # [[0, 1, 2, 3],
      #  [101, 5, 102, 7],
      #  [8, 9, 10, 11]]

      a[1,true]=99
      a
      # => Numo::DFloat#shape=[3,4]
      # [[0, 1, 2, 3],
      #  [99, 99, 99, 99],
      #  [8, 9, 10, 11]]

*/
// implemented in subclasses
#define na_aset rb_f_notimplement

/*
  Multi-dimensional array indexing.
  Similar to numpy's tuple indexing, i.e., `a[[1,2,..],[3,4,..]]`
  Same as Numo::NArray#[] for one-dimensional NArray.
  @overload at(dim0,...,dimL)
    @param [Range,Array,Numo::Int32,Numo::Int64] dim0,...,dimL  multi-dimensional index arrays.
    @return [Numo::NArray] one-dimensional NArray view.
  @see #[]

  @example
      x = Numo::DFloat.new(3,3,3).seq
      # => Numo::DFloat#shape=[3,3,3]
      #  [[[0, 1, 2],
      #    [3, 4, 5],
      #    [6, 7, 8]],
      #   [[9, 10, 11],
      #    [12, 13, 14],
      #    [15, 16, 17]],
      #   [[18, 19, 20],
      #    [21, 22, 23],
      #    [24, 25, 26]]]

      x.at([0,1,2],[0,1,2],[-1,-2,-3])
      # => Numo::DFloat(view)#shape=[3]
      #  [2, 13, 24]
 */
static VALUE na_at(int argc, VALUE* argv, VALUE self) {
  int i;
  size_t n;
  ssize_t stride = 1;
  narray_t* na;
  VALUE idx = Qnil;

  na_index_arg_to_internal_order(argc, argv, self);

  GetNArray(self, na);
  if (NA_NDIM(na) != argc) {
    rb_raise(rb_eArgError, "the number of argument must be same as dimension");
  }
  for (i = argc; i > 0;) {
    i--;
    n = NA_SHAPE(na)[i];
    na_at_parse_each(argv[i], n, i, &idx, stride);
    stride *= n;
  }
  return na_aref_main(1, &idx, self, 1, 1);
}

void Init_nary_index(void) {
  rb_define_method(cNArray, "slice", na_slice, -1);
  rb_define_method(cNArray, "[]", na_aref, -1);
  rb_define_method(cNArray, "[]=", na_aset, -1);
  rb_define_method(cNArray, "at", na_at, -1);

  sym_ast = ID2SYM(rb_intern("*"));
  sym_all = ID2SYM(rb_intern("all"));
  sym_minus = ID2SYM(rb_intern("-"));
  sym_new = ID2SYM(rb_intern("new"));
  sym_reverse = ID2SYM(rb_intern("reverse"));
  sym_plus = ID2SYM(rb_intern("+"));
  // sym_reduce   = ID2SYM(rb_intern("reduce"));
  sym_sum = ID2SYM(rb_intern("sum"));
  sym_tilde = ID2SYM(rb_intern("~"));
  sym_rest = ID2SYM(rb_intern("rest"));
  id_beg = rb_intern("begin");
  id_end = rb_intern("end");
  id_exclude_end = rb_intern("exclude_end?");
  id_each = rb_intern("each");
  id_step = rb_intern("step");
  id_dup = rb_intern("dup");
  id_bracket = rb_intern("[]");
  id_shift_left = rb_intern("<<");
  id_mask = rb_intern("mask");
  id_where = rb_intern("where");
}
