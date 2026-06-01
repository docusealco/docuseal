#ifndef NUMO_NARRAY_MH_BINCOUNT_H
#define NUMO_NARRAY_MH_BINCOUNT_H 1

#define DEF_BINCOUNT_FUNCS(tDType, tNAryClass)                                                 \
  static void iter_##tDType##_bincount_32(na_loop_t* const lp) {                               \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    const size_t m = lp->args[0].shape[0];                                                     \
    const size_t n = lp->args[1].shape[0];                                                     \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(u_int32_t*)(p2 + s2 * i) = 0;                                                          \
    }                                                                                          \
                                                                                               \
    size_t x;                                                                                  \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < m; i++) {                                                         \
        GET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
        (*(u_int32_t*)(p2 + s2 * x))++;                                                        \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < m; i++) {                                                         \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        (*(u_int32_t*)(p2 + s2 * x))++;                                                        \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bincount_32(VALUE self, size_t length) {                               \
    size_t shape_out[1] = { length };                                                          \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 1 } };                                            \
    ndfunc_arg_out_t aout[1] = { { numo_cUInt32, 1, shape_out } };                             \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_bincount_32, NO_LOOP | NDF_STRIDE_LOOP | NDF_INDEX_LOOP, 1, 1, ain, aout \
    };                                                                                         \
    return na_ndloop(&ndf, 1, self);                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_bincount_64(na_loop_t* const lp) {                               \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    const size_t m = lp->args[0].shape[0];                                                     \
    const size_t n = lp->args[1].shape[0];                                                     \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(u_int64_t*)(p2 + s2 * i) = 0;                                                          \
    }                                                                                          \
                                                                                               \
    size_t x;                                                                                  \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < m; i++) {                                                         \
        GET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
        (*(u_int64_t*)(p2 + s2 * x))++;                                                        \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < m; i++) {                                                         \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        (*(u_int64_t*)(p2 + s2 * x))++;                                                        \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bincount_64(VALUE self, size_t length) {                               \
    size_t shape_out[1] = { length };                                                          \
    ndfunc_arg_in_t ain[1] = { { tNAryClass, 1 } };                                            \
    ndfunc_arg_out_t aout[1] = { { numo_cUInt64, 1, shape_out } };                             \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_bincount_64, NO_LOOP | NDF_STRIDE_LOOP | NDF_INDEX_LOOP, 1, 1, ain, aout \
    };                                                                                         \
    return na_ndloop(&ndf, 1, self);                                                           \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_bincount_sf(na_loop_t* const lp) {                               \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    const size_t l = lp->args[0].shape[0];                                                     \
    const size_t m = lp->args[1].shape[0];                                                     \
    const size_t n = lp->args[2].shape[0];                                                     \
                                                                                               \
    if (l != m) {                                                                              \
      rb_raise(nary_eShapeError, "size mismatch along last axis between self and weight");     \
    }                                                                                          \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(float*)(p3 + s3 * i) = 0;                                                              \
    }                                                                                          \
    size_t x;                                                                                  \
    float w;                                                                                   \
    for (size_t i = 0; i < l; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, float, w);                                                       \
      (*(float*)(p3 + s3 * x)) += w;                                                           \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bincount_sf(VALUE self, VALUE weight, size_t length) {                 \
    size_t shape_out[1] = { length };                                                          \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 1 }, { numo_cSFloat, 1 } };                       \
    ndfunc_arg_out_t aout[1] = { { numo_cSFloat, 1, shape_out } };                             \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_bincount_sf, NO_LOOP | NDF_STRIDE_LOOP, 2, 1, ain, aout                  \
    };                                                                                         \
    return na_ndloop(&ndf, 2, self, weight);                                                   \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_bincount_df(na_loop_t* const lp) {                               \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    const size_t l = lp->args[0].shape[0];                                                     \
    const size_t m = lp->args[1].shape[0];                                                     \
    const size_t n = lp->args[2].shape[0];                                                     \
                                                                                               \
    if (l != m) {                                                                              \
      rb_raise(nary_eShapeError, "size mismatch along last axis between self and weight");     \
    }                                                                                          \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      *(double*)(p3 + s3 * i) = 0;                                                             \
    }                                                                                          \
    size_t x;                                                                                  \
    double w;                                                                                  \
    for (size_t i = 0; i < l; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, double, w);                                                      \
      (*(double*)(p3 + s3 * x)) += w;                                                          \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bincount_df(VALUE self, VALUE weight, size_t length) {                 \
    size_t shape_out[1] = { length };                                                          \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 1 }, { numo_cDFloat, 1 } };                       \
    ndfunc_arg_out_t aout[1] = { { numo_cDFloat, 1, shape_out } };                             \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_bincount_df, NO_LOOP | NDF_STRIDE_LOOP, 2, 1, ain, aout                  \
    };                                                                                         \
    return na_ndloop(&ndf, 2, self, weight);                                                   \
  }

