#ifndef NUMO_NARRAY_MH_OP_ADD_H
#define NUMO_NARRAY_MH_OP_ADD_H 1

#include "binary_func.h"

#define DEF_NARRAY_ADD_METHOD_FUNC(tDType, tNAryClass)                                         \
  static void iter_##tDType##_add(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY(add, tDType)                                            \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(add, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(add, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(add, tDType)                                      \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(add, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(add, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(add, '+', tDType, tNAryClass)

#define DEF_NARRAY_INT8_ADD_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_add(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        ITER_BINARY_INPLACE_OR_NEW_SCL(add, tDType)                                            \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(add, tDType)                                                   \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(add, tDType)                                          \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(add, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(add, '+', tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_ADD_METHOD_FUNC()                                                      \
  static void iter_robject_add(na_loop_t* const lp) {                                          \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        ITER_BINARY_INPLACE_OR_NEW_SCL(add, robject)                                           \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(add, robject)                                                  \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(add, robject)                                         \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(add, robject, numo_cRObject)                                            \
  static VALUE robject_add(VALUE self, VALUE other) {                                          \
    return robject_add_self(self, other);                                                      \
  }

#define DEF_NARRAY_SFLT_ADD_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_SFLT_SSE2_ITER_FUNC(add, _mm_add_ps)                                              \
  DEF_BINARY_SELF_FUNC(add, sfloat, numo_cSFloat)                                              \
  DEF_BINARY_FUNC(add, '+', sfloat, numo_cSFloat)

#define DEF_NARRAY_DFLT_ADD_SSE2_METHOD_FUNC()                                                 \
  DEF_BINARY_DFLT_SSE2_ITER_FUNC(add, _mm_add_pd)                                              \
  DEF_BINARY_SELF_FUNC(add, dfloat, numo_cDFloat)                                              \
  DEF_BINARY_FUNC(add, '+', dfloat, numo_cDFloat)

#endif /* NUMO_NARRAY_MH_OP_ADD_H */
