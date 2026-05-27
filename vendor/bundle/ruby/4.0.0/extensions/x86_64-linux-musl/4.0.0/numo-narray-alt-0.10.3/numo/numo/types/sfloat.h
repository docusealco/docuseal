typedef float dtype;
typedef float rtype;
#define cT numo_cSFloat
#define cRT numo_cSFloat
#define mTM numo_mSFloatMath

#include "float_macro.h"

#ifdef SFMT_H
/* generates a random number on [0,1)-real-interval */
inline static dtype m_rand(dtype max) {
  return to_real2(gen_rand32()) * max;
}

/* generates random numbers from the normal distribution
   using Box-Muller Transformation.
 */
inline static void m_rand_norm(dtype mu, dtype sigma, dtype* a0, dtype* a1) {
  dtype x1, x2, w;
  do {
    x1 = to_real2(gen_rand32());
    x1 = x1 * 2 - 1;
    x2 = to_real2(gen_rand32());
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

#define m_min_init numo_sfloat_new_dim0(0.0 / 0.0)
#define m_max_init numo_sfloat_new_dim0(0.0 / 0.0)

#define m_extract(x) rb_float_new(*(float*)x)
#define m_nearly_eq(x, y) (fabs(x - y) <= (fabs(x) + fabs(y)) * FLT_EPSILON * 2)

#define M_EPSILON rb_float_new(1.1920928955078125e-07)
#define M_MIN rb_float_new(1.1754943508222875e-38)
#define M_MAX rb_float_new(3.4028234663852886e+38)
