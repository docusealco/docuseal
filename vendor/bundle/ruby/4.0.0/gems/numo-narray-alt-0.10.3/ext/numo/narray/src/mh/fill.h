#ifndef NUMO_NARRAY_MH_FILL_H
#define NUMO_NARRAY_MH_FILL_H 1

#define DEF_NARRAY_FILL_METHOD_FUNC(tDType)                                                    \
  static void iter_##tDType##_fill(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    VALUE x = lp->option;                                                                      \
    tDType y;                                                                                  \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    y = m_num_to_data(x);                                                                      \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        SET_DATA_INDEX(p1, idx1, tDType, y);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        SET_DATA_STRIDE(p1, s1, tDType, y);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_fill(VALUE self, VALUE val) {                                          \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_option } };                             \
    ndfunc_t ndf = { iter_##tDType##_fill, FULL_LOOP, 2, 0, ain, 0 };                          \
    na_ndloop(&ndf, 2, self, val);                                                             \
    return self;                                                                               \
  }

#define DEF_NARRAY_BIT_FILL_METHOD_FUNC()                                                      \
  static void iter_bit_fill(na_loop_t* const lp) {                                             \
    size_t n;                                                                                  \
    size_t p3;                                                                                 \
    ssize_t s3;                                                                                \
    size_t* idx3;                                                                              \
    int len;                                                                                   \
    BIT_DIGIT* a3;                                                                             \
    BIT_DIGIT y;                                                                               \
    VALUE x = lp->option;                                                                      \
                                                                                               \
    if (x == INT2FIX(0) || x == Qfalse) {                                                      \
      y = 0;                                                                                   \
    } else if (x == INT2FIX(1) || x == Qtrue) {                                                \
      y = ~(BIT_DIGIT)0;                                                                       \
    } else {                                                                                   \
      rb_raise(rb_eArgError, "invalid value for Bit");                                         \
    }                                                                                          \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_BIT_IDX(lp, 0, a3, p3, s3, idx3);                                                 \
    if (idx3) {                                                                                \
      y = y & 1;                                                                               \
      for (size_t i = 0; i < n; i++) {                                                         \
        STORE_BIT(a3, p3 + *idx3, y);                                                          \
        idx3++;                                                                                \
      }                                                                                        \
    } else if (s3 != 1) {                                                                      \
      y = y & 1;                                                                               \
      for (size_t i = 0; i < n; i++) {                                                         \
        STORE_BIT(a3, p3, y);                                                                  \
        p3 += s3;                                                                              \
      }                                                                                        \
    } else {                                                                                   \
      if (p3 > 0 || n < NB) {                                                                  \
        len = (int)(NB - p3);                                                                  \
        if ((int)n < len) {                                                                    \
          len = (int)n;                                                                        \
        }                                                                                      \
        *a3 = (y & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));                              \
        a3++;                                                                                  \
        n -= len;                                                                              \
      }                                                                                        \
      for (; n >= NB; n -= NB) {                                                               \
        *(a3++) = y;                                                                           \
      }                                                                                        \
      if (n > 0) {                                                                             \
        *a3 = (y & SLB(n)) | (*a3 & BALL << n);                                                \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE bit_fill(VALUE self, VALUE val) {                                               \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_option } };                             \
    ndfunc_t ndf = { iter_bit_fill, FULL_LOOP, 2, 0, ain, 0 };                                 \
    na_ndloop(&ndf, 2, self, val);                                                             \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_FILL_H */
