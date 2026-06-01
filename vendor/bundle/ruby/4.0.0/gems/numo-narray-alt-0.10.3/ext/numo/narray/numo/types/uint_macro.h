#include "xint_macro.h"

#define m_abs(x) (x)
#define m_sign(x) (((x) == 0) ? 0 : 1)

static inline dtype int_reciprocal(dtype x) {
  switch (x) {
  case 1:
    return 1;
  case 0:
    rb_raise(rb_eZeroDivError, "divided by 0");
  default:
    return 0;
  }
}

static dtype pow_int(dtype x, int p) {
  dtype r = m_one;
  switch (p) {
  case 0:
    return 1;
  case 1:
    return x;
  case 2:
    return x * x;
  case 3:
    return x * x * x;
  }
  while (p) {
    if (p & 1) r *= x;
    x *= x;
    p >>= 1;
  }
  return r;
}

static inline u_int64_t f_sum(size_t n, char* p, ssize_t stride) {
  u_int64_t x, y = 0;
  size_t i = n;
  for (; i--;) {
    x = *(dtype*)p;
    y += x;
    p += stride;
  }
  return y;
}

static inline u_int64_t f_prod(size_t n, char* p, ssize_t stride) {
  u_int64_t x, y = 1;
  size_t i = n;
  for (; i--;) {
    x = *(dtype*)p;
    y *= x;
    p += stride;
  }
  return y;
}
