#ifndef NUMO_NARRAY_MH_OP_MUL_H
#define NUMO_NARRAY_MH_OP_MUL_H 1

#include "binary_func.h"

#define DEF_NARRAY_MUL_METHOD_FUNC(tDType, tNAryClass)                                         \
  static void iter_##tDType##_mul(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY(mul, tDType)                                            \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(mul, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(mul, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(mul, tDType)                                      \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(mul, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mul, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(mul, '*', tDType, tNAryClass)

#define DEF_NARRAY_INT8_MUL_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_mul(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        ITER_BINARY_INPLACE_OR_NEW_SCL(mul, tDType)                                            \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(mul, tDType)                                                   \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(mul, tDType)                                          \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mul, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(mul, '*', tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_MUL_METHOD_FUNC()                                                      \
  static void iter_robject_mul(na_loop_t* const lp) {                                          \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        ITER_BINARY_INPLACE_OR_NEW_SCL(mul, robject)                                           \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(mul, robject)                                                  \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(mul, robject)                                         \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mul, robject, numo_cRObject)                                            \
  static VALUE robject_mul(VALUE self, VALUE other) {                                          \
    return robject_mul_self(self, other);                                                      \
  }

#define DEF_NARRAY_SFLT_MUL_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_SFLT_SSE2_ITER_FUNC(mul, _mm_mul_ps)                                              \
  DEF_BINARY_SELF_FUNC(mul, sfloat, numo_cSFloat)                                              \
  DEF_BINARY_FUNC(mul, '*', sfloat, numo_cSFloat)

#define DEF_NARRAY_DFLT_MUL_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_DFLT_SSE2_ITER_FUNC(mul, _mm_mul_pd)                                              \
  DEF_BINARY_SELF_FUNC(mul, dfloat, numo_cDFloat)                                              \
  DEF_BINARY_FUNC(mul, '*', dfloat, numo_cDFloat)

#endif /* NUMO_NARRAY_MH_OP_MUL_H */
