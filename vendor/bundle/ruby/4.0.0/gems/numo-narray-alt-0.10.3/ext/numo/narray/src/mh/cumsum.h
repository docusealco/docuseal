#ifndef NUMO_NARRAY_MH_CUMSUM_H
#define NUMO_NARRAY_MH_CUMSUM_H 1

#define DEF_NARRAY_FLT_CUMSUM_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_cumsum(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
                                                                                               \
    GET_DATA_STRIDE(p1, s1, tDType, x);                                                        \
    SET_DATA_STRIDE(p2, s2, tDType, x);                                                        \
    for (size_t i = 0; i < n - 1; i++) {                                                       \
      GET_DATA_STRIDE(p1, s1, tDType, y);                                                      \
      m_cumsum(x, y);                                                                          \
      SET_DATA_STRIDE(p2, s2, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_cumsum_nan(na_loop_t* const lp) {                                \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
                                                                                               \
    GET_DATA_STRIDE(p1, s1, tDType, x);                                                        \
    SET_DATA_STRIDE(p2, s2, tDType, x);                                                        \
    for (size_t i = 0; i < n - 1; i++) {                                                       \
      GET_DATA_STRIDE(p1, s1, tDType, y);                                                      \
      m_cumsum_nan(x, y);                                                                      \
      SET_DATA_STRIDE(p2, s2, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_cumsum(int argc, VALUE* argv, VALUE self) {                            \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_cumsum, STRIDE_LOOP | NDF_FLAT_REDUCE | NDF_CUM, 2, 1, ain, aout         \
    };                                                                                         \
                                                                                               \
    reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_cumsum_nan);      \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#define DEF_NARRAY_INT_CUMSUM_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_cumsum(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
                                                                                               \
    GET_DATA_STRIDE(p1, s1, tDType, x);                                                        \
    SET_DATA_STRIDE(p2, s2, tDType, x);                                                        \
    for (size_t i = 0; i < n - 1; i++) {                                                       \
      GET_DATA_STRIDE(p1, s1, tDType, y);                                                      \
      m_cumsum(x, y);                                                                          \
      SET_DATA_STRIDE(p2, s2, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_cumsum(int argc, VALUE* argv, VALUE self) {                            \
    VALUE reduce;                                                                              \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { sym_reduce, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_cumsum, STRIDE_LOOP | NDF_FLAT_REDUCE | NDF_CUM, 2, 1, ain, aout         \
    };                                                                                         \
                                                                                               \
    reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                               \
                                                                                               \
    return na_ndloop(&ndf, 2, self, reduce);                                                   \
  }

#endif /* NUMO_NARRAY_MH_CUMSUM_H */
