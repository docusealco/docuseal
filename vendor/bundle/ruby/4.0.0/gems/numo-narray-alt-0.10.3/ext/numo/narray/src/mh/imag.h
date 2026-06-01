#ifndef NUMO_NARRAY_MH_IMAG_H
#define NUMO_NARRAY_MH_IMAG_H 1

#define DEF_NARRAY_IMAG_METHOD_FUNC(tDType, tNAryClass, tRtDType, tRtNAryClass)                \
  static void iter_##tDType##_imag(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
    tDType x;                                                                                  \
    tRtDType y;                                                                                \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          y = m_imag(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tRtDType, y);                                               \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          y = m_imag(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tRtDType, y);                                                \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          y = m_imag(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tRtDType, y);                                               \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          y = m_imag(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tRtDType, y);                                                \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_imag(VALUE self) {                                                     \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { tRtNAryClass, 0 } };                                        \
    ndfunc_t ndf = { iter_##tDType##_imag, FULL_LOOP, 1, 1, ain, aout };                       \
    return na_ndloop(&ndf, 1, self);                                                           \
  }

#endif /* NUMO_NARRAY_MH_IMAG_H */
