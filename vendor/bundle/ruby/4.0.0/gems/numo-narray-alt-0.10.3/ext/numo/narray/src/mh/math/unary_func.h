#ifndef NUMO_NARRAY_MH_MATH_UNARY_FUNC_H
#define NUMO_NARRAY_MH_MATH_UNARY_FUNC_H 1

#define DEF_NARRAY_FLT_UNARY_MATH_METHOD_FUNC(fMathFunc, tDType, tNAryClass)                   \
  static void iter_##tDType##_math_s_##fMathFunc(na_loop_t* const lp) {                        \
    size_t n;                                                                                  \
    char *p1, *p2;                                                                             \
    ssize_t s1, s2;                                                                            \
    size_t *idx1, *idx2;                                                                       \
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
          x = m_##fMathFunc(x);                                                                \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_##fMathFunc(x);                                                                \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_##fMathFunc(x);                                                                \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType))) {                \
          if (s1 == sizeof(tDType) && s2 == sizeof(tDType)) {                                  \
            for (size_t i = 0; i < n; i++) {                                                   \
              ((tDType*)p2)[i] = m_##fMathFunc(((tDType*)p1)[i]);                              \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
          if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType))) {    \
            for (size_t i = 0; i < n; i++) {                                                   \
              *(tDType*)p2 = m_##fMathFunc(*(tDType*)p1);                                      \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
        }                                                                                      \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_##fMathFunc(x);                                                                \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_math_s_##fMathFunc(VALUE mod, VALUE a1) {                              \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_math_s_##fMathFunc, FULL_LOOP, 1, 1, ain, aout };         \
    return na_ndloop(&ndf, 1, a1);                                                             \
  }

#endif /* NUMO_NARRAY_MH_MATH_UNARY_FUNC_H */
