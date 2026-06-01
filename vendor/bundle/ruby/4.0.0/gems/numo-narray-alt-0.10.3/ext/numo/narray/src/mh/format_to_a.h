#ifndef NUMO_NARRAY_MH_FORMAT_TO_A_H
#define NUMO_NARRAY_MH_FORMAT_TO_A_H 1

#define DEF_NARRAY_FORMAT_TO_A_METHOD_FUNC(tDType)                                             \
  static void iter_##tDType##_format_to_a(na_loop_t* const lp) {                               \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType* x;                                                                                 \
    VALUE y;                                                                                   \
    volatile VALUE a;                                                                          \
    VALUE fmt = lp->option;                                                                    \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
                                                                                               \
    a = rb_ary_new2(n);                                                                        \
    rb_ary_push(lp->args[1].value, a);                                                         \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = (tDType*)(p1 + *idx1);                                                             \
        idx1++;                                                                                \
        y = format_##tDType(fmt, x);                                                           \
        rb_ary_push(a, y);                                                                     \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = (tDType*)p1;                                                                       \
        p1 += s1;                                                                              \
        y = format_##tDType(fmt, x);                                                           \
        rb_ary_push(a, y);                                                                     \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_format_to_a(int argc, VALUE* argv, VALUE self) {                       \
    VALUE fmt = Qnil;                                                                          \
    ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { sym_loop_opt }, { sym_option } };                \
    ndfunc_arg_out_t aout[1] = { { rb_cArray, 0 } };                                           \
    ndfunc_t ndf = { iter_##tDType##_format_to_a, FULL_LOOP_NIP, 3, 1, ain, aout };            \
    rb_scan_args(argc, argv, "01", &fmt);                                                      \
    return na_ndloop_cast_narray_to_rarray(&ndf, self, fmt);                                   \
  }

#define DEF_NARRAY_BIT_FORMAT_TO_A_METHOD_FUNC()                                               \
  static void iter_bit_format_to_a(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    BIT_DIGIT* a1;                                                                             \
    BIT_DIGIT x = 0;                                                                           \
    size_t p1;                                                                                 \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    VALUE y;                                                                                   \
    VALUE fmt = lp->option;                                                                    \
    volatile VALUE a;                                                                          \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);                                                 \
                                                                                               \
    a = rb_ary_new2(n);                                                                        \
    rb_ary_push(lp->args[1].value, a);                                                         \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1 + *idx1, x);                                                           \
        idx1++;                                                                                \
        y = format_bit(fmt, x);                                                                \
        rb_ary_push(a, y);                                                                     \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1, x);                                                                   \
        p1 += s1;                                                                              \
        y = format_bit(fmt, x);                                                                \
        rb_ary_push(a, y);                                                                     \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE bit_format_to_a(int argc, VALUE* argv, VALUE self) {                            \
    VALUE fmt = Qnil;                                                                          \
    ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { sym_loop_opt }, { sym_option } };                \
    ndfunc_arg_out_t aout[1] = { { rb_cArray, 0 } };                                           \
    ndfunc_t ndf = { iter_bit_format_to_a, FULL_LOOP_NIP, 3, 1, ain, aout };                   \
    rb_scan_args(argc, argv, "01", &fmt);                                                      \
    return na_ndloop_cast_narray_to_rarray(&ndf, self, fmt);                                   \
  }

#endif /* NUMO_NARRAY_MH_FORMAT_TO_A_H */
