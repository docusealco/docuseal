#ifndef NUMO_NARRAY_MH_ARGMAX_H
#define NUMO_NARRAY_MH_ARGMAX_H 1

#define DEF_NARRAY_FLT_ARGMAX_METHOD_FUNC(tDType)                                              \
  static void iter_##tDType##_argmax_arg64(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int64_t*)o_ptr = (int64_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_argmax_arg32(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int32_t*)o_ptr = (int32_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_argmax_arg64_nan(na_loop_t* const lp) {                          \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index_nan(n, d_ptr, d_step);                                                   \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int64_t*)o_ptr = (int64_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_argmax_arg32_nan(na_loop_t* const lp) {                          \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index_nan(n, d_ptr, d_step);                                                   \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int32_t*)o_ptr = (int32_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_argmax(int argc, VALUE* argv, VALUE self) {                            \
    narray_t* na;                                                                              \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[2] = { { Qnil, 0 }, { sym_reduce, 0 } };                               \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 2, 1, ain, aout };    \
                                                                                               \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
                                                                                               \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      aout[0].type = numo_cInt64;                                                              \
      ndf.func = iter_##tDType##_argmax_arg64;                                                 \
      reduce =                                                                                 \
        na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_argmax_arg64_nan);     \
    } else {                                                                                   \
      aout[0].type = numo_cInt32;                                                              \
      ndf.func = iter_##tDType##_argmax_arg32;                                                 \
      reduce =                                                                                 \
        na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_argmax_arg32_nan);     \
    }                                                                                          \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#define DEF_NARRAY_INT_ARGMAX_METHOD_FUNC(tDType)                                              \
  static void iter_##tDType##_argmax_arg64(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int64_t*)o_ptr = (int64_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_argmax_arg32(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_max_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    o_ptr = NDL_PTR(lp, 1);                                                                    \
    *(int32_t*)o_ptr = (int32_t)idx;                                                           \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_argmax(int argc, VALUE* argv, VALUE self) {                            \
    narray_t* na;                                                                              \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[2] = { { Qnil, 0 }, { sym_reduce, 0 } };                               \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 2, 1, ain, aout };    \
                                                                                               \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
                                                                                               \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      aout[0].type = numo_cInt64;                                                              \
      ndf.func = iter_##tDType##_argmax_arg64;                                                 \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    } else {                                                                                   \
      aout[0].type = numo_cInt32;                                                              \
      ndf.func = iter_##tDType##_argmax_arg32;                                                 \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    }                                                                                          \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#endif /* NUMO_NARRAY_MH_ARGMAX_H */
