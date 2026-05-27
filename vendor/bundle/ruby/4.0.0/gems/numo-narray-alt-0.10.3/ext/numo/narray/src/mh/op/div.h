#ifndef NUMO_NARRAY_MH_OP_DIV_H
#define NUMO_NARRAY_MH_OP_DIV_H 1

#include "binary_func.h"

#define DEF_NARRAY_FLT_DIV_METHOD_FUNC(tDType, tNAryClass)                                     \
  static void iter_##tDType##_div(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY(div, tDType)                                            \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(div, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(div, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(div, tDType)                                      \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(div, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(div, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(div, '/', tDType, tNAryClass)

#define DEF_NARRAY_INT_DIV_METHOD_FUNC(tDType, tNAryClass)                                     \
  static void iter_##tDType##_div(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY_ZERODIV(div, tDType)                                    \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if ((*(tDType*)p2) == 0) {                                                           \
            lp->err_type = rb_eZeroDivError;                                                   \
            return;                                                                            \
          }                                                                                    \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(div, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(div, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(div, tDType)                              \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(div, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(div, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(div, '/', tDType, tNAryClass)

#define DEF_NARRAY_INT8_DIV_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_div(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if ((*(tDType*)p2) == 0) {                                                               \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        ITER_BINARY_INPLACE_OR_NEW_SCL(div, tDType)                                            \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(div, tDType)                                                   \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(div, tDType)                                  \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(div, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(div, '/', tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_DIV_METHOD_FUNC()                                                      \
  static void iter_robject_div(na_loop_t* const lp) {                                          \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if ((*(robject*)p2) == 0) {                                                              \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        ITER_BINARY_INPLACE_OR_NEW_SCL(div, robject)                                           \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(div, robject)                                                  \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(div, robject)                                 \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(div, robject, numo_cRObject)                                            \
  static VALUE robject_div(VALUE self, VALUE other) {                                          \
    return robject_div_self(self, other);                                                      \
  }

#define DEF_NARRAY_SFLT_DIV_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_SFLT_SSE2_ITER_FUNC(div, _mm_div_ps)                                              \
  DEF_BINARY_SELF_FUNC(div, sfloat, numo_cSFloat)                                              \
  DEF_BINARY_FUNC(div, '/', sfloat, numo_cSFloat)

#define DEF_NARRAY_DFLT_DIV_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_DFLT_SSE2_ITER_FUNC(div, _mm_div_pd)                                              \
  DEF_BINARY_SELF_FUNC(div, dfloat, numo_cDFloat)                                              \
  DEF_BINARY_FUNC(div, '/', dfloat, numo_cDFloat)

#endif /* NUMO_NARRAY_MH_OP_DIV_H */
