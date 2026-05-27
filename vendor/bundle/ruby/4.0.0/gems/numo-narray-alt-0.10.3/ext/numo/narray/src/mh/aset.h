#ifndef NUMO_NARRAY_MH_ASET_H
#define NUMO_NARRAY_MH_ASET_H 1

/**
 * Convert a data value of obj (with a single element) to dtype.
 */
#define DEF_EXTRACT_DATA_FUNC(tDType, tNAryClass)                                              \
  static tDType tDType##_extract_data(VALUE obj) {                                             \
    if (IsNArray(obj)) {                                                                       \
      narray_t* na;                                                                            \
      GetNArray(obj, na);                                                                      \
      if (na->size != 1) {                                                                     \
        rb_raise(nary_eShapeError, "narray size should be 1");                                 \
      }                                                                                        \
      VALUE klass = rb_obj_class(obj);                                                         \
      char* ptr = na_get_pointer_for_read(obj);                                                \
      size_t pos = na_get_offset(obj);                                                         \
      if (klass == numo_cBit) {                                                                \
        BIT_DIGIT b;                                                                           \
        LOAD_BIT(ptr, pos, b);                                                                 \
        return m_from_sint(b);                                                                 \
      }                                                                                        \
      if (klass == numo_cDFloat) {                                                             \
        return m_from_real(*(double*)(ptr + pos));                                             \
      }                                                                                        \
      if (klass == numo_cSFloat) {                                                             \
        return m_from_real(*(float*)(ptr + pos));                                              \
      }                                                                                        \
      if (klass == numo_cInt64) {                                                              \
        return (tDType)m_from_int64(*(int64_t*)(ptr + pos));                                   \
      }                                                                                        \
      if (klass == numo_cInt32) {                                                              \
        return m_from_int32(*(int32_t*)(ptr + pos));                                           \
      }                                                                                        \
      if (klass == numo_cInt16) {                                                              \
        return m_from_sint(*(int16_t*)(ptr + pos));                                            \
      }                                                                                        \
      if (klass == numo_cInt8) {                                                               \
        return m_from_sint(*(int8_t*)(ptr + pos));                                             \
      }                                                                                        \
      if (klass == numo_cUInt64) {                                                             \
        return (tDType)m_from_uint64(*(u_int64_t*)(ptr + pos));                                \
      }                                                                                        \
      if (klass == numo_cUInt32) {                                                             \
        return m_from_uint32(*(u_int32_t*)(ptr + pos));                                        \
      }                                                                                        \
      if (klass == numo_cUInt16) {                                                             \
        return m_from_sint(*(u_int16_t*)(ptr + pos));                                          \
      }                                                                                        \
      if (klass == numo_cUInt8) {                                                              \
        return m_from_sint(*(u_int8_t*)(ptr + pos));                                           \
      }                                                                                        \
      if (klass == numo_cRObject) {                                                            \
        return m_num_to_data(*(VALUE*)(ptr + pos));                                            \
      }                                                                                        \
      VALUE r = rb_funcall(obj, rb_intern("coerce_cast"), 1, tNAryClass);                      \
      if (rb_obj_class(r) == tNAryClass) {                                                     \
        return tDType##_extract_data(r);                                                       \
      }                                                                                        \
      rb_raise(                                                                                \
        nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)), \
        rb_class2name(tNAryClass)                                                              \
      );                                                                                       \
    }                                                                                          \
    if (TYPE(obj) == T_ARRAY) {                                                                \
      if (RARRAY_LEN(obj) != 1) {                                                              \
        rb_raise(nary_eShapeError, "array size should be 1");                                  \
      }                                                                                        \
      return m_num_to_data(RARRAY_AREF(obj, 0));                                               \
    }                                                                                          \
    return m_num_to_data(obj);                                                                 \
  }

