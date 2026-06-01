typedef scomplex dtype;
typedef float rtype;
#define cT numo_cSComplex
#define cRT numo_cSFloat
#define mTM numo_mSComplexMath

#include "complex_macro.h"

static inline bool c_nearly_eq(dtype x, dtype y) {
  return c_abs(c_sub(x, y)) <= (c_abs(x) + c_abs(y)) * FLT_EPSILON * 2;
}

#ifdef SFMT_H
/* generates a random number on [0,1)-real-interval */
inline static dtype m_rand(dtype max) {
  dtype z;
  REAL(z) = to_real2(gen_rand32()) * REAL(max);
  IMAG(z) = to_real2(gen_rand32()) * IMAG(max);
  return z;
}

/* generates random numbers from the normal distribution
   using Box-Muller Transformation.
 */
inline static void m_rand_norm(dtype mu, rtype sigma, dtype* a0) {
  rtype x1, x2, w;
  do {
    x1 = to_real2(gen_rand32());
    x1 = x1 * 2 - 1;
    x2 = to_real2(gen_rand32());
    x2 = x2 * 2 - 1;
    w = x1 * x1 + x2 * x2;
  } while (w >= 1);
  w = sqrt((-2 * log(w)) / w);
  REAL(*a0) = x1 * w * sigma + REAL(mu);
  IMAG(*a0) = x2 * w * sigma + IMAG(mu);
}
#endif

#define M_EPSILON rb_float_new(1.1920928955078125e-07)
#define M_MIN rb_float_new(1.1754943508222875e-38)
#define M_MAX rb_float_new(3.4028234663852886e+38)
