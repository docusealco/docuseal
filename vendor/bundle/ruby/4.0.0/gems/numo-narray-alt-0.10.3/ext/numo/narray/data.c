/*
  data.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#include <ruby.h>

#include "numo/narray.h"
#include "numo/template.h"

static ID id_mulsum;
static ID id_store;
static ID id_swap_byte;

// ---------------------------------------------------------------------

#define LOOP_UNARY_PTR(lp, proc)                                                               \
  {                                                                                            \
    size_t i;                                                                                  \
    ssize_t s1, s2;                                                                            \
    char *p1, *p2;                                                                             \
    size_t *idx1, *idx2;                                                                       \
    INIT_COUNTER(lp, i);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (; i--;) {                                                                         \
          proc((p1 + *idx1), (p2 + *idx2));                                                    \
          idx1++;                                                                              \
          idx2++;                                                                              \
        }                                                                                      \
      } else {                                                                                 \
        for (; i--;) {                                                                         \
          proc((p1 + *idx1), p2);                                                              \
          idx1++;                                                                              \
          p2 += s2;                                                                            \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (; i--;) {                                                                         \
          proc(p1, (p1 + *idx2));                                                              \
          p1 += s1;                                                                            \
          idx2++;                                                                              \
        }                                                                                      \
      } else {                                                                                 \
        for (; i--;) {                                                                         \
          proc(p1, p2);                                                                        \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }

#define m_memcpy(src, dst) memcpy(dst, src, e)
static void iter_copy_bytes(na_loop_t* const lp) {
  size_t e;
  e = lp->args[0].elmsz;
  LOOP_UNARY_PTR(lp, m_memcpy);
}

VALUE
na_copy(VALUE self) {
  VALUE v;
  ndfunc_arg_in_t ain[1] = { { Qnil, 0 } };
  ndfunc_arg_out_t aout[1] = { { INT2FIX(0), 0 } };
  ndfunc_t ndf = { iter_copy_bytes, FULL_LOOP, 1, 1, ain, aout };

  v = na_ndloop(&ndf, 1, self);
  return v;
}

VALUE
na_store(VALUE self, VALUE src) {
  return rb_funcall(self, id_store, 1, src);
}

// ---------------------------------------------------------------------

#define m_swap_byte(q1, q2)                                                                    \
  {                                                                                            \
    size_t j;                                                                                  \
    memcpy(b1, q1, e);                                                                         \
    for (j = 0; j < e; j++) {                                                                  \
      b2[e - 1 - j] = b1[j];                                                                   \
    }                                                                                          \
    memcpy(q2, b2, e);                                                                         \
  }

static void iter_swap_byte(na_loop_t* const lp) {
  char *b1, *b2;
  size_t e;

  e = lp->args[0].elmsz;
  b1 = ALLOCA_N(char, e);
  b2 = ALLOCA_N(char, e);
  LOOP_UNARY_PTR(lp, m_swap_byte);
}

static VALUE nary_swap_byte(VALUE self) {
  VALUE v;
  ndfunc_arg_in_t ain[1] = { { Qnil, 0 } };
  ndfunc_arg_out_t aout[1] = { { INT2FIX(0), 0 } };
  ndfunc_t ndf = { iter_swap_byte, FULL_LOOP | NDF_ACCEPT_BYTESWAP, 1, 1, ain, aout };

  v = na_ndloop(&ndf, 1, self);
  if (self != v) {
    na_copy_flags(self, v);
  }
  REVERSE_ENDIAN(v);
  return v;
}

static VALUE nary_to_network(VALUE self) {
  if (TEST_BIG_ENDIAN(self)) {
    return self;
  }
  return rb_funcall(self, id_swap_byte, 0);
}

static VALUE nary_to_vacs(VALUE self) {
  if (TEST_LITTLE_ENDIAN(self)) {
    return self;
  }
  return rb_funcall(self, id_swap_byte, 0);
}

static VALUE nary_to_host(VALUE self) {
  if (TEST_HOST_ORDER(self)) {
    return self;
  }
  return rb_funcall(self, id_swap_byte, 0);
}

static VALUE nary_to_swapped(VALUE self) {
  if (TEST_BYTE_SWAPPED(self)) {
    return self;
  }
  return rb_funcall(self, id_swap_byte, 0);
}

//----------------------------------------------------------------------

static inline int check_axis(int axis, int ndim) {
  if (axis < -ndim || axis >= ndim) {
    rb_raise(nary_eDimensionError, "invalid axis (%d for %d-dimension)", axis, ndim);
  }
  if (axis < 0) {
    axis += ndim;
  }
  return axis;
}

/*
  Interchange two axes.
  @overload  swapaxes(axis1,axis2)
    @param [Integer] axis1
    @param [Integer] axis2
    @return [Numo::NArray]  view of NArray.
  @example
    x = Numo::Int32[[1,2,3]]

    x.swapaxes(0,1)
    # => Numo::Int32(view)#shape=[3,1]
    # [[1],
    #  [2],
    #  [3]]

    x = Numo::Int32[[[0,1],[2,3]],[[4,5],[6,7]]]
    # => Numo::Int32#shape=[2,2,2]
    # [[[0, 1],
    #   [2, 3]],
    #  [[4, 5],
    #   [6, 7]]]

    x.swapaxes(0,2)
    # => Numo::Int32(view)#shape=[2,2,2]
    # [[[0, 4],
    #   [2, 6]],
    #  [[1, 5],
    #   [3, 7]]]
*/
static VALUE na_swapaxes(VALUE self, VALUE a1, VALUE a2) {
  int i, j, ndim;
  size_t tmp_shape;
  stridx_t tmp_stridx;
  narray_view_t* na;
  volatile VALUE view;

  view = na_make_view(self);
  GetNArrayView(view, na);

  ndim = na->base.ndim;
  i = check_axis(NUM2INT(a1), ndim);
  j = check_axis(NUM2INT(a2), ndim);

  tmp_shape = na->base.shape[i];
  tmp_stridx = na->stridx[i];
  na->base.shape[i] = na->base.shape[j];
  na->stridx[i] = na->stridx[j];
  na->base.shape[j] = tmp_shape;
  na->stridx[j] = tmp_stridx;

  return view;
}

