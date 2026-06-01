/*
  ndloop.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#include <ruby.h>

#include "numo/narray.h"

#if 0
#define DBG(x) x
#else
#define DBG(x)
#endif

#ifdef HAVE_STDARG_PROTOTYPES
#include <stdarg.h>
#define va_init_list(a, b) va_start(a, b)
#else
#include <varargs.h>
#define va_init_list(a, b) va_start(a)
#endif

typedef struct NA_BUFFER_COPY {
  int ndim;
  size_t elmsz;
  size_t* n;
  char* src_ptr;
  char* buf_ptr;
  na_loop_iter_t* src_iter;
  na_loop_iter_t* buf_iter;
} na_buffer_copy_t;

typedef struct NA_LOOP_XARGS {
  na_loop_iter_t* iter;    // moved from na_loop_t
  na_buffer_copy_t* bufcp; // copy data to buffer
  int flag;                // NDL_READ NDL_WRITE
  bool free_user_iter;     // alloc LARG(lp,j).iter=lp->xargs[j].iter
} na_loop_xargs_t;

typedef struct NA_MD_LOOP {
  int narg;
  int nin;
  int ndim;                 // n of total dimension
  unsigned int copy_flag;   // set i-th bit if i-th arg is cast
  void* ptr;                // memory for n
  na_loop_iter_t* iter_ptr; // memory for iter
  size_t* n;                // n of elements for each dim
  na_loop_t user;           // loop in user function
  na_loop_xargs_t* xargs;   // extra data for each arg
  int writeback;            // write back result to i-th arg
  int init_aidx;            // index of initializer argument
  int reduce_dim;
  int* trans_map;
  VALUE vargs;
  VALUE reduce;
  VALUE loop_opt;
  ndfunc_t* ndfunc;
  void (*loop_func)(ndfunc_t*, struct NA_MD_LOOP*);
} na_md_loop_t;

#define LARG(lp, iarg) ((lp)->user.args[iarg])
#define LITER(lp, idim, iarg) ((lp)->xargs[iarg].iter[idim])
#define LITER_SRC(lp, idim) ((lp)->src_iter[idim])
#define LBUFCP(lp, j) ((lp)->xargs[j].bufcp)

#define CASTABLE(t) (RTEST(t) && (t) != OVERWRITE)

#define NDL_READ 1
#define NDL_WRITE 2
#define NDL_READ_WRITE (NDL_READ | NDL_WRITE)

static ID id_cast;
static ID id_extract;

static inline VALUE nary_type_s_cast(VALUE type, VALUE obj) {
  return rb_funcall(type, id_cast, 1, obj);
}

static void print_ndfunc(ndfunc_t* nf) {
  volatile VALUE t;
  int i, k;
  printf("ndfunc_t = 0x%" SZF "x {\n", (size_t)nf);
  printf("  func  = 0x%" SZF "x\n", (size_t)nf->func);
  printf("  flag  = 0x%" SZF "x\n", (size_t)nf->flag);
  printf("  nin   = %d\n", nf->nin);
  printf("  nout  = %d\n", nf->nout);
  printf("  ain   = 0x%" SZF "x\n", (size_t)nf->ain);
  for (i = 0; i < nf->nin; i++) {
    t = rb_inspect(nf->ain[i].type);
    printf("  ain[%d].type = %s\n", i, StringValuePtr(t));
    printf("  ain[%d].dim = %d\n", i, nf->ain[i].dim);
  }
  printf("  aout  = 0x%" SZF "x\n", (size_t)nf->aout);
  for (i = 0; i < nf->nout; i++) {
    t = rb_inspect(nf->aout[i].type);
    printf("  aout[%d].type = %s\n", i, StringValuePtr(t));
    printf("  aout[%d].dim = %d\n", i, nf->aout[i].dim);
    for (k = 0; k < nf->aout[i].dim; k++) {
      printf("  aout[%d].shape[%d] = %" SZF "u\n", i, k, nf->aout[i].shape[k]);
    }
  }
  printf("}\n");
}

static void print_ndloop(na_md_loop_t* lp) {
  int i, j, nd;
  printf("na_md_loop_t = 0x%" SZF "x {\n", (size_t)lp);
  printf("  narg = %d\n", lp->narg);
  printf("  nin  = %d\n", lp->nin);
  printf("  ndim = %d\n", lp->ndim);
  printf("  copy_flag = %x\n", lp->copy_flag);
  printf("  writeback = %d\n", lp->writeback);
  printf("  init_aidx = %d\n", lp->init_aidx);
  printf("  reduce_dim = %d\n", lp->reduce_dim);
  printf("  trans_map = 0x%" SZF "x\n", (size_t)lp->trans_map);
  nd = lp->ndim + lp->user.ndim;
  for (i = 0; i < nd; i++) {
    printf("  trans_map[%d] = %d\n", i, lp->trans_map[i]);
  }
  printf("  n = 0x%" SZF "x\n", (size_t)lp->n);
  nd = lp->ndim + lp->user.ndim;
  for (i = 0; i <= lp->ndim; i++) {
    printf("  n[%d] = %" SZF "u\n", i, lp->n[i]);
  }
  printf("  user.n = 0x%" SZF "x\n", (size_t)lp->user.n);
  if (lp->user.n) {
    for (i = 0; i <= lp->user.ndim; i++) {
      printf("  user.n[%d] = %" SZF "u\n", i, lp->user.n[i]);
    }
  }
  printf("  xargs = 0x%" SZF "x\n", (size_t)lp->xargs);
  printf("  iter_ptr = 0x%" SZF "x\n", (size_t)lp->iter_ptr);
  printf("  user.narg = %d\n", lp->user.narg);
  printf("  user.ndim = %d\n", lp->user.ndim);
  printf("  user.args = 0x%" SZF "x\n", (size_t)lp->user.args);
  for (j = 0; j < lp->narg; j++) {
  }
  printf("  user.opt_ptr = 0x%" SZF "x\n", (size_t)lp->user.opt_ptr);
  if (lp->reduce == Qnil) {
    printf("  reduce  = nil\n");
  } else {
    printf("  reduce  = 0x%x\n", NUM2INT(lp->reduce));
  }
  for (j = 0; j < lp->narg; j++) {
    printf("--user.args[%d]--\n", j);
    printf("  user.args[%d].ptr = 0x%" SZF "x\n", j, (size_t)LARG(lp, j).ptr);
    printf("  user.args[%d].elmsz = %" SZF "d\n", j, LARG(lp, j).elmsz);
    printf("  user.args[%d].value = 0x%" PRI_VALUE_PREFIX "x\n", j, LARG(lp, j).value);
    printf("  user.args[%d].ndim = %d\n", j, LARG(lp, j).ndim);
    printf("  user.args[%d].shape = 0x%" SZF "x\n", j, (size_t)LARG(lp, j).shape);
    if (LARG(lp, j).shape) {
      for (i = 0; i < LARG(lp, j).ndim; i++) {
        printf("  user.args[%d].shape[%d] = %" SZF "d\n", j, i, LARG(lp, j).shape[i]);
      }
    }
    printf("  user.args[%d].iter = 0x%" SZF "x\n", j, (size_t)lp->user.args[j].iter);
    if (lp->user.args[j].iter) {
      for (i = 0; i < lp->user.ndim; i++) {
        printf(
          " &user.args[%d].iter[%d] = 0x%" SZF "x\n", j, i, (size_t)&lp->user.args[j].iter[i]
        );
        printf(
          "  user.args[%d].iter[%d].pos = %" SZF "u\n", j, i, lp->user.args[j].iter[i].pos
        );
        printf(
          "  user.args[%d].iter[%d].step = %" SZF "d\n", j, i, lp->user.args[j].iter[i].step
        );
        printf(
          "  user.args[%d].iter[%d].idx = 0x%" SZF "x\n", j, i,
          (size_t)lp->user.args[j].iter[i].idx
        );
      }
    }
    //
    printf("  xargs[%d].flag = %d\n", j, lp->xargs[j].flag);
    printf("  xargs[%d].free_user_iter = %d\n", j, lp->xargs[j].free_user_iter);
    for (i = 0; i <= nd; i++) {
      printf(" &xargs[%d].iter[%d] = 0x%" SZF "x\n", j, i, (size_t)&LITER(lp, i, j));
      printf("  xargs[%d].iter[%d].pos = %" SZF "u\n", j, i, LITER(lp, i, j).pos);
      printf("  xargs[%d].iter[%d].step = %" SZF "d\n", j, i, LITER(lp, i, j).step);
      printf("  xargs[%d].iter[%d].idx = 0x%" SZF "x\n", j, i, (size_t)LITER(lp, i, j).idx);
    }
    printf("  xargs[%d].bufcp = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp);
    if (lp->xargs[j].bufcp) {
      printf("  xargs[%d].bufcp->ndim = %d\n", j, lp->xargs[j].bufcp->ndim);
      printf("  xargs[%d].bufcp->elmsz = %" SZF "d\n", j, lp->xargs[j].bufcp->elmsz);
      printf("  xargs[%d].bufcp->n = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp->n);
      printf(
        "  xargs[%d].bufcp->src_ptr = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp->src_ptr
      );
      printf(
        "  xargs[%d].bufcp->buf_ptr = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp->buf_ptr
      );
      printf(
        "  xargs[%d].bufcp->src_iter = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp->src_iter
      );
      printf(
        "  xargs[%d].bufcp->buf_iter = 0x%" SZF "x\n", j, (size_t)lp->xargs[j].bufcp->buf_iter
      );
    }
  }
  printf("}\n");
}

static unsigned int ndloop_func_loop_spec(ndfunc_t* nf, int user_ndim) {
  unsigned int f = 0;
  // If user function supports LOOP
  if (user_ndim > 0 || NDF_TEST(nf, NDF_HAS_LOOP)) {
    if (!NDF_TEST(nf, NDF_STRIDE_LOOP)) {
      f |= 1;
    }
    if (!NDF_TEST(nf, NDF_INDEX_LOOP)) {
      f |= 2;
    }
  }
  return f;
}

static int ndloop_cast_required(VALUE type, VALUE value) {
  return CASTABLE(type) && type != rb_obj_class(value);
}

static int ndloop_castable_type(VALUE type) {
  return rb_obj_is_kind_of(type, rb_cClass) && RTEST(rb_class_inherited_p(type, cNArray));
}

static void ndloop_cast_error(VALUE type, VALUE value) {
  VALUE x = rb_inspect(type);
  char* s = StringValueCStr(x);
  rb_bug("fail cast from %s to %s", rb_obj_classname(value), s);
  rb_raise(rb_eTypeError, "fail cast from %s to %s", rb_obj_classname(value), s);
}

// convert input argeuments given by RARRAY_PTR(args)[j]
//              to type specified by nf->args[j].type
// returns copy_flag where nth-bit is set if nth argument is converted.
static unsigned int ndloop_cast_args(ndfunc_t* nf, VALUE args) {
  int j;
  unsigned int copy_flag = 0;
  VALUE type, value;

  for (j = 0; j < nf->nin; j++) {

    type = nf->ain[j].type;
    if (TYPE(type) == T_SYMBOL) continue;
    value = RARRAY_AREF(args, j);
    if (!ndloop_cast_required(type, value)) continue;

    if (ndloop_castable_type(type)) {
      RARRAY_ASET(args, j, nary_type_s_cast(type, value));
      copy_flag |= 1 << j;
    } else {
      ndloop_cast_error(type, value);
    }
  }

  RB_GC_GUARD(type);
  RB_GC_GUARD(value);
  return copy_flag;
}

static void ndloop_handle_symbol_in_ain(VALUE type, VALUE value, int at, na_md_loop_t* lp) {
  if (type == sym_reduce) {
    lp->reduce = value;
  } else if (type == sym_option) {
    lp->user.option = value;
  } else if (type == sym_loop_opt) {
    lp->loop_opt = value;
  } else if (type == sym_init) {
    lp->init_aidx = at;
  } else {
    rb_bug("ndloop parse_options: unknown type");
  }
}

static inline int max2(int x, int y) {
  return x > y ? x : y;
}

static void ndloop_find_max_dimension(na_md_loop_t* lp, ndfunc_t* nf, VALUE args) {
  int j;
  int nin = 0;     // number of input objects (except for symbols)
  int user_nd = 0; // max dimension of user function
  int loop_nd = 0; // max dimension of md-loop

  for (j = 0; j < RARRAY_LEN(args); j++) {
    VALUE t = nf->ain[j].type;
    VALUE v = RARRAY_AREF(args, j);
    if (TYPE(t) == T_SYMBOL) {
      ndloop_handle_symbol_in_ain(t, v, j, lp);
    } else {
      nin++;
      user_nd = max2(user_nd, nf->ain[j].dim);
      if (IsNArray(v)) loop_nd = max2(loop_nd, RNARRAY_NDIM(v) - nf->ain[j].dim);
    }
  }

  lp->narg = lp->user.narg = nin + nf->nout;
  lp->nin = nin;
  lp->ndim = loop_nd;
  lp->user.ndim = user_nd;
}

/*
  user-dimension:
    user_nd = MAX( nf->args[j].dim )

  user-support dimension:

  loop dimension:
    loop_nd
*/

