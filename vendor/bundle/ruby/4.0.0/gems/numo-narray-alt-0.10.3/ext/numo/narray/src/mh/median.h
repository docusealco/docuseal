#ifndef NUMO_NARRAY_MH_MEDIAN_H
#define NUMO_NARRAY_MH_MEDIAN_H 1

#define DEF_NARRAY_INT_MEDIAN_METHOD_FUNC(tDType)                                              \
  static void iter_##tDType##_median(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    INIT_COUNTER(lp, n);                                                                       \
    char* p1 = NDL_PTR(lp, 0);                                                                 \
    char* p2 = NDL_PTR(lp, 1);                                                                 \
    tDType* buf = (tDType*)p1;                                                                 \
    tDType##_qsort(buf, n, sizeof(tDType));                                                    \
    if (n == 0) {                                                                              \
      *(tDType*)p2 = buf[0];                                                                   \
    } else if (n % 2 == 0) {                                                                   \
      *(tDType*)p2 = (buf[n / 2 - 1] + buf[n / 2]) / 2;                                        \
    } else {                                                                                   \
      *(tDType*)p2 = buf[(n - 1) / 2];                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_median(int argc, VALUE* argv, VALUE self) {                            \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_reduce, 0 } };                          \
    ndfunc_arg_out_t aout[1] = { { INT2FIX(0), 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_median, NDF_HAS_LOOP | NDF_FLAT_REDUCE, 2, 1, ain, aout                  \
    };                                                                                         \
    self = na_copy(self);                                                                      \
    VALUE reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                         \
    VALUE v = na_ndloop(&ndf, 2, self, reduce);                                                \
    return tDType##_extract(v);                                                                \
  }

#define DEF_NARRAY_FLT_MEDIAN_METHOD_FUNC(tDType)                                              \
  static void iter_##tDType##_median_ignan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    INIT_COUNTER(lp, n);                                                                       \
    char* p1 = NDL_PTR(lp, 0);                                                                 \
    char* p2 = NDL_PTR(lp, 1);                                                                 \
    tDType* buf = (tDType*)p1;                                                                 \
    tDType##_qsort_ignan(buf, n, sizeof(tDType));                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      if (!isnan(buf[i])) break;                                                               \
    }                                                                                          \
    if (n == 0) {                                                                              \
      *(tDType*)p2 = buf[0];                                                                   \
    } else if (n % 2 == 0) {                                                                   \
      *(tDType*)p2 = (buf[n / 2 - 1] + buf[n / 2]) / 2;                                        \
    } else {                                                                                   \
      *(tDType*)p2 = buf[(n - 1) / 2];                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void iter_##tDType##_median_prnan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    INIT_COUNTER(lp, n);                                                                       \
    char* p1 = NDL_PTR(lp, 0);                                                                 \
    char* p2 = NDL_PTR(lp, 1);                                                                 \
    tDType* buf = (tDType*)p1;                                                                 \
    tDType##_qsort_prnan(buf, n, sizeof(tDType));                                              \
    for (size_t i = 0; i < n; i++) {                                                           \
      if (!isnan(buf[i])) break;                                                               \
    }                                                                                          \
    if (n == 0) {                                                                              \
      *(tDType*)p2 = buf[0];                                                                   \
    } else if (n % 2 == 0) {                                                                   \
      *(tDType*)p2 = (buf[n / 2 - 1] + buf[n / 2]) / 2;                                        \
    } else {                                                                                   \
      *(tDType*)p2 = buf[(n - 1) / 2];                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_median(int argc, VALUE* argv, VALUE self) {                            \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_reduce, 0 } };                          \
    ndfunc_arg_out_t aout[1] = { { INT2FIX(0), 0 } };                                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_median_ignan, NDF_HAS_LOOP | NDF_FLAT_REDUCE, 2, 1, ain, aout            \
    };                                                                                         \
    self = na_copy(self);                                                                      \
    VALUE reduce =                                                                             \
      na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_median_prnan);           \
    VALUE v = na_ndloop(&ndf, 2, self, reduce);                                                \
    return tDType##_extract(v);                                                                \
  }

#endif /* NUMO_NARRAY_MH_MEDIAN_H */
