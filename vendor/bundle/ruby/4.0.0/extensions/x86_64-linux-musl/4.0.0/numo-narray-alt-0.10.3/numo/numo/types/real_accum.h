#define not_nan(x) ((x) == (x))

#define m_mulsum(x, y, z)                                                                      \
  { z = m_add(m_mul(x, y), z); }
#define m_mulsum_nan(x, y, z)                                                                  \
  {                                                                                            \
    if (not_nan(x) && not_nan(y)) {                                                            \
      z = m_add(m_mul(x, y), z);                                                               \
    }                                                                                          \
  }

#define m_cumsum(x, y)                                                                         \
  { (x) = m_add(x, y); }
#define m_cumsum_nan(x, y)                                                                     \
  {                                                                                            \
    if (!not_nan(x)) {                                                                         \
      (x) = (y);                                                                               \
    } else if (not_nan(y)) {                                                                   \
      (x) = m_add(x, y);                                                                       \
    }                                                                                          \
  }

#define m_cumprod(x, y)                                                                        \
  { (x) = m_mul(x, y); }
#define m_cumprod_nan(x, y)                                                                    \
  {                                                                                            \
    if (!not_nan(x)) {                                                                         \
      (x) = (y);                                                                               \
    } else if (not_nan(y)) {                                                                   \
      (x) = m_mul(x, y);                                                                       \
    }                                                                                          \
  }

static inline dtype f_sum(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    y = m_add(x, y);
    p += stride;
  }
  return y;
}

static inline dtype f_sum_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (not_nan(x)) {
      y = m_add(x, y);
    }
  }
  return y;
}

static inline dtype f_prod(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x, y = m_one;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    y = m_mul(x, y);
  }
  return y;
}

static inline dtype f_prod_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  dtype x, y = m_one;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (not_nan(x)) {
      y = m_mul(x, y);
    }
  }
  return y;
}

static inline dtype f_mean(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    y = m_add(x, y);
    count++;
  }
  return m_div(y, m_from_real(count));
}

static inline dtype f_mean_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (not_nan(x)) {
      y = m_add(x, y);
      count++;
    }
  }
  return m_div(y, m_from_real(count));
}

static inline dtype f_var(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;
  dtype a, m;

  m = f_mean(n, p, stride);

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    a = m_abs(m_sub(x, m));
    y = m_add(y, m_square(a));
    count++;
  }
  return m_div(y, m_from_real(count - 1));
}

static inline dtype f_var_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;
  dtype a, m;

  m = f_mean_nan(n, p, stride);

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (not_nan(x)) {
      a = m_abs(m_sub(x, m));
      y = m_add(y, m_square(a));
      count++;
    }
  }
  return m_div(y, m_from_real(count - 1));
}

static inline dtype f_stddev(size_t n, char* p, ssize_t stride) {
  return m_sqrt(f_var(n, p, stride));
}

static inline dtype f_stddev_nan(size_t n, char* p, ssize_t stride) {
  return m_sqrt(f_var_nan(n, p, stride));
}

static inline dtype f_rms(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    y = m_add(y, m_square(m_abs(x)));
    count++;
  }
  return m_sqrt(m_div(y, m_from_real(count)));
}

static inline dtype f_rms_nan(size_t n, char* p, ssize_t stride) {
  size_t i = n;
  size_t count = 0;
  dtype x, y = m_zero;

  for (; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (not_nan(x)) {
      y = m_add(y, m_square(m_abs(x)));
      count++;
    }
  }
  return m_sqrt(m_div(y, m_from_real(count)));
}

// ---------------------------------------------------------

static inline dtype f_min_nan(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i = n;

  y = *(dtype*)p;
  p += stride;
  if (!not_nan(y)) {
    return y;
  }
  for (i--; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (!not_nan(x)) {
      return x;
    }
    if (m_lt(x, y)) {
      y = x;
    }
  }
  return y;
}

static inline dtype f_min(size_t n, char* p, ssize_t stride) {
  dtype x, y = m_zero;
  size_t i = n;

  for (; i--;) {
    y = *(dtype*)p;
    p += stride;
    if (not_nan(y)) {
      for (; i--;) {
        x = *(dtype*)p;
        p += stride;
        if (m_lt(x, y)) {
          y = x;
        }
      }
      break;
    }
  }
  return y;
}

