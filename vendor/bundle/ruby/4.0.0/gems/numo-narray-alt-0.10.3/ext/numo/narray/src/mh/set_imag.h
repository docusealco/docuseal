#ifndef NUMO_NARRAY_MH_SET_IMAG_H
#define NUMO_NARRAY_MH_SET_IMAG_H 1

#define DEF_NARRAY_SET_IMAG_METHOD_FUNC(tDType, tNAryClass, tRtDType, tRtNAryClass)            \
  static void iter_##tDType##_set_imag(na_loop_t* const lp) {                                  \
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
          GET_DATA(p1 + *idx1, tDType, x);                                                     \
          GET_DATA_INDEX(p2, idx2, tRtDType, y);                                               \
          x = m_set_imag(x, y);                                                                \
          SET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA(p1 + *idx1, tDType, x);                                                     \
          GET_DATA_STRIDE(p2, s2, tRtDType, y);                                                \
          x = m_set_imag(x, y);                                                                \
          SET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA(p1, tDType, x);                                                             \
          GET_DATA_INDEX(p2, idx2, tRtDType, y);                                               \
          x = m_set_imag(x, y);                                                                \
          SET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA(p1, tDType, x);                                                             \
          GET_DATA_STRIDE(p2, s2, tRtDType, y);                                                \
          x = m_set_imag(x, y);                                                                \
          SET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_set_imag(VALUE self, VALUE a1) {                                       \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { tRtNAryClass, 0 } };                        \
    ndfunc_t ndf = { iter_##tDType##_set_imag, FULL_LOOP, 2, 0, ain, 0 };                      \
    na_ndloop(&ndf, 2, self, a1);                                                              \
    return a1;                                                                                 \
  }

#endif /* NUMO_NARRAY_MH_SET_IMAG_H */
