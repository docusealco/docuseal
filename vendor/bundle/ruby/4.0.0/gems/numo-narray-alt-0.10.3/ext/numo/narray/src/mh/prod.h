#ifndef NUMO_NARRAY_MH_PROD_H
#define NUMO_NARRAY_MH_PROD_H 1

#define DEF_NARRAY_FLT_PROD_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_prod(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    p2 = NDL_PTR(lp, 1);                                                                       \
                                                                                               \
    *(tDType*)p2 = f_prod(n, p1, s1);                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_prod_nan(na_loop_t* const lp) {                                  \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    p2 = NDL_PTR(lp, 1);                                                                       \
                                                                                               \
    *(tDType*)p2 = f_prod_nan(n, p1, s1);                                                      \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_prod(int argc, VALUE* argv, VALUE self) {                              \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_prod, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE, 2, 1, ain, aout                 \
    };                                                                                         \
    VALUE reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_prod_nan);  \
    VALUE v = na_ndloop(&ndf, 2, self, reduce);                                                \
                                                                                               \
    return rb_funcall(v, rb_intern("extract"), 0);                                             \
  }

#define DEF_NARRAY_INT_PROD_METHOD_FUNC(tDType, tNAryClass, tRtDType, tRtNAryClass)            \
  static void iter_##tDType##_prod(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    p2 = NDL_PTR(lp, 1);                                                                       \
                                                                                               \
    *(tRtDType*)p2 = f_prod(n, p1, s1);                                                        \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_prod(int argc, VALUE* argv, VALUE self) {                              \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tRtNAryClass, 0 } };                                        \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_prod, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE, 2, 1, ain, aout                 \
    };                                                                                         \
    VALUE reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                         \
    VALUE v = na_ndloop(&ndf, 2, self, reduce);                                                \
                                                                                               \
    return rb_funcall(v, rb_intern("extract"), 0);                                             \
  }

#endif /* NUMO_NARRAY_MH_PROD_H */