static void ndloop_alloc(
  na_md_loop_t* lp, ndfunc_t* nf, VALUE args, void* opt_ptr, unsigned int copy_flag,
  void (*loop_func)(ndfunc_t*, na_md_loop_t*)
) {
  int i, j;
  int narg;
  int max_nd;

  char* buf;
  size_t n1, n2, n3, n4, n5;

  long args_len;

  na_loop_iter_t* iter;

  int trans_dim;
  unsigned int f;

  args_len = RARRAY_LEN(args);

  if (args_len != nf->nin) {
    rb_bug("wrong number of arguments for ndfunc (%lu for %d)", args_len, nf->nin);
  }

  lp->vargs = args;
  lp->ndfunc = nf;
  lp->loop_func = loop_func;
  lp->copy_flag = copy_flag;

  lp->reduce = Qnil;
  lp->user.option = Qnil;
  lp->user.opt_ptr = opt_ptr;
  lp->user.err_type = Qfalse;
  lp->loop_opt = Qnil;
  lp->writeback = -1;
  lp->init_aidx = -1;

  lp->ptr = NULL;
  lp->user.n = NULL;

  ndloop_find_max_dimension(lp, nf, args);
  narg = lp->nin + nf->nout;
  max_nd = lp->ndim + lp->user.ndim;

  n1 = sizeof(size_t) * (max_nd + 1);
  n2 = sizeof(na_loop_xargs_t) * narg;
  n2 = ((n2 - 1) / 8 + 1) * 8;
  n3 = sizeof(na_loop_args_t) * narg;
  n3 = ((n3 - 1) / 8 + 1) * 8;
  n4 = sizeof(na_loop_iter_t) * narg * (max_nd + 1);
  n4 = ((n4 - 1) / 8 + 1) * 8;
  n5 = sizeof(int) * (max_nd + 1);

  lp->ptr = buf = (char*)xmalloc(n1 + n2 + n3 + n4 + n5);
  lp->n = (size_t*)buf;
  buf += n1;
  lp->xargs = (na_loop_xargs_t*)buf;
  buf += n2;
  lp->user.args = (na_loop_args_t*)buf;
  buf += n3;
  lp->iter_ptr = iter = (na_loop_iter_t*)buf;
  buf += n4;
  lp->trans_map = (int*)buf;

  for (j = 0; j < narg; j++) {
    LARG(lp, j).value = Qnil;
    LARG(lp, j).iter = NULL;
    LARG(lp, j).shape = NULL;
    LARG(lp, j).ndim = 0;
    lp->xargs[j].iter = &(iter[(max_nd + 1) * j]);
    lp->xargs[j].bufcp = NULL;
    lp->xargs[j].flag = (j < lp->nin) ? NDL_READ : NDL_WRITE;
    lp->xargs[j].free_user_iter = 0;
  }

  for (i = 0; i <= max_nd; i++) {
    lp->n[i] = 1;
    for (j = 0; j < narg; j++) {
      LITER(lp, i, j).pos = 0;
      LITER(lp, i, j).step = 0;
      LITER(lp, i, j).idx = NULL;
    }
  }

  // transpose reduce-dimensions to last dimensions
  //              array          loop
  //           [*,+,*,+,*] => [*,*,*,+,+]
  // trans_map=[0,3,1,4,2] <= [0,1,2,3,4]
  if (NDF_TEST(nf, NDF_FLAT_REDUCE) && RTEST(lp->reduce)) {
    trans_dim = 0;
    for (i = 0; i < max_nd; i++) {
      if (na_test_reduce(lp->reduce, i)) {
        lp->trans_map[i] = -1;
      } else {
        lp->trans_map[i] = trans_dim++;
      }
    }
    j = trans_dim;
    for (i = 0; i < max_nd; i++) {
      if (lp->trans_map[i] == -1) {
        lp->trans_map[i] = j++;
      }
    }
    lp->reduce_dim = max_nd - trans_dim;
    f = 0;
    for (i = trans_dim; i < max_nd; i++) {
      f |= 1 << i;
    }
    lp->reduce = INT2FIX(f);
  } else {
    for (i = 0; i < max_nd; i++) {
      lp->trans_map[i] = i;
    }
    lp->reduce_dim = 0;
  }
}

