#ifndef NUMO_NARRAY_MH_POW_H
#define NUMO_NARRAY_MH_POW_H 1

#define DEF_NARRAY_POW_METHOD_FUNC(tDType, tNAryClass)                                         \
  static void iter_##tDType##_pow(na_loop_t* const lp) {                                       \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      x = m_pow(x, y);                                                                         \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_pow_int32(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    tDType x;                                                                                  \
    int32_t y;                                                                                 \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, int32_t, y);                                                     \
      x = m_pow_int(x, y);                                                                     \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_pow_self(VALUE self, VALUE other) {                                    \
    ndfunc_arg_in_t ain_i[2] = { { tNAryClass, 0 }, { numo_cInt32, 0 } };                      \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf_i = { iter_##tDType##_pow_int32, STRIDE_LOOP, 2, 1, ain_i, aout };            \
    ndfunc_t ndf = { iter_##tDType##_pow, STRIDE_LOOP, 2, 1, ain, aout };                      \
    if (FIXNUM_P(other) || rb_obj_is_kind_of(other, numo_cInt32)) {                            \
      return na_ndloop(&ndf_i, 2, self, other);                                                \
    }                                                                                          \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_pow(VALUE self, VALUE other) {                                         \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_pow_self(self, other);                                                   \
    }                                                                                          \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
    return rb_funcall(v, id_pow, 1, other);                                                    \
  }

#define DEF_NARRAY_INT64_POW_METHOD_FUNC(tDType, tNAryClass)                                   \
  static void iter_##tDType##_pow(na_loop_t* const lp) {                                       \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      x = m_pow(x, (int)y);                                                                    \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_pow_int32(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    tDType x;                                                                                  \
    int32_t y;                                                                                 \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, int32_t, y);                                                     \
      x = m_pow_int(x, y);                                                                     \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_pow_self(VALUE self, VALUE other) {                                    \
    ndfunc_arg_in_t ain_i[2] = { { tNAryClass, 0 }, { numo_cInt32, 0 } };                      \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf_i = { iter_##tDType##_pow_int32, STRIDE_LOOP, 2, 1, ain_i, aout };            \
    ndfunc_t ndf = { iter_##tDType##_pow, STRIDE_LOOP, 2, 1, ain, aout };                      \
    if (FIXNUM_P(other) || rb_obj_is_kind_of(other, numo_cInt32)) {                            \
      return na_ndloop(&ndf_i, 2, self, other);                                                \
    }                                                                                          \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_pow(VALUE self, VALUE other) {                                         \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_pow_self(self, other);                                                   \
    }                                                                                          \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
    return rb_funcall(v, id_pow, 1, other);                                                    \
  }

#define DEF_NARRAY_ROBJ_POW_METHOD_FUNC()                                                      \
  static void iter_robject_pow(na_loop_t* const lp) {                                          \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    robject x;                                                                                 \
    robject y;                                                                                 \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, robject, x);                                                     \
      GET_DATA_STRIDE(p2, s2, robject, y);                                                     \
      x = m_pow(x, y);                                                                         \
      SET_DATA_STRIDE(p3, s3, robject, x);                                                     \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_robject_pow_int32(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    robject x;                                                                                 \
    int32_t y;                                                                                 \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, robject, x);                                                     \
      GET_DATA_STRIDE(p2, s2, int32_t, y);                                                     \
      x = m_pow_int(x, y);                                                                     \
      SET_DATA_STRIDE(p3, s3, robject, x);                                                     \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE robject_pow_self(VALUE self, VALUE other) {                                     \
    ndfunc_arg_in_t ain_i[2] = { { numo_cRObject, 0 }, { numo_cInt32, 0 } };                   \
    ndfunc_arg_in_t ain[2] = { { numo_cRObject, 0 }, { numo_cRObject, 0 } };                   \
    ndfunc_arg_out_t aout[1] = { { numo_cRObject, 0 } };                                       \
    ndfunc_t ndf_i = { iter_robject_pow_int32, STRIDE_LOOP, 2, 1, ain_i, aout };               \
    ndfunc_t ndf = { iter_robject_pow, STRIDE_LOOP, 2, 1, ain, aout };                         \
    if (FIXNUM_P(other) || rb_obj_is_kind_of(other, numo_cInt32)) {                            \
      return na_ndloop(&ndf_i, 2, self, other);                                                \
    }                                                                                          \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE robject_pow(VALUE self, VALUE other) {                                          \
    return robject_pow_self(self, other);                                                      \
  }

#endif /* NUMO_NARRAY_MH_POW_H */