static inline dtype f_max_nan(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i = n;

  y = *(dtype*)p;
  p += stride;
  if (!not_nan(y)) {
    return y;
  }
  for (i--; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (!not_nan(x)) {
      return x;
    }
    if (m_gt(x, y)) {
      y = x;
    }
  }
  return y;
}

static inline dtype f_max(size_t n, char* p, ssize_t stride) {
  dtype x, y = m_zero;
  size_t i = n;

  for (; i--;) {
    y = *(dtype*)p;
    p += stride;
    if (not_nan(y)) {
      for (; i--;) {
        x = *(dtype*)p;
        p += stride;
        if (m_gt(x, y)) {
          y = x;
        }
      }
      break;
    }
  }
  return y;
}

static inline size_t f_min_index_nan(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  y = *(dtype*)p;
  p += stride;
  if (!not_nan(y)) {
    return j;
  }
  for (i = 1; i < n; i++) {
    x = *(dtype*)p;
    p += stride;
    if (!not_nan(x)) {
      return i;
    }
    if (m_lt(x, y)) {
      y = x;
      j = i;
    }
  }
  return j;
}

static inline size_t f_min_index(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  for (i = 0; i < n; i++) {
    y = *(dtype*)p;
    p += stride;
    if (not_nan(y)) {
      j = i;
      i++;
      for (; i < n; i++) {
        x = *(dtype*)p;
        p += stride;
        if (m_lt(x, y)) {
          y = x;
          j = i;
        }
      }
      break;
    }
  }
  return j;
}

static inline size_t f_max_index_nan(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  y = *(dtype*)p;
  p += stride;
  if (!not_nan(y)) {
    return j;
  }
  for (i = 1; i < n; i++) {
    x = *(dtype*)p;
    p += stride;
    if (!not_nan(x)) {
      return i;
    }
    if (m_gt(x, y)) {
      y = x;
      j = i;
    }
  }
  return j;
}

static inline size_t f_max_index(size_t n, char* p, ssize_t stride) {
  dtype x, y;
  size_t i, j = 0;

  for (i = 0; i < n; i++) {
    y = *(dtype*)p;
    p += stride;
    if (not_nan(y)) {
      j = i;
      i++;
      for (; i < n; i++) {
        x = *(dtype*)p;
        p += stride;
        if (m_gt(x, y)) {
          y = x;
          j = i;
        }
      }
      break;
    }
  }
  return j;
}

static inline void f_minmax_nan(size_t n, char* p, ssize_t stride, dtype* amin, dtype* amax) {
  dtype x, min, max;
  size_t i = n;

  min = max = *(dtype*)p;
  p += stride;
  if (!not_nan(min)) {
    *amin = *amax = min;
    return;
  }
  for (i--; i--;) {
    x = *(dtype*)p;
    p += stride;
    if (!not_nan(x)) {
      *amin = *amax = x;
      return;
    }
    if (m_lt(x, min)) {
      min = x;
    }
    if (m_gt(x, max)) {
      max = x;
    }
  }
  *amin = min;
  *amax = max;
  return;
}

static inline dtype f_ptp_nan(size_t n, char* p, ssize_t stride) {
  dtype min, max;
  f_minmax_nan(n, p, stride, &min, &max);
  return m_sub(max, min);
}

static inline void f_minmax(size_t n, char* p, ssize_t stride, dtype* amin, dtype* amax) {
  dtype x, min, max;
  size_t i = n;

  min = max = m_zero;
  for (; i--;) {
    min = *(dtype*)p;
    p += stride;
    if (not_nan(min)) {
      max = min;
      for (; i--;) {
        x = *(dtype*)p;
        p += stride;
        if (m_lt(x, min)) {
          min = x;
        }
        if (m_gt(x, max)) {
          max = x;
        }
      }
      break;
    }
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

static inline dtype f_maximum(dtype x, dtype y) {
  if (m_ge(x, y)) {
    return x;
  }
  if (not_nan(y)) {
    return y;
  }
  return x;
}

static inline dtype f_maximum_nan(dtype x, dtype y) {
  if (m_ge(x, y)) {
    return x;
  }
  if (!not_nan(x)) {
    return x;
  }
  return y;
}

static inline dtype f_minimum(dtype x, dtype y) {
  if (m_le(x, y)) {
    return x;
  }
  if (not_nan(y)) {
    return y;
  }
  return x;
}

static inline dtype f_minimum_nan(dtype x, dtype y) {
  if (m_le(x, y)) {
    return x;
  }
  if (!not_nan(x)) {
    return x;
  }
  return y;
}
