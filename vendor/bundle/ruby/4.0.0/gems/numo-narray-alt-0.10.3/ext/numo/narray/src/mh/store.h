#ifndef NUMO_NARRAY_MH_STORE_H
#define NUMO_NARRAY_MH_STORE_H 1

#define DEF_STORE_NUMERIC_FUNC(tDType, tNAryClass)                                             \
  static VALUE tDType##_store(VALUE, VALUE);                                                   \
                                                                                               \
  static VALUE tDType##_new_dim0(tDType x) {                                                   \
    VALUE v = nary_new(tNAryClass, 0, NULL);                                                   \
    tDType* ptr = (tDType*)(char*)na_get_pointer_for_write(v);                                 \
    *ptr = x;                                                                                  \
    na_release_lock(v);                                                                        \
    return v;                                                                                  \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_store_numeric(VALUE self, VALUE obj) {                                 \
    tDType x = m_num_to_data(obj);                                                             \
    obj = tDType##_new_dim0(x);                                                                \
    tDType##_store(self, obj);                                                                 \
    return self;                                                                               \
  }

#define DEF_STORE_BIT_FUNC(tDType)                                                             \
  static void iter_##tDType##_store_bit(na_loop_t* const lp) {                                 \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    size_t p2;                                                                                 \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    BIT_DIGIT* a2;                                                                             \
    BIT_DIGIT x;                                                                               \
    tDType y;                                                                                  \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);                                                 \
    if (idx2) {                                                                                \
      if (idx1) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          LOAD_BIT(a2, p2 + *idx2, x);                                                         \
          idx2++;                                                                              \
          y = m_from_sint(x);                                                                  \
          SET_DATA_INDEX(p1, idx1, dtype, y);                                                  \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          LOAD_BIT(a2, p2 + *idx2, x);                                                         \
          idx2++;                                                                              \
          y = m_from_sint(x);                                                                  \
          SET_DATA_STRIDE(p1, s1, dtype, y);                                                   \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx1) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          LOAD_BIT(a2, p2, x);                                                                 \
          p2 += s2;                                                                            \
          y = m_from_sint(x);                                                                  \
          SET_DATA_INDEX(p1, idx1, dtype, y);                                                  \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          LOAD_BIT(a2, p2, x);                                                                 \
          p2 += s2;                                                                            \
          y = m_from_sint(x);                                                                  \
          SET_DATA_STRIDE(p1, s1, dtype, y);                                                   \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_store_bit(VALUE self, VALUE obj) {                                     \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };                                \
    ndfunc_t ndf = { iter_##tDType##_store_bit, FULL_LOOP, 2, 0, ain, 0 };                     \
    na_ndloop(&ndf, 2, self, obj);                                                             \
    return self;                                                                               \
  }

#define DEF_STORE_DTYPE_FUNC(tDType, tFrmDType, tFrmPType, mFrmFunc)                           \
  static void iter_##tDType##_store_##tFrmDType(na_loop_t* const lp) {                         \
    size_t n;                                                                                  \
    size_t s1;                                                                                 \
    size_t s2;                                                                                 \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    size_t* idx1;                                                                              \
    size_t* idx2;                                                                              \
    tFrmPType x;                                                                               \
    tDType y;                                                                                  \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    INIT_PTR_IDX(lp, 1, p2, s2, idx2);                                                         \
    if (idx2) {                                                                                \
      if (idx1) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p2, idx2, tFrmPType, x);                                              \
          y = (tDType)mFrmFunc(x);                                                             \
          SET_DATA_INDEX(p1, idx1, tDType, y);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_INDEX(p2, idx2, tFrmPType, x);                                              \
          y = (tDType)mFrmFunc(x);                                                             \
          SET_DATA_STRIDE(p1, s1, tDType, y);                                                  \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (idx1) {                                                                              \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p2, s2, tFrmPType, x);                                               \
          y = (tDType)mFrmFunc(x);                                                             \
          SET_DATA_INDEX(p1, idx1, tDType, y);                                                 \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          GET_DATA_STRIDE(p2, s2, tFrmPType, x);                                               \
          y = (tDType)mFrmFunc(x);                                                             \
          SET_DATA_STRIDE(p1, s1, tDType, y);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_store_##tFrmDType(VALUE self, VALUE obj) {                             \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };                                \
    ndfunc_t ndf = { iter_##tDType##_store_##tFrmDType, FULL_LOOP, 2, 0, ain, 0 };             \
    na_ndloop(&ndf, 2, self, obj);                                                             \
    return self;                                                                               \
  }