static VALUE ndloop_release(VALUE vlp) {
  int j;
  VALUE v;
  na_md_loop_t* lp = (na_md_loop_t*)(vlp);

  for (j = 0; j < lp->narg; j++) {
    v = LARG(lp, j).value;
    if (IsNArray(v)) {
      na_release_lock(v);
    }
  }
  for (j = 0; j < lp->narg; j++) {
    if (lp->xargs[j].bufcp) {
      xfree(lp->xargs[j].bufcp->buf_iter);
      xfree(lp->xargs[j].bufcp->buf_ptr);
      xfree(lp->xargs[j].bufcp->n);
      xfree(lp->xargs[j].bufcp);
      if (lp->xargs[j].free_user_iter) {
        xfree(LARG(lp, j).iter);
      }
    }
  }
  xfree(lp->ptr);
  return Qnil;
}

/*
  set lp->n[i] (shape of n-d iteration) here
*/
static void ndloop_check_shape(na_md_loop_t* lp, int nf_dim, narray_t* na) {
  int i, k;
  size_t n;
  int dim_beg;

  dim_beg = lp->ndim + nf_dim - na->ndim;

  for (k = na->ndim - nf_dim - 1; k >= 0; k--) {
    i = lp->trans_map[k + dim_beg];
    n = na->shape[k];
    // if n==1 then repeat this dimension
    if (n != 1) {
      if (lp->n[i] == 1) {
        lp->n[i] = n;
      } else if (lp->n[i] != n) {
        // inconsistent array shape
        rb_raise(
          nary_eShapeError, "shape1[%d](=%" SZF "u) != shape2[%d](=%" SZF "u)", i, lp->n[i], k,
          n
        );
      }
    }
  }
}

/*
na->shape[i] == lp->n[ dim_map[i] ]
 */
static void ndloop_set_stepidx(na_md_loop_t* lp, int j, VALUE vna, int* dim_map, int rwflag) {
  size_t n, s;
  int i, k, nd;
  stridx_t sdx;
  narray_t* na;

  LARG(lp, j).value = vna;
  LARG(lp, j).elmsz = nary_element_stride(vna);
  if (rwflag == NDL_READ) {
    LARG(lp, j).ptr = na_get_pointer_for_read(vna);
  } else if (rwflag == NDL_WRITE) {
    LARG(lp, j).ptr = na_get_pointer_for_write(vna);
  } else if (rwflag == NDL_READ_WRITE) {
    LARG(lp, j).ptr = na_get_pointer_for_read_write(vna);
  } else {
    rb_bug("invalid value for read-write flag");
  }
  GetNArray(vna, na);
  nd = LARG(lp, j).ndim;

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    if (NA_DATA_PTR(na) == NULL && NA_SIZE(na) > 0) {
      rb_bug("cannot read no-data NArray");
      rb_raise(rb_eRuntimeError, "cannot read no-data NArray");
    }
    // through
  case NARRAY_FILEMAP_T:
    s = LARG(lp, j).elmsz;
    for (k = na->ndim; k--;) {
      n = na->shape[k];
      if (n > 1 || nd > 0) {
        i = dim_map[k];
        LITER(lp, i, j).step = s;
        // LITER(lp,i,j).idx = NULL;
      }
      s *= n;
      nd--;
    }
    LITER(lp, 0, j).pos = 0;
    break;
  case NARRAY_VIEW_T:
    LITER(lp, 0, j).pos = NA_VIEW_OFFSET(na);
    for (k = 0; k < na->ndim; k++) {
      n = na->shape[k];
      sdx = NA_VIEW_STRIDX(na)[k];
      if (n > 1 || nd > 0) {
        i = dim_map[k];
        if (SDX_IS_INDEX(sdx)) {
          LITER(lp, i, j).step = 0;
          LITER(lp, i, j).idx = SDX_GET_INDEX(sdx);
        } else {
          LITER(lp, i, j).step = SDX_GET_STRIDE(sdx);
          // LITER(lp,i,j).idx = NULL;
        }
      } else if (n == 1) {
        if (SDX_IS_INDEX(sdx)) {
          LITER(lp, 0, j).pos += SDX_GET_INDEX(sdx)[0];
        }
      }
      nd--;
    }
    break;
  default:
    rb_bug("invalid narray internal type");
  }
}