static VALUE na_transpose_map(VALUE self, int* map) {
  int i, ndim;
  size_t* shape;
  stridx_t* stridx;
  narray_view_t* na;
  volatile VALUE view;

  view = na_make_view(self);
  GetNArrayView(view, na);

  ndim = na->base.ndim;
  shape = ALLOCA_N(size_t, ndim);
  stridx = ALLOCA_N(stridx_t, ndim);

  for (i = 0; i < ndim; i++) {
    shape[i] = na->base.shape[i];
    stridx[i] = na->stridx[i];
  }
  for (i = 0; i < ndim; i++) {
    na->base.shape[i] = shape[map[i]];
    na->stridx[i] = stridx[map[i]];
  }
  return view;
}

#define SWAP(a, b, tmp)                                                                        \
  {                                                                                            \
    tmp = a;                                                                                   \
    a = b;                                                                                     \
    b = tmp;                                                                                   \
  }

static VALUE na_transpose(int argc, VALUE* argv, VALUE self) {
  int ndim, *map, *permute;
  int i, d;
  bool is_positive, is_negative;
  narray_t* na1;

  GetNArray(self, na1);
  ndim = na1->ndim;
  if (ndim < 2) {
    if (argc > 0) {
      rb_raise(rb_eArgError, "unnecessary argument for 1-d array");
    }
    return na_make_view(self);
  }
  map = ALLOCA_N(int, ndim);
  if (argc == 0) {
    for (i = 0; i < ndim; i++) {
      map[i] = ndim - 1 - i;
    }
    return na_transpose_map(self, map);
  }
  // with argument
  if (argc > ndim) {
    rb_raise(rb_eArgError, "more arguments than ndim");
  }
  for (i = 0; i < ndim; i++) {
    map[i] = i;
  }
  permute = ALLOCA_N(int, argc);
  for (i = 0; i < argc; i++) {
    permute[i] = 0;
  }
  is_positive = is_negative = 0;
  for (i = 0; i < argc; i++) {
    if (TYPE(argv[i]) != T_FIXNUM) {
      rb_raise(rb_eArgError, "invalid argument");
    }
    d = FIX2INT(argv[i]);
    if (d >= 0) {
      if (d >= argc) {
        rb_raise(rb_eArgError, "out of dimension range");
      }
      if (is_negative) {
        rb_raise(rb_eArgError, "dimension must be non-negative only or negative only");
      }
      if (permute[d]) {
        rb_raise(rb_eArgError, "not permutation");
      }
      map[i] = d;
      permute[d] = 1;
      is_positive = 1;
    } else {
      if (d < -argc) {
        rb_raise(rb_eArgError, "out of dimension range");
      }
      if (is_positive) {
        rb_raise(rb_eArgError, "dimension must be non-negative only or negative only");
      }
      if (permute[argc + d]) {
        rb_raise(rb_eArgError, "not permutation");
      }
      map[ndim - argc + i] = ndim + d;
      permute[argc + d] = 1;
      is_negative = 1;
    }
  }
  return na_transpose_map(self, map);
}

