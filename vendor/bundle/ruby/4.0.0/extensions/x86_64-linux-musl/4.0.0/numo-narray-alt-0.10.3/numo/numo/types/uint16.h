typedef u_int16_t dtype;
typedef u_int16_t rtype;
#define cT numo_cUInt16
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2UINT(x))
#if SIZEOF_INT > 2
#define m_data_to_num(x) INT2FIX(x)
#else
#define m_data_to_num(x) UINT2NUM(x)
#endif
#define m_sprintf(s, x) sprintf(s, "%u", (unsigned int)(x))

#ifndef UINT16_MAX
#define UINT16_MAX (65535)
#endif

#define DATA_MIN UINT16_MIN
#define DATA_MAX UINT16_MAX

#define M_MIN INT2FIX(0)
#define M_MAX m_data_to_num(UINT16_MAX)

#include "uint_macro.h"
