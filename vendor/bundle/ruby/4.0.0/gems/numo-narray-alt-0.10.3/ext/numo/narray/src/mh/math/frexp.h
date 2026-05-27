#ifndef NUMO_NARRAY_MH_MATH_FREXP_H
#define NUMO_NARRAY_MH_MATH_FREXP_H 1

#define DEF_NARRAY_FLT_FREXP_METHOD_FUNC(tDType, tNAryClass)                                   \
  static void iter_##tDType##_math_s_frexp(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char *p1, *p2, *p3;                                                                        \
    ssize_t s1, s2, s3;                                                                        \
    tDType x;                                                                                  \
    int y;                                                                                     \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      x = m_frexp(x, &y);                                                                      \
      SET_DATA_STRIDE(p2, s2, tDType, x);                                                      \
      SET_DATA_STRIDE(p3, s3, int32_t, y);                                                     \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_math_s_frexp(VALUE mod, VALUE a1) {                                    \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { numo_cInt32, 0 } };                      \
    ndfunc_t ndf = { iter_##tDType##_math_s_frexp, STRIDE_LOOP, 1, 2, ain, aout };             \
    return na_ndloop(&ndf, 1, a1);                                                             \
  }

#endif /* NUMO_NARRAY_MH_MATH_FREXP_H */
