#ifndef NUMO_NARRAY_MH_COMP_GE_H
#define NUMO_NARRAY_MH_COMP_GE_H 1

#include "binary_func.h"

#define DEF_NARRAY_GE_METHOD_FUNC(tDType, tNAryClass)                                          \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(ge, tDType, tNAryClass)                             \
                                                                                               \
  static VALUE tDType##_ge(VALUE self, VALUE other) {                                          \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_ge_self(self, other);                                                    \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, id_ge, 1, other);                                                   \
    }                                                                                          \
  }

#define DEF_NARRAY_ROBJ_GE_METHOD_FUNC()                                                       \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(ge, robject, numo_cRObject)                         \
                                                                                               \
  static VALUE robject_ge(VALUE self, VALUE other) {                                           \
    return robject_ge_self(self, other);                                                       \
  }

#endif /* NUMO_NARRAY_MH_COMP_GE_H */
