typedef dcomplex dtype;
typedef double rtype;
#define cT numo_cDComplex
#define cRT numo_cDFloat
#define mTM numo_mDComplexMath

#include "complex_macro.h"

static inline bool c_nearly_eq(dtype x, dtype y) {
  return c_abs(c_sub(x, y)) <= (c_abs(x) + c_abs(y)) * DBL_EPSILON * 2;
}

#ifdef SFMT_H
/* generates a random number on [0,1)-real-interval */
inline static dtype m_rand(dtype max) {
  dtype z;
  REAL(z) = genrand_res53_mix() * REAL(max);
  IMAG(z) = genrand_res53_mix() * IMAG(max);
  return z;
}

/* generates random numbers from the normal distribution
   using Box-Muller Transformation.
 */
inline static void m_rand_norm(dtype mu, rtype sigma, dtype* a0) {
  rtype x1, x2, w;
  do {
    x1 = genrand_res53_mix();
    x1 = x1 * 2 - 1;
    x2 = genrand_res53_mix();
    x2 = x2 * 2 - 1;
    w = x1 * x1 + x2 * x2;
  } while (w >= 1);
  w = sqrt((-2 * log(w)) / w);
  REAL(*a0) = x1 * w * sigma + REAL(mu);
  IMAG(*a0) = x2 * w * sigma + IMAG(mu);
}
#endif

#define M_EPSILON rb_float_new(2.2204460492503131e-16)
#define M_MIN rb_float_new(2.2250738585072014e-308)
#define M_MAX rb_float_new(1.7976931348623157e+308)
