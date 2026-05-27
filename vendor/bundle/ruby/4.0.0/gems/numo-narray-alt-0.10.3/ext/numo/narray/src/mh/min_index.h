#ifndef NUMO_NARRAY_MH_MIN_INDEX_H
#define NUMO_NARRAY_MH_MIN_INDEX_H 1

#define DEF_NARRAY_FLT_MIN_INDEX_METHOD_FUNC(tDType)                                           \
  static void iter_##tDType##_min_index_index64(na_loop_t* const lp) {                         \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_min_index_index32(na_loop_t* const lp) {                         \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_min_index_index64_nan(na_loop_t* const lp) {                     \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index_nan(n, d_ptr, d_step);                                                   \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_min_index_index32_nan(na_loop_t* const lp) {                     \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index_nan(n, d_ptr, d_step);                                                   \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_min_index(int argc, VALUE* argv, VALUE self) {                         \
    narray_t* na;                                                                              \
    VALUE idx;                                                                                 \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { Qnil, 0 }, { sym_reduce, 0 } };                  \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 3, 1, ain, aout };    \
                                                                                               \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
                                                                                               \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      aout[0].type = numo_cInt64;                                                              \
      idx = nary_new(numo_cInt64, na->ndim, na->shape);                                        \
      ndf.func = iter_##tDType##_min_index_index64;                                            \
      reduce = na_reduce_dimension(                                                            \
        argc, argv, 1, &self, &ndf, iter_##tDType##_min_index_index64_nan                      \
      );                                                                                       \
    } else {                                                                                   \
      aout[0].type = numo_cInt32;                                                              \
      idx = nary_new(numo_cInt32, na->ndim, na->shape);                                        \
      ndf.func = iter_##tDType##_min_index_index32;                                            \
      reduce = na_reduce_dimension(                                                            \
        argc, argv, 1, &self, &ndf, iter_##tDType##_min_index_index32_nan                      \
      );                                                                                       \
    }                                                                                          \
                                                                                               \
    rb_funcall(idx, rb_intern("seq"), 0);                                                      \
                                                                                               \
    return na_ndloop(&ndf, 3, self, idx, reduce);                                              \
  }

#define DEF_NARRAY_INT_MIN_INDEX_METHOD_FUNC(tDType)                                           \
  static void iter_##tDType##_min_index_index64(na_loop_t* const lp) {                         \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_min_index_index32(na_loop_t* const lp) {                         \
    size_t n;                                                                                  \
    size_t idx;                                                                                \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
                                                                                               \
    idx = f_min_index(n, d_ptr, d_step);                                                       \
                                                                                               \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    o_ptr = NDL_PTR(lp, 2);                                                                    \
    *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                      \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_min_index(int argc, VALUE* argv, VALUE self) {                         \
    narray_t* na;                                                                              \
    VALUE idx;                                                                                 \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { Qnil, 0 }, { sym_reduce, 0 } };                  \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 3, 1, ain, aout };    \
                                                                                               \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
                                                                                               \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      aout[0].type = numo_cInt64;                                                              \
      idx = nary_new(numo_cInt64, na->ndim, na->shape);                                        \
      ndf.func = iter_##tDType##_min_index_index64;                                            \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    } else {                                                                                   \
      aout[0].type = numo_cInt32;                                                              \
      idx = nary_new(numo_cInt32, na->ndim, na->shape);                                        \
      ndf.func = iter_##tDType##_min_index_index32;                                            \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    }                                                                                          \
                                                                                               \
    rb_funcall(idx, rb_intern("seq"), 0);                                                      \
                                                                                               \
    return na_ndloop(&ndf, 3, self, idx, reduce);                                              \
  }

#endif /* NUMO_NARRAY_MH_MIN_INDEX_H */
