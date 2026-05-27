#ifndef NUMO_NARRAY_MH_COMP_BINARY_FUNC_H
#define NUMO_NARRAY_MH_COMP_BINARY_FUNC_H 1

#define DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(fCompFunc, tDType, tNAryClass)                \
  static void iter_##tDType##_##fCompFunc(na_loop_t* const lp) {                               \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    BIT_DIGIT* a3;                                                                             \
    size_t p3;                                                                                 \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    BIT_DIGIT b;                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR_BIT(lp, 2, a3, p3, s3);                                                           \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      b = (m_##fCompFunc(x, y)) ? 1 : 0;                                                       \
      STORE_BIT(a3, p3, b);                                                                    \
      p3 += s3;                                                                                \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_##fCompFunc##_self(VALUE self, VALUE other) {                          \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { numo_cBit, 0 } };                                           \
    ndfunc_t ndf = { iter_##tDType##_##fCompFunc, STRIDE_LOOP, 2, 1, ain, aout };              \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }

#endif /* NUMO_NARRAY_MH_COMP_BINARY_FUNC_H */
