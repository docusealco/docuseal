#ifndef NUMO_NARRAY_MH_KAHAN_SUM_H
#define NUMO_NARRAY_MH_KAHAN_SUM_H 1

#define DEF_NARRAY_KAHAN_SUM_METHOD_FUNC(tDType, tNAryClass)                                   \
  static void iter_##tDType##_kahan_sum(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    p2 = NDL_PTR(lp, 1);                                                                       \
    *(tDType*)p2 = f_kahan_sum(n, p1, s1);                                                     \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_kahan_sum_nan(na_loop_t* const lp) {                             \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    p2 = NDL_PTR(lp, 1);                                                                       \
    *(tDType*)p2 = f_kahan_sum_nan(n, p1, s1);                                                 \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_kahan_sum(int argc, VALUE* argv, VALUE self) {                         \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_kahan_sum, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE, 2, 1, ain, aout            \
    };                                                                                         \
    VALUE reduce =                                                                             \
      na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_kahan_sum_nan);          \
    VALUE v = na_ndloop(&ndf, 2, self, reduce);                                                \
    return rb_funcall(v, rb_intern("extract"), 0);                                             \
  }

#endif /* NUMO_NARRAY_MH_KAHAN_SUM_H */