static void ndloop_init_args(ndfunc_t* nf, na_md_loop_t* lp, VALUE args) {
  int i, j;
  VALUE v;
  narray_t* na;
  int nf_dim;
  int dim_beg;
  int* dim_map;
  int max_nd = lp->ndim + lp->user.ndim;
  int flag;
  size_t s;

  /*
  na->shape[i] == lp->n[ dim_map[i] ]
   */
  dim_map = ALLOCA_N(int, max_nd);

  // input arguments
  for (j = 0; j < nf->nin; j++) {
    if (TYPE(nf->ain[j].type) == T_SYMBOL) {
      continue;
    }
    v = RARRAY_AREF(args, j);
    if (IsNArray(v)) {
      // set LARG(lp,j) with v
      GetNArray(v, na);
      nf_dim = nf->ain[j].dim;
      if (nf_dim > na->ndim) {
        rb_raise(
          nary_eDimensionError,
          "requires >= %d-dimensioal array "
          "while %d-dimensional array is given",
          nf_dim, na->ndim
        );
      }
      ndloop_check_shape(lp, nf_dim, na);
      dim_beg = lp->ndim + nf->ain[j].dim - na->ndim;
      for (i = 0; i < na->ndim; i++) {
        dim_map[i] = lp->trans_map[i + dim_beg];
      }
      if (nf->ain[j].type == OVERWRITE) {
        lp->xargs[j].flag = flag = NDL_WRITE;
      } else {
        lp->xargs[j].flag = flag = NDL_READ;
      }
      LARG(lp, j).ndim = nf_dim;
      ndloop_set_stepidx(lp, j, v, dim_map, flag);
      if (nf_dim > 0) {
        LARG(lp, j).shape = na->shape + (na->ndim - nf_dim);
      }
    } else if (TYPE(v) == T_ARRAY) {
      LARG(lp, j).value = v;
      LARG(lp, j).elmsz = sizeof(VALUE);
      LARG(lp, j).ptr = NULL;
      for (i = 0; i <= max_nd; i++) {
        LITER(lp, i, j).step = 1;
      }
    }
  }
  // check whether # of element is zero
  for (s = 1, i = 0; i <= max_nd; i++) {
    s *= lp->n[i];
  }
  if (s == 0) {
    for (i = 0; i <= max_nd; i++) {
      lp->n[i] = 0;
    }
  }
}

static int ndloop_check_inplace(VALUE type, int na_ndim, size_t* na_shape, VALUE v) {
  int i;
  narray_t* na;

  // type check
  if (type != rb_obj_class(v)) {
    return 0;
  }
  GetNArray(v, na);
  // shape check
  if (na->ndim != na_ndim) {
    return 0;
  }
  for (i = 0; i < na_ndim; i++) {
    if (na_shape[i] != na->shape[i]) {
      return 0;
    }
  }
  // v is selected as output
  return 1;
}

static VALUE ndloop_find_inplace(
  ndfunc_t* nf, na_md_loop_t* lp, VALUE type, int na_ndim, size_t* na_shape, VALUE args
) {
  int j;
  VALUE v;

  // find inplace
  for (j = 0; j < nf->nin; j++) {
    v = RARRAY_AREF(args, j);
    if (IsNArray(v)) {
      if (TEST_INPLACE(v)) {
        if (ndloop_check_inplace(type, na_ndim, na_shape, v)) {
          // if already copied, create outary and write-back
          if (lp->copy_flag & (1 << j)) {
            lp->writeback = j;
          }
          return v;
        }
      }
    }
  }
  // find casted or copied input array
  for (j = 0; j < nf->nin; j++) {
    if (lp->copy_flag & (1 << j)) {
      v = RARRAY_AREF(args, j);
      if (ndloop_check_inplace(type, na_ndim, na_shape, v)) {
        return v;
      }
    }
  }
  return Qnil;
}

static VALUE ndloop_get_arg_type(ndfunc_t* nf, VALUE args, VALUE t) {
  int i;

  // if type is FIXNUM, get the type of i-th argument
  if (FIXNUM_P(t)) {
    i = FIX2INT(t);
    if (i < 0 || i >= nf->nin) {
      rb_bug("invalid type: index (%d) out of # of args", i);
    }
    t = nf->ain[i].type;
    // if i-th type is Qnil, get the type of i-th input value
    if (!CASTABLE(t)) {
      t = rb_obj_class(RARRAY_AREF(args, i));
    }
  }
  return t;
}

static VALUE
ndloop_set_output_narray(ndfunc_t* nf, na_md_loop_t* lp, int k, VALUE type, VALUE args) {
  int i, j;
  int na_ndim;
  int lp_dim;
  volatile VALUE v = Qnil;
  size_t* na_shape;
  int* dim_map;
  int flag = NDL_READ_WRITE;
  int nd;
  int max_nd = lp->ndim + nf->aout[k].dim;

  na_shape = ALLOCA_N(size_t, max_nd);
  dim_map = ALLOCA_N(int, max_nd);

  // md-loop shape
  na_ndim = 0;
  for (i = 0; i < lp->ndim; i++) {
    // na_shape[i] == lp->n[lp->trans_map[i]]
    lp_dim = lp->trans_map[i];
    if (NDF_TEST(nf, NDF_CUM)) { // cumulate with shape kept
      na_shape[na_ndim] = lp->n[lp_dim];
    } else if (na_test_reduce(lp->reduce, lp_dim)) { // accumulate dimension
      if (NDF_TEST(nf, NDF_KEEP_DIM)) {
        na_shape[na_ndim] = 1; // leave it
      } else {
        continue; // delete dimension
      }
    } else {
      na_shape[na_ndim] = lp->n[lp_dim];
    }
    dim_map[na_ndim++] = lp_dim;
    // dim_map[lp_dim] = na_ndim++;
  }

  // user-specified shape
  for (i = 0; i < nf->aout[k].dim; i++) {
    na_shape[na_ndim] = nf->aout[k].shape[i];
    dim_map[na_ndim++] = i + lp->ndim;
  }

  // find inplace from input arrays
  if (k == 0 && NDF_TEST(nf, NDF_INPLACE)) {
    v = ndloop_find_inplace(nf, lp, type, na_ndim, na_shape, args);
  }
  if (!RTEST(v)) {
    // new object
    v = nary_new(type, na_ndim, na_shape);
    flag = NDL_WRITE;
  }

  j = lp->nin + k;
  LARG(lp, j).ndim = nd = nf->aout[k].dim;
  ndloop_set_stepidx(lp, j, v, dim_map, flag);
  if (nd > 0) {
    LARG(lp, j).shape = nf->aout[k].shape;
  }

  return v;
}

static VALUE ndloop_set_output(ndfunc_t* nf, na_md_loop_t* lp, VALUE args) {
  int i, j, k, idx;
  volatile VALUE v, t, results;
  VALUE init;

  int max_nd = lp->ndim + lp->user.ndim;

  // output results
  results = rb_ary_new2(nf->nout);

  for (k = 0; k < nf->nout; k++) {
    t = nf->aout[k].type;
    t = ndloop_get_arg_type(nf, args, t);

    if (rb_obj_is_kind_of(t, rb_cClass)) {
      if (RTEST(rb_class_inherited_p(t, cNArray))) {
        // NArray
        v = ndloop_set_output_narray(nf, lp, k, t, args);
        rb_ary_push(results, v);
      } else if (RTEST(rb_class_inherited_p(t, rb_cArray))) {
        // Ruby Array
        j = lp->nin + k;
        for (i = 0; i <= max_nd; i++) {
          LITER(lp, i, j).step = sizeof(VALUE);
        }
        LARG(lp, j).value = t;
        LARG(lp, j).elmsz = sizeof(VALUE);
      } else {
        rb_raise(rb_eRuntimeError, "ndloop_set_output: invalid for type");
      }
    }
  }

  // initialilzer
  k = lp->init_aidx;
  if (k > -1) {
    idx = nf->ain[k].dim;
    v = RARRAY_AREF(results, idx);
    init = RARRAY_AREF(args, k);
    na_store(v, init);
  }

  return results;
}

