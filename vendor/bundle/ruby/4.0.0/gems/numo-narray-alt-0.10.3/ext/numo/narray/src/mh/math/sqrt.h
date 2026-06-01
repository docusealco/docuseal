#ifndef NUMO_NARRAY_MH_MATH_SQRT_H
#define NUMO_NARRAY_MH_MATH_SQRT_H 1

#include "unary_func.h"

#define DEF_NARRAY_FLT_SQRT_METHOD_FUNC(tDType, tNAryClass)                                    \
  DEF_NARRAY_FLT_UNARY_MATH_METHOD_FUNC(sqrt, tDType, tNAryClass)

#define DEF_NARRAY_FLT_SQRT_SSE2_SGL_METHOD_FUNC(tDType, tNAryClass)                           \
  static void iter_##tDType##_math_s_sqrt(na_loop_t* const lp) {                               \
    size_t i = 0;                                                                              \
    size_t n;                                                                                  \
    char *p1, *p2;                                                                             \
    ssize_t s1, s2;                                                                            \
    size_t *idx1, *idx2;                                                                       \
    tDType x;                                                                                  \
    size_t cnt;                                                                                \
    size_t cnt_simd_loop = -1;                                                                 \
    __m128 a;                                                                                  \
    size_t num_pack;                                                                           \
    num_pack = SIMD_ALIGNMENT_SIZE / sizeof(tDType);                                           \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
                                                                                               \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_sqrt(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_sqrt(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_sqrt(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType))) {                \
          if (s1 == sizeof(tDType) && s2 == sizeof(tDType)) {                                  \
            if ((n >= num_pack) &&                                                             \
                is_same_aligned2(&((tDType*)p1)[i], &((tDType*)p2)[i], SIMD_ALIGNMENT_SIZE)) { \
              cnt = get_count_of_elements_not_aligned_to_simd_size(                            \
                &((tDType*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(tDType)                         \
              );                                                                               \
              for (i = 0; i < cnt; i++) {                                                      \
                ((tDType*)p2)[i] = m_sqrt(((tDType*)p1)[i]);                                   \
              }                                                                                \
              cnt_simd_loop = (n - i) % num_pack;                                              \
              if (p1 == p2) {                                                                  \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_ps(&((tDType*)p1)[i]);                                          \
                  a = _mm_sqrt_ps(a);                                                          \
                  _mm_store_ps(&((tDType*)p1)[i], a);                                          \
                }                                                                              \
              } else {                                                                         \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_ps(&((tDType*)p1)[i]);                                          \
                  a = _mm_sqrt_ps(a);                                                          \
                  _mm_stream_ps(&((tDType*)p2)[i], a);                                         \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
            if (cnt_simd_loop != 0) {                                                          \
              for (; i < n; i++) {                                                             \
                ((tDType*)p2)[i] = m_sqrt(((tDType*)p1)[i]);                                   \
              }                                                                                \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
          if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType))) {    \
            for (i = 0; i < n; i++) {                                                          \
              *(tDType*)p2 = m_sqrt(*(tDType*)p1);                                             \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
        }                                                                                      \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_sqrt(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_math_s_sqrt(VALUE mod, VALUE a1) {                                     \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_math_s_sqrt, FULL_LOOP, 1, 1, ain, aout };                \
    return na_ndloop(&ndf, 1, a1);                                                             \
  }

#define DEF_NARRAY_FLT_SQRT_SSE2_DBL_METHOD_FUNC(tDType, tNAryClass)                           \
  static void iter_##tDType##_math_s_sqrt(na_loop_t* const lp) {                               \
    size_t i = 0;                                                                              \
    size_t n;                                                                                  \
    char *p1, *p2;                                                                             \
    ssize_t s1, s2;                                                                            \
    size_t *idx1, *idx2;                                                                       \
    tDType x;                                                                                  \
    size_t cnt;                                                                                \
    size_t cnt_simd_loop = -1;                                                                 \
    __m128d a;                                                                                 \
    size_t num_pack;                                                                           \
    num_pack = SIMD_ALIGNMENT_SIZE / sizeof(tDType);                                           \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
                                                                                               \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_sqrt(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = m_sqrt(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_sqrt(x);                                                                       \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType))) {                \
          if (s1 == sizeof(tDType) && s2 == sizeof(tDType)) {                                  \
            if ((n >= num_pack) &&                                                             \
                is_same_aligned2(&((tDType*)p1)[i], &((tDType*)p2)[i], SIMD_ALIGNMENT_SIZE)) { \
              cnt = get_count_of_elements_not_aligned_to_simd_size(                            \
                &((tDType*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(tDType)                         \
              );                                                                               \
              for (i = 0; i < cnt; i++) {                                                      \
                ((tDType*)p2)[i] = m_sqrt(((tDType*)p1)[i]);                                   \
              }                                                                                \
              cnt_simd_loop = (n - i) % num_pack;                                              \
              if (p1 == p2) {                                                                  \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_pd(&((tDType*)p1)[i]);                                          \
                  a = _mm_sqrt_pd(a);                                                          \
                  _mm_store_pd(&((tDType*)p1)[i], a);                                          \
                }                                                                              \
              } else {                                                                         \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_pd(&((tDType*)p1)[i]);                                          \
                  a = _mm_sqrt_pd(a);                                                          \
                  _mm_stream_pd(&((tDType*)p2)[i], a);                                         \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
            if (cnt_simd_loop != 0) {                                                          \
              for (; i < n; i++) {                                                             \
                ((tDType*)p2)[i] = m_sqrt(((tDType*)p1)[i]);                                   \
              }                                                                                \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
          if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType))) {    \
            for (i = 0; i < n; i++) {                                                          \
              *(tDType*)p2 = m_sqrt(*(tDType*)p1);                                             \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
            return;                                                                            \
          }                                                                                    \
        }                                                                                      \
        for (i = 0; i < n; i++) {                                                              \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = m_sqrt(x);                                                                       \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_math_s_sqrt(VALUE mod, VALUE a1) {                                     \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 0 } };                                            \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_math_s_sqrt, FULL_LOOP, 1, 1, ain, aout };                \
    return na_ndloop(&ndf, 1, a1);                                                             \
  }

#endif /* NUMO_NARRAY_MH_MATH_SQRT_H */
