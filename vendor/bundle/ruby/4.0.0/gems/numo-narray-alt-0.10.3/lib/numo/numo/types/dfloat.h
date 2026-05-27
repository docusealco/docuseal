typedef double dtype;
typedef double rtype;
#define cT numo_cDFloat
#define cRT numo_cDFloat
#define mTM numo_mDFloatMath

#include "float_macro.h"

#ifdef SFMT_H
/* generates a random number on [0,1)-real-interval */
inline static dtype m_rand(dtype max) {
  return genrand_res53_mix() * max;
}

/* generates random numbers from the normal distribution
   using Box-Muller Transformation.
 */
inline static void m_rand_norm(dtype mu, dtype sigma, dtype* a0, dtype* a1) {
  dtype x1, x2, w;
  do {
    x1 = genrand_res53_mix();
    x1 = x1 * 2 - 1;
    x2 = genrand_res53_mix();
    x2 = x2 * 2 - 1;
    w = x1 * x1 + x2 * x2;
  } while (w >= 1);
  w = sqrt((-2 * log(w)) / w);
  if (a0) {
    *a0 = x1 * w * sigma + mu;
  }
  if (a1) {
    *a1 = x2 * w * sigma + mu;
  }
}
#endif

#define m_min_init numo_dfloat_new_dim0(0.0 / 0.0)
#define m_max_init numo_dfloat_new_dim0(0.0 / 0.0)
#define m_extract(x) rb_float_new(*(double*)x)
#define m_nearly_eq(x, y) (fabs(x - y) <= (fabs(x) + fabs(y)) * DBL_EPSILON * 2)

#define M_EPSILON rb_float_new(2.2204460492503131e-16)
#define M_MIN rb_float_new(2.2250738585072014e-308)
#define M_MAX rb_float_new(1.7976931348623157e+308)
