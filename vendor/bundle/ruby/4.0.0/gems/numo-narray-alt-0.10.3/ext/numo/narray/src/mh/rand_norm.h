#ifndef NUMO_NARRAY_MH_RAND_NORM_H
#define NUMO_NARRAY_MH_RAND_NORM_H 1

#define DEF_NARRAY_CMP_RAND_NORM_METHOD_FUNC(tDType, tRType)                                   \
  typedef struct {                                                                             \
    tDType mu;                                                                                 \
    tRType sigma;                                                                              \
  } randn_opt_t;                                                                               \
                                                                                               \
  static void iter_##tDType##_rand_norm(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    tDType mu;                                                                                 \
    tRType sigma;                                                                              \
    randn_opt_t* g = (randn_opt_t*)(lp->opt_ptr);                                              \
    mu = g->mu;                                                                                \
    sigma = g->sigma;                                                                          \
    tDType* a0;                                                                                \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        a0 = (tDType*)(p1 + *idx1);                                                            \
        m_rand_norm(mu, sigma, a0);                                                            \
        idx1 += 1;                                                                             \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        a0 = (tDType*)(p1);                                                                    \
        m_rand_norm(mu, sigma, a0);                                                            \
        p1 += s1;                                                                              \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand_norm(int argc, VALUE* argv, VALUE self) {                         \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    const int n = rb_scan_args(argc, argv, "02", &v1, &v2);                                    \
    randn_opt_t g;                                                                             \
    if (n == 0) {                                                                              \
      g.mu = m_zero;                                                                           \
    } else {                                                                                   \
      g.mu = m_num_to_data(v1);                                                                \
    }                                                                                          \
    if (n == 2) {                                                                              \
      g.sigma = NUM2DBL(v2);                                                                   \
    } else {                                                                                   \
      g.sigma = 1;                                                                             \
    }                                                                                          \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand_norm, FULL_LOOP, 1, 0, ain, 0 };                     \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#define DEF_NARRAY_FLT_RAND_NORM_METHOD_FUNC(tDType)                                           \
  typedef struct {                                                                             \
    tDType mu;                                                                                 \
    tDType sigma;                                                                              \
  } randn_opt_t;                                                                               \
                                                                                               \
  static void iter_##tDType##_rand_norm(na_loop_t* const lp) {                                 \
    size_t i;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    INIT_COUNTER(lp, i);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    tDType mu;                                                                                 \
    tDType sigma;                                                                              \
    randn_opt_t* g = (randn_opt_t*)(lp->opt_ptr);                                              \
    mu = g->mu;                                                                                \
    sigma = g->sigma;                                                                          \
    tDType* a0;                                                                                \
    tDType* a1;                                                                                \
    if (idx1) {                                                                                \
      for (; i > 1; i -= 2) {                                                                  \
        a0 = (tDType*)(p1 + *idx1);                                                            \
        a1 = (tDType*)(p1 + *(idx1 + 1));                                                      \
        m_rand_norm(mu, sigma, a0, a1);                                                        \
        idx1 += 2;                                                                             \
      }                                                                                        \
      if (i > 0) {                                                                             \
        a0 = (tDType*)(p1 + *idx1);                                                            \
        m_rand_norm(mu, sigma, a0, 0);                                                         \
      }                                                                                        \
    } else {                                                                                   \
      for (; i > 1; i -= 2) {                                                                  \
        a0 = (tDType*)(p1);                                                                    \
        a1 = (tDType*)(p1 + s1);                                                               \
        m_rand_norm(mu, sigma, a0, a1);                                                        \
        p1 += s1 * 2;                                                                          \
      }                                                                                        \
      if (i > 0) {                                                                             \
        a0 = (tDType*)(p1);                                                                    \
        m_rand_norm(mu, sigma, a0, 0);                                                         \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_rand_norm(int argc, VALUE* args, VALUE self) {                         \
    VALUE v1 = Qnil;                                                                           \
    VALUE v2 = Qnil;                                                                           \
    const int n = rb_scan_args(argc, args, "02", &v1, &v2);                                    \
    randn_opt_t g;                                                                             \
    if (n == 0) {                                                                              \
      g.mu = m_zero;                                                                           \
    } else {                                                                                   \
      g.mu = m_num_to_data(v1);                                                                \
    }                                                                                          \
    if (n == 2) {                                                                              \
      g.sigma = NUM2DBL(v2);                                                                   \
    } else {                                                                                   \
      g.sigma = 1;                                                                             \
    }                                                                                          \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_rand_norm, FULL_LOOP, 1, 0, ain, 0 };                     \
    na_ndloop3(&ndf, &g, 1, self);                                                             \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_RAND_NORM_H */
