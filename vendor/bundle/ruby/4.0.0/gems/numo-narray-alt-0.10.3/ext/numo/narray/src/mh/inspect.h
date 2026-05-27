#ifndef NUMO_NARRAY_MH_INSPECT_H
#define NUMO_NARRAY_MH_INSPECT_H 1

#define DEF_NARRAY_INSPECT_METHOD_FUNC(tDType)                                                 \
  static VALUE iter_##tDType##_inspect(char* ptr, size_t pos, VALUE fmt) {                     \
    return format_##tDType(fmt, (tDType*)(ptr + pos));                                         \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_inspect(VALUE ary) {                                                   \
    return na_ndloop_inspect(ary, iter_##tDType##_inspect, Qnil);                              \
  }

#define DEF_NARRAY_ROBJ_INSPECT_METHOD_FUNC()                                                  \
  static VALUE iter_robject_inspect(char* ptr, size_t pos, VALUE fmt) {                        \
    return rb_inspect(*(VALUE*)(ptr + pos));                                                   \
  }                                                                                            \
                                                                                               \
  static VALUE robject_inspect(VALUE ary) {                                                    \
    return na_ndloop_inspect(ary, iter_robject_inspect, Qnil);                                 \
  }

#define DEF_NARRAY_BIT_INSPECT_METHOD_FUNC()                                                   \
  static VALUE iter_bit_inspect(char* ptr, size_t pos, VALUE fmt) {                            \
    BIT_DIGIT x;                                                                               \
    LOAD_BIT(ptr, pos, x);                                                                     \
    return format_bit(fmt, x);                                                                 \
  }                                                                                            \
                                                                                               \
  static VALUE bit_inspect(VALUE ary) {                                                        \
    return na_ndloop_inspect(ary, iter_bit_inspect, Qnil);                                     \
  }

#endif /* NUMO_NARRAY_MH_INSPECT_H */