//----------------------------------------------------------------------

static void na_check_reshape(int argc, VALUE* argv, VALUE self, size_t* shape) {
  int i, unfixed = -1;
  size_t total = 1;
  narray_t* na;

  if (argc == 0) {
    rb_raise(rb_eArgError, "No argrument");
  }
  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    rb_raise(rb_eRuntimeError, "cannot reshape empty array");
  }

  /* get shape from argument */
  for (i = 0; i < argc; ++i) {
    switch (TYPE(argv[i])) {
    case T_FIXNUM:
      total *= shape[i] = NUM2INT(argv[i]);
      break;
    case T_NIL:
    case T_TRUE:
      if (unfixed >= 0) {
        rb_raise(rb_eArgError, "multiple unfixed dimension");
      }
      unfixed = i;
      break;
    default:
      rb_raise(rb_eArgError, "illegal type");
    }
  }

  if (unfixed >= 0) {
    if (NA_SIZE(na) % total != 0) {
      rb_raise(rb_eArgError, "Total size size must be divisor");
    }
    shape[unfixed] = NA_SIZE(na) / total;
  } else if (total != NA_SIZE(na)) {
    rb_raise(rb_eArgError, "Total size must be same");
  }
}

/*
  Change the shape of self NArray without coping.
  Raise exception if self is non-contiguous.

  @overload  reshape!(size0,size1,...)
    @param sizeN [Integer] new shape
    @return [Numo::NArray] return self.
*/
static VALUE na_reshape_bang(int argc, VALUE* argv, VALUE self) {
  size_t* shape;
  narray_t* na;
  narray_view_t* na2;
  ssize_t stride;
  stridx_t* stridx;
  int i;

  if (na_check_contiguous(self) == Qfalse) {
    rb_raise(rb_eStandardError, "cannot change shape of non-contiguous NArray");
  }
  shape = ALLOCA_N(size_t, argc);
  na_check_reshape(argc, argv, self, shape);

  GetNArray(self, na);
  if (na->type == NARRAY_VIEW_T) {
    GetNArrayView(self, na2);
    if (na->ndim < argc) {
      stridx = ALLOC_N(stridx_t, argc);
    } else {
      stridx = na2->stridx;
    }
    stride = SDX_GET_STRIDE(na2->stridx[na->ndim - 1]);
    for (i = argc; i--;) {
      SDX_SET_STRIDE(stridx[i], stride);
      stride *= shape[i];
    }
    if (stridx != na2->stridx) {
      xfree(na2->stridx);
      na2->stridx = stridx;
    }
  }
  na_setup_shape(na, argc, shape);
  return self;
}

