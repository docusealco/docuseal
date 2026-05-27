typedef VALUE dtype;
typedef VALUE rtype;
#define cT numo_cRObject
#define cRT cT
// #define mTM mRObjectMath

#include "float_def.h"
#include "robj_macro.h"

#define m_min_init (0.0 / 0.0)
#define m_max_init (0.0 / 0.0)
#define m_extract(x) (*(VALUE*)x)
#define m_nearly_eq(x, y) robj_nearly_eq(x, y)

inline static int robj_nearly_eq(VALUE vx, VALUE vy) {
  double x, y;
  x = NUM2DBL(vx);
  y = NUM2DBL(vy);
  return (fabs(x - y) <= (fabs(x) + fabs(y)) * DBL_EPSILON * 2);
}

/* generates a random number on [0,1)-real-interval */
inline static dtype m_rand(dtype max) {
  return DBL2NUM(genrand_res53_mix() * NUM2DBL(max));
}
