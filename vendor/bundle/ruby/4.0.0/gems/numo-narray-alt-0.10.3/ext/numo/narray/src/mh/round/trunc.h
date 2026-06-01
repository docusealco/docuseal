#ifndef NUMO_NARRAY_MH_ROUND_TRUNC_H
#define NUMO_NARRAY_MH_ROUND_TRUNC_H 1

#include "unary_func.h"

#define DEF_NARRAY_FLT_TRUNC_METHOD_FUNC(tDType, tNAryClass)                                   \
  DEF_NARRAY_FLT_UNARY_ROUND_METHOD_FUNC(trunc, tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_TRUNC_METHOD_FUNC() DEF_NARRAY_ROBJ_UNARY_ROUND_METHOD_FUNC(trunc)

#endif /* NUMO_NARRAY_MH_ROUND_TRUNC_H */
