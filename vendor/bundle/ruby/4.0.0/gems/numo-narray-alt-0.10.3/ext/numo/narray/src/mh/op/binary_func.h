#ifndef NUMO_NARRAY_MH_OP_BINARY_FUNC_H
#define NUMO_NARRAY_MH_OP_BINARY_FUNC_H 1

#define ITER_BINARY_INIT_VARS()                                                                \
  size_t n;                                                                                    \
  char* p1;                                                                                    \
  char* p2;                                                                                    \
  char* p3;                                                                                    \
  ssize_t s1;                                                                                  \
  ssize_t s2;                                                                                  \
  ssize_t s3;                                                                                  \
  INIT_COUNTER(lp, n);                                                                         \
  INIT_PTR(lp, 0, p1, s1);                                                                     \
  INIT_PTR(lp, 1, p2, s2);                                                                     \
  INIT_PTR(lp, 2, p3, s3);

#define ITER_BINARY_INPLACE_OR_NEW_ARY(fOpFunc, tDType)                                        \
  if (p1 == p3) {                                                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      ((tDType*)p1)[i] = m_##fOpFunc(((tDType*)p1)[i], ((tDType*)p2)[i]);                      \
    }                                                                                          \
  } else {                                                                                     \
    for (size_t i = 0; i < n; i++) {                                                           \
      ((tDType*)p3)[i] = m_##fOpFunc(((tDType*)p1)[i], ((tDType*)p2)[i]);                      \
    }                                                                                          \
  }

#define ITER_BINARY_INPLACE_OR_NEW_ARY_ZERODIV(fOpFunc, tDType)                                \
  if (p1 == p3) {                                                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      if ((((tDType*)p2)[i]) == 0) {                                                           \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      ((tDType*)p1)[i] = m_##fOpFunc(((tDType*)p1)[i], ((tDType*)p2)[i]);                      \
    }                                                                                          \
  } else {                                                                                     \
    for (size_t i = 0; i < n; i++) {                                                           \
      if ((((tDType*)p2)[i]) == 0) {                                                           \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      ((tDType*)p3)[i] = m_##fOpFunc(((tDType*)p1)[i], ((tDType*)p2)[i]);                      \
    }                                                                                          \
  }

#define ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(fOpFunc, tDType)                                    \
  if (p1 == p3) {                                                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(tDType*)p1 = m_##fOpFunc(*(tDType*)p1, *(tDType*)p2);                                  \
      p1 += s1;                                                                                \
      p2 += s2;                                                                                \
    }                                                                                          \
  } else {                                                                                     \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(tDType*)p3 = m_##fOpFunc(*(tDType*)p1, *(tDType*)p2);                                  \
      p1 += s1;                                                                                \
      p2 += s2;                                                                                \
      p3 += s3;                                                                                \
    }                                                                                          \
  }

#define ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(fOpFunc, tDType)                            \
  if (p1 == p3) {                                                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      if ((*(tDType*)p2) == 0) {                                                               \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      *(tDType*)p1 = m_##fOpFunc(*(tDType*)p1, *(tDType*)p2);                                  \
      p1 += s1;                                                                                \
      p2 += s2;                                                                                \
    }                                                                                          \
  } else {                                                                                     \
    for (size_t i = 0; i < n; i++) {                                                           \
      if ((*(tDType*)p2) == 0) {                                                               \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      *(tDType*)p3 = m_##fOpFunc(*(tDType*)p1, *(tDType*)p2);                                  \
      p1 += s1;                                                                                \
      p2 += s2;                                                                                \
      p3 += s3;                                                                                \
    }                                                                                          \
  }

#define ITER_BINARY_INPLACE_OR_NEW_SCL(fOpFunc, tDType)                                        \
  if (p1 == p3) {                                                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      ((tDType*)p1)[i] = m_##fOpFunc(((tDType*)p1)[i], *(tDType*)p2);                          \
    }                                                                                          \
  } else {                                                                                     \
    for (size_t i = 0; i < n; i++) {                                                           \
      ((tDType*)p3)[i] = m_##fOpFunc(((tDType*)p1)[i], *(tDType*)p2);                          \
    }                                                                                          \
  }