/*
  Copy and change the shape of NArray.
  Returns a copied NArray.

  @overload  reshape(size0,size1,...)
    @param sizeN [Integer] new shape
    @return [Numo::NArray] return self.
*/
static VALUE na_reshape(int argc, VALUE* argv, VALUE self) {
  size_t* shape;
  narray_t* na;
  VALUE copy;

  shape = ALLOCA_N(size_t, argc);
  na_check_reshape(argc, argv, self, shape);

  copy = rb_funcall(self, rb_intern("dup"), 0);
  GetNArray(copy, na);
  na_setup_shape(na, argc, shape);
  return copy;
}

//----------------------------------------------------------------------

VALUE
na_flatten_dim(VALUE self, int sd) {
  int i, nd, fd;
  size_t j, ofs;
  size_t *c, *pos, *idx1, *idx2;
  size_t stride;
  size_t *shape, size;
  stridx_t sdx;
  narray_t* na;
  narray_view_t *na1, *na2;
  volatile VALUE view;

  GetNArray(self, na);
  nd = na->ndim;

  if (nd == 0) {
    return na_make_view(self);
  }
  if (sd < 0 || sd >= nd) {
    rb_bug("na_flaten_dim: start_dim (%d) out of range", sd);
  }

  // new shape
  shape = ALLOCA_N(size_t, sd + 1);
  for (i = 0; i < sd; i++) {
    shape[i] = na->shape[i];
  }
  size = 1;
  for (i = sd; i < nd; i++) {
    size *= na->shape[i];
  }
  shape[sd] = size;

  // new object
  view = na_s_allocate_view(rb_obj_class(self));
  na_copy_flags(self, view);
  GetNArrayView(view, na2);

  // new stride
  na_setup_shape((narray_t*)na2, sd + 1, shape);
  na2->stridx = ALLOC_N(stridx_t, sd + 1);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    stride = nary_element_stride(self);
    for (i = sd + 1; i--;) {
      SDX_SET_STRIDE(na2->stridx[i], stride);
      stride *= shape[i];
    }
    na2->offset = 0;
    na2->data = self;
    break;
  case NARRAY_VIEW_T:
    GetNArrayView(self, na1);
    na2->data = na1->data;
    na2->offset = na1->offset;
    for (i = 0; i < sd; i++) {
      if (SDX_IS_INDEX(na1->stridx[i])) {
        idx1 = SDX_GET_INDEX(na1->stridx[i]);
        idx2 = ALLOC_N(size_t, shape[i]);
        for (j = 0; j < shape[i]; j++) {
          idx2[j] = idx1[j];
        }
        SDX_SET_INDEX(na2->stridx[i], idx2);
      } else {
        na2->stridx[i] = na1->stridx[i];
      }
    }
    // flat dimension == last dimension
    if (RTEST(na_check_ladder(self, sd))) {
      na2->stridx[sd] = na1->stridx[nd - 1];
    } else {
      // set index
      idx2 = ALLOC_N(size_t, (shape[sd] == 0) ? 1 : shape[sd]);
      SDX_SET_INDEX(na2->stridx[sd], idx2);
      // init for md-loop
      fd = nd - sd;
      c = ALLOCA_N(size_t, fd);
      for (i = 0; i < fd; i++) c[i] = 0;
      pos = ALLOCA_N(size_t, fd + 1);
      pos[0] = 0;
      // md-loop
      for (i = j = 0;;) {
        for (; i < fd; i++) {
          sdx = na1->stridx[i + sd];
          if (SDX_IS_INDEX(sdx)) {
            if (SDX_GET_INDEX(sdx)) {
              ofs = SDX_GET_INDEX(sdx)[c[i]];
            } else {
              ofs = 0;
            }
          } else {
            ofs = SDX_GET_STRIDE(sdx) * c[i];
          }
          pos[i + 1] = pos[i] + ofs;
        }
        idx2[j++] = pos[i];
        for (;;) {
          if (i == 0) goto loop_end;
          i--;
          c[i]++;
          if (c[i] < na1->base.shape[i + sd]) break;
          c[i] = 0;
        }
      }
    loop_end:;
    }
    break;
  }
  return view;
}

