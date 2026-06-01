#ifndef NUMO_NARRAY_MH_MINIMUM_H
#define NUMO_NARRAY_MH_MINIMUM_H 1

#define DEF_NARRAY_FLT_MINIMUM_METHOD_FUNC(tDType, tNAryClass)                                 \
  static void iter_##tDType##_s_minimum(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      tDType x;                                                                                \
      tDType y;                                                                                \
      tDType z;                                                                                \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      GET_DATA(p3, tDType, z);                                                                 \
      z = f_minimum(x, y);                                                                     \
      SET_DATA_STRIDE(p3, s3, tDType, z);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_s_minimum_nan(na_loop_t* const lp) {                             \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      tDType x;                                                                                \
      tDType y;                                                                                \
      tDType z;                                                                                \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      GET_DATA(p3, tDType, z);                                                                 \
      z = f_minimum_nan(x, y);                                                                 \
      SET_DATA_STRIDE(p3, s3, tDType, z);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_s_minimum(int argc, VALUE* argv, VALUE mod) {                          \
    VALUE a1 = Qnil;                                                                           \
    VALUE a2 = Qnil;                                                                           \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_s_minimum, STRIDE_LOOP_NIP, 2, 1, ain, aout };            \
                                                                                               \
    VALUE kw_hash = Qnil;                                                                      \
    ID kw_table[1] = { id_nan };                                                               \
    VALUE opts[1] = { Qundef };                                                                \
                                                                                               \
    rb_scan_args(argc, argv, "20:", &a1, &a2, &kw_hash);                                       \
    rb_get_kwargs(kw_hash, kw_table, 0, 1, opts);                                              \
    if (opts[0] != Qundef) {                                                                   \
      ndf.func = iter_##tDType##_s_minimum_nan;                                                \
    }                                                                                          \
                                                                                               \
    return na_ndloop(&ndf, 2, a1, a2);                                                         \
  }

#define DEF_NARRAY_INT_MINIMUM_METHOD_FUNC(tDType, tNAryClass)                                 \
  static void iter_##tDType##_s_minimum(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      tDType x;                                                                                \
      tDType y;                                                                                \
      tDType z;                                                                                \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      GET_DATA(p3, tDType, z);                                                                 \
      z = f_minimum(x, y);                                                                     \
      SET_DATA_STRIDE(p3, s3, tDType, z);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_s_minimum(int argc, VALUE* argv, VALUE mod) {                          \
    VALUE a1 = Qnil;                                                                           \
    VALUE a2 = Qnil;                                                                           \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_s_minimum, STRIDE_LOOP_NIP, 2, 1, ain, aout };            \
                                                                                               \
    rb_scan_args(argc, argv, "20", &a1, &a2);                                                  \
                                                                                               \
    return na_ndloop(&ndf, 2, a1, a2);                                                         \
  }

#endif /* NUMO_NARRAY_MH_MINIMUM_H */
