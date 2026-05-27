typedef int8_t dtype;
typedef int8_t rtype;
#define cT numo_cInt8
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2INT(x))
#define m_data_to_num(x) INT2FIX(x)
#define m_sprintf(s, x) sprintf(s, "%d", (int)(x))

#ifndef INT8_MIN
#define INT8_MIN (-127 - 1)
#endif
#ifndef INT8_MAX
#define INT8_MAX (127)
#endif

#define DATA_MIN INT8_MIN
#define DATA_MAX INT8_MAX

#define M_MIN INT2FIX(INT8_MIN)
#define M_MAX INT2FIX(INT8_MAX)

#include "int_macro.h"
