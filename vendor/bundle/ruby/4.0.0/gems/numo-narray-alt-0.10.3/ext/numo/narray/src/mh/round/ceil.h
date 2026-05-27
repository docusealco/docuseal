#ifndef NUMO_NARRAY_MH_ROUND_CEIL_H
#define NUMO_NARRAY_MH_ROUND_CEIL_H 1

#include "unary_func.h"

#define DEF_NARRAY_FLT_CEIL_METHOD_FUNC(tDType, tNAryClass)                                    \
  DEF_NARRAY_FLT_UNARY_ROUND_METHOD_FUNC(ceil, tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_CEIL_METHOD_FUNC() DEF_NARRAY_ROBJ_UNARY_ROUND_METHOD_FUNC(ceil)

#endif /* NUMO_NARRAY_MH_ROUND_CEIL_H */
