#ifndef NUMO_NARRAY_MH_EACH_WITH_INDEX_H
#define NUMO_NARRAY_MH_EACH_WITH_INDEX_H 1

#define DEF_NARRAY_EACH_WITH_INDEX_METHOD_FUNC(tDType)                                         \
  static inline void yield_each_with_index(tDType x, size_t* c, VALUE* a, int nd, int md) {    \
    a[0] = m_data_to_num(x);                                                                   \
    for (int j = 0; j <= nd; j++) {                                                            \
      a[j + 1] = SIZET2NUM(c[j]);                                                              \
    }                                                                                          \
    rb_yield(rb_ary_new4(md, a));                                                              \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_each_with_index(na_loop_t* const lp) {                           \
    size_t* c = (size_t*)(lp->opt_ptr);                                                        \
    int nd = lp->ndim;                                                                         \
    if (nd > 0) {                                                                              \
      nd--;                                                                                    \
    }                                                                                          \
    int md = nd + 2;                                                                           \
    VALUE* a = ALLOCA_N(VALUE, md);                                                            \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    size_t s1;                                                                                 \
    size_t* idx1;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    tDType x;                                                                                  \
    c[nd] = 0;                                                                                 \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        GET_DATA_INDEX(p1, idx1, tDType, x);                                                   \
        yield_each_with_index(x, c, a, nd, md);                                                \
        c[nd]++;                                                                               \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        GET_DATA_STRIDE(p1, s1, tDType, x);                                                    \
        yield_each_with_index(x, c, a, nd, md);                                                \
        c[nd]++;                                                                               \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_each_with_index(VALUE self) {                                          \
    ndfunc_arg_in_t ain[1] = { { Qnil, 0 } };                                                  \
    ndfunc_t ndf = { iter_##tDType##_each_with_index, FULL_LOOP_NIP, 1, 0, ain, 0 };           \
    na_ndloop_with_index(&ndf, 1, self);                                                       \
    return self;                                                                               \
  }

#define DEF_NARRAY_BIT_EACH_WITH_INDEX_METHOD_FUNC()                                           \
  static inline void yield_each_with_index(BIT_DIGIT x, size_t* c, VALUE* a, int nd, int md) { \
    a[0] = m_data_to_num(x);                                                                   \
    for (int j = 0; j <= nd; j++) {                                                            \
      a[j + 1] = SIZET2NUM(c[j]);                                                              \
    }                                                                                          \
    rb_yield(rb_ary_new4(md, a));                                                              \
  }                                                                                            \
                                                                                               \
  static void iter_bit_each_with_index(na_loop_t* const lp) {                                  \
    size_t* c = (size_t*)(lp->opt_ptr);                                                        \
    int nd = lp->ndim - 1;                                                                     \
    int md = lp->ndim + 1;                                                                     \
    VALUE* a = ALLOCA_N(VALUE, md);                                                            \
    size_t n;                                                                                  \
    BIT_DIGIT* a1;                                                                             \
    size_t p1;                                                                                 \
    ssize_t s1;                                                                                \
    size_t* idx1;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);                                                 \
    BIT_DIGIT x = 0;                                                                           \
    c[nd] = 0;                                                                                 \
    if (idx1) {                                                                                \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1 + *idx1, x);                                                           \
        idx1++;                                                                                \
        yield_each_with_index(x, c, a, nd, md);                                                \
        c[nd]++;                                                                               \
      }                                                                                        \
    } else {                                                                                   \
      for (size_t i = 0; i < n; i++) {                                                         \
        LOAD_BIT(a1, p1, x);                                                                   \
        p1 += s1;                                                                              \
        yield_each_with_index(x, c, a, nd, md);                                                \
        c[nd]++;                                                                               \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE bit_each_with_index(VALUE self) {                                               \
    ndfunc_arg_in_t ain[1] = { { Qnil, 0 } };                                                  \
    ndfunc_t ndf = { iter_bit_each_with_index, FULL_LOOP_NIP, 1, 0, ain, 0 };                  \
    na_ndloop_with_index(&ndf, 1, self);                                                       \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_EACH_WITH_INDEX_H */