VALUE
na_flatten(VALUE self) {
  return na_flatten_dim(self, 0);
}

//----------------------------------------------------------------------

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

/*
  Returns a diagonal view of NArray
  @overload  diagonal([offset,axes])
    @param [Integer] offset  Diagonal offset from the main diagonal.
      The default is 0. k>0 for diagonals above the main diagonal,
      and k<0 for diagonals below the main diagonal.
    @param [Array] axes  Array of axes to be used as the 2-d sub-arrays
      from which the diagonals should be taken. Defaults to last-two
      axes ([-2,-1]).
    @return [Numo::NArray]  diagonal view of NArray.
  @example
    a = Numo::DFloat.new(4,5).seq
    # => Numo::DFloat#shape=[4,5]
    # [[0, 1, 2, 3, 4],
    #  [5, 6, 7, 8, 9],
    #  [10, 11, 12, 13, 14],
    #  [15, 16, 17, 18, 19]]
    b = a.diagonal(1)
    # => Numo::DFloat(view)#shape=[4]
    # [1, 7, 13, 19]

    b.store(0)
    a
    # => Numo::DFloat#shape=[4,5]
    # [[0, 0, 2, 3, 4],
    #  [5, 6, 0, 8, 9],
    #  [10, 11, 12, 0, 14],
    #  [15, 16, 17, 18, 0]]

    b.store([1,2,3,4])
    a
    # => Numo::DFloat#shape=[4,5]
    # [[0, 1, 2, 3, 4],
    #  [5, 6, 2, 8, 9],
    #  [10, 11, 12, 3, 14],
    #  [15, 16, 17, 18, 4]]
 */
