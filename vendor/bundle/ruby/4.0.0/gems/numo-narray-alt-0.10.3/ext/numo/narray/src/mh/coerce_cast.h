#ifndef NUMO_NARRAY_MH_COERCE_CAST_H
#define NUMO_NARRAY_MH_COERCE_CAST_H 1

#define DEF_NARRAY_COERCE_CAST_METHOD_FUNC(tDType)                                             \
  static VALUE tDType##_coerce_cast(VALUE self, VALUE type) {                                  \
    return Qnil;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_COERCE_CAST_H */
