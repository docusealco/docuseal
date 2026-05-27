#ifndef NUMO_NARRAY_MH_OP_SUB_H
#define NUMO_NARRAY_MH_OP_SUB_H 1

#include "binary_func.h"

#define DEF_NARRAY_SUB_METHOD_FUNC(tDType, tNAryClass)                                         \
  static void iter_##tDType##_sub(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY(sub, tDType)                                            \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(sub, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(sub, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(sub, tDType)                                      \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(sub, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(sub, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(sub, '-', tDType, tNAryClass)

#define DEF_NARRAY_INT8_SUB_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_sub(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        ITER_BINARY_INPLACE_OR_NEW_SCL(sub, tDType)                                            \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(sub, tDType)                                                   \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(sub, tDType)                                          \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(sub, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(sub, '-', tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_SUB_METHOD_FUNC()                                                      \
  static void iter_robject_sub(na_loop_t* const lp) {                                          \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        ITER_BINARY_INPLACE_OR_NEW_SCL(sub, robject)                                           \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(sub, robject)                                                  \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(sub, robject)                                         \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(sub, robject, numo_cRObject)                                            \
  static VALUE robject_sub(VALUE self, VALUE other) {                                          \
    return robject_sub_self(self, other);                                                      \
  }

#define DEF_NARRAY_SFLT_SUB_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_SFLT_SSE2_ITER_FUNC(sub, _mm_sub_ps)                                              \
  DEF_BINARY_SELF_FUNC(sub, sfloat, numo_cSFloat)                                              \
  DEF_BINARY_FUNC(sub, '-', sfloat, numo_cSFloat)

#define DEF_NARRAY_DFLT_SUB_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_DFLT_SSE2_ITER_FUNC(sub, _mm_sub_pd)                                              \
  DEF_BINARY_SELF_FUNC(sub, dfloat, numo_cDFloat)                                              \
  DEF_BINARY_FUNC(sub, '-', dfloat, numo_cDFloat)

#endif /* NUMO_NARRAY_MH_OP_SUB_H */
