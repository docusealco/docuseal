typedef u_int32_t dtype;
typedef u_int32_t rtype;
#define cT numo_cUInt32
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2UINT32(x))
#define m_data_to_num(x) UINT322NUM((u_int32_t)(x))
#define m_sprintf(s, x) sprintf(s, "%" PRIu32, (u_int32_t)(x))

#ifndef UINT32_MAX
#define UINT32_MAX (4294967295u)
#endif

#define DATA_MIN UINT32_MIN
#define DATA_MAX UINT32_MAX

#define M_MIN INT2FIX(0)
#define M_MAX m_data_to_num(UINT32_MAX)

#include "uint_macro.h"