static void ndfunc_contract_loop(na_md_loop_t* lp) {
  int i, j, k, success, cnt = 0;
  int red0, redi;

  redi = na_test_reduce(lp->reduce, 0);

  // for (i=0; i<lp->ndim; i++) {
  // }

  for (i = 1; i < lp->ndim; i++) {
    red0 = redi;
    redi = na_test_reduce(lp->reduce, i);
    if (red0 != redi) {
      continue;
    }
    success = 1;
    for (j = 0; j < lp->narg; j++) {
      if (!(LITER(lp, i, j).idx == NULL && LITER(lp, i - 1, j).idx == NULL &&
            LITER(lp, i - 1, j).step == LITER(lp, i, j).step * (ssize_t)(lp->n[i]))) {
        success = 0;
        break;
      }
    }
    if (success) {
      //        i-1,i, i,lp->n[i], i-1,lp->n[i-1]);
      //  contract (i-1)-th and i-th dimension
      lp->n[i] *= lp->n[i - 1];
      // shift dimensions
      for (k = i - 1; k > cnt; k--) {
        lp->n[k] = lp->n[k - 1];
      }
      for (; k >= 0; k--) {
        lp->n[k] = 1;
      }
      for (j = 0; j < lp->narg; j++) {
        for (k = i - 1; k > cnt; k--) {
          LITER(lp, k, j) = LITER(lp, k - 1, j);
        }
      }
      if (redi) {
        lp->reduce_dim--;
      }
      cnt++;
    }
  }
  if (cnt > 0) {
    for (j = 0; j < lp->narg; j++) {
      LITER(lp, cnt, j).pos = LITER(lp, 0, j).pos;
      lp->xargs[j].iter = &LITER(lp, cnt, j);
    }
    lp->n = &(lp->n[cnt]);
    lp->ndim -= cnt;
  }
}

static void ndfunc_set_user_loop(ndfunc_t* nf, na_md_loop_t* lp) {
  int j, ud = 0;

  if (lp->reduce_dim > 0) {
    ud = lp->reduce_dim;
  } else if (lp->ndim > 0 && NDF_TEST(nf, NDF_HAS_LOOP)) {
    ud = 1;
  } else {
    goto skip_ud;
  }
  if (ud > lp->ndim) {
    rb_bug("Reduce-dimension is larger than loop-dimension");
  }
  // increase user dimension
  lp->user.ndim += ud;
  lp->ndim -= ud;
  for (j = 0; j < lp->narg; j++) {
    if (LARG(lp, j).shape) {
      rb_bug("HAS_LOOP or reduce-dimension=%d conflicts with user-dimension", lp->reduce_dim);
    }
    LARG(lp, j).ndim += ud;
    LARG(lp, j).shape = &(lp->n[lp->ndim]);
  }

skip_ud:
  lp->user.n = &(lp->n[lp->ndim]);
  for (j = 0; j < lp->narg; j++) {
    LARG(lp, j).iter = &LITER(lp, lp->ndim, j);
  }
}

static void ndfunc_set_bufcp(na_md_loop_t* lp, unsigned int loop_spec) {
  unsigned int f;
  int i, j;
  int nd, ndim;
  bool zero_step;
  ssize_t n, sz, elmsz, stride, n_total; //, last_step;
  size_t* buf_shape;
  na_loop_iter_t *buf_iter = NULL, *src_iter;

  // if (loop_spec==0) return;

  n_total = lp->user.n[0];
  for (i = 1; i < lp->user.ndim; i++) {
    n_total *= lp->user.n[i];
  }

  // for (j=0; j<lp->nin; j++) {
  for (j = 0; j < lp->narg; j++) {
    // ndim = nd = lp->user.ndim;
    ndim = nd = LARG(lp, j).ndim;
    sz = elmsz = LARG(lp, j).elmsz;
    src_iter = LARG(lp, j).iter;
    // last_step = src_iter[ndim-1].step;
    f = 0;
    zero_step = 1;
    for (i = ndim; i > 0;) {
      i--;
      if (LARG(lp, j).shape) {
        n = LARG(lp, j).shape[i];
      } else {
        n = lp->user.n[i];
      }
      stride = sz * n;
      if (src_iter[i].idx) {
        f |= 2; // INDEX LOOP
        zero_step = 0;
      } else {
        if (src_iter[i].step != sz) {
          f |= 1; // NON_CONTIGUOUS LOOP
        } else {
          // CONTIGUOUS LOOP
          if (i == ndim - 1) { // contract if last dimension
            ndim = i;
            elmsz = stride;
          }
        }
        if (src_iter[i].step != 0) {
          zero_step = 0;
        }
      }
      sz = stride;
    }

    if (zero_step) {
      // no buffer needed
      continue;
    }

    // should check flatten-able loop to avoid buffering

    // over loop_spec or reduce_loop is not contiguous
    if (f & loop_spec || (lp->reduce_dim > 1 && ndim > 0)) {
      buf_iter = ALLOC_N(na_loop_iter_t, nd + 3);
      buf_shape = ALLOC_N(size_t, nd);
      buf_iter[nd].pos = 0;
      buf_iter[nd].step = 0;
      buf_iter[nd].idx = NULL;
      sz = LARG(lp, j).elmsz;
      // last_step = sz;
      for (i = nd; i > 0;) {
        i--;
        buf_iter[i].pos = 0;
        buf_iter[i].step = sz;
        buf_iter[i].idx = NULL;
        // n = lp->user.n[i];
        n = LARG(lp, j).shape[i];
        buf_shape[i] = n;
        sz *= n;
      }
      LBUFCP(lp, j) = ALLOC(na_buffer_copy_t);
      LBUFCP(lp, j)->ndim = ndim;
      LBUFCP(lp, j)->elmsz = elmsz;
      LBUFCP(lp, j)->n = buf_shape;
      LBUFCP(lp, j)->src_iter = src_iter;
      LBUFCP(lp, j)->buf_iter = buf_iter;
      LARG(lp, j).iter = buf_iter;
      LBUFCP(lp, j)->src_ptr = LARG(lp, j).ptr;
      LARG(lp, j).ptr = LBUFCP(lp, j)->buf_ptr = xmalloc(sz);
    }
  }

#if 0
    for (j=0; j<lp->narg; j++) {
        ndim = lp->user.ndim;
        src_iter = LARG(lp,j).iter;
        last_step = src_iter[ndim-1].step;
        if (lp->reduce_dim>1) {
            buf_iter = ALLOC_N(na_loop_iter_t,2);
            buf_iter[0].pos = LARG(lp,j).iter[0].pos;
            buf_iter[0].step = last_step;
            buf_iter[0].idx = NULL;
            buf_iter[1].pos = 0;
            buf_iter[1].step = 0;
            buf_iter[1].idx = NULL;
            LARG(lp,j).iter = buf_iter;
            lp->xargs[j].free_user_iter = 1;
        }
    }
#endif

  // flatten reduce dimensions
  if (lp->reduce_dim > 1) {
#if 1
    for (j = 0; j < lp->narg; j++) {
      ndim = lp->user.ndim;
      LARG(lp, j).iter[0].step = LARG(lp, j).iter[ndim - 1].step;
      LARG(lp, j).iter[0].idx = NULL;
    }
#endif
    lp->user.n[0] = n_total;
    lp->user.ndim = 1;
  }
}

