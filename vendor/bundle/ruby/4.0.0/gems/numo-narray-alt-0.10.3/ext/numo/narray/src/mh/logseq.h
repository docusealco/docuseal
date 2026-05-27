#ifndef NUMO_NARRAY_MH_LOGSEQ_H
#define NUMO_NARRAY_MH_LOGSEQ_H 1

#define DEF_NARRAY_FLT_LOGSEQ_METHOD_FUNC(tDType)                                              \
  typedef struct {                                                                             \
    tDType beg;                                                                                \
    tDType step;                                                                               \
    tDType base;                                                                               \
    double count;                                                                              \
  } logseq_opt_t;                                                                              \
                                                                                               \
  static void iter_##tDType##_logseq(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    tDType beg;                                                                                \
    tDType step;                                                                               \
    tDType base;                                                                               \
    double c;                                                                                  \
    logseq_opt_t* g;                                                                           \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (logseq_opt_t*)(lp->opt_ptr);                                                          \
    beg = g->beg;                                                                              \
    step = g->step;                                                                            \
    base = g->base;                                                                            \
    c = g->count;                                                                              \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1 + *idx1) = m_pow(base, x);                                               \
        idx1++;                                                                                \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1) = m_pow(base, x);                                                       \
        p1 += s1;                                                                              \
      }                                                                                        \
    }                                                                                          \
    g->count = c;                                                                              \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_logseq(int argc, VALUE* argv, VALUE self) {                            \
    logseq_opt_t* g;                                                                           \
    VALUE vbeg;                                                                                \
    VALUE vstep;                                                                               \
    VALUE vbase = Qnil;                                                                        \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_logseq, FULL_LOOP, 1, 0, ain, 0 };                        \
                                                                                               \
    g = ALLOCA_N(logseq_opt_t, 1);                                                             \
    rb_scan_args(argc, argv, "21", &vbeg, &vstep, &vbase);                                     \
    g->beg = m_num_to_data(vbeg);                                                              \
    g->step = m_num_to_data(vstep);                                                            \
    g->count = 0;                                                                              \
    if (vbase == Qnil) {                                                                       \
      g->base = m_from_real(10);                                                               \
    } else {                                                                                   \
      g->base = m_num_to_data(vbase);                                                          \
    }                                                                                          \
    na_ndloop3(&ndf, g, 1, self);                                                              \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_LOGSEQ_H */
