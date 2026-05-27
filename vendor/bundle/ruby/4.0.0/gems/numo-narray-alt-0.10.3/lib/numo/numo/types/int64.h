typedef int64_t dtype;
typedef int64_t rtype;
#define cT numo_cInt64
#define cRT cT

#define m_num_to_data(x) ((dtype)NUM2INT64(x))
#define m_data_to_num(x) INT642NUM((int64_t)(x))
#define m_sprintf(s, x) sprintf(s, "%" PRId64, (int64_t)(x))

#ifndef INT64_MIN
#define INT64_MIN (-9223372036854775807l - 1)
#endif
#ifndef INT64_MAX
#define INT64_MAX (9223372036854775807l)
#endif

#define DATA_MIN INT64_MIN
#define DATA_MAX INT64_MAX

#define M_MIN m_data_to_num(INT64_MIN)
#define M_MAX m_data_to_num(INT64_MAX)

#include "int_macro.h"