static void ndloop_copy_to_buffer(na_buffer_copy_t* lp) {
  size_t* c;
  char *src, *buf;
  int i;
  int nd = lp->ndim;
  size_t elmsz = lp->elmsz;
  size_t buf_pos = 0;
  DBG(size_t j);

  DBG(printf("<to buf> ["));
  // zero-dimension
  if (nd == 0) {
    src = lp->src_ptr + LITER_SRC(lp, 0).pos;
    buf = lp->buf_ptr;
    memcpy(buf, src, elmsz);
    DBG(for (j = 0; j < elmsz / 8; j++) { printf("%g,", ((double*)(buf))[j]); });
    goto loop_end;
  }
  // initialize loop counter
  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;
  // loop body
  for (i = 0;;) {
    // i-th dimension
    for (; i < nd; i++) {
      if (LITER_SRC(lp, i).idx) {
        LITER_SRC(lp, i + 1).pos = LITER_SRC(lp, i).pos + LITER_SRC(lp, i).idx[c[i]];
      } else {
        LITER_SRC(lp, i + 1).pos = LITER_SRC(lp, i).pos + LITER_SRC(lp, i).step * c[i];
      }
    }
    src = lp->src_ptr + LITER_SRC(lp, nd).pos;
    buf = lp->buf_ptr + buf_pos;
    memcpy(buf, src, elmsz);
    DBG(for (j = 0; j < elmsz / 8; j++) { printf("%g,", ((double*)(buf))[j]); });
    buf_pos += elmsz;
    // count up
    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:;
  DBG(printf("]\n"));
}

static void ndloop_copy_from_buffer(na_buffer_copy_t* lp) {
  size_t* c;
  char *src, *buf;
  int i;
  int nd = lp->ndim;
  size_t elmsz = lp->elmsz;
  size_t buf_pos = 0;
  DBG(size_t j);

  DBG(printf("<from buf> ["));
  // zero-dimension
  if (nd == 0) {
    src = lp->src_ptr + LITER_SRC(lp, 0).pos;
    buf = lp->buf_ptr;
    memcpy(src, buf, elmsz);
    DBG(for (j = 0; j < elmsz / 8; j++) { printf("%g,", ((double*)(src))[j]); });
    goto loop_end;
  }
  // initialize loop counter
  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;
  // loop body
  for (i = 0;;) {
    // i-th dimension
    for (; i < nd; i++) {
      if (LITER_SRC(lp, i).idx) {
        LITER_SRC(lp, i + 1).pos = LITER_SRC(lp, i).pos + LITER_SRC(lp, i).idx[c[i]];
      } else {
        LITER_SRC(lp, i + 1).pos = LITER_SRC(lp, i).pos + LITER_SRC(lp, i).step * c[i];
      }
    }
    src = lp->src_ptr + LITER_SRC(lp, nd).pos;
    buf = lp->buf_ptr + buf_pos;
    memcpy(src, buf, elmsz);
    DBG(for (j = 0; j < elmsz / 8; j++) { printf("%g,", ((double*)(src))[j]); });
    buf_pos += elmsz;
    // count up
    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:
  DBG(printf("]\n"));
}

static void ndfunc_write_back(ndfunc_t* nf, na_md_loop_t* lp, VALUE orig_args, VALUE results) {
  VALUE src, dst;

  if (lp->writeback >= 0) {
    dst = RARRAY_AREF(orig_args, lp->writeback);
    src = RARRAY_AREF(results, 0);
    na_store(dst, src);
    RARRAY_ASET(results, 0, dst);
  }
}

static VALUE ndloop_extract(VALUE results, ndfunc_t* nf) {
  long n, i;
  VALUE x, y;
  narray_t* na;

  // extract result objects
  switch (nf->nout) {
  case 0:
    return Qnil;
  case 1:
    x = RARRAY_AREF(results, 0);
    if (NDF_TEST(nf, NDF_EXTRACT)) {
      if (IsNArray(x)) {
        GetNArray(x, na);
        if (NA_NDIM(na) == 0) {
          x = rb_funcall(x, id_extract, 0);
        }
      }
    }
    return x;
  }
  if (NDF_TEST(nf, NDF_EXTRACT)) {
    n = RARRAY_LEN(results);
    for (i = 0; i < n; i++) {
      x = RARRAY_AREF(results, i);
      if (IsNArray(x)) {
        GetNArray(x, na);
        if (NA_NDIM(na) == 0) {
          y = rb_funcall(x, id_extract, 0);
          RARRAY_ASET(results, i, y);
        }
      }
    }
  }
  return results;
}

static void loop_narray(ndfunc_t* nf, na_md_loop_t* lp);

static VALUE ndloop_run(VALUE vlp) {
  unsigned int loop_spec;
  volatile VALUE args, orig_args, results;
  na_md_loop_t* lp = (na_md_loop_t*)(vlp);
  ndfunc_t* nf;

  orig_args = lp->vargs;
  nf = lp->ndfunc;

  args = rb_obj_dup(orig_args);

  // setup ndloop iterator with arguments
  ndloop_init_args(nf, lp, args);
  results = ndloop_set_output(nf, lp, args);

  // if (na_debug_flag) {
  //     print_ndloop(lp);
  // }

  // contract loop
  if (lp->loop_func == loop_narray) {
    ndfunc_contract_loop(lp);
    // if (na_debug_flag) {
    //     print_ndloop(lp);
    // }
  }

  // setup objects in which results are stored
  ndfunc_set_user_loop(nf, lp);

  // setup buffering during loop
  if (lp->loop_func == loop_narray) {
    loop_spec = ndloop_func_loop_spec(nf, lp->user.ndim);
    ndfunc_set_bufcp(lp, loop_spec);
  }
  if (na_debug_flag) {
    printf("-- ndfunc_set_bufcp --\n");
    print_ndloop(lp);
  }

  // loop
  (*(lp->loop_func))(nf, lp);

  // if (na_debug_flag) {
  //     print_ndloop(lp);
  // }

  if (RTEST(lp->user.err_type)) {
    rb_raise(lp->user.err_type, "error in NArray operation");
  }

  // write-back will be placed here
  ndfunc_write_back(nf, lp, orig_args, results);

  // extract result objects
  return ndloop_extract(results, nf);
}

// ---------------------------------------------------------------------------

static void loop_narray(ndfunc_t* nf, na_md_loop_t* lp) {
  size_t* c;
  int i, j;
  int nd = lp->ndim;

  if (nd < 0) {
    rb_bug("bug? lp->ndim = %d\n", lp->ndim);
  }

  if (nd == 0) {
    for (j = 0; j < lp->nin; j++) {
      if (lp->xargs[j].bufcp) {
        ndloop_copy_to_buffer(lp->xargs[j].bufcp);
      }
    }
    (*(nf->func))(&(lp->user));
    for (j = 0; j < lp->narg; j++) {
      if (lp->xargs[j].bufcp && (lp->xargs[j].flag & NDL_WRITE)) {
        //  copy data to work buffer
        ndloop_copy_from_buffer(lp->xargs[j].bufcp);
      }
    }
    return;
  }

  // initialize loop counter
  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;

  // loop body
  for (i = 0;;) {
    // i-th dimension
    for (; i < nd; i++) {
      // j-th argument
      for (j = 0; j < lp->narg; j++) {
        if (LITER(lp, i, j).idx) {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).idx[c[i]];
        } else {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).step * c[i];
        }
      }
    }
    for (j = 0; j < lp->nin; j++) {
      if (lp->xargs[j].bufcp) {
        // copy data to work buffer
        // cp lp->iter[j][nd..*] to lp->user.args[j].iter[0..*]
        ndloop_copy_to_buffer(lp->xargs[j].bufcp);
      }
    }
    (*(nf->func))(&(lp->user));
    for (j = 0; j < lp->narg; j++) {
      if (lp->xargs[j].bufcp && (lp->xargs[j].flag & NDL_WRITE)) {
        // copy data to work buffer
        ndloop_copy_from_buffer(lp->xargs[j].bufcp);
      }
    }
    if (RTEST(lp->user.err_type)) {
      return;
    }

    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:;
}

static VALUE na_ndloop_main(ndfunc_t* nf, VALUE args, void* opt_ptr) {
  unsigned int copy_flag;
  na_md_loop_t lp;

  if (na_debug_flag) print_ndfunc(nf);

  // cast arguments to NArray
  copy_flag = ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, nf, args, opt_ptr, copy_flag, loop_narray);

  return rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);
}

