typedef u_int64_t dtype;
typedef u_int64_t rtype;
#define cT numo_cUInt64
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2UINT64(x))
#define m_data_to_num(x) UINT642NUM((u_int64_t)(x))
#define m_sprintf(s, x) sprintf(s, "%" PRIu64, (u_int64_t)(x))

#ifndef UINT64_MAX
#define UINT64_MAX (18446744073709551615ul)
#endif

#define DATA_MIN UINT64_MIN
#define DATA_MAX UINT64_MAX

#define M_MIN INT2FIX(0)
#define M_MAX m_data_to_num(UINT64_MAX)

#include "uint_macro.h"
