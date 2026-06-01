#ifndef NUMO_NARRAY_MH_FORMAT_H
#define NUMO_NARRAY_MH_FORMAT_H 1

#define DEF_NARRAY_FORMAT_METHOD_FUNC(tDType)                                                  \
  static VALUE format_##tDType(VALUE fmt, tDType* x) {                                         \
    if (NIL_P(fmt)) {                                                                          \
      char s[48];                                                                              \
      int n = m_sprintf(s, *x);                                                                \
      return rb_str_new(s, n);                                                                 \
    }                                                                                          \
    return rb_funcall(fmt, '%', 1, m_data_to_num(*x));                                         \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_format(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    tDType* x;                                                                                 \
    VALUE y;                                                                                   \
    VALUE fmt = lp->option;                                                                    \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = (tDType*)(p1 + *idx1);                                                             \
        idx1++;                                                                                \
        y = format_##tDType(fmt, x);                                                           \
        SET_DATA_STRIDE(p2, s2, VALUE, y);                                                     \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = (tDType*)p1;                                                                       \
        p1 += s1;                                                                              \
        y = format_##tDType(fmt, x);                                                           \
        SET_DATA_STRIDE(p2, s2, VALUE, y);                                                     \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_format(int argc, VALUE* argv, VALUE self) {                            \
    VALUE fmt = Qnil;                                                                          \
    ndfunc_arg_in_t ain[2] = { { Qnil, 0 }, { sym_option } };                                  \
    ndfunc_arg_out_t aout[1] = { { numo_cRObject, 0 } };                                       \
    ndfunc_t ndf = { iter_##tDType##_format, FULL_LOOP_NIP, 2, 1, ain, aout };                 \
    rb_scan_args(argc, argv, "01", &fmt);                                                      \
    return na_ndloop(&ndf, 2, self, fmt);                                                      \
  }

#define DEF_NARRAY_BIT_FORMAT_METHOD_FUNC()                                                    \
  static VALUE format_bit(VALUE fmt, BIT_DIGIT x) {                                            \
    if (NIL_P(fmt)) {                                                                          \
      char s[4];                                                                               \
      int n;                                                                                   \
      n = m_sprintf(s, x);                                                                     \
      return rb_str_new(s, n);                                                                 \
    }                                                                                          \
    return rb_funcall(fmt, '%', 1, m_data_to_num(x));                                          \
  }                                                                                            \
                                                                                               \
  static void iter_bit_format(na_loop_t* const lp) {                                           \
    size_t n;                                                                                  \
    BIT_DIGIT* a1;                                                                             \
    BIT_DIGIT x = 0;                                                                           \
    size_t p1;                                                                                 \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    VALUE y;                                                                                   \
    VALUE fmt = lp->option;                                                                    \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);                                                 \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
                                                                                               \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1 + *idx1, x);                                                           \
        idx1++;                                                                                \
        y = format_bit(fmt, x);                                                                \
        SET_DATA_STRIDE(p2, s2, VALUE, y);                                                     \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1, x);                                                                   \
        p1 += s1;                                                                              \
        y = format_bit(fmt, x);                                                                \
        SET_DATA_STRIDE(p2, s2, VALUE, y);                                                     \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE bit_format(int argc, VALUE* argv, VALUE self) {                                 \
    VALUE fmt = Qnil;                                                                          \
    ndfunc_arg_in_t ain[2] = { { Qnil, 0 }, { sym_option } };                                  \
    ndfunc_arg_out_t aout[1] = { { numo_cRObject, 0 } };                                       \
    ndfunc_t ndf = { iter_bit_format, FULL_LOOP_NIP, 2, 1, ain, aout };                        \
    rb_scan_args(argc, argv, "01", &fmt);                                                      \
    return na_ndloop(&ndf, 2, self, fmt);                                                      \
  }

#endif /* NUMO_NARRAY_MH_FORMAT_H */
