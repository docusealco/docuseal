#ifndef NUMO_NARRAY_MH_SEQ_H
#define NUMO_NARRAY_MH_SEQ_H 1

#define DEF_NARRAY_FLT_SEQ_METHOD_FUNC(tDType)                                                 \
  typedef struct {                                                                             \
    tDType beg;                                                                                \
    tDType step;                                                                               \
    double count;                                                                              \
  } seq_opt_t;                                                                                 \
                                                                                               \
  static void iter_##tDType##_seq(na_loop_t* const lp) {                                       \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    tDType beg;                                                                                \
    tDType step;                                                                               \
    double c;                                                                                  \
    seq_opt_t* g;                                                                              \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (seq_opt_t*)(lp->opt_ptr);                                                             \
    beg = g->beg;                                                                              \
    step = g->step;                                                                            \
    c = g->count;                                                                              \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1 + *idx1) = x;                                                            \
        idx1++;                                                                                \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1) = x;                                                                    \
        p1 += s1;                                                                              \
      }                                                                                        \
    }                                                                                          \
    g->count = c;                                                                              \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_seq(int argc, VALUE* args, VALUE self) {                               \
    seq_opt_t* g;                                                                              \
    VALUE vbeg = Qnil;                                                                         \
    VALUE vstep = Qnil;                                                                        \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_seq, FULL_LOOP, 1, 0, ain, 0 };                           \
                                                                                               \
    g = ALLOCA_N(seq_opt_t, 1);                                                                \
    g->beg = m_zero;                                                                           \
    g->step = m_one;                                                                           \
    g->count = 0;                                                                              \
    rb_scan_args(argc, args, "02", &vbeg, &vstep);                                             \
    if (vbeg != Qnil) {                                                                        \
      g->beg = m_num_to_data(vbeg);                                                            \
    }                                                                                          \
    if (vstep != Qnil) {                                                                       \
      g->step = m_num_to_data(vstep);                                                          \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, g, 1, self);                                                              \
    return self;                                                                               \
  }

#define DEF_NARRAY_INT_SEQ_METHOD_FUNC(tDType)                                                 \
  typedef struct {                                                                             \
    double beg;                                                                                \
    double step;                                                                               \
    double count;                                                                              \
  } seq_opt_t;                                                                                 \
                                                                                               \
  static void iter_##tDType##_seq(na_loop_t* const lp) {                                       \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    tDType x;                                                                                  \
    double beg;                                                                                \
    double step;                                                                               \
    double c;                                                                                  \
    seq_opt_t* g;                                                                              \
                                                                                               \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    g = (seq_opt_t*)(lp->opt_ptr);                                                             \
    beg = g->beg;                                                                              \
    step = g->step;                                                                            \
    c = g->count;                                                                              \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1 + *idx1) = x;                                                            \
        idx1++;                                                                                \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        x = f_seq(beg, step, c++);                                                             \
        *(tDType*)(p1) = x;                                                                    \
        p1 += s1;                                                                              \
      }                                                                                        \
    }                                                                                          \
    g->count = c;                                                                              \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_seq(int argc, VALUE* argv, VALUE self) {                               \
    seq_opt_t* g;                                                                              \
    VALUE vbeg = Qnil;                                                                         \
    VALUE vstep = Qnil;                                                                        \
    ndfunc_arg_in_t ain[1] = { { OVERWRITE, 0 } };                                             \
    ndfunc_t ndf = { iter_##tDType##_seq, FULL_LOOP, 1, 0, ain, 0 };                           \
                                                                                               \
    g = ALLOCA_N(seq_opt_t, 1);                                                                \
    g->beg = m_zero;                                                                           \
    g->step = m_one;                                                                           \
    g->count = 0;                                                                              \
    rb_scan_args(argc, argv, "02", &vbeg, &vstep);                                             \
    if (vbeg != Qnil) {                                                                        \
      g->beg = NUM2DBL(vbeg);                                                                  \
    }                                                                                          \
    if (vstep != Qnil) {                                                                       \
      g->step = NUM2DBL(vstep);                                                                \
    }                                                                                          \
                                                                                               \
    na_ndloop3(&ndf, g, 1, self);                                                              \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_SEQ_H */