#define ITER_BINARY_NEW_PTR_SCL(fOpFunc, tDType)                                               \
  for (size_t i = 0; i < n; i++) {                                                             \
    *(tDType*)p3 = m_##fOpFunc(*(tDType*)p1, *(tDType*)p2);                                    \
    p1 += s1;                                                                                  \
    p3 += s3;                                                                                  \
  }

#define ITER_BINARY_FALLBACK_LOOP(fOpFunc, tDType)                                             \
  for (size_t i = 0; i < n; i++) {                                                             \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    tDType z;                                                                                  \
    GET_DATA_STRIDE(p1, s1, tDType, x);                                                        \
    GET_DATA_STRIDE(p2, s2, tDType, y);                                                        \
    z = m_##fOpFunc(x, y);                                                                     \
    SET_DATA_STRIDE(p3, s3, tDType, z);                                                        \
  }

#define DEF_BINARY_SELF_FUNC(fOpFunc, tDType, tNAryClass)                                      \
  static VALUE tDType##_##fOpFunc##_self(VALUE self, VALUE other) {                            \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_##fOpFunc, STRIDE_LOOP, 2, 1, ain, aout };                \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }

#define DEF_BINARY_FUNC(fOpFunc, sRbOp, tDType, tNAryClass)                                    \
  static VALUE tDType##_##fOpFunc(VALUE self, VALUE other) {                                   \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_##fOpFunc##_self(self, other);                                           \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, sRbOp, 1, other);                                                   \
    }                                                                                          \
  }

