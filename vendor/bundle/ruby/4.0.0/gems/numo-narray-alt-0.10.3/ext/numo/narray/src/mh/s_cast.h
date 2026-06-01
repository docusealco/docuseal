#ifndef NUMO_NARRAY_MH_S_CAST_H
#define NUMO_NARRAY_MH_S_CAST_H 1

#define DEF_CAST_ARRAY_FUNC(tDType, tNAryClass)                                                \
  static VALUE tDType##_cast_array(VALUE rary) {                                               \
    VALUE nary = na_s_new_like(tNAryClass, rary);                                              \
    narray_t* na;                                                                              \
    GetNArray(nary, na);                                                                       \
    if (na->size > 0) {                                                                        \
      tDType##_store_array(nary, rary);                                                        \
    }                                                                                          \
    return nary;                                                                               \
  }

#define DEF_NARRAY_S_CAST_METHOD_FUNC(tDType, tNAryClass)                                      \
  DEF_CAST_ARRAY_FUNC(tDType, tNAryClass)                                                      \
  static VALUE tDType##_s_cast(VALUE type, VALUE obj) {                                        \
    if (rb_obj_class(obj) == tNAryClass) {                                                     \
      return obj;                                                                              \
    }                                                                                          \
    if (RTEST(rb_obj_is_kind_of(obj, rb_cNumeric))) {                                          \
      tDType x = m_num_to_data(obj);                                                           \
      return tDType##_new_dim0(x);                                                             \
    }                                                                                          \
    if (RTEST(rb_obj_is_kind_of(obj, rb_cArray))) {                                            \
      return tDType##_cast_array(obj);                                                         \
    }                                                                                          \
    if (IsNArray(obj)) {                                                                       \
      narray_t* na;                                                                            \
      GetNArray(obj, na);                                                                      \
      VALUE v = nary_new(cT, NA_NDIM(na), NA_SHAPE(na));                                       \
      if (NA_SIZE(na) > 0) {                                                                   \
        tDType##_store(v, obj);                                                                \
      }                                                                                        \
      return v;                                                                                \
    }                                                                                          \
    if (rb_respond_to(obj, id_to_a)) {                                                         \
      obj = rb_funcall(obj, id_to_a, 0);                                                       \
      if (TYPE(obj) != T_ARRAY) {                                                              \
        rb_raise(rb_eTypeError, "`to_a' did not return Array");                                \
      }                                                                                        \
      return tDType##_cast_array(obj);                                                         \
    }                                                                                          \
    rb_raise(nary_eCastError, "cannot cast to %s", rb_class2name(type));                       \
    return Qnil;                                                                               \
  }

#define DEF_NARRAY_ROBJ_S_CAST_METHOD_FUNC()                                                   \
  DEF_CAST_ARRAY_FUNC(robject, numo_cRObject)                                                  \
  static VALUE robject_s_cast(VALUE type, VALUE obj) {                                         \
    if (rb_obj_class(obj) == numo_cRObject) {                                                  \
      return obj;                                                                              \
    }                                                                                          \
    if (RTEST(rb_obj_is_kind_of(obj, rb_cNumeric))) {                                          \
      robject x = m_num_to_data(obj);                                                          \
      return robject_new_dim0(x);                                                              \
    }                                                                                          \
    if (RTEST(rb_obj_is_kind_of(obj, rb_cArray))) {                                            \
      return robject_cast_array(obj);                                                          \
    }                                                                                          \
    if (IsNArray(obj)) {                                                                       \
      narray_t* na;                                                                            \
      GetNArray(obj, na);                                                                      \
      VALUE v = nary_new(numo_cRObject, NA_NDIM(na), NA_SHAPE(na));                            \
      if (NA_SIZE(na) > 0) {                                                                   \
        robject_store(v, obj);                                                                 \
      }                                                                                        \
      return v;                                                                                \
    }                                                                                          \
    if (rb_respond_to(obj, id_to_a)) {                                                         \
      obj = rb_funcall(obj, id_to_a, 0);                                                       \
      if (TYPE(obj) != T_ARRAY) {                                                              \
        rb_raise(rb_eTypeError, "`to_a' did not return Array");                                \
      }                                                                                        \
      return robject_cast_array(obj);                                                          \
    }                                                                                          \
    return robject_new_dim0(obj);                                                              \
  }

#endif /* NUMO_NARRAY_MH_S_CAST_H */
