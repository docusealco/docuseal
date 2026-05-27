typedef int32_t dtype;
typedef int32_t rtype;
#define cT numo_cInt32
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2INT32(x))
#define m_data_to_num(x) INT322NUM((int32_t)(x))
#define m_sprintf(s, x) sprintf(s, "%" PRId32, (int32_t)(x))

#ifndef INT32_MIN
#define INT32_MIN (-2147483647 - 1)
#endif
#ifndef INT32_MAX
#define INT32_MAX (2147483647)
#endif

#define DATA_MIN INT32_MIN
#define DATA_MAX INT32_MAX

#define M_MIN m_data_to_num(INT32_MIN)
#define M_MAX m_data_to_num(INT32_MAX)

#include "int_macro.h"
