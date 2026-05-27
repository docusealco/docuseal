#ifndef NUMO_NARRAY_MH_CLIP_H
#define NUMO_NARRAY_MH_CLIP_H 1

#define DEF_NARRAY_CLIP_METHOD_FUNC(tDType, tNAryClass)                                        \
  static void iter_##tDType##_clip(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    char* p4;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    ssize_t s4;                                                                                \
    tDType x;                                                                                  \
    tDType min;                                                                                \
    tDType max;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    INIT_PTR(lp, 3, p4, s4);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, min);                                                    \
      GET_DATA_STRIDE(p3, s3, tDType, max);                                                    \
      if (m_gt(min, max)) {                                                                    \
        rb_raise(nary_eOperationError, "min is greater than max");                             \
      }                                                                                        \
      if (m_lt(x, min)) {                                                                      \
        x = min;                                                                               \
      }                                                                                        \
      if (m_gt(x, max)) {                                                                      \
        x = max;                                                                               \
      }                                                                                        \
      SET_DATA_STRIDE(p4, s4, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_clip_min(na_loop_t* const lp) {                                  \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    tDType x;                                                                                  \
    tDType min;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, min);                                                    \
      if (m_lt(x, min)) {                                                                      \
        x = min;                                                                               \
      }                                                                                        \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_clip_max(na_loop_t* const lp) {                                  \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    tDType x;                                                                                  \
    tDType max;                                                                                \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
                                                                                               \
    for (size_t i = 0; i < n; i++) {                                                           \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, max);                                                    \
      if (m_gt(x, max)) {                                                                      \
        x = max;                                                                               \
      }                                                                                        \
      SET_DATA_STRIDE(p3, s3, tDType, x);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_clip(VALUE self, VALUE min, VALUE max) {                               \
    ndfunc_arg_in_t ain[3] = { { Qnil, 0 }, { tNAryClass, 0 }, { tNAryClass, 0 } };            \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf_min = { iter_##tDType##_clip_min, STRIDE_LOOP, 2, 1, ain, aout };             \
    ndfunc_t ndf_max = { iter_##tDType##_clip_max, STRIDE_LOOP, 2, 1, ain, aout };             \
    ndfunc_t ndf_both = { iter_##tDType##_clip, STRIDE_LOOP, 3, 1, ain, aout };                \
                                                                                               \
    if (RTEST(min)) {                                                                          \
      if (RTEST(max)) {                                                                        \
        return na_ndloop(&ndf_both, 3, self, min, max);                                        \
      }                                                                                        \
      return na_ndloop(&ndf_min, 2, self, min);                                                \
    } else {                                                                                   \
      if (RTEST(max)) {                                                                        \
        return na_ndloop(&ndf_max, 2, self, max);                                              \
      }                                                                                        \
    }                                                                                          \
    rb_raise(rb_eArgError, "min and max are not given");                                       \
    return Qnil;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_CLIP_H */
