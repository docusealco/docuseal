/*
  complex.h
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/

static inline dtype c_new(rtype r, rtype i) {
  dtype z;
  REAL(z) = r;
  IMAG(z) = i;
  return z;
}

static inline dtype c_set_real(dtype x, rtype r) {
  REAL(x) = r;
  return x;
}

static inline dtype c_set_imag(dtype x, rtype i) {
  IMAG(x) = i;
  return x;
}

static inline VALUE COMP2NUM(dtype x) {
  VALUE v;
  v = rb_funcall(
    rb_intern("Kernel"), rb_intern("Complex"), 2, rb_float_new(REAL(x)), rb_float_new(IMAG(x))
  );
  return v;
}

static inline dtype NUM2COMP(VALUE v) {
  dtype z;
  REAL(z) = NUM2DBL(rb_funcall(v, id_real, 0));
  IMAG(z) = NUM2DBL(rb_funcall(v, id_imag, 0));
  return z;
}

#define c_is_zero(x) (REAL(x) == 0 && IMAG(x) == 0)
#define c_eq(x, y) (REAL(x) == REAL(y) && IMAG(x) == IMAG(y))
#define c_ne(x, y) (REAL(x) != REAL(y) || IMAG(x) != IMAG(y))
#define c_isnan(x) (isnan(REAL(x)) || isnan(IMAG(x)))
#define c_isinf(x) (isinf(REAL(x)) || isinf(IMAG(x)))
#define c_isposinf(x)                                                                          \
  ((isinf(REAL(x)) && signbit(REAL(x)) == 0) || (isinf(IMAG(x)) && signbit(IMAG(x)) == 0))
#define c_isneginf(x)                                                                          \
  ((isinf(REAL(x)) && signbit(REAL(x))) || (isinf(IMAG(x)) && signbit(IMAG(x))))
#define c_isfinite(x) (isfinite(REAL(x)) && isfinite(IMAG(x)))

static inline dtype c_zero(void) {
  dtype z;
  REAL(z) = 0;
  IMAG(z) = 0;
  return z;
}

static inline dtype c_one(void) {
  dtype z;
  REAL(z) = 1;
  IMAG(z) = 0;
  return z;
}

static inline dtype c_minus(dtype x) {
  dtype z;
  REAL(z) = -REAL(x);
  IMAG(z) = -IMAG(x);
  return z;
}

static inline dtype c_im(dtype x) {
  dtype z;
  REAL(z) = -IMAG(x);
  IMAG(z) = REAL(x);
  return z;
}

static inline dtype c_add(dtype x, dtype y) {
  dtype z;
  REAL(z) = REAL(x) + REAL(y);
  IMAG(z) = IMAG(x) + IMAG(y);
  return z;
}

static inline dtype c_sub(dtype x, dtype y) {
  dtype z;
  REAL(z) = REAL(x) - REAL(y);
  IMAG(z) = IMAG(x) - IMAG(y);
  return z;
}

static inline dtype c_mul(dtype x, dtype y) {
  dtype z;
  REAL(z) = REAL(x) * REAL(y) - IMAG(x) * IMAG(y);
  IMAG(z) = REAL(x) * IMAG(y) + IMAG(x) * REAL(y);
  return z;
}

static inline dtype c_mul_r(dtype x, rtype y) {
  dtype z;
  REAL(z) = REAL(x) * y;
  IMAG(z) = IMAG(x) * y;
  return z;
}

static inline dtype c_div(dtype x, dtype y) {
  dtype z;
  rtype s, yr, yi;
  s = r_hypot(REAL(y), IMAG(y));
  yr = REAL(y) / s;
  yi = IMAG(y) / s;
  REAL(z) = (REAL(x) * yr + IMAG(x) * yi) / s;
  IMAG(z) = (IMAG(x) * yr - REAL(x) * yi) / s;
  return z;
}

static inline dtype c_div_r(dtype x, rtype y) {
  dtype z;
  REAL(z) = REAL(x) / y;
  IMAG(z) = IMAG(x) / y;
  return z;
}

static inline dtype c_reciprocal(dtype x) {
  dtype z;
  if (r_abs(REAL(x)) > r_abs(IMAG(x))) {
    IMAG(z) = IMAG(x) / REAL(x);
    REAL(z) = (1 + IMAG(z) * IMAG(z)) * REAL(x);
    IMAG(z) /= -REAL(z);
    REAL(z) = 1 / REAL(z);
  } else {
    REAL(z) = REAL(x) / IMAG(x);
    IMAG(z) = (1 + REAL(z) * REAL(z)) * IMAG(x);
    REAL(z) /= IMAG(z);
    IMAG(z) = -1 / IMAG(z);
  }
  return z;
}

static inline dtype c_square(dtype x) {
  dtype z;
  REAL(z) = REAL(x) * REAL(x) - IMAG(x) * IMAG(x);
  IMAG(z) = 2 * REAL(x) * IMAG(x);
  return z;
}

static inline dtype c_sqrt(dtype x) {
  dtype z;
  rtype xr, xi, r;
  xr = REAL(x) / 2;
  xi = IMAG(x) / 2;
  r = r_hypot(xr, xi);
  if (xr > 0) {
    REAL(z) = sqrt(r + xr);
    IMAG(z) = xi / REAL(z);
  } else if ((r -= xr) != 0) {
    IMAG(z) = (xi >= 0) ? sqrt(r) : -sqrt(r);
    REAL(z) = xi / IMAG(z);
  } else {
    REAL(z) = IMAG(z) = 0;
  }
  return z;
}

static inline dtype c_log(dtype x) {
  dtype z;
  REAL(z) = r_log(r_hypot(REAL(x), IMAG(x)));
  IMAG(z) = r_atan2(IMAG(x), REAL(x));
  return z;
}

static inline dtype c_log2(dtype x) {
  dtype z;
  z = c_log(x);
  z = c_mul_r(z, M_LOG2E);
  return z;
}

static inline dtype c_log10(dtype x) {
  dtype z;
  z = c_log(x);
  z = c_mul_r(z, M_LOG10E);
  return z;
}

static inline dtype c_exp(dtype x) {
  dtype z;
  rtype a = r_exp(REAL(x));
  REAL(z) = a * r_cos(IMAG(x));
  IMAG(z) = a * r_sin(IMAG(x));
  return z;
}

static inline dtype c_exp2(dtype x) {
  dtype z;
  rtype a = r_exp(REAL(x) * M_LN2);
  REAL(z) = a * r_cos(IMAG(x));
  IMAG(z) = a * r_sin(IMAG(x));
  return z;
}

static inline dtype c_exp10(dtype x) {
  dtype z;
  rtype a = r_exp(REAL(x) * M_LN10);
  REAL(z) = a * r_cos(IMAG(x));
  IMAG(z) = a * r_sin(IMAG(x));
  return z;
}

static inline dtype c_sin(dtype x) {
  dtype z;
  REAL(z) = r_sin(REAL(x)) * r_cosh(IMAG(x));
  IMAG(z) = r_cos(REAL(x)) * r_sinh(IMAG(x));
  return z;
}

static inline dtype c_sinh(dtype x) {
  dtype z;
  REAL(z) = r_sinh(REAL(x)) * r_cos(IMAG(x));
  IMAG(z) = r_cosh(REAL(x)) * r_sin(IMAG(x));
  return z;
}

static inline dtype c_cos(dtype x) {
  dtype z;
  REAL(z) = r_cos(REAL(x)) * r_cosh(IMAG(x));
  IMAG(z) = -r_sin(REAL(x)) * r_sinh(IMAG(x));
  return z;
}

static inline dtype c_cosh(dtype x) {
  dtype z;
  REAL(z) = r_cosh(REAL(x)) * r_cos(IMAG(x));
  IMAG(z) = r_sinh(REAL(x)) * r_sin(IMAG(x));
  return z;
}

static inline dtype c_tan(dtype x) {
  dtype z;
  rtype c, d;
  if (r_abs(IMAG(x)) < 1) {
    c = r_cos(REAL(x));
    d = r_sinh(IMAG(x));
    d = c * c + d * d;
    REAL(z) = 0.5 * r_sin(2 * REAL(x)) / d;
    IMAG(z) = 0.5 * r_sinh(2 * IMAG(x)) / d;
  } else {
    d = r_exp(-IMAG(x));
    c = 2 * d / (1 - d * d);
    c = c * c;
    d = r_cos(REAL(x));
    d = 1.0 + d * d * c;
    REAL(z) = 0.5 * r_sin(2 * REAL(x)) * c / d;
    IMAG(z) = 1 / r_tanh(IMAG(x)) / d;
  }
  return z;
}

static inline dtype c_tanh(dtype x) {
  dtype z;
  rtype c, d, s;
  c = r_cos(IMAG(x));
  s = r_sinh(REAL(x));
  d = c * c + s * s;
  if (r_abs(REAL(x)) < 1) {
    REAL(z) = s * r_cosh(REAL(x)) / d;
    IMAG(z) = 0.5 * r_sin(2 * IMAG(x)) / d;
  } else {
    c = c / s;
    c = 1 + c * c;
    REAL(z) = 1 / (r_tanh(REAL(x)) * c);
    IMAG(z) = 0.5 * r_sin(2 * IMAG(x)) / d;
  }
  return z;
}

static inline dtype c_asin(dtype x) {
  dtype z, y;
  y = c_square(x);
  REAL(y) = 1 - REAL(y);
  IMAG(y) = -IMAG(y);
  y = c_sqrt(y);
  REAL(y) -= IMAG(x);
  IMAG(y) += REAL(x);
  y = c_log(y);
  REAL(z) = IMAG(y);
  IMAG(z) = -REAL(y);
  return z;
}

static inline dtype c_asinh(dtype x) {
  dtype z, y;
  y = c_square(x);
  REAL(y) += 1;
  y = c_sqrt(y);
  REAL(y) += REAL(x);
  IMAG(y) += IMAG(x);
  z = c_log(y);
  return z;
}

static inline dtype c_acos(dtype x) {
  dtype z, y;
  y = c_square(x);
  REAL(y) = 1 - REAL(y);
  IMAG(y) = -IMAG(y);
  y = c_sqrt(y);
  REAL(z) = REAL(x) - IMAG(y);
  IMAG(z) = IMAG(x) + REAL(y);
  y = c_log(z);
  REAL(z) = IMAG(y);
  IMAG(z) = -REAL(y);
  return z;
}

static inline dtype c_acosh(dtype x) {
  dtype z, y;
  y = c_square(x);
  REAL(y) -= 1;
  y = c_sqrt(y);
  REAL(y) += REAL(x);
  IMAG(y) += IMAG(x);
  z = c_log(y);
  return z;
}

static inline dtype c_atan(dtype x) {
  dtype z, y;
  REAL(y) = -REAL(x);
  IMAG(y) = 1 - IMAG(x);
  REAL(z) = REAL(x);
  IMAG(z) = 1 + IMAG(x);
  y = c_div(z, y);
  y = c_log(y);
  REAL(z) = -IMAG(y) / 2;
  IMAG(z) = REAL(y) / 2;
  return z;
}

static inline dtype c_atanh(dtype x) {
  dtype z, y;
  REAL(y) = 1 - REAL(x);
  IMAG(y) = -IMAG(x);
  REAL(z) = 1 + REAL(x);
  IMAG(z) = IMAG(x);
  y = c_div(z, y);
  y = c_log(y);
  REAL(z) = REAL(y) / 2;
  IMAG(z) = IMAG(y) / 2;
  return z;
}

static inline dtype c_pow(dtype x, dtype y) {
  dtype z;
  if (c_is_zero(y)) {
    z = c_one();
  } else if (c_is_zero(x) && REAL(y) > 0 && IMAG(y) == 0) {
    z = c_zero();
  } else {
    z = c_log(x);
    z = c_mul(y, z);
    z = c_exp(z);
  }
  return z;
}

static inline dtype c_pow_int(dtype x, int p) {
  dtype z = c_one();
  if (p < 0) {
    x = c_pow_int(x, -p);
    return c_reciprocal(x);
  }
  if (p == 2) {
    return c_square(x);
  }
  if (p & 1) {
    z = x;
  }
  p >>= 1;
  while (p) {
    x = c_square(x);
    if (p & 1) z = c_mul(z, x);
    p >>= 1;
  }
  return z;
}

static inline dtype c_cbrt(dtype x) {
  dtype z;
  z = c_log(x);
  z = c_div_r(z, 3);
  z = c_exp(z);
  return z;
}

static inline rtype c_abs(dtype x) {
  return r_hypot(REAL(x), IMAG(x));
}

static inline rtype c_abs_square(dtype x) {
  return REAL(x) * REAL(x) + IMAG(x) * IMAG(x);
}

/*
static inline rtype c_hypot(dtype x, dtype y) {
    return r_hypot(c_abs(x),c_abs(y));
}
*/
