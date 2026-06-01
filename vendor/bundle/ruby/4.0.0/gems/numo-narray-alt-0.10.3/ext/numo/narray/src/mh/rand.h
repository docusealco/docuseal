#ifndef NUMO_NARRAY_MH_RAND_H
#define NUMO_NARRAY_MH_RAND_H 1

#define DEF_NARRAY_CMP_RAND_METHOD_FUNC(tDType)                                                \
  typedef struct {                                                                             \
    tDType low;                                                                                \
    tDType max;                                                                                \
  } rand_opt_t;                                                                                \
                                                                                               \
  static void iter_##tDType##_rand(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    rand_opt_t* g;                                                                             \
    tDType low;                                                                                \
    tDType max;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (rand_opt_t*)(lp->opt_ptr);                                                            \
    low = g->low;                                                                              \
    max = g->max;                                                                              \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max), low);                                                           \
        SET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max), low);                                                           \
        SET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand(int argc, VALUE* argv, VALUE self) {                              \
    rand_opt_t g;                                                                              \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    tDType high;                                                                               \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand, FULL_LOOP, 1, 0, ain, 0 };                          \
                                                                                               \
    rb_scan_args(argc, argv, "02", &v1, &v2);                                                  \
    if (v2 == Qnil) {                                                                          \
      g.low = m_zero;                                                                          \
      if (v1 == Qnil) {                                                                        \
        g.max = high = c_new(1, 1);                                                            \
      } else {                                                                                 \
        g.max = high = m_num_to_data(v1);                                                      \
      }                                                                                        \
    } else {                                                                                   \
      g.low = m_num_to_data(v1);                                                               \
      high = m_num_to_data(v2);                                                                \
      g.max = m_sub(high, g.low);                                                              \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#define DEF_NARRAY_FLT_RAND_METHOD_FUNC(tDType)                                                \
  typedef struct {                                                                             \
    tDType low;                                                                                \
    tDType max;                                                                                \
  } rand_opt_t;                                                                                \
                                                                                               \
  static void iter_##tDType##_rand(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    rand_opt_t* g;                                                                             \
    tDType low;                                                                                \
    tDType max;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (rand_opt_t*)(lp->opt_ptr);                                                            \
    low = g->low;                                                                              \
    max = g->max;                                                                              \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max), low);                                                           \
        SET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max), low);                                                           \
        SET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand(int argc, VALUE* args, VALUE self) {                              \
    rand_opt_t g;                                                                              \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    tDType high;                                                                               \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand, FULL_LOOP, 1, 0, ain, 0 };                          \
                                                                                               \
    rb_scan_args(argc, args, "02", &v1, &v2);                                                  \
    if (v2 == Qnil) {                                                                          \
      g.low = m_zero;                                                                          \
      if (v1 == Qnil) {                                                                        \
        g.max = high = m_one;                                                                  \
      } else {                                                                                 \
        g.max = high = m_num_to_data(v1);                                                      \
      }                                                                                        \
    } else {                                                                                   \
      g.low = m_num_to_data(v1);                                                               \
      high = m_num_to_data(v2);                                                                \
      g.max = m_sub(high, g.low);                                                              \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#define DEF_NARRAY_INT_RAND_METHOD_FUNC(tDType)                                                \
  static int msb_pos(uint32_t a) {                                                             \
    const int hwid = 4 * sizeof(tDType);                                                       \
    int width = hwid;                                                                          \
    int pos = 0;                                                                               \
    uint32_t mask = (((tDType)1 << hwid) - 1) << hwid;                                         \
                                                                                               \
    if (a == 0) {                                                                              \
      return -1;                                                                               \
    }                                                                                          \
                                                                                               \
    while (width) {                                                                            \
      if (a & mask) {                                                                          \
        pos += width;                                                                          \
      } else {                                                                                 \
        mask >>= width;                                                                        \
      }                                                                                        \
      width >>= 1;                                                                             \
      mask &= mask << width;                                                                   \
    }                                                                                          \
    return pos;                                                                                \
  }                                                                                            \
                                                                                               \
  inline static tDType m_rand(uint32_t max, int shift) {                                       \
    uint32_t x;                                                                                \
    do {                                                                                       \
      x = gen_rand32();                                                                        \
      x >>= shift;                                                                             \
    } while (x >= max);                                                                        \
    return x;                                                                                  \
  }                                                                                            \
                                                                                               \
  typedef struct {                                                                             \
    tDType low;                                                                                \
    uint32_t max;                                                                              \
  } rand_opt_t;                                                                                \
                                                                                               \
  static void iter_##tDType##_rand(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    rand_opt_t* g;                                                                             \
    tDType low;                                                                                \
    uint32_t max;                                                                              \
    int shift;                                                                                 \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (rand_opt_t*)(lp->opt_ptr);                                                            \
    low = g->low;                                                                              \
    max = g->max;                                                                              \
    shift = 31 - msb_pos(max);                                                                 \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max, shift), low);                                                    \
        SET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max, shift), low);                                                    \
        SET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand(int argc, VALUE* argv, VALUE self) {                              \
    rand_opt_t g;                                                                              \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    tDType high;                                                                               \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand, FULL_LOOP, 1, 0, ain, 0 };                          \
                                                                                               \
    rb_scan_args(argc, argv, "11", &v1, &v2);                                                  \
    if (v2 == Qnil) {                                                                          \
      g.low = m_zero;                                                                          \
      g.max = high = m_num_to_data(v1);                                                        \
    } else {                                                                                   \
      g.low = m_num_to_data(v1);                                                               \
      high = m_num_to_data(v2);                                                                \
      g.max = m_sub(high, g.low);                                                              \
    }                                                                                          \
                                                                                               \
    if (high <= g.low) {                                                                       \
      rb_raise(rb_eArgError, "high must be larger than low");                                  \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#define DEF_NARRAY_INT64_RAND_METHOD_FUNC(tDType)                                              \
  static int msb_pos(uint64_t a) {                                                             \
    const int hwid = 4 * sizeof(tDType);                                                       \
    int width = hwid;                                                                          \
    int pos = 0;                                                                               \
    uint64_t mask = (((tDType)1 << hwid) - 1) << hwid;                                         \
                                                                                               \
    if (a == 0) {                                                                              \
      return -1;                                                                               \
    }                                                                                          \
                                                                                               \
    while (width) {                                                                            \
      if (a & mask) {                                                                          \
        pos += width;                                                                          \
      } else {                                                                                 \
        mask >>= width;                                                                        \
      }                                                                                        \
      width >>= 1;                                                                             \
      mask &= mask << width;                                                                   \
    }                                                                                          \
    return pos;                                                                                \
  }                                                                                            \
                                                                                               \
  inline static tDType m_rand(uint64_t max, int shift) {                                       \
    uint64_t x;                                                                                \
    do {                                                                                       \
      x = gen_rand32();                                                                        \
      x = (x << 32) | gen_rand32();                                                            \
      x >>= shift;                                                                             \
    } while (x >= max);                                                                        \
    return x;                                                                                  \
  }                                                                                            \
                                                                                               \
  typedef struct {                                                                             \
    tDType low;                                                                                \
    uint64_t max;                                                                              \
  } rand_opt_t;                                                                                \
                                                                                               \
  static void iter_##tDType##_rand(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    rand_opt_t* g;                                                                             \
    tDType low;                                                                                \
    uint64_t max;                                                                              \
    int shift;                                                                                 \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (rand_opt_t*)(lp->opt_ptr);                                                            \
    low = g->low;                                                                              \
    max = g->max;                                                                              \
    shift = 63 - msb_pos(max);                                                                 \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max, shift), low);                                                    \
        SET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = m_add(m_rand(max, shift), low);                                                    \
        SET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand(int argc, VALUE* argv, VALUE self) {                              \
    rand_opt_t g;                                                                              \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    tDType high;                                                                               \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand, FULL_LOOP, 1, 0, ain, 0 };                          \
                                                                                               \
    rb_scan_args(argc, argv, "11", &v1, &v2);                                                  \
    if (v2 == Qnil) {                                                                          \
      g.low = m_zero;                                                                          \
      g.max = high = m_num_to_data(v1);                                                        \
    } else {                                                                                   \
      g.low = m_num_to_data(v1);                                                               \
      high = m_num_to_data(v2);                                                                \
      g.max = m_sub(high, g.low);                                                              \
    }                                                                                          \
                                                                                               \
    if (high <= g.low) {                                                                       \
      rb_raise(rb_eArgError, "high must be larger than low");                                  \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_RAND_H */
