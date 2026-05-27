#ifndef NUMO_NARRAY_MH_COMP_NEARLY_EQ_H
#define NUMO_NARRAY_MH_COMP_NEARLY_EQ_H 1

#include "binary_func.h"

#define DEF_NARRAY_NEARLY_EQ_METHOD_FUNC(tDType, tNAryClass)                                   \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(nearly_eq, tDType, tNAryClass)                      \
                                                                                               \
  static VALUE tDType##_nearly_eq(VALUE self, VALUE other) {                                   \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_nearly_eq_self(self, other);                                             \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, id_nearly_eq, 1, other);                                            \
    }                                                                                          \
  }

#define DEF_NARRAY_ROBJ_NEARLY_EQ_METHOD_FUNC()                                                \
  DEF_NARRAY_BINARY_COMPARISON_METHOD_FUNC(nearly_eq, robject, numo_cRObject)                  \
                                                                                               \
  static VALUE robject_nearly_eq(VALUE self, VALUE other) {                                    \
    return robject_nearly_eq_self(self, other);                                                \
  }

#endif /* NUMO_NARRAY_MH_COMP_NEARLY_EQ_H */
