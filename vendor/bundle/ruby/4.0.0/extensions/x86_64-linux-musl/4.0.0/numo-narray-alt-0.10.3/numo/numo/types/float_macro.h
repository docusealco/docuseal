#include "float_def.h"

extern double round(double);
extern double log2(double);
extern double exp2(double);
#ifdef HAVE_EXP10
extern double exp10(double);
#else
extern double pow(double, double);
#endif

#define m_zero 0.0
#define m_one 1.0

#define m_num_to_data(x) (NIL_P(x) ? nan("") : NUM2DBL(x))
#define m_data_to_num(x) rb_float_new(x)

#define m_from_double(x) (x)
#define m_from_real(x) (x)
#define m_from_sint(x) (x)
#define m_from_int32(x) (x)
#define m_from_int64(x) (x)
#define m_from_uint32(x) (x)
#define m_from_uint64(x) (x)

#define m_add(x, y) ((x) + (y))
#define m_sub(x, y) ((x) - (y))
#define m_mul(x, y) ((x) * (y))
#define m_div(x, y) ((x) / (y))
#define m_div_r(x, y) m_div(x, m_from_real(y))
#define m_div_check(x, y) ((y) == 0)
#define m_mod(x, y) fmod(x, y)
#define m_divmod(x, y, a, b)                                                                   \
  {                                                                                            \
    a = (x) / (y);                                                                             \
    b = m_mod(x, y);                                                                           \
  }
#define m_pow(x, y) pow(x, y)
#define m_pow_int(x, y) pow_int(x, y)

#define m_abs(x) fabs(x)
#define m_minus(x) (-(x))
#define m_reciprocal(x) (1 / (x))
#define m_square(x) ((x) * (x))
#define m_floor(x) floor(x)
#define m_round(x) round(x)
#define m_ceil(x) ceil(x)
#define m_trunc(x) trunc(x)
#define m_rint(x) rint(x)
#define m_sign(x) (((x) == 0) ? 0.0 : (((x) > 0) ? 1.0 : (((x) < 0) ? -1.0 : (x))))
#define m_copysign(x, y) copysign(x, y)
#define m_signbit(x) signbit(x)
#define m_modf(x, y, z)                                                                        \
  {                                                                                            \
    double d;                                                                                  \
    y = modf(x, &d);                                                                           \
    z = d;                                                                                     \
  }

#define m_eq(x, y) ((x) == (y))
#define m_ne(x, y) ((x) != (y))
#define m_gt(x, y) ((x) > (y))
#define m_ge(x, y) ((x) >= (y))
#define m_lt(x, y) ((x) < (y))
#define m_le(x, y) ((x) <= (y))

#define m_isnan(x) isnan(x)
#define m_isinf(x) isinf(x)
#define m_isposinf(x) (isinf(x) && signbit(x) == 0)
#define m_isneginf(x) (isinf(x) && signbit(x))
#define m_isfinite(x) isfinite(x)

#define m_mulsum_init INT2FIX(0)

#define m_sprintf(s, x) sprintf(s, "%g", x)

#define cmp_prnan(a, b)                                                                        \
  ((qsort_cast(a) == qsort_cast(b)) ? 0 : (qsort_cast(a) > qsort_cast(b)) ? 1 : -1)

#define cmp_ignan(a, b)                                                                        \
  (m_isnan(qsort_cast(a))                                                                      \
     ? (m_isnan(qsort_cast(b)) ? 0 : 1)                                                        \
     : (m_isnan(qsort_cast(b)) ? -1                                                            \
                               : ((qsort_cast(a) == qsort_cast(b))  ? 0                        \
                                  : (qsort_cast(a) > qsort_cast(b)) ? 1                        \
                                                                    : -1)))

#define cmpgt_prnan(a, b) (qsort_cast(a) > qsort_cast(b))

#define cmpgt_ignan(a, b)                                                                      \
  ((m_isnan(qsort_cast(a)) && !m_isnan(qsort_cast(b))) || (qsort_cast(a) > qsort_cast(b)))

#define m_sqrt(x) sqrt(x)
#define m_cbrt(x) cbrt(x)
#define m_log(x) log(x)
#define m_log2(x) log2(x)
#define m_log10(x) log10(x)
#define m_exp(x) exp(x)
#define m_exp2(x) exp2(x)
#ifdef HAVE_EXP10
#define m_exp10(x) exp10(x)
#else
#define m_exp10(x) pow(10, x)
#endif
#define m_expm1(x) expm1(x)
#define m_log1p(x) log1p(x)

#define m_sin(x) sin(x)
#define m_cos(x) cos(x)
#define m_tan(x) tan(x)
#define m_asin(x) asin(x)
#define m_acos(x) acos(x)
#define m_atan(x) atan(x)
#define m_sinh(x) sinh(x)
#define m_cosh(x) cosh(x)
#define m_tanh(x) tanh(x)
#define m_asinh(x) asinh(x)
#define m_acosh(x) acosh(x)
#define m_atanh(x) atanh(x)
#define m_atan2(x, y) atan2(x, y)
#define m_hypot(x, y) hypot(x, y)
#define m_sinc(x) (((x) == 0) ? 1.0 : (sin(x) / (x)))

#define m_erf(x) erf(x)
#define m_erfc(x) erfc(x)
#define m_ldexp(x, y) ldexp(x, y)
#define m_frexp(x, exp) frexp(x, exp)

static inline dtype pow_int(dtype x, int p) {
  dtype r = 1;
  switch (p) {
  case 0:
    return 1;
  case 1:
    return x;
  case 2:
    return x * x;
  case 3:
    return x * x * x;
  case 4:
    x = x * x;
    return x * x;
  }
  if (p < 0) return 1 / pow_int(x, -p);
  if (p > 64) return pow(x, p);
  while (p) {
    if (p & 1) r *= x;
    x *= x;
    p >>= 1;
  }
  return r;
}

static inline dtype f_seq(dtype x, dtype y, double c) {
  return x + y * c;
}

static inline dtype f_kahan_sum(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x;
  volatile dtype y = 0;
  volatile dtype t, r = 0;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (fabs(x) > fabs(y)) {
      dtype z = x;
      x = y;
      y = z;
    }
    r += x;
    t = y;
    y += r;
    t = y - t;
    r -= t;
  }
  return y;
}

static inline dtype f_kahan_sum_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x;
  volatile dtype y = 0;
  volatile dtype t, r = 0;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (!m_isnan(x)) {
      if (fabs(x) > fabs(y)) {
        dtype z = x;
        x = y;
        y = z;
      }
      r += x;
      t = y;
      y += r;
      t = y - t;
      r -= t;
    }
  }
  return y;
}

#include "real_accum.h"