VALUE
#ifdef HAVE_STDARG_PROTOTYPES
na_ndloop(ndfunc_t* nf, int argc, ...)
#else
na_ndloop(nf, argc, va_alist) ndfunc_t* nf;
int argc;
va_dcl
#endif
{
  va_list ar;

  int i;
  VALUE* argv;
  volatile VALUE args;

  argv = ALLOCA_N(VALUE, argc);

  va_init_list(ar, argc);
  for (i = 0; i < argc; i++) {
    argv[i] = va_arg(ar, VALUE);
  }
  va_end(ar);

  args = rb_ary_new4(argc, argv);

  return na_ndloop_main(nf, args, NULL);
}

VALUE
na_ndloop2(ndfunc_t* nf, VALUE args) {
  return na_ndloop_main(nf, args, NULL);
}

VALUE
#ifdef HAVE_STDARG_PROTOTYPES
na_ndloop3(ndfunc_t* nf, void* ptr, int argc, ...)
#else
na_ndloop3(nf, ptr, argc, va_alist) ndfunc_t* nf;
void* ptr;
int argc;
va_dcl
#endif
{
  va_list ar;

  int i;
  VALUE* argv;
  volatile VALUE args;

  argv = ALLOCA_N(VALUE, argc);

  va_init_list(ar, argc);
  for (i = 0; i < argc; i++) {
    argv[i] = va_arg(ar, VALUE);
  }
  va_end(ar);

  args = rb_ary_new4(argc, argv);

  return na_ndloop_main(nf, args, ptr);
}

VALUE
na_ndloop4(ndfunc_t* nf, void* ptr, VALUE args) {
  return na_ndloop_main(nf, args, ptr);
}

//----------------------------------------------------------------------

VALUE
na_info_str(VALUE ary) {
  int nd, i;
  char tmp[32];
  VALUE buf;
  narray_t* na;

  GetNArray(ary, na);
  nd = na->ndim;

  buf = rb_str_new2(rb_class2name(rb_obj_class(ary)));
  if (NA_TYPE(na) == NARRAY_VIEW_T) {
    rb_str_cat(buf, "(view)", 6);
  }
  rb_str_cat(buf, "#shape=[", 8);
  if (nd > 0) {
    for (i = 0;;) {
      sprintf(tmp, "%" SZF "u", na->shape[i]);
      rb_str_cat2(buf, tmp);
      if (++i == nd) break;
      rb_str_cat(buf, ",", 1);
    }
  }
  rb_str_cat(buf, "]", 1);
  return buf;
}

//----------------------------------------------------------------------

#define ncol numo_na_inspect_cols
#define nrow numo_na_inspect_rows
extern int ncol, nrow;

static void loop_inspect(ndfunc_t* nf, na_md_loop_t* lp) {
  int nd, i, ii;
  size_t* c;
  int col = 0, row = 0;
  long len;
  VALUE str;
  na_text_func_t func = (na_text_func_t)(nf->func);
  VALUE buf, opt;

  nd = lp->ndim;
  buf = lp->loop_opt;
  // opt = *(VALUE*)(lp->user.opt_ptr);
  opt = lp->user.option;

  for (i = 0; i < nd; i++) {
    if (lp->n[i] == 0) {
      rb_str_cat(buf, "[]", 2);
      return;
    }
  }

  rb_str_cat(buf, "\n", 1);

  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;

  if (nd > 0) {
    rb_str_cat(buf, "[", 1);
  } else {
    rb_str_cat(buf, "", 0);
  }

  col = nd * 2;
  for (i = 0;;) {
    if (i < nd - 1) {
      for (ii = 0; ii < i; ii++) rb_str_cat(buf, " ", 1);
      for (; ii < nd - 1; ii++) rb_str_cat(buf, "[", 1);
    }
    for (; i < nd; i++) {
      if (LITER(lp, i, 0).idx) {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).idx[c[i]];
      } else {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).step * c[i];
      }
    }
    str = (*func)(LARG(lp, 0).ptr, LITER(lp, i, 0).pos, opt);

    len = RSTRING_LEN(str) + 2;
    if (ncol > 0 && col + len > ncol - 3) {
      rb_str_cat(buf, "...", 3);
      c[i - 1] = lp->n[i - 1];
    } else {
      rb_str_append(buf, str);
      col += len;
    }
    for (;;) {
      if (i == 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      rb_str_cat(buf, "]", 1);
      c[i] = 0;
    }
    // line_break:
    rb_str_cat(buf, ", ", 2);
    if (i < nd - 1) {
      rb_str_cat(buf, "\n ", 2);
      col = nd * 2;
      row++;
      if (row == nrow) {
        rb_str_cat(buf, "...", 3);
        goto loop_end;
      }
    }
  }
loop_end:;
}

VALUE
na_ndloop_inspect(VALUE nary, na_text_func_t func, VALUE opt) {
  volatile VALUE args;
  na_md_loop_t lp;
  VALUE buf;
  ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { sym_loop_opt }, { sym_option } };
  ndfunc_t nf = { (na_iter_func_t)func, NO_LOOP, 3, 0, ain, 0 };
  // nf = ndfunc_alloc(NULL, NO_LOOP, 1, 0, Qnil);

  buf = na_info_str(nary);

  if (na_get_pointer(nary) == NULL) {
    return rb_str_cat(buf, "(empty)", 7);
  }

  // rb_p(args);
  // if (na_debug_flag) print_ndfunc(&nf);

  args = rb_ary_new3(3, nary, buf, opt);

  // cast arguments to NArray
  // ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, &nf, args, NULL, 0, loop_inspect);

  rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);

  return buf;
}

//----------------------------------------------------------------------

