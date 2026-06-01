#ifndef NUMO_NARRAY_MH_ROUND_FLOOR_H
#define NUMO_NARRAY_MH_ROUND_FLOOR_H 1

#include "unary_func.h"

#define DEF_NARRAY_FLT_FLOOR_METHOD_FUNC(tDType, tNAryClass)                                   \
  DEF_NARRAY_FLT_UNARY_ROUND_METHOD_FUNC(floor, tDType, tNAryClass)

#define DEF_NARRAY_ROBJ_FLOOR_METHOD_FUNC() DEF_NARRAY_ROBJ_UNARY_ROUND_METHOD_FUNC(floor)

#endif /* NUMO_NARRAY_MH_ROUND_FLOOR_H */