#define DEF_STORE_ARRAY_FUNC(tDType)                                                           \
  static void iter_##tDType##_store_array(na_loop_t* const lp) {                               \
    size_t i;                                                                                  \
    size_t i1;                                                                                 \
    size_t n1;                                                                                 \
    VALUE v1;                                                                                  \
    VALUE* ptr;                                                                                \
    VALUE x;                                                                                   \
    double y;                                                                                  \
    tDType z;                                                                                  \
    size_t len;                                                                                \
    size_t c;                                                                                  \
    double beg;                                                                                \
    double step;                                                                               \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    size_t s1;                                                                                 \
    size_t* idx1;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR_IDX(lp, 0, p1, s1, idx1);                                                         \
    v1 = lp->args[1].value;                                                                    \
    i = 0;                                                                                     \
    if (lp->args[1].ptr) {                                                                     \
      if (v1 == Qtrue) {                                                                       \
        iter_##tDType##_store_##tDType(lp);                                                    \
        i = lp->args[1].shape[0];                                                              \
        if (idx1) {                                                                            \
          idx1 += i;                                                                           \
        } else {                                                                               \
          p1 += s1 * i;                                                                        \
        }                                                                                      \
      }                                                                                        \
      goto loop_end;                                                                           \
    }                                                                                          \
    ptr = &v1;                                                                                 \
    switch (TYPE(v1)) {                                                                        \
    case T_ARRAY:                                                                              \
      n1 = RARRAY_LEN(v1);                                                                     \
      ptr = RARRAY_PTR(v1);                                                                    \
      break;                                                                                   \
    case T_NIL:                                                                                \
      n1 = 0;                                                                                  \
      break;                                                                                   \
    default:                                                                                   \
      n1 = 1;                                                                                  \
    }                                                                                          \
    if (idx1) {                                                                                \
      for (i = i1 = 0; i1 < n1 && i < n; i++, i1++) {                                          \
        x = ptr[i1];                                                                           \
        if (rb_obj_is_kind_of(x, rb_cRange) || rb_obj_is_kind_of(x, rb_cArithSeq)) {           \
          nary_step_sequence(x, &len, &beg, &step);                                            \
          for (c = 0; c < len && i < n; c++, i++) {                                            \
            y = beg + step * c;                                                                \
            z = m_from_double(y);                                                              \
            SET_DATA_INDEX(p1, idx1, tDType, z);                                               \
          }                                                                                    \
        } else if (TYPE(x) != T_ARRAY) {                                                       \
          z = m_num_to_data(x);                                                                \
          SET_DATA_INDEX(p1, idx1, tDType, z);                                                 \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      for (i = i1 = 0; i1 < n1 && i < n; i++, i1++) {                                          \
        x = ptr[i1];                                                                           \
        if (rb_obj_is_kind_of(x, rb_cRange) || rb_obj_is_kind_of(x, rb_cArithSeq)) {           \
          nary_step_sequence(x, &len, &beg, &step);                                            \
          for (c = 0; c < len && i < n; c++, i++) {                                            \
            y = beg + step * c;                                                                \
            z = m_from_double(y);                                                              \
            SET_DATA_STRIDE(p1, s1, tDType, z);                                                \
          }                                                                                    \
        } else if (TYPE(x) != T_ARRAY) {                                                       \
          z = m_num_to_data(x);                                                                \
          SET_DATA_STRIDE(p1, s1, tDType, z);                                                  \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
  loop_end:                                                                                    \
    z = m_zero;                                                                                \
    if (idx1) {                                                                                \
      for (; i < n; i++) {                                                                     \
        SET_DATA_INDEX(p1, idx1, tDType, z);                                                   \
      }                                                                                        \
    } else {                                                                                   \
      for (; i < n; i++) {                                                                     \
        SET_DATA_STRIDE(p1, s1, tDType, z);                                                    \
      }                                                                                        \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_store_array(VALUE self, VALUE rary) {                                  \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { rb_cArray, 0 } };                           \
    ndfunc_t ndf = { iter_##tDType##_store_array, FULL_LOOP, 2, 0, ain, 0 };                   \
    na_ndloop_store_rarray(&ndf, self, rary);                                                  \
    return self;                                                                               \
  }

#define DEF_NARRAY_STORE_METHOD_FUNC(tDType, tNAryClass)                                       \
  DEF_STORE_NUMERIC_FUNC(tDType, tNAryClass)                                                   \
  DEF_STORE_BIT_FUNC(tDType)                                                                   \
  DEF_STORE_DTYPE_FUNC(tDType, dfloat, double, m_from_real)                                    \
  DEF_STORE_DTYPE_FUNC(tDType, sfloat, float, m_from_real)                                     \
  DEF_STORE_DTYPE_FUNC(tDType, int64, int64_t, m_from_int64)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, int32, int32_t, m_from_int32)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, int16, int16_t, m_from_sint)                                    \
  DEF_STORE_DTYPE_FUNC(tDType, int8, int8_t, m_from_sint)                                      \
  DEF_STORE_DTYPE_FUNC(tDType, uint64, u_int64_t, m_from_uint64)                               \
  DEF_STORE_DTYPE_FUNC(tDType, uint32, u_int32_t, m_from_uint32)                               \
  DEF_STORE_DTYPE_FUNC(tDType, uint16, u_int16_t, m_from_sint)                                 \
  DEF_STORE_DTYPE_FUNC(tDType, uint8, u_int8_t, m_from_sint)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, robject, VALUE, m_num_to_data)                                  \
  DEF_STORE_ARRAY_FUNC(tDType)                                                                 \
  static VALUE tDType##_store(VALUE self, VALUE obj) {                                         \
    VALUE klass = rb_obj_class(obj);                                                           \
    if (IS_INTEGER_CLASS(klass) || klass == rb_cFloat || klass == rb_cComplex) {               \
      tDType##_store_numeric(self, obj);                                                       \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cBit) {                                                                  \
      tDType##_store_bit(self, obj);                                                           \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cDFloat) {                                                               \
      tDType##_store_dfloat(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cSFloat) {                                                               \
      tDType##_store_sfloat(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt64) {                                                                \
      tDType##_store_int64(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt32) {                                                                \
      tDType##_store_int32(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt16) {                                                                \
      tDType##_store_int16(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt8) {                                                                 \
      tDType##_store_int8(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt64) {                                                               \
      tDType##_store_uint64(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt32) {                                                               \
      tDType##_store_uint32(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt16) {                                                               \
      tDType##_store_uint16(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt8) {                                                                \
      tDType##_store_uint8(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cRObject) {                                                              \
      tDType##_store_robject(self, obj);                                                       \
      return self;                                                                             \
    }                                                                                          \
    if (klass == rb_cArray) {                                                                  \
      tDType##_store_array(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (IsNArray(obj)) {                                                                       \
      VALUE r = rb_funcall(obj, rb_intern("coerce_cast"), 1, tNAryClass);                      \
      if (rb_obj_class(r) == tNAryClass) {                                                     \
        tDType##_store(self, r);                                                               \
        return self;                                                                           \
      }                                                                                        \
    }                                                                                          \
    rb_raise(                                                                                  \
      nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)),   \
      rb_class2name(rb_obj_class(self))                                                        \
    );                                                                                         \
    return self;                                                                               \
  }

