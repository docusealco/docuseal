#define m_zero 0
#define m_one 1

#define m_extract(x) m_data_to_num(*(dtype*)(x))

/* Handle negative values consistently across platforms for unsigned integer types */
#define m_from_double(x) ((x) < 0 ? (dtype)((long long)(x)) : (dtype)(x))
#define m_from_real(x) ((x) < 0 ? (dtype)((long long)(x)) : (dtype)(x))
#define m_from_sint(x) (x)
#define m_from_int32(x) (x)
#define m_from_int64(x) (x)
#define m_from_uint32(x) (x)
#define m_from_uint64(x) (x)

#define m_add(x, y) ((x) + (y))
#define m_sub(x, y) ((x) - (y))
#define m_mul(x, y) ((x) * (y))
#define m_div(x, y) ((x) / (y))
#define m_mod(x, y) ((x) % (y))
#define m_divmod(x, y, a, b)                                                                   \
  {                                                                                            \
    a = (x) / (y);                                                                             \
    b = m_mod(x, y);                                                                           \
  }
#define m_pow(x, y) pow_int(x, y)
#define m_pow_int(x, y) pow_int(x, y)

#define m_bit_and(x, y) ((x) & (y))
#define m_bit_or(x, y) ((x) | (y))
#define m_bit_xor(x, y) ((x) ^ (y))
#define m_bit_not(x) (~(x))

#define m_minus(x) (-(x))
#define m_reciprocal(x) int_reciprocal(x)
#define m_square(x) ((x) * (x))

#define m_eq(x, y) ((x) == (y))
#define m_ne(x, y) ((x) != (y))
#define m_gt(x, y) ((x) > (y))
#define m_ge(x, y) ((x) >= (y))
#define m_lt(x, y) ((x) < (y))
#define m_le(x, y) ((x) <= (y))
#define m_left_shift(x, y) ((x) << (y))
#define m_right_shift(x, y) ((x) >> (y))

#define m_isnan(x) 0

#define m_mulsum(x, y, z)                                                                      \
  { z += x * y; }
#define m_mulsum_init INT2FIX(0)
#define m_cumsum(x, y)                                                                         \
  { x += y; }
#define m_cumprod(x, y)                                                                        \
  { x *= y; }

#define cmp(a, b)                                                                              \
  ((qsort_cast(a) == qsort_cast(b)) ? 0 : (qsort_cast(a) > qsort_cast(b)) ? 1 : -1)
#define cmpgt(a, b) (qsort_cast(a) > qsort_cast(b))

static inline dtype f_min(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i = n;

  y = *(dtype*)p;
  p += stride;
  i--;
  for (; i--;) {
    x = *(dtype*)p;
    if (x < y) {
      y = x;
    }
    p += stride;
  }
  return y;
}

static inline dtype f_max(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i = n;

  y = *(dtype*)p;
  p += stride;
  i--;
  for (; i--;) {
    x = *(dtype*)p;
    if (x > y) {
      y = x;
    }
    p += stride;
  }
  return y;
}

static inline size_t f_min_index(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  y = *(dtype*)p;
  for (i = 1; i < n; i++) {
    x = *(dtype*)(p + i * stride);
    if (x < y) {
      y = x;
      j = i;
    }
  }
  return j;
}

static inline size_t f_max_index(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  y = *(dtype*)p;
  for (i = 1; i < n; i++) {
    x = *(dtype*)(p + i * stride);
    if (x > y) {
      y = x;
      j = i;
    }
  }
  return j;
}

static inline void f_minmax(size_t n, char* p, ssize_t stride, dtype* amin, dtype* amax) {
  dtype x, min, max;
  size_t i = n;

  min = max = *(dtype*)p;
  p += stride;
  for (i--; i--;) {
    x = *(dtype*)p;
    if (m_gt(x, max)) {
      max = x;
    }
    if (m_lt(x, min)) {
      min = x;
    }
    p += stride;
  }
  *amin = min;
  *amax = max;
  return;
}

static inline dtype f_ptp(size_t n, char* p, ssize_t stride) {
  dtype min, max;
  f_minmax(n, p, stride, &min, &max);
  return m_sub(max, min);
}

static inline double f_seq(double x, double y, double c) {
  return x + y * c;
}

static inline dtype f_maximum(dtype x, dtype y) {
  if (m_ge(x, y)) {
    return x;
  }
  return y;
}

static inline dtype f_minimum(dtype x, dtype y) {
  if (m_le(x, y)) {
    return x;
  }
  return y;
}

static inline double f_mean(size_t n, char* p, ssize_t stride) {
  size_t count = 0;
  double sum = 0.0;
  for (size_t i = n; i--;) {
    const double x = (double)(*(dtype*)p);
    p += stride;
    sum = m_add(sum, x);
    count++;
  }
  return sum / (double)count;
}

static inline double f_var(size_t n, char* p, ssize_t stride) {
  size_t count = 0;
  double sum = 0.0;
  const double mean = f_mean(n, p, stride);
  for (size_t i = n; i--;) {
    const double x = (double)(*(dtype*)p);
    const double d = m_sub(x, mean);
    p += stride;
    sum = m_add(sum, m_square(d));
    count++;
  }
  return sum / (double)(count - 1);
}

static inline double f_stddev(size_t n, char* p, ssize_t stride) {
  return sqrt(f_var(n, p, stride));
}

static inline double f_rms(size_t n, char* p, ssize_t stride) {
  size_t count = 0;
  double sum = 0.0;
  for (size_t i = n; i--;) {
    const double x = (double)(*(dtype*)p);
    p += stride;
    sum = m_add(sum, m_square(x));
    count++;
  }
  return sqrt(sum / (double)count);
}
