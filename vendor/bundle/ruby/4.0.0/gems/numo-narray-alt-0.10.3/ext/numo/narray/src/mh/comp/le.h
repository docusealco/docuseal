#ifndef NUMO_NARRAY_MH_COMP_LE_H
#define NUMO_NARRAY_MH_COMP_LE_H 1

#include "binary_func.h"

#define DEF_NARRAY_LE_METHOD_FUNC(tDType, tNAryClass)                                          \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(le, tDType, tNAryClass)                             \
                                                                                               \
  static VALUE tDType##_le(VALUE self, VALUE other) {                                          \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_le_self(self, other);                                                    \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, id_le, 1, other);                                                   \
    }                                                                                          \
  }

#define DEF_NARRAY_ROBJ_LE_METHOD_FUNC()                                                       \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(le, robject, numo_cRObject)                         \
                                                                                               \
  static VALUE robject_le(VALUE self, VALUE other) {                                           \
    return robject_le_self(self, other);                                                       \
  }

#endif /* NUMO_NARRAY_MH_COMP_LE_H */
