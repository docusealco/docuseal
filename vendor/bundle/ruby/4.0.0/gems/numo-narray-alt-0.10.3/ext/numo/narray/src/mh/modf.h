#ifndef NUMO_NARRAY_MH_MODF_H
#define NUMO_NARRAY_MH_MODF_H 1

#define DEF_NARRAY_MODF_METHOD_FUNC(tDType, tNAryClass)                                        \
  static void iter_##tDType##_modf(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    tDType z;                                                                                  \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      m_modf(x, y, z);                                                                         \
      SET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      SET_DATA_STRIDE(p3, s3, tDType, z);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_modf(VALUE self) {                                                     \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                       \
    ndfunc_t ndf = { iter_##tDType##_modf, STRIDE_LOOP, 1, 2, ain, aout };                     \
    return na_ndloop(&ndf, 1, self);                                                           \
  }

#endif /* NUMO_NARRAY_MH_MODF_H */