#define DEF_BINARY_SFLT_SSE2_ITER_FUNC(fOpFunc, fSimdOp)                                       \
  static void iter_sfloat_##fOpFunc(na_loop_t* const lp) {                                     \
    size_t i = 0;                                                                              \
    ITER_BINARY_INIT_VARS()                                                                    \
                                                                                               \
    size_t cnt;                                                                                \
    size_t cnt_simd_loop = -1;                                                                 \
    __m128 a;                                                                                  \
    __m128 b;                                                                                  \
    size_t num_pack;                                                                           \
    num_pack = SIMD_ALIGNMENT_SIZE / sizeof(sfloat);                                           \
                                                                                               \
    if (is_aligned(p1, sizeof(sfloat)) && is_aligned(p2, sizeof(sfloat)) &&                    \
        is_aligned(p3, sizeof(sfloat))) {                                                      \
      if (s1 == sizeof(sfloat) && s2 == sizeof(sfloat) && s3 == sizeof(sfloat)) {              \
        if ((n >= num_pack) &&                                                                 \
            is_same_aligned3(                                                                  \
              &((sfloat*)p1)[i], &((sfloat*)p2)[i], &((sfloat*)p3)[i], SIMD_ALIGNMENT_SIZE     \
            )) {                                                                               \
          cnt = get_count_of_elements_not_aligned_to_simd_size(                                \
            &((sfloat*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(sfloat)                             \
          );                                                                                   \
          if (p1 == p3) {                                                                      \
            for (i = 0; i < cnt; i++) {                                                        \
              ((sfloat*)p1)[i] = m_##fOpFunc(((sfloat*)p1)[i], ((sfloat*)p2)[i]);              \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < cnt; i++) {                                                        \
              ((sfloat*)p3)[i] = m_##fOpFunc(((sfloat*)p1)[i], ((sfloat*)p2)[i]);              \
            }                                                                                  \
          }                                                                                    \
          cnt_simd_loop = (n - i) % num_pack;                                                  \
          if (p1 == p3) {                                                                      \
            for (; i < n - cnt_simd_loop; i += num_pack) {                                     \
              a = _mm_load_ps(&((sfloat*)p1)[i]);                                              \
              b = _mm_load_ps(&((sfloat*)p2)[i]);                                              \
              a = fSimdOp(a, b);                                                               \
              _mm_store_ps(&((sfloat*)p1)[i], a);                                              \
            }                                                                                  \
          } else {                                                                             \
            for (; i < n - cnt_simd_loop; i += num_pack) {                                     \
              a = _mm_load_ps(&((sfloat*)p1)[i]);                                              \
              b = _mm_load_ps(&((sfloat*)p2)[i]);                                              \
              a = fSimdOp(a, b);                                                               \
              _mm_stream_ps(&((sfloat*)p3)[i], a);                                             \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        if (cnt_simd_loop != 0) {                                                              \
          if (p1 == p3) {                                                                      \
            for (; i < n; i++) {                                                               \
              ((sfloat*)p1)[i] = m_##fOpFunc(((sfloat*)p1)[i], ((sfloat*)p2)[i]);              \
            }                                                                                  \
          } else {                                                                             \
            for (; i < n; i++) {                                                               \
              ((sfloat*)p3)[i] = m_##fOpFunc(((sfloat*)p1)[i], ((sfloat*)p2)[i]);              \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(sfloat)) && is_aligned_step(s2, sizeof(sfloat)) &&        \
          is_aligned_step(s3, sizeof(sfloat))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(sfloat) && s3 == sizeof(sfloat)) {                                  \
            b = _mm_load1_ps(&((sfloat*)p2)[0]);                                               \
            if ((n >= num_pack) &&                                                             \
                is_same_aligned2(&((sfloat*)p1)[i], &((sfloat*)p3)[i], SIMD_ALIGNMENT_SIZE)) { \
              cnt = get_count_of_elements_not_aligned_to_simd_size(                            \
                &((sfloat*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(sfloat)                         \
              );                                                                               \
              if (p1 == p3) {                                                                  \
                for (i = 0; i < cnt; i++) {                                                    \
                  ((sfloat*)p1)[i] = m_##fOpFunc(((sfloat*)p1)[i], *(sfloat*)p2);              \
                }                                                                              \
              } else {                                                                         \
                for (i = 0; i < cnt; i++) {                                                    \
                  ((sfloat*)p3)[i] = m_##fOpFunc(((sfloat*)p1)[i], *(sfloat*)p2);              \
                }                                                                              \
              }                                                                                \
              cnt_simd_loop = (n - i) % num_pack;                                              \
              if (p1 == p3) {                                                                  \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_ps(&((sfloat*)p1)[i]);                                          \
                  a = fSimdOp(a, b);                                                           \
                  _mm_store_ps(&((sfloat*)p1)[i], a);                                          \
                }                                                                              \
              } else {                                                                         \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_ps(&((sfloat*)p1)[i]);                                          \
                  a = fSimdOp(a, b);                                                           \
                  _mm_stream_ps(&((sfloat*)p3)[i], a);                                         \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
            if (cnt_simd_loop != 0) {                                                          \
              if (p1 == p3) {                                                                  \
                for (; i < n; i++) {                                                           \
                  ((sfloat*)p1)[i] = m_##fOpFunc(((sfloat*)p1)[i], *(sfloat*)p2);              \
                }                                                                              \
              } else {                                                                         \
                for (; i < n; i++) {                                                           \
                  ((sfloat*)p3)[i] = m_##fOpFunc(((sfloat*)p1)[i], *(sfloat*)p2);              \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < n; i++) {                                                          \
              *(sfloat*)p3 = m_##fOpFunc(*(sfloat*)p1, *(sfloat*)p2);                          \
              p1 += s1;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        } else {                                                                               \
          if (p1 == p3) {                                                                      \
            for (i = 0; i < n; i++) {                                                          \
              *(sfloat*)p1 = m_##fOpFunc(*(sfloat*)p1, *(sfloat*)p2);                          \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < n; i++) {                                                          \
              *(sfloat*)p3 = m_##fOpFunc(*(sfloat*)p1, *(sfloat*)p2);                          \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
                                                                                               \
    for (i = 0; i < n; i++) {                                                                  \
      sfloat x;                                                                                \
      sfloat y;                                                                                \
      sfloat z;                                                                                \
      GET_DATA_STRIDE(p1, s1, sfloat, x);                                                      \
      GET_DATA_STRIDE(p2, s2, sfloat, y);                                                      \
      z = m_##fOpFunc(x, y);                                                                   \
      SET_DATA_STRIDE(p3, s3, sfloat, z);                                                      \
    }                                                                                          \
  }

#define DEF_BINARY_DFLT_SSE2_ITER_FUNC(fOpFunc, fSimdOp)                                       \
  static void iter_dfloat_##fOpFunc(na_loop_t* const lp) {                                     \
    size_t i = 0;                                                                              \
    ITER_BINARY_INIT_VARS()                                                                    \
                                                                                               \
    size_t cnt;                                                                                \
    size_t cnt_simd_loop = -1;                                                                 \
    __m128d a;                                                                                 \
    __m128d b;                                                                                 \
    size_t num_pack;                                                                           \
    num_pack = SIMD_ALIGNMENT_SIZE / sizeof(dfloat);                                           \
                                                                                               \
    if (is_aligned(p1, sizeof(dfloat)) && is_aligned(p2, sizeof(dfloat)) &&                    \
        is_aligned(p3, sizeof(dfloat))) {                                                      \
      if (s1 == sizeof(dfloat) && s2 == sizeof(dfloat) && s3 == sizeof(dfloat)) {              \
        if ((n >= num_pack) &&                                                                 \
            is_same_aligned3(                                                                  \
              &((dfloat*)p1)[i], &((dfloat*)p2)[i], &((dfloat*)p3)[i], SIMD_ALIGNMENT_SIZE     \
            )) {                                                                               \
          cnt = get_count_of_elements_not_aligned_to_simd_size(                                \
            &((dfloat*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(dfloat)                             \
          );                                                                                   \
          if (p1 == p3) {                                                                      \
            for (i = 0; i < cnt; i++) {                                                        \
              ((dfloat*)p1)[i] = m_##fOpFunc(((dfloat*)p1)[i], ((dfloat*)p2)[i]);              \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < cnt; i++) {                                                        \
              ((dfloat*)p3)[i] = m_##fOpFunc(((dfloat*)p1)[i], ((dfloat*)p2)[i]);              \
            }                                                                                  \
          }                                                                                    \
          cnt_simd_loop = (n - i) % num_pack;                                                  \
          if (p1 == p3) {                                                                      \
            for (; i < n - cnt_simd_loop; i += num_pack) {                                     \
              a = _mm_load_pd(&((dfloat*)p1)[i]);                                              \
              b = _mm_load_pd(&((dfloat*)p2)[i]);                                              \
              a = fSimdOp(a, b);                                                               \
              _mm_store_pd(&((dfloat*)p1)[i], a);                                              \
            }                                                                                  \
          } else {                                                                             \
            for (; i < n - cnt_simd_loop; i += num_pack) {                                     \
              a = _mm_load_pd(&((dfloat*)p1)[i]);                                              \
              b = _mm_load_pd(&((dfloat*)p2)[i]);                                              \
              a = fSimdOp(a, b);                                                               \
              _mm_stream_pd(&((dfloat*)p3)[i], a);                                             \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        if (cnt_simd_loop != 0) {                                                              \
          if (p1 == p3) {                                                                      \
            for (; i < n; i++) {                                                               \
              ((dfloat*)p1)[i] = m_##fOpFunc(((dfloat*)p1)[i], ((dfloat*)p2)[i]);              \
            }                                                                                  \
          } else {                                                                             \
            for (; i < n; i++) {                                                               \
              ((dfloat*)p3)[i] = m_##fOpFunc(((dfloat*)p1)[i], ((dfloat*)p2)[i]);              \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(dfloat)) && is_aligned_step(s2, sizeof(dfloat)) &&        \
          is_aligned_step(s3, sizeof(dfloat))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(dfloat) && s3 == sizeof(dfloat)) {                                  \
            b = _mm_load1_pd(&((dfloat*)p2)[0]);                                               \
            if ((n >= num_pack) &&                                                             \
                is_same_aligned2(&((dfloat*)p1)[i], &((dfloat*)p3)[i], SIMD_ALIGNMENT_SIZE)) { \
              cnt = get_count_of_elements_not_aligned_to_simd_size(                            \
                &((dfloat*)p1)[i], SIMD_ALIGNMENT_SIZE, sizeof(dfloat)                         \
              );                                                                               \
              if (p1 == p3) {                                                                  \
                for (; i < cnt; i++) {                                                         \
                  ((dfloat*)p1)[i] = m_##fOpFunc(((dfloat*)p1)[i], *(dfloat*)p2);              \
                }                                                                              \
              } else {                                                                         \
                for (; i < cnt; i++) {                                                         \
                  ((dfloat*)p3)[i] = m_##fOpFunc(((dfloat*)p1)[i], *(dfloat*)p2);              \
                }                                                                              \
              }                                                                                \
              cnt_simd_loop = (n - i) % num_pack;                                              \
              if (p1 == p3) {                                                                  \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_pd(&((dfloat*)p1)[i]);                                          \
                  a = fSimdOp(a, b);                                                           \
                  _mm_store_pd(&((dfloat*)p1)[i], a);                                          \
                }                                                                              \
              } else {                                                                         \
                for (; i < n - cnt_simd_loop; i += num_pack) {                                 \
                  a = _mm_load_pd(&((dfloat*)p1)[i]);                                          \
                  a = fSimdOp(a, b);                                                           \
                  _mm_stream_pd(&((dfloat*)p3)[i], a);                                         \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
            if (cnt_simd_loop != 0) {                                                          \
              if (p1 == p3) {                                                                  \
                for (; i < n; i++) {                                                           \
                  ((dfloat*)p1)[i] = m_##fOpFunc(((dfloat*)p1)[i], *(dfloat*)p2);              \
                }                                                                              \
              } else {                                                                         \
                for (; i < n; i++) {                                                           \
                  ((dfloat*)p3)[i] = m_##fOpFunc(((dfloat*)p1)[i], *(dfloat*)p2);              \
                }                                                                              \
              }                                                                                \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < n; i++) {                                                          \
              *(dfloat*)p3 = m_##fOpFunc(*(dfloat*)p1, *(dfloat*)p2);                          \
              p1 += s1;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        } else {                                                                               \
          if (p1 == p3) {                                                                      \
            for (i = 0; i < n; i++) {                                                          \
              *(dfloat*)p1 = m_##fOpFunc(*(dfloat*)p1, *(dfloat*)p2);                          \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
          } else {                                                                             \
            for (i = 0; i < n; i++) {                                                          \
              *(dfloat*)p3 = m_##fOpFunc(*(dfloat*)p1, *(dfloat*)p2);                          \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
                                                                                               \
    for (i = 0; i < n; i++) {                                                                  \
      dfloat x;                                                                                \
      dfloat y;                                                                                \
      dfloat z;                                                                                \
      GET_DATA_STRIDE(p1, s1, dfloat, x);                                                      \
      GET_DATA_STRIDE(p2, s2, dfloat, y);                                                      \
      z = m_##fOpFunc(x, y);                                                                   \
      SET_DATA_STRIDE(p3, s3, dfloat, z);                                                      \
    }                                                                                          \
  }

#endif /* NUMO_NARRAY_MH_OP_BINARY_FUNC_H */