#define DEF_NARRAY_CMP_STORE_METHOD_FUNC(tDType, tNAryClass)                                   \
  DEF_STORE_NUMERIC_FUNC(tDType, tNAryClass)                                                   \
  DEF_STORE_BIT_FUNC(tDType)                                                                   \
  DEF_STORE_DTYPE_FUNC(tDType, dcomplex, dcomplex, m_from_dcomplex)                            \
  DEF_STORE_DTYPE_FUNC(tDType, scomplex, scomplex, m_from_scomplex)                            \
  DEF_STORE_DTYPE_FUNC(tDType, dfloat, double, m_from_real)                                    \
  DEF_STORE_DTYPE_FUNC(tDType, sfloat, float, m_from_real)                                     \
  DEF_STORE_DTYPE_FUNC(tDType, int64, int64_t, m_from_int64)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, int32, int32_t, m_from_int32)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, int16, int16_t, m_from_sint)                                    \
  DEF_STORE_DTYPE_FUNC(tDType, int8, int8_t, m_from_sint)                                      \
  DEF_STORE_DTYPE_FUNC(tDType, uint64, u_int64_t, m_from_uint64)                               \
  DEF_STORE_DTYPE_FUNC(tDType, uint32, u_int32_t, m_from_uint32)                               \
  DEF_STORE_DTYPE_FUNC(tDType, uint16, u_int16_t, m_from_sint)                                 \
  DEF_STORE_DTYPE_FUNC(tDType, uint8, u_int8_t, m_from_sint)                                   \
  DEF_STORE_DTYPE_FUNC(tDType, robject, VALUE, m_num_to_data)                                  \
  DEF_STORE_ARRAY_FUNC(tDType)                                                                 \
  static VALUE tDType##_store(VALUE self, VALUE obj) {                                         \
    VALUE klass = rb_obj_class(obj);                                                           \
    if (IS_INTEGER_CLASS(klass) || klass == rb_cFloat || klass == rb_cComplex) {               \
      tDType##_store_numeric(self, obj);                                                       \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cBit) {                                                                  \
      tDType##_store_bit(self, obj);                                                           \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cDComplex) {                                                             \
      tDType##_store_dcomplex(self, obj);                                                      \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cSComplex) {                                                             \
      tDType##_store_scomplex(self, obj);                                                      \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cDFloat) {                                                               \
      tDType##_store_dfloat(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cSFloat) {                                                               \
      tDType##_store_sfloat(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt64) {                                                                \
      tDType##_store_int64(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt32) {                                                                \
      tDType##_store_int32(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt16) {                                                                \
      tDType##_store_int16(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt8) {                                                                 \
      tDType##_store_int8(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt64) {                                                               \
      tDType##_store_uint64(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt32) {                                                               \
      tDType##_store_uint32(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt16) {                                                               \
      tDType##_store_uint16(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt8) {                                                                \
      tDType##_store_uint8(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cRObject) {                                                              \
      tDType##_store_robject(self, obj);                                                       \
      return self;                                                                             \
    }                                                                                          \
    if (klass == rb_cArray) {                                                                  \
      tDType##_store_array(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (IsNArray(obj)) {                                                                       \
      VALUE r = rb_funcall(obj, rb_intern("coerce_cast"), 1, tNAryClass);                      \
      if (rb_obj_class(r) == tNAryClass) {                                                     \
        tDType##_store(self, r);                                                               \
        return self;                                                                           \
      }                                                                                        \
    }                                                                                          \
    rb_raise(                                                                                  \
      nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)),   \
      rb_class2name(rb_obj_class(self))                                                        \
    );                                                                                         \
    return self;                                                                               \
  }

