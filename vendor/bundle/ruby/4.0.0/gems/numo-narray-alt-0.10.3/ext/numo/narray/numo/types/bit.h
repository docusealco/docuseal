typedef BIT_DIGIT dtype;
typedef BIT_DIGIT rtype;
#define cT numo_cBit
#define cRT cT

#define m_zero 0
#define m_one 1

#define m_abs(x) (x)
#define m_sign(x) (((x) == 0) ? 0 : 1)

#define m_from_double(x) (((x) == 0) ? 0 : 1)
#define m_from_real(x) (((x) == 0) ? 0 : 1)
#define m_from_sint(x) (((x) == 0) ? 0 : 1)
#define m_from_int32(x) (((x) == 0) ? 0 : 1)
#define m_from_int64(x) (((x) == 0) ? 0 : 1)
#define m_from_uint32(x) (((x) == 0) ? 0 : 1)
#define m_from_uint64(x) (((x) == 0) ? 0 : 1)
#define m_data_to_num(x) INT2FIX(x)
#define m_sprintf(s, x) sprintf(s, "%1d", (int)(x))

#define m_add(x, y) ((x) + (y))
#define m_div(x, y) ((x) / (y))

#define m_copy(x) (x)
#define m_not(x) (~(x))
#define m_and(x, y) ((x) & (y))
#define m_or(x, y) ((x) | (y))
#define m_xor(x, y) ((x) ^ (y))
#define m_eq(x, y) (~((x) ^ (y)))
#define m_count_true(x) ((x) != 0)
#define m_count_false(x) ((x) == 0)

static inline BIT_DIGIT m_num_to_data(VALUE num) {
  if (RTEST(num)) {
    if (!RTEST(rb_equal(num, INT2FIX(0)))) {
      return 1;
    }
  }
  return 0;
}

static inline double f_mean(size_t n, BIT_DIGIT* p, size_t pos, ssize_t stride, size_t* idx) {
  size_t count = 0;
  double sum = 0.0;
  BIT_DIGIT x;
  if (idx) {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos + *idx, x);
      idx++;
      sum += (double)x;
      count++;
    }
  } else {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos, x);
      pos += stride;
      sum += (double)x;
      count++;
    }
  }
  return sum / (double)count;
}

static inline double f_var(size_t n, BIT_DIGIT* p, size_t pos, ssize_t stride, size_t* idx) {
  size_t count = 0;
  double sum = 0.0;
  BIT_DIGIT x;
  const double mean = f_mean(n, p, pos, stride, idx);
  if (idx) {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos + *idx, x);
      const double d = (double)x - mean;
      idx++;
      sum += d * d;
      count++;
    }
  } else {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos, x);
      const double d = (double)x - mean;
      pos += stride;
      sum += d * d;
      count++;
    }
  }
  return sum / (double)(count - 1);
}

static inline double f_stddev(size_t n, BIT_DIGIT* p, size_t pos, ssize_t stride, size_t* idx) {
  return sqrt(f_var(n, p, pos, stride, idx));
}

static inline double f_rms(size_t n, BIT_DIGIT* p, size_t pos, ssize_t stride, size_t* idx) {
  size_t count = 0;
  double sum = 0.0;
  BIT_DIGIT x;
  if (idx) {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos + *idx, x);
      idx++;
      sum += (double)(x * x);
      count++;
    }
  } else {
    for (size_t i = n; i--;) {
      LOAD_BIT(p, pos, x);
      pos += stride;
      sum += (double)(x * x);
      count++;
    }
  }
  return sqrt(sum / (double)count);
}