#define DEF_NARRAY_INT_BINCOUNT_METHOD_FUNC(tDType, tNAryClass)                                \
  DEF_BINCOUNT_FUNCS(tDType, tNAryClass)                                                       \
  static VALUE tDType##_bincount(int argc, VALUE* argv, VALUE self) {                          \
    VALUE weight = Qnil;                                                                       \
    VALUE kw = Qnil;                                                                           \
    VALUE opts[1] = { Qundef };                                                                \
    ID table[1] = { id_minlength };                                                            \
    rb_scan_args(argc, argv, "01:", &weight, &kw);                                             \
    rb_get_kwargs(kw, table, 0, 1, opts);                                                      \
                                                                                               \
    VALUE v = tDType##_minmax(0, 0, self);                                                     \
    if (m_num_to_data(RARRAY_AREF(v, 0)) < 0) {                                                \
      rb_raise(rb_eArgError, "array items must be non-netagive");                              \
    }                                                                                          \
    v = RARRAY_AREF(v, 1);                                                                     \
                                                                                               \
    size_t length = NUM2SIZET(v) + 1;                                                          \
    if (opts[0] != Qundef) {                                                                   \
      const size_t minlength = NUM2SIZET(opts[0]);                                             \
      if (minlength > length) {                                                                \
        length = minlength;                                                                    \
      }                                                                                        \
    }                                                                                          \
                                                                                               \
    if (NIL_P(weight)) {                                                                       \
      if (length > 4294967295ul) {                                                             \
        return tDType##_bincount_64(self, length);                                             \
      }                                                                                        \
      return tDType##_bincount_32(self, length);                                               \
    } else {                                                                                   \
      if (rb_obj_class(weight) == numo_cSFloat) {                                              \
        return tDType##_bincount_sf(self, weight, length);                                     \
      }                                                                                        \
      return tDType##_bincount_df(self, weight, length);                                       \
    }                                                                                          \
  }

#define DEF_NARRAY_UINT_BINCOUNT_METHOD_FUNC(tDType, tNAryClass)                               \
  DEF_BINCOUNT_FUNCS(tDType, tNAryClass)                                                       \
  static VALUE tDType##_bincount(int argc, VALUE* argv, VALUE self) {                          \
    VALUE weight = Qnil;                                                                       \
    VALUE kw = Qnil;                                                                           \
    VALUE opts[1] = { Qundef };                                                                \
    ID table[1] = { id_minlength };                                                            \
    rb_scan_args(argc, argv, "01:", &weight, &kw);                                             \
    rb_get_kwargs(kw, table, 0, 1, opts);                                                      \
                                                                                               \
    VALUE v = tDType##_max(0, 0, self);                                                        \
                                                                                               \
    size_t length = NUM2SIZET(v) + 1;                                                          \
    if (opts[0] != Qundef) {                                                                   \
      const size_t minlength = NUM2SIZET(opts[0]);                                             \
      if (minlength > length) {                                                                \
        length = minlength;                                                                    \
      }                                                                                        \
    }                                                                                          \
                                                                                               \
    if (NIL_P(weight)) {                                                                       \
      if (length > 4294967295ul) {                                                             \
        return tDType##_bincount_64(self, length);                                             \
      }                                                                                        \
      return tDType##_bincount_32(self, length);                                               \
    } else {                                                                                   \
      if (rb_obj_class(weight) == numo_cSFloat) {                                              \
        return tDType##_bincount_sf(self, weight, length);                                     \
      }                                                                                        \
      return tDType##_bincount_df(self, weight, length);                                       \
    }                                                                                          \
  }

#endif /* NUMO_NARRAY_MH_BINCOUNT_H */