static VALUE na_diagonal(int argc, VALUE* argv, VALUE self) {
  int i, k, nd;
  size_t j;
  size_t *idx0, *idx1, *diag_idx;
  size_t* shape;
  size_t diag_size;
  ssize_t stride, stride0, stride1;
  narray_t* na;
  narray_view_t *na1, *na2;
  VALUE view;
  VALUE vofs = 0, vaxes = 0;
  ssize_t kofs;
  size_t k0, k1;
  int ax[2];

  // check arguments
  if (argc > 2) {
    rb_raise(rb_eArgError, "too many arguments (%d for 0..2)", argc);
  }

  for (i = 0; i < argc; i++) {
    switch (TYPE(argv[i])) {
    case T_FIXNUM:
      if (vofs) {
        rb_raise(rb_eArgError, "offset is given twice");
      }
      vofs = argv[i];
      break;
    case T_ARRAY:
      if (vaxes) {
        rb_raise(rb_eArgError, "axes-array is given twice");
      }
      vaxes = argv[i];
      break;
    }
  }

  if (vofs) {
    kofs = NUM2SSIZET(vofs);
  } else {
    kofs = 0;
  }

  GetNArray(self, na);
  nd = na->ndim;
  if (nd < 2) {
    rb_raise(nary_eDimensionError, "less than 2-d array");
  }

  if (vaxes) {
    if (RARRAY_LEN(vaxes) != 2) {
      rb_raise(rb_eArgError, "axes must be 2-element array");
    }
    ax[0] = NUM2INT(RARRAY_AREF(vaxes, 0));
    ax[1] = NUM2INT(RARRAY_AREF(vaxes, 1));
    if (ax[0] < -nd || ax[0] >= nd || ax[1] < -nd || ax[1] >= nd) {
      rb_raise(rb_eArgError, "axis out of range:[%d,%d]", ax[0], ax[1]);
    }
    if (ax[0] < 0) {
      ax[0] += nd;
    }
    if (ax[1] < 0) {
      ax[1] += nd;
    }
    if (ax[0] == ax[1]) {
      rb_raise(rb_eArgError, "same axes:[%d,%d]", ax[0], ax[1]);
    }
  } else {
    ax[0] = nd - 2;
    ax[1] = nd - 1;
  }

  // Diagonal offset from the main diagonal.
  if (kofs >= 0) {
    k0 = 0;
    k1 = kofs;
    if (k1 >= na->shape[ax[1]]) {
      rb_raise(
        rb_eArgError,
        "invalid diagonal offset(%" SZF "d) for "
        "last dimension size(%" SZF "d)",
        kofs, na->shape[ax[1]]
      );
    }
  } else {
    k0 = -kofs;
    k1 = 0;
    if (k0 >= na->shape[ax[0]]) {
      rb_raise(
        rb_eArgError,
        "invalid diagonal offset(=%" SZF "d) for "
        "last-1 dimension size(%" SZF "d)",
        kofs, na->shape[ax[0]]
      );
    }
  }

  diag_size = MIN(na->shape[ax[0]] - k0, na->shape[ax[1]] - k1);

  // new shape
  shape = ALLOCA_N(size_t, nd - 1);
  for (i = k = 0; i < nd; i++) {
    if (i != ax[0] && i != ax[1]) {
      shape[k++] = na->shape[i];
    }
  }
  shape[k] = diag_size;

  // new object
  view = na_s_allocate_view(rb_obj_class(self));
  na_copy_flags(self, view);
  GetNArrayView(view, na2);

  // new stride
  na_setup_shape((narray_t*)na2, nd - 1, shape);
  na2->stridx = ALLOC_N(stridx_t, nd - 1);

  switch (na->type) {
  case NARRAY_DATA_T:
  case NARRAY_FILEMAP_T:
    na2->offset = 0;
    na2->data = self;
    stride = stride0 = stride1 = nary_element_stride(self);
    for (i = nd, k = nd - 2; i--;) {
      if (i == ax[1]) {
        stride1 = stride;
        if (kofs > 0) {
          na2->offset = kofs * stride;
        }
      } else if (i == ax[0]) {
        stride0 = stride;
        if (kofs < 0) {
          na2->offset = (-kofs) * stride;
        }
      } else {
        SDX_SET_STRIDE(na2->stridx[--k], stride);
      }
      stride *= na->shape[i];
    }
    SDX_SET_STRIDE(na2->stridx[nd - 2], stride0 + stride1);
    break;

  case NARRAY_VIEW_T:
    GetNArrayView(self, na1);
    na2->data = na1->data;
    na2->offset = na1->offset;
    for (i = k = 0; i < nd; i++) {
      if (i != ax[0] && i != ax[1]) {
        if (SDX_IS_INDEX(na1->stridx[i])) {
          idx0 = SDX_GET_INDEX(na1->stridx[i]);
          idx1 = ALLOC_N(size_t, na->shape[i]);
          for (j = 0; j < na->shape[i]; j++) {
            idx1[j] = idx0[j];
          }
          SDX_SET_INDEX(na2->stridx[k], idx1);
        } else {
          na2->stridx[k] = na1->stridx[i];
        }
        k++;
      }
    }
    if (SDX_IS_INDEX(na1->stridx[ax[0]])) {
      idx0 = SDX_GET_INDEX(na1->stridx[ax[0]]);
      diag_idx = ALLOC_N(size_t, diag_size);
      if (SDX_IS_INDEX(na1->stridx[ax[1]])) {
        idx1 = SDX_GET_INDEX(na1->stridx[ax[1]]);
        for (j = 0; j < diag_size; j++) {
          diag_idx[j] = idx0[j + k0] + idx1[j + k1];
        }
      } else {
        stride1 = SDX_GET_STRIDE(na1->stridx[ax[1]]);
        for (j = 0; j < diag_size; j++) {
          diag_idx[j] = idx0[j + k0] + stride1 * (j + k1);
        }
      }
      SDX_SET_INDEX(na2->stridx[nd - 2], diag_idx);
    } else {
      stride0 = SDX_GET_STRIDE(na1->stridx[ax[0]]);
      if (SDX_IS_INDEX(na1->stridx[ax[1]])) {
        idx1 = SDX_GET_INDEX(na1->stridx[ax[1]]);
        diag_idx = ALLOC_N(size_t, diag_size);
        for (j = 0; j < diag_size; j++) {
          diag_idx[j] = stride0 * (j + k0) + idx1[j + k1];
        }
        SDX_SET_INDEX(na2->stridx[nd - 2], diag_idx);
      } else {
        stride1 = SDX_GET_STRIDE(na1->stridx[ax[1]]);
        na2->offset += stride0 * k0 + stride1 * k1;
        SDX_SET_STRIDE(na2->stridx[nd - 2], stride0 + stride1);
      }
    }
    break;
  }
  return view;
}