#define DEF_CMP_EXTRACT_DATA_FUNC(tDType, tNAryClass)                                          \
  static tDType tDType##_extract_data(VALUE obj) {                                             \
    if (IsNArray(obj)) {                                                                       \
      narray_t* na;                                                                            \
      GetNArray(obj, na);                                                                      \
      if (na->size != 1) {                                                                     \
        rb_raise(nary_eShapeError, "narray size should be 1");                                 \
      }                                                                                        \
      VALUE klass = rb_obj_class(obj);                                                         \
      char* ptr = na_get_pointer_for_read(obj);                                                \
      size_t pos = na_get_offset(obj);                                                         \
      if (klass == numo_cBit) {                                                                \
        BIT_DIGIT b;                                                                           \
        LOAD_BIT(ptr, pos, b);                                                                 \
        return m_from_sint(b);                                                                 \
      }                                                                                        \
      if (klass == numo_cDComplex) {                                                           \
        dcomplex* p = (dcomplex*)(ptr + pos);                                                  \
        return c_new(REAL(*p), IMAG(*p));                                                      \
      }                                                                                        \
      if (klass == numo_cSComplex) {                                                           \
        scomplex* p = (scomplex*)(ptr + pos);                                                  \
        return c_new(REAL(*p), IMAG(*p));                                                      \
      }                                                                                        \
      if (klass == numo_cDFloat) {                                                             \
        return m_from_real(*(double*)(ptr + pos));                                             \
      }                                                                                        \
      if (klass == numo_cSFloat) {                                                             \
        return m_from_real(*(float*)(ptr + pos));                                              \
      }                                                                                        \
      if (klass == numo_cInt64) {                                                              \
        return m_from_int64(*(int64_t*)(ptr + pos));                                           \
      }                                                                                        \
      if (klass == numo_cInt32) {                                                              \
        return m_from_int32(*(int32_t*)(ptr + pos));                                           \
      }                                                                                        \
      if (klass == numo_cInt16) {                                                              \
        return m_from_sint(*(int16_t*)(ptr + pos));                                            \
      }                                                                                        \
      if (klass == numo_cInt8) {                                                               \
        return m_from_sint(*(int8_t*)(ptr + pos));                                             \
      }                                                                                        \
      if (klass == numo_cUInt64) {                                                             \
        return m_from_uint64(*(u_int64_t*)(ptr + pos));                                        \
      }                                                                                        \
      if (klass == numo_cUInt32) {                                                             \
        return m_from_uint32(*(u_int32_t*)(ptr + pos));                                        \
      }                                                                                        \
      if (klass == numo_cUInt16) {                                                             \
        return m_from_sint(*(u_int16_t*)(ptr + pos));                                          \
      }                                                                                        \
      if (klass == numo_cUInt8) {                                                              \
        return m_from_sint(*(u_int8_t*)(ptr + pos));                                           \
      }                                                                                        \
      if (klass == numo_cRObject) {                                                            \
        return m_num_to_data(*(VALUE*)(ptr + pos));                                            \
      }                                                                                        \
      VALUE r = rb_funcall(obj, rb_intern("coerce_cast"), 1, tNAryClass);                      \
      if (rb_obj_class(r) == tNAryClass) {                                                     \
        return tDType##_extract_data(r);                                                       \
      }                                                                                        \
      rb_raise(                                                                                \
        nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)), \
        rb_class2name(tNAryClass)                                                              \
      );                                                                                       \
    }                                                                                          \
    if (TYPE(obj) == T_ARRAY) {                                                                \
      if (RARRAY_LEN(obj) != 1) {                                                              \
        rb_raise(nary_eShapeError, "array size should be 1");                                  \
      }                                                                                        \
      return m_num_to_data(RARRAY_AREF(obj, 0));                                               \
    }                                                                                          \
    return m_num_to_data(obj);                                                                 \
  }

#define DEF_NARRAY_ASET_METHOD_FUNC(tDType)                                                    \
  static VALUE tDType##_aset(int argc, VALUE* argv, VALUE self) {                              \
    argc--;                                                                                    \
    if (argc == 0) {                                                                           \
      tDType##_store(self, argv[argc]);                                                        \
    } else {                                                                                   \
      size_t pos;                                                                              \
      int nd = na_get_result_dimension(self, argc, argv, sizeof(tDType), &pos);                \
      if (nd) {                                                                                \
        VALUE a = na_aref_main(argc, argv, self, 0, nd);                                       \
        tDType##_store(a, argv[argc]);                                                         \
      } else {                                                                                 \
        tDType x = tDType##_extract_data(argv[argc]);                                          \
        char* ptr = na_get_pointer_for_read_write(self) + pos;                                 \
        *(tDType*)ptr = x;                                                                     \
      }                                                                                        \
    }                                                                                          \
    return argv[argc];                                                                         \
  }

#endif /* NUMO_NARRAY_MH_ASET_H */
