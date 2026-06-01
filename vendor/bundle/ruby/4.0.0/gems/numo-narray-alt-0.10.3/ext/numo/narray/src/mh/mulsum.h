#ifndef NUMO_NARRAY_MH_MULSUM_H
#define NUMO_NARRAY_MH_MULSUM_H 1

#define DEF_NARRAY_FLT_MULSUM_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_mulsum(na_loop_t* const lp) {                                    \
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
    if (s3 == 0) {                                                                             \
      tDType z;                                                                                \
      GET_DATA(p3, tDType, z);                                                                 \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x;                                                                              \
        tDType y;                                                                              \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        m_mulsum(x, y, z);                                                                     \
      }                                                                                        \
      SET_DATA(p3, tDType, z);                                                                 \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x;                                                                              \
        tDType y;                                                                              \
        tDType z;                                                                              \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        GET_DATA(p3, tDType, z);                                                               \
        m_mulsum(x, y, z);                                                                     \
        SET_DATA_STRIDE(p3, s3, tDType, z);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_mulsum_nan(na_loop_t* const lp) {                                \
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
    if (s3 == 0) {                                                                             \
      tDType z;                                                                                \
      GET_DATA(p3, tDType, z);                                                                 \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x;                                                                              \
        tDType y;                                                                              \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        m_mulsum_nan(x, y, z);                                                                 \
      }                                                                                        \
      SET_DATA(p3, tDType, z);                                                                 \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x;                                                                              \
        tDType y;                                                                              \
        tDType z;                                                                              \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        GET_DATA(p3, tDType, z);                                                               \
        m_mulsum_nan(x, y, z);                                                                 \
        SET_DATA_STRIDE(p3, s3, tDType, z);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_mulsum_self(int argc, VALUE* argv, VALUE self) {                       \
    if (argc < 1) {                                                                            \
      rb_raise(rb_eArgError, "wrong number of arguments (%d for >=1)", argc);                  \
    }                                                                                          \
                                                                                               \
    ndfunc_arg_in_t ain[4] = {                                                                 \
      { tNAryClass, 0 }, { tNAryClass, 0 }, { sym_reduce, 0 }, { sym_init, 0 }                 \
    };                                                                                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_mulsum, STRIDE_LOOP_NIP, 4, 1, ain, aout };               \
    VALUE naryv[2] = { self, argv[0] };                                                        \
    VALUE reduce =                                                                             \
      na_reduce_dimension(argc - 1, argv + 1, 2, naryv, &ndf, iter_##tDType##_mulsum_nan);     \
    VALUE v = na_ndloop(&ndf, 4, self, argv[0], reduce, m_mulsum_init);                        \
                                                                                               \
    return rb_funcall(v, rb_intern("extract"), 0);                                             \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_mulsum(int argc, VALUE* argv, VALUE self) {                            \
    if (argc < 1) {                                                                            \
      rb_raise(rb_eArgError, "wrong number of arguments (%d for >=1)", argc);                  \
    }                                                                                          \
                                                                                               \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(argv[0]));                        \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_mulsum_self(argc, argv, self);                                           \
    }                                                                                          \
                                                                                               \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
                                                                                               \
    return rb_funcallv_kw(v, rb_intern("mulsum"), argc, argv, RB_PASS_CALLED_KEYWORDS);        \
  }

#define DEF_NARRAY_INT_MULSUM_METHOD_FUNC(tDType, tNAryClass)                                  \
  static void iter_##tDType##_mulsum(na_loop_t* const lp) {                                    \
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
    if (s3 == 0) {                                                                             \
      tDType z;                                                                                \
      GET_DATA(p3, tDType, z);                                                                 \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x, y;                                                                           \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        m_mulsum(x, y, z);                                                                     \
      }                                                                                        \
      SET_DATA(p3, tDType, z);                                                                 \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        tDType x, y, z;                                                                        \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        GET_DATA_STRIDE(p2, s2, tDType, y);                                                    \
        GET_DATA(p3, tDType, z);                                                               \
        m_mulsum(x, y, z);                                                                     \
        SET_DATA_STRIDE(p3, s3, tDType, z);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_mulsum_self(int argc, VALUE* argv, VALUE self) {                       \
    if (argc < 1) {                                                                            \
      rb_raise(rb_eArgError, "wrong number of arguments (%d for >=1)", argc);                  \
    }                                                                                          \
                                                                                               \
    ndfunc_arg_in_t ain[4] = {                                                                 \
      { tNAryClass, 0 }, { tNAryClass, 0 }, { sym_reduce, 0 }, { sym_init, 0 }                 \
    };                                                                                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_mulsum, STRIDE_LOOP_NIP, 4, 1, ain, aout };               \
    VALUE naryv[2] = { self, argv[0] };                                                        \
    VALUE reduce = na_reduce_dimension(argc - 1, argv + 1, 2, naryv, &ndf, 0);                 \
    VALUE v = na_ndloop(&ndf, 4, self, argv[0], reduce, m_mulsum_init);                        \
                                                                                               \
    return rb_funcall(v, rb_intern("extract"), 0);                                             \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_mulsum(int argc, VALUE* argv, VALUE self) {                            \
    if (argc < 1) {                                                                            \
      rb_raise(rb_eArgError, "wrong number of arguments (%d for >=1)", argc);                  \
    }                                                                                          \
                                                                                               \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(argv[0]));                        \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_mulsum_self(argc, argv, self);                                           \
    }                                                                                          \
                                                                                               \
    VALUE v = rb_funcall(klass, id_cast, 1, self);                                             \
                                                                                               \
    return rb_funcallv_kw(v, rb_intern("mulsum"), argc, argv, RB_PASS_CALLED_KEYWORDS);        \
  }

#endif /* NUMO_NARRAY_MH_MULSUM_H */