//----------------------------------------------------------------------

#if 0
#ifdef SWAP
#undef SWAP
#endif
#define SWAP(a, b, t)                                                                          \
  {                                                                                            \
    t = a;                                                                                     \
    a = b;                                                                                     \
    b = t;                                                                                     \
  }

static VALUE
na_new_dimension_for_dot(VALUE self, int pos, int len, bool transpose)
{
    int i, k, l, nd;
    size_t  j;
    size_t *idx1, *idx2;
    size_t *shape;
    ssize_t stride;
    narray_t *na;
    narray_view_t *na1, *na2;
    size_t shape_n;
    stridx_t stridx_n;
    volatile VALUE view;

    GetNArray(self,na);
    nd = na->ndim;

    view = na_s_allocate_view(rb_obj_class(self));

    na_copy_flags(self, view);
    GetNArrayView(view, na2);

    // new dimension
    if (pos < 0) pos += nd;
    if (pos > nd || pos < 0) {
        rb_raise(rb_eRangeError,"new dimension is out of range");
    }
    nd += len;
    shape = ALLOCA_N(size_t,nd);
    na2->stridx = ALLOC_N(stridx_t,nd);

    switch(na->type) {
    case NARRAY_DATA_T:
    case NARRAY_FILEMAP_T:
        i = k = 0;
        while (i < nd) {
            if (i == pos && len > 0) {
                for (l=0; l<len; l++) {
                    shape[i++] = 1;
                }
            } else {
                shape[i++] = na->shape[k++];
            }
        }
        na_setup_shape((narray_t*)na2, nd, shape);
        stride = nary_element_stride(self);
        for (i=nd; i--;) {
            SDX_SET_STRIDE(na2->stridx[i], stride);
            stride *= shape[i];
        }
        na2->offset = 0;
        na2->data = self;
        break;
    case NARRAY_VIEW_T:
        GetNArrayView(self, na1);
        i = k = 0;
        while (i < nd) {
            if (i == pos && len > 0) {
                if (SDX_IS_INDEX(na1->stridx[k])) {
                    stride = SDX_GET_INDEX(na1->stridx[k])[0];
                } else {
                    stride = SDX_GET_STRIDE(na1->stridx[k]);
                }
                for (l=0; l<len; l++) {
                    shape[i] = 1;
                    SDX_SET_STRIDE(na2->stridx[i], stride);
                    i++;
                }
            } else {
                shape[i] = na1->base.shape[k];
                if (SDX_IS_INDEX(na1->stridx[k])) {
                    idx1 = SDX_GET_INDEX(na1->stridx[k]);
                    idx2 = ALLOC_N(size_t,na1->base.shape[k]);
                    for (j=0; j<na1->base.shape[k]; j++) {
                        idx2[j] = idx1[j];
                    }
                    SDX_SET_INDEX(na2->stridx[i], idx2);
                } else {
                    na2->stridx[i] = na1->stridx[k];
                }
                i++; k++;
            }
        }
        na_setup_shape((narray_t*)na2, nd, shape);
        na2->offset = na1->offset;
        na2->data = na1->data;
        break;
    }

    if (transpose) {
	SWAP(na2->base.shape[nd-1], na2->base.shape[nd-2], shape_n);
	SWAP(na2->stridx[nd-1], na2->stridx[nd-2], stridx_n);
    }

    return view;
}


