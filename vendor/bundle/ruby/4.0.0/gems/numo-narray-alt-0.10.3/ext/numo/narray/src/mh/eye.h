#ifndef NUMO_NARRAY_MH_EYE_H
#define NUMO_NARRAY_MH_EYE_H 1

#define DEF_NARRAY_EYE_METHOD_FUNC(tDType)                                                     \
  static void iter_##tDType##_eye(na_loop_t* const lp) {                                       \
    char* g = (char*)(lp->opt_ptr);                                                            \
    ssize_t kofs = *(ssize_t*)g;                                                               \
    tDType data = *(tDType*)(g + sizeof(ssize_t));                                             \
                                                                                               \
    size_t n0 = lp->args[0].shape[0];                                                          \
    size_t n1 = lp->args[0].shape[1];                                                          \
    ssize_t s0 = lp->args[0].iter[0].step;                                                     \
    ssize_t s1 = lp->args[0].iter[1].step;                                                     \
    char* p0 = NDL_PTR(lp, 0);                                                                 \
                                                                                               \
    for (size_t i0 = 0; i0 < n0; i0++) {                                                       \
      char* p1 = p0;                                                                           \
      for (size_t i1 = 0; i1 < n1; i1++) {                                                     \
        *(tDType*)p1 = (i0 + kofs == i1) ? data : m_zero;                                      \
        p1 += s1;                                                                              \
      }                                                                                        \
      p0 += s0;                                                                                \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_eye(int argc, VALUE* argv, VALUE self) {                               \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 2 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_eye, NO_LOOP, 1, 0, ain, 0 };                             \
    ssize_t kofs;                                                                              \
    tDType data;                                                                               \
    char* g;                                                                                   \
    int nd;                                                                                    \
    narray_t* na;                                                                              \
                                                                                               \
    if (argc > 2) {                                                                            \
      rb_raise(rb_eArgError, "too many arguments (%d for 0..2)", argc);                        \
    } else if (argc == 2) {                                                                    \
      data = m_num_to_data(argv[0]);                                                           \
      kofs = NUM2SSIZET(argv[1]);                                                              \
    } else if (argc == 1) {                                                                    \
      data = m_num_to_data(argv[0]);                                                           \
      kofs = 0;                                                                                \
    } else {                                                                                   \
      data = m_one;                                                                            \
      kofs = 0;                                                                                \
    }                                                                                          \
                                                                                               \
    GetNArray(self, na);                                                                       \
    nd = na->ndim;                                                                             \
    if (nd < 2) {                                                                              \
      rb_raise(nary_eDimensionError, "less than 2-d array");                                   \
    }                                                                                          \
                                                                                               \
    if (kofs >= 0) {                                                                           \
      if ((size_t)(kofs) >= na->shape[nd - 1]) {                                               \
        rb_raise(                                                                              \
          rb_eArgError,                                                                        \
          "invalid diagonal offset(%" SZF "d) for "                                            \
          "last dimension size(%" SZF "d)",                                                    \
          kofs, na->shape[nd - 1]                                                              \
        );                                                                                     \
      }                                                                                        \
    } else {                                                                                   \
      if ((size_t)(-kofs) >= na->shape[nd - 2]) {                                              \
        rb_raise(                                                                              \
          rb_eArgError,                                                                        \
          "invalid diagonal offset(%" SZF "d) for "                                            \
          "last-1 dimension size(%" SZF "d)",                                                  \
          kofs, na->shape[nd - 2]                                                              \
        );                                                                                     \
      }                                                                                        \
    }                                                                                          \
                                                                                               \
    g = ALLOCA_N(char, sizeof(ssize_t) + sizeof(tDType));                                      \
    *(ssize_t*)g = kofs;                                                                       \
    *(tDType*)(g + sizeof(ssize_t)) = data;                                                    \
                                                                                               \
    na_ndloop3(&ndf, g, 1, self);                                                              \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_EYE_H */
