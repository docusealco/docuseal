#ifndef NUMO_NARRAY_MH_COMP_LT_H
#define NUMO_NARRAY_MH_COMP_LT_H 1

#include "binary_func.h"

#define DEF_NARRAY_LT_METHOD_FUNC(tDType, tNAryClass)                                          \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(lt, tDType, tNAryClass)                             \
                                                                                               \
  static VALUE tDType##_lt(VALUE self, VALUE other) {                                          \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_lt_self(self, other);                                                    \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, id_lt, 1, other);                                                   \
    }                                                                                          \
  }

#define DEF_NARRAY_ROBJ_LT_METHOD_FUNC()                                                       \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(lt, robject, numo_cRObject)                         \
                                                                                               \
  static VALUE robject_lt(VALUE self, VALUE other) {                                           \
    return robject_lt_self(self, other);                                                       \
  }

#endif /* NUMO_NARRAY_MH_COMP_LT_H */