//----------------------------------------------------------------------

/*
 *  call-seq:
 *     narray.dot(other) => narray
 *
 *  Returns dot product.
 *
 */

static VALUE
numo_na_dot(VALUE self, VALUE other)
{
    volatile VALUE a1=self, a2=other;
    narray_t *na1, *na2;

    if (!rb_respond_to(a1, id_mulsum)) {
        rb_raise(rb_eNoMethodError,"requires mulsum method for dot method");
    }
    GetNArray(a1,na1);
    GetNArray(a2,na2);
    if (na1->ndim==0 || na2->ndim==0) {
        rb_raise(nary_eDimensionError,"zero dimensional narray");
    }
    if (na2->ndim > 1) {
        if (na1->shape[na1->ndim-1] != na2->shape[na2->ndim-2]) {
            rb_raise(nary_eShapeError,"shape mismatch: self.shape[-1](=%"SZF"d) != other.shape[-2](=%"SZF"d)",
                     na1->shape[na1->ndim-1], na2->shape[na2->ndim-2]);
        }
        // insert new axis [ ..., last-1-dim, newaxis*other.ndim, last-dim ]
        a1 = na_new_dimension_for_dot(a1, na1->ndim-1, na2->ndim-1, 0);
        // insert & transpose [ newaxis*self.ndim, ..., last-dim, last-1-dim ]
        a2 = na_new_dimension_for_dot(a2, 0, na1->ndim-1, 1);
    }
    return rb_funcall(a1,id_mulsum,2,a2,INT2FIX(-1));
}
#endif

void Init_nary_data(void) {
  rb_define_method(cNArray, "copy", na_copy, 0); // deprecated

  rb_define_method(cNArray, "flatten", na_flatten, 0);
  rb_define_method(cNArray, "swapaxes", na_swapaxes, 2);
  rb_define_method(cNArray, "transpose", na_transpose, -1);

  rb_define_method(cNArray, "reshape", na_reshape, -1);
  rb_define_method(cNArray, "reshape!", na_reshape_bang, -1);
  /*
  rb_define_alias(cNArray,  "shape=","reshape!");
  */
  rb_define_method(cNArray, "diagonal", na_diagonal, -1);

  rb_define_method(cNArray, "swap_byte", nary_swap_byte, 0);
#ifdef DYNAMIC_ENDIAN
#else
#ifdef WORDS_BIGENDIAN
#else // LITTLE_ENDIAN
  rb_define_alias(cNArray, "hton", "swap_byte");
  rb_define_alias(cNArray, "network_order?", "byte_swapped?");
  rb_define_alias(cNArray, "little_endian?", "host_order?");
  rb_define_alias(cNArray, "vacs_order?", "host_order?");
#endif
#endif
  rb_define_method(cNArray, "to_network", nary_to_network, 0);
  rb_define_method(cNArray, "to_vacs", nary_to_vacs, 0);
  rb_define_method(cNArray, "to_host", nary_to_host, 0);
  rb_define_method(cNArray, "to_swapped", nary_to_swapped, 0);

  // rb_define_method(cNArray, "dot", numo_na_dot, 1);

  id_mulsum = rb_intern("mulsum");
  id_store = rb_intern("store");
  id_swap_byte = rb_intern("swap_byte");
}
