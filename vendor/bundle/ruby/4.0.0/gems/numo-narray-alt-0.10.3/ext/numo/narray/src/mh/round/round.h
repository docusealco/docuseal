#ifndef NUMO_NARRAY_MH_ROUND_ROUND_H
#define NUMO_NARRAY_MH_ROUND_ROUND_H 1

#include "unary_func.h"

#define DEF_NARRAY_FLT_ROUND_METHOD_FUNC(tDType, tNAryClass)                                   \
  DEF_NARRAY_FLT_UNARY_ROUND_METHOD_FUNC(round, tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_ROUND_METHOD_FUNC() DEF_NARRAY_ROBJ_UNARY_ROUND_METHOD_FUNC(round)

#endif /* NUMO_NARRAY_MH_ROUND_ROUND_H */
