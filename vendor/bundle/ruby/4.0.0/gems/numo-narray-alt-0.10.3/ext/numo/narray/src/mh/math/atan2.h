#ifndef NUMO_NARRAY_MH_MATH_ATAN2_H
#define NUMO_NARRAY_MH_MATH_ATAN2_H 1

#define DEF_NARRAY_FLT_ATAN2_METHOD_FUNC(tDType, tNAryClass)                                   \
  static void iter_##tDType##_math_s_atan2(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char *p1, *p2, *p3;                                                                        \
    ssize_t s1, s2, s3;                                                                        \
    tDType x, y;                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      x = m_atan2(x, y);                                                                       \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_math_s_atan2(VALUE mod, VALUE a1, VALUE a2) {                          \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_math_s_atan2, STRIDE_LOOP, 2, 1, ain, aout };             \
    return na_ndloop(&ndf, 2, a1, a2);                                                         \
  }

#endif /* NUMO_NARRAY_MH_MATH_ATAN2_H */
