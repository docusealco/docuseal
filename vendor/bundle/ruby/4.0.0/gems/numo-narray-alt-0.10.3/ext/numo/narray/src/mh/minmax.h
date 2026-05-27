#ifndef NUMO_NARRAY_MH_MINMAX_H
#define NUMO_NARRAY_MH_MINMAX_H 1

#define DEF_NARRAY_FLT_MINMAX_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_minmax(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    tDType xmin;                                                                               \
    tDType xmax;                                                                               \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
                                                                                               \
    f_minmax(n, p1, s1, &xmin, &xmax);                                                         \
                                                                                               \
    *(tDType*)NDL_PTR(lp, 1) = xmin;                                                           \
    *(tDType*)NDL_PTR(lp, 2) = xmax;                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_minmax_nan(na_loop_t* const lp) {                                \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    tDType xmin;                                                                               \
    tDType xmax;                                                                               \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
                                                                                               \
    f_minmax_nan(n, p1, s1, &xmin, &xmax);                                                     \
                                                                                               \
    *(tDType*)NDL_PTR(lp, 1) = xmin;                                                           \
    *(tDType*)NDL_PTR(lp, 2) = xmax;                                                           \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_minmax(int argc, VALUE* argv, VALUE self) {                            \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                       \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_minmax, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 2, 2, ain, aout \
    };                                                                                         \
    VALUE reduce =                                                                             \
      na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_minmax_nan);             \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#define DEF_NARRAY_INT_MINMAX_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_minmax(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    tDType xmin;                                                                               \
    tDType xmax;                                                                               \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
                                                                                               \
    f_minmax(n, p1, s1, &xmin, &xmax);                                                         \
                                                                                               \
    *(tDType*)NDL_PTR(lp, 1) = xmin;                                                           \
    *(tDType*)NDL_PTR(lp, 2) = xmax;                                                           \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_minmax(int argc, VALUE* argv, VALUE self) {                            \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                       \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_minmax, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_EXTRACT, 2, 2, ain, aout \
    };                                                                                         \
    VALUE reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                         \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#endif /* NUMO_NARRAY_MH_MINMAX_H */
