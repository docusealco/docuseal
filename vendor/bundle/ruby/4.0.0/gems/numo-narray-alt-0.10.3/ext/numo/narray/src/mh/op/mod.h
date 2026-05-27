#ifndef NUMO_NARRAY_MH_OP_MOD_H
#define NUMO_NARRAY_MH_OP_MOD_H 1

#include "binary_func.h"

#define DEF_NARRAY_FLT_MOD_METHOD_FUNC(tDType, tNAryClass)                                     \
  static void iter_##tDType##_mod(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY(mod, tDType)                                            \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            ITER_BINARY_INPLACE_OR_NEW_SCL(mod, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(mod, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY(mod, tDType)                                      \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(mod, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mod, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(mod, '%', tDType, tNAryClass)

#define DEF_NARRAY_INT_MOD_METHOD_FUNC(tDType, tNAryClass)                                     \
  static void iter_##tDType##_mod(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        ITER_BINARY_INPLACE_OR_NEW_ARY_ZERODIV(mod, tDType)                                    \
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
            ITER_BINARY_INPLACE_OR_NEW_SCL(mod, tDType)                                        \
          } else {                                                                             \
            ITER_BINARY_NEW_PTR_SCL(mod, tDType)                                               \
          }                                                                                    \
        } else {                                                                               \
          ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(mod, tDType)                              \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    ITER_BINARY_FALLBACK_LOOP(mod, tDType)                                                     \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mod, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(mod, '%', tDType, tNAryClass)

#define DEF_NARRAY_INT8_MOD_METHOD_FUNC(tDType, tNAryClass)                                    \
  static void iter_##tDType##_mod(na_loop_t* const lp) {                                       \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if ((*(tDType*)p2) == 0) {                                                               \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        ITER_BINARY_INPLACE_OR_NEW_SCL(mod, tDType)                                            \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(mod, tDType)                                                   \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(mod, tDType)                                  \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mod, tDType, tNAryClass)                                                \
  DEF_BINARY_FUNC(mod, '%', tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_MOD_METHOD_FUNC()                                                      \
  static void iter_robject_mod(na_loop_t* const lp) {                                          \
    ITER_BINARY_INIT_VARS()                                                                    \
    if (s2 == 0) {                                                                             \
      if ((*(robject*)p2) == 0) {                                                              \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        ITER_BINARY_INPLACE_OR_NEW_SCL(mod, robject)                                           \
      } else {                                                                                 \
        ITER_BINARY_NEW_PTR_SCL(mod, robject)                                                  \
      }                                                                                        \
    } else {                                                                                   \
      ITER_BINARY_INPLACE_OR_NEW_PTR_ARY_ZERODIV(mod, robject)                                 \
    }                                                                                          \
  }                                                                                            \
  DEF_BINARY_SELF_FUNC(mod, robject, numo_cRObject)                                            \
  static VALUE robject_mod(VALUE self, VALUE other) {                                          \
    return robject_mod_self(self, other);                                                      \
  }

#endif /* NUMO_NARRAY_MH_OP_MOD_H */