static void loop_store_subnarray(ndfunc_t* nf, na_md_loop_t* lp, int i0, size_t* c, VALUE a) {
  int nd = lp->ndim;
  int i, j;
  narray_t* na;
  int* dim_map;
  VALUE a_type;

  a_type = rb_obj_class(LARG(lp, 0).value);
  if (rb_obj_class(a) != a_type) {
    a = rb_funcall(a_type, id_cast, 1, a);
  }
  GetNArray(a, na);
  if (na->ndim != nd - i0 + 1) {
    rb_raise(
      nary_eShapeError,
      "mismatched dimension of sub-narray: "
      "nd_src=%d, nd_dst=%d",
      na->ndim, nd - i0 + 1
    );
  }
  dim_map = ALLOCA_N(int, na->ndim);
  for (i = 0; i < na->ndim; i++) {
    dim_map[i] = lp->trans_map[i + i0];
  }
  ndloop_set_stepidx(lp, 1, a, dim_map, NDL_READ);
  LARG(lp, 1).shape = &(na->shape[na->ndim - 1]);

  // loop body
  for (i = i0;;) {
    LARG(lp, 1).value = Qtrue;
    for (; i < nd; i++) {
      for (j = 0; j < 2; j++) {
        if (LITER(lp, i, j).idx) {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).idx[c[i]];
        } else {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).step * c[i];
        }
      }
      if (c[i] >= na->shape[i - i0]) {
        LARG(lp, 1).value = Qfalse;
      }
    }

    (*(nf->func))(&(lp->user));

    for (;;) {
      if (i <= i0) goto loop_end;
      i--;
      c[i]++;
      if (c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:
  LARG(lp, 1).ptr = NULL;
}

static void loop_store_rarray(ndfunc_t* nf, na_md_loop_t* lp) {
  size_t* c;
  int i;
  VALUE* a;
  int nd = lp->ndim;

  // counter
  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;

  // array at each dimension
  a = ALLOCA_N(VALUE, nd + 1);
  a[0] = LARG(lp, 1).value;

  // print_ndloop(lp);

  // loop body
  for (i = 0;;) {
    for (; i < nd; i++) {
      if (LITER(lp, i, 0).idx) {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).idx[c[i]];
      } else {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).step * c[i];
      }
      if (TYPE(a[i]) == T_ARRAY) {
        if (c[i] < (size_t)RARRAY_LEN(a[i])) {
          a[i + 1] = RARRAY_AREF(a[i], c[i]);
        } else {
          a[i + 1] = Qnil;
        }
      } else if (IsNArray(a[i])) {
        loop_store_subnarray(nf, lp, i, c, a[i]);
        goto loop_next;
      } else {
        if (c[i] == 0) {
          a[i + 1] = a[i];
        } else {
          a[i + 1] = Qnil;
        }
      }
    }

    if (IsNArray(a[i])) {
      loop_store_subnarray(nf, lp, i, c, a[i]);
    } else {
      LARG(lp, 1).value = a[i];
      (*(nf->func))(&(lp->user));
    }

  loop_next:
    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      c[i]++;
      if (c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:;
}

VALUE
na_ndloop_store_rarray(ndfunc_t* nf, VALUE nary, VALUE rary) {
  na_md_loop_t lp;
  VALUE args;

  // rb_p(args);
  if (na_debug_flag) print_ndfunc(nf);

  args = rb_assoc_new(nary, rary);

  // cast arguments to NArray
  // ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, nf, args, NULL, 0, loop_store_rarray);

  return rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);
}

VALUE
na_ndloop_store_rarray2(ndfunc_t* nf, VALUE nary, VALUE rary, VALUE opt) {
  na_md_loop_t lp;
  VALUE args;

  // rb_p(args);
  if (na_debug_flag) print_ndfunc(nf);

  // args = rb_assoc_new(rary,nary);
  args = rb_ary_new3(3, nary, rary, opt);

  // cast arguments to NArray
  // ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, nf, args, NULL, 0, loop_store_rarray);

  return rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);
}

//----------------------------------------------------------------------

static void loop_narray_to_rarray(ndfunc_t* nf, na_md_loop_t* lp) {
  size_t* c;
  int i;
  // int nargs = nf->narg + nf->nres;
  int nd = lp->ndim;
  VALUE* a;
  volatile VALUE a0;

  // alloc counter
  c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;
  // c[i]=1; // for zero-dim

  a = ALLOCA_N(VALUE, nd + 1);
  a[0] = a0 = lp->loop_opt;

  // loop body
  for (i = 0;;) {
    for (; i < nd; i++) {
      if (LITER(lp, i, 0).idx) {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).idx[c[i]];
      } else {
        LITER(lp, i + 1, 0).pos = LITER(lp, i, 0).pos + LITER(lp, i, 0).step * c[i];
      }
      if (c[i] == 0) {
        a[i + 1] = rb_ary_new2(lp->n[i]);
        rb_ary_push(a[i], a[i + 1]);
      }
    }

    // lp->user.info = a[i];
    LARG(lp, 1).value = a[i];
    (*(nf->func))(&(lp->user));

    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:;
}

VALUE
na_ndloop_cast_narray_to_rarray(ndfunc_t* nf, VALUE nary, VALUE fmt) {
  na_md_loop_t lp;
  VALUE args, a0;

  // rb_p(args);
  if (na_debug_flag) print_ndfunc(nf);

  a0 = rb_ary_new();
  args = rb_ary_new3(3, nary, a0, fmt);

  // cast arguments to NArray
  // ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, nf, args, NULL, 0, loop_narray_to_rarray);

  rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);
  return RARRAY_AREF(a0, 0);
}

//----------------------------------------------------------------------

static void loop_narray_with_index(ndfunc_t* nf, na_md_loop_t* lp) {
  size_t* c;
  int i, j;
  int nd = lp->ndim;

  if (nd < 0) {
    rb_bug("bug? lp->ndim = %d\n", lp->ndim);
  }
  if (lp->n[0] == 0) { // empty array
    return;
  }

  // pass total ndim to iterator
  lp->user.ndim += nd;

  // alloc counter
  lp->user.opt_ptr = c = ALLOCA_N(size_t, nd + 1);
  for (i = 0; i <= nd; i++) c[i] = 0;

  // loop body
  for (i = 0;;) {
    for (; i < nd; i++) {
      // j-th argument
      for (j = 0; j < lp->narg; j++) {
        if (LITER(lp, i, j).idx) {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).idx[c[i]];
        } else {
          LITER(lp, i + 1, j).pos = LITER(lp, i, j).pos + LITER(lp, i, j).step * c[i];
        }
      }
    }

    (*(nf->func))(&(lp->user));

    for (;;) {
      if (i <= 0) goto loop_end;
      i--;
      if (++c[i] < lp->n[i]) break;
      c[i] = 0;
    }
  }
loop_end:;
}

VALUE
#ifdef HAVE_STDARG_PROTOTYPES
na_ndloop_with_index(ndfunc_t* nf, int argc, ...)
#else
na_ndloop_with_index(nf, argc, va_alist) ndfunc_t* nf;
int argc;
va_dcl
#endif
{
  va_list ar;

  int i;
  VALUE* argv;
  volatile VALUE args;
  na_md_loop_t lp;

  argv = ALLOCA_N(VALUE, argc);

  va_init_list(ar, argc);
  for (i = 0; i < argc; i++) {
    argv[i] = va_arg(ar, VALUE);
  }
  va_end(ar);

  args = rb_ary_new4(argc, argv);

  // return na_ndloop_main(nf, args, NULL);
  if (na_debug_flag) print_ndfunc(nf);

  // cast arguments to NArray
  // copy_flag = ndloop_cast_args(nf, args);

  // allocate ndloop struct
  ndloop_alloc(&lp, nf, args, 0, 0, loop_narray_with_index);

  return rb_ensure(ndloop_run, (VALUE)&lp, ndloop_release, (VALUE)&lp);
}

void Init_nary_ndloop(void) {
  id_cast = rb_intern("cast");
  id_extract = rb_intern("extract");
}
