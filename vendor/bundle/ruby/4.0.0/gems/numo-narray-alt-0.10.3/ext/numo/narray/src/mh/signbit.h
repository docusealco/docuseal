#ifndef NUMO_NARRAY_MH_SIGNBIT_H
#define NUMO_NARRAY_MH_SIGNBIT_H 1

#define DEF_NARRAY_SIGNBIT_METHOD_FUNC(tDType, tNAryClass)                                     \
  static void iter_##tDType##_signbit(na_loop_t* const lp) {                                   \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    BIT_DIGIT* a2;                                                                             \
    size_t p2;                                                                                 \
    ssize_t s2;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_BIT(lp, 1, a2, p2, s2);                                                           \
    BIT_DIGIT b;                                                                               \
    tDType x;                                                                                  \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        GET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
        b = (m_signbit(x)) ? 1 : 0;                                                            \
        STORE_BIT(a2, p2, b);                                                                  \
        p2 += s2;                                                                              \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        b = (m_signbit(x)) ? 1 : 0;                                                            \
        STORE_BIT(a2, p2, b);                                                                  \
        p2 += s2;                                                                              \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_signbit(VALUE self) {                                                  \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { numo_cBit, 0 } };                                           \
    ndfunc_t ndf = { iter_##tDType##_signbit, FULL_LOOP, 1, 1, ain, aout };                    \
    return na_ndloop(&ndf, 1, self);                                                           \
  }

#endif /* NUMO_NARRAY_MH_SIGNBIT_H */
