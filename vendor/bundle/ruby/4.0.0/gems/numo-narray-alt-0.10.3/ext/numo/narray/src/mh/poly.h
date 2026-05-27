#ifndef NUMO_NARRAY_MH_POLY_H
#define NUMO_NARRAY_MH_POLY_H 1

#define DEF_NARRAY_POLY_METHOD_FUNC(tDType, tNAryClass)                                        \
  static void iter_##tDType##_poly(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    tDType x;                                                                                  \
    tDType y;                                                                                  \
    tDType a;                                                                                  \
    n = lp->narg - 2;                                                                          \
    x = *(tDType*)NDL_PTR(lp, 0);                                                              \
    y = *(tDType*)NDL_PTR(lp, n);                                                              \
    for (size_t i = 1; i < n; i++) {                                                           \
      y = m_mul(x, y);                                                                         \
      a = *(tDType*)NDL_PTR(lp, n - i);                                                        \
      y = m_add(y, a);                                                                         \
    }                                                                                          \
    n = lp->narg - 1;                                                                          \
    *(tDType*)NDL_PTR(lp, n) = y;                                                              \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_poly(VALUE self, VALUE args) {                                         \
    const int argc = (int)RARRAY_LEN(args);                                                    \
    const int n_in = argc + 1;                                                                 \
    ndfunc_arg_in_t* ain = ALLOCA_N(ndfunc_arg_in_t, n_in);                                    \
    for (int i = 0; i < n_in; i++) {                                                           \
      ain[i].type = tNAryClass;                                                                \
      ain[i].dim = 0;                                                                          \
    }                                                                                          \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_poly, NO_LOOP, n_in, 1, ain, aout };                      \
    VALUE* argv = ALLOCA_N(VALUE, n_in);                                                       \
    argv[0] = self;                                                                            \
    for (int i = 0; i < argc; i++) {                                                           \
      argv[i + 1] = RARRAY_AREF(args, i);                                                      \
    }                                                                                          \
    volatile VALUE a = rb_ary_new4(n_in, argv);                                                \
    volatile VALUE v = na_ndloop2(&ndf, a);                                                    \
    return tDType##_extract(v);                                                                \
  }

#endif /* NUMO_NARRAY_MH_POLY_H */