#define DEF_NARRAY_ROBJ_STORE_METHOD_FUNC()                                                    \
  DEF_STORE_NUMERIC_FUNC(robject, numo_cRObject)                                               \
  DEF_STORE_BIT_FUNC(robject)                                                                  \
  DEF_STORE_DTYPE_FUNC(robject, dfloat, double, m_from_real)                                   \
  DEF_STORE_DTYPE_FUNC(robject, sfloat, float, m_from_real)                                    \
  DEF_STORE_DTYPE_FUNC(robject, int64, int64_t, m_from_int64)                                  \
  DEF_STORE_DTYPE_FUNC(robject, int32, int32_t, m_from_int32)                                  \
  DEF_STORE_DTYPE_FUNC(robject, int16, int16_t, m_from_sint)                                   \
  DEF_STORE_DTYPE_FUNC(robject, int8, int8_t, m_from_sint)                                     \
  DEF_STORE_DTYPE_FUNC(robject, uint64, u_int64_t, m_from_uint64)                              \
  DEF_STORE_DTYPE_FUNC(robject, uint32, u_int32_t, m_from_uint32)                              \
  DEF_STORE_DTYPE_FUNC(robject, uint16, u_int16_t, m_from_sint)                                \
  DEF_STORE_DTYPE_FUNC(robject, uint8, u_int8_t, m_from_sint)                                  \
  DEF_STORE_DTYPE_FUNC(robject, robject, VALUE, m_num_to_data)                                 \
  DEF_STORE_ARRAY_FUNC(robject)                                                                \
  static VALUE robject_store(VALUE self, VALUE obj) {                                          \
    VALUE klass = rb_obj_class(obj);                                                           \
    if (IS_INTEGER_CLASS(klass) || klass == rb_cFloat || klass == rb_cComplex) {               \
      robject_store_numeric(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cBit) {                                                                  \
      robject_store_bit(self, obj);                                                            \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cDFloat) {                                                               \
      robject_store_dfloat(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cSFloat) {                                                               \
      robject_store_sfloat(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt64) {                                                                \
      robject_store_int64(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt32) {                                                                \
      robject_store_int32(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt16) {                                                                \
      robject_store_int16(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cInt8) {                                                                 \
      robject_store_int8(self, obj);                                                           \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt64) {                                                               \
      robject_store_uint64(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt32) {                                                               \
      robject_store_uint32(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt16) {                                                               \
      robject_store_uint16(self, obj);                                                         \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cUInt8) {                                                                \
      robject_store_uint8(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (klass == numo_cRObject) {                                                              \
      robject_store_robject(self, obj);                                                        \
      return self;                                                                             \
    }                                                                                          \
    if (klass == rb_cArray) {                                                                  \
      robject_store_array(self, obj);                                                          \
      return self;                                                                             \
    }                                                                                          \
    if (IsNArray(obj)) {                                                                       \
      VALUE r = rb_funcall(obj, rb_intern("coerce_cast"), 1, numo_cRObject);                   \
      if (rb_obj_class(r) == numo_cRObject) {                                                  \
        robject_store(self, r);                                                                \
        return self;                                                                           \
      }                                                                                        \
    }                                                                                          \
    robject_store_numeric(self, obj);                                                          \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_STORE_H */
