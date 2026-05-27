#ifndef NUMO_NARRAY_MH_DIVMOD_H
#define NUMO_NARRAY_MH_DIVMOD_H 1

#define DEF_NARRAY_FLT_DIVMOD_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_divmod(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    char* p4;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    ssize_t s4;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    INIT_PTR(lp, 3, p4, s4);                                                                   \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    tDType a;                                                                                  \
    tDType b;                                                                                  \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      m_divmod(x, y, a, b);                                                                    \
      SET_DATA_STRIDE(p3, s3, tDType, a);                                                      \
      SET_DATA_STRIDE(p4, s4, tDType, b);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_divmod_self(VALUE self, VALUE other) {                                 \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                       \
    ndfunc_t ndf = { iter_##tDType##_divmod, STRIDE_LOOP, 2, 2, ain, aout };                   \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_divmod(VALUE self, VALUE other) {                                      \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_divmod_self(self, other);                                                \
    }                                                                                          \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
    return rb_funcall(v, id_divmod, 1, other);                                                 \
  }

#define DEF_NARRAY_INT_DIVMOD_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_divmod(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    char* p4;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    ssize_t s4;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    INIT_PTR(lp, 3, p4, s4);                                                                   \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    tDType a;                                                                                  \
    tDType b;                                                                                  \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      if (y == 0) {                                                                            \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      m_divmod(x, y, a, b);                                                                    \
      SET_DATA_STRIDE(p3, s3, tDType, a);                                                      \
      SET_DATA_STRIDE(p4, s4, tDType, b);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_divmod_self(VALUE self, VALUE other) {                                 \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                       \
    ndfunc_t ndf = { iter_##tDType##_divmod, STRIDE_LOOP, 2, 2, ain, aout };                   \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_divmod(VALUE self, VALUE other) {                                      \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_divmod_self(self, other);                                                \
    }                                                                                          \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
    return rb_funcall(v, id_divmod, 1, other);                                                 \
  }

#define DEF_NARRAY_ROBJ_DIVMOD_METHOD_FUNC()                                                   \
  static void iter_robject_divmod(na_loop_t* const lp) {                                       \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    char* p4;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    ssize_t s4;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    INIT_PTR(lp, 3, p4, s4);                                                                   \
    robject x;                                                                                 \
    robject y;                                                                                 \
    robject a;                                                                                 \
    robject b;                                                                                 \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, robject, x);                                                     \
      GET_DATA_STRIDE(p2, s2, robject, y);                                                     \
      if (y == 0) {                                                                            \
        lp->err_type = rb_eZeroDivError;                                                       \
        return;                                                                                \
      }                                                                                        \
      m_divmod(x, y, a, b);                                                                    \
      SET_DATA_STRIDE(p3, s3, robject, a);                                                     \
      SET_DATA_STRIDE(p4, s4, robject, b);                                                     \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE robject_divmod_self(VALUE self, VALUE other) {                                  \
    ndfunc_arg_in_t ain[2] = { { numo_cRObject, 0 }, { numo_cRObject, 0 } };                   \
    ndfunc_arg_out_t aout[2] = { { numo_cRObject, 0 }, { numo_cRObject, 0 } };                 \
    ndfunc_t ndf = { iter_robject_divmod, STRIDE_LOOP, 2, 2, ain, aout };                      \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE robject_divmod(VALUE self, VALUE other) {                                       \
    return robject_divmod_self(self, other);                                                   \
  }

#endif /* NUMO_NARRAY_MH_DIVMOD_H */
