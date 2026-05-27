typedef int16_t dtype;
typedef int16_t rtype;
#define cT numo_cInt16
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2INT(x))
#if SIZEOF_INT > 2
#define m_data_to_num(x) INT2FIX(x)
#else
#define m_data_to_num(x) INT2NUM(x)
#endif
#define m_sprintf(s, x) sprintf(s, "%d", (int)(x))

#ifndef INT16_MIN
#define INT16_MIN (-32767 - 1)
#endif
#ifndef INT16_MAX
#define INT16_MAX (32767)
#endif

#define DATA_MIN INT16_MIN
#define DATA_MAX INT16_MAX

#define M_MIN m_data_to_num(INT16_MIN)
#define M_MAX m_data_to_num(INT16_MAX)

#include "int_macro.h"
