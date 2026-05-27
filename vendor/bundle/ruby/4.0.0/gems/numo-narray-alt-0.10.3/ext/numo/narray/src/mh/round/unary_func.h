#ifndef NUMO_NARRAY_MH_ROUND_UNARY_FUNC_H
#define NUMO_NARRAY_MH_ROUND_UNARY_FUNC_H 1

#define DEF_NARRAY_FLT_UNARY_ROUND_METHOD_FUNC(fRoundFunc, tDType, tNAryClass)                 \
  static void iter_##tDType##_##fRoundFunc(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    tDType x;                                                                                  \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
                                                                                               \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType))) {                \
          if (s1 == sizeof(tDType) && s2 == sizeof(tDType)) {                                  \
            for (size_t i = 0; i < n; i++) {                                                   \
              ((tDType*)p2)[i] = m_##fRoundFunc(((tDType*)p1)[i]);                             \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
          if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType))) {    \
            for (size_t i = 0; i < n; i++) {                                                   \
              *(tDType*)p2 = m_##fRoundFunc(*(tDType*)p1);                                     \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
        }                                                                                      \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_##fRoundFunc(VALUE self) {                                             \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_##fRoundFunc, FULL_LOOP, 1, 1, ain, aout };               \
    return na_ndloop(&ndf, 1, self);                                                           \
  }

#define DEF_NARRAY_ROBJ_UNARY_ROUND_METHOD_FUNC(fRoundFunc)                                    \
  static void iter_robject_##fRoundFunc(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    robject x;                                                                                 \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
                                                                                               \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, robject, x);                                                \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_INDEX(p2, idx2, robject, x);                                                \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, robject, x);                                                \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_STRIDE(p2, s2, robject, x);                                                 \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, robject, x);                                                 \
          x = m_##fRoundFunc(x);                                                               \
          SET_DATA_INDEX(p2, idx2, robject, x);                                                \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(robject*)p2 = m_##fRoundFunc(*(robject*)p1);                                       \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE robject_##fRoundFunc(VALUE self) {                                              \
    ndfunc_arg_in_t ain[1] = { { numo_cRObject, 0 } };                                         \
    ndfunc_arg_out_t aout[1] = { { numo_cRObject, 0 } };                                       \
    ndfunc_t ndf = { iter_robject_##fRoundFunc, FULL_LOOP, 1, 1, ain, aout };                  \
    return na_ndloop(&ndf, 1, self);                                                           \
  }

#endif /* NUMO_NARRAY_MH_ROUND_UNARY_FUNC_H */
