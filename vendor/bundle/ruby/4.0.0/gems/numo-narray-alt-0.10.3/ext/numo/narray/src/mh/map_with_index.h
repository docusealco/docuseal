#ifndef NUMO_NARRAY_MH_MAP_WITH_INDEX_H
#define NUMO_NARRAY_MH_MAP_WITH_INDEX_H 1

#define DEF_NARRAY_MAP_WITH_INDEX_METHOD_FUNC(tDType, tNAryClass)                              \
  static inline tDType yield_map_with_index(tDType x, size_t* c, VALUE* a, int nd, int md) {   \
    a[0] = m_data_to_num(x);                                                                   \
    for (int j = 0; j <= nd; j++) {                                                            \
      a[j + 1] = SIZET2NUM(c[j]);                                                              \
    }                                                                                          \
    VALUE y = rb_yield(rb_ary_new4(md, a));                                                    \
    return m_num_to_data(y);                                                                   \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_map_with_index(na_loop_t* const lp) {                            \
    size_t* c = (size_t*)(lp->opt_ptr);                                                        \
    int nd = lp->ndim;                                                                         \
    if (nd > 0) {                                                                              \
      nd--;                                                                                    \
    }                                                                                          \
    int md = nd + 2;                                                                           \
    VALUE* a = ALLOCA_N(VALUE, md);                                                            \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
    tDType x;                                                                                  \
    c[nd] = 0;                                                                                 \
    if (idx1) {                                                                                \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = yield_map_with_index(x, c, a, nd, md);                                           \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
          c[nd]++;                                                                             \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p1, idx1, tDType, x);                                                 \
          x = yield_map_with_index(x, c, a, nd, md);                                           \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
          c[nd]++;                                                                             \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx2) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = yield_map_with_index(x, c, a, nd, md);                                           \
          SET_DATA_INDEX(p2, idx2, tDType, x);                                                 \
          c[nd]++;                                                                             \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p1, s1, tDType, x);                                                  \
          x = yield_map_with_index(x, c, a, nd, md);                                           \
          SET_DATA_STRIDE(p2, s2, tDType, x);                                                  \
          c[nd]++;                                                                             \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_map_with_index(VALUE self) {                                           \
    ndfunc_arg_in_t ain[1] = { { Qnil, 0 } };                                                  \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_map_with_index, FULL_LOOP, 1, 1, ain, aout };             \
    return na_ndloop_with_index(&ndf, 1, self);                                                \
  }

#endif /* NUMO_NARRAY_MH_MAP_WITH_INDEX_H */
