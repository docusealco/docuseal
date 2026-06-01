#ifndef NUMO_NARRAY_MH_BIT_XOR_H
#define NUMO_NARRAY_MH_BIT_XOR_H 1

#define DEF_NARRAY_INT_BIT_XOR_METHOD_FUNC(tDType, tNAryClass)                                 \
  static void iter_##tDType##_bit_xor(na_loop_t* const lp) {                                   \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    if (is_aligned(p1, sizeof(tDType)) && is_aligned(p2, sizeof(tDType)) &&                    \
        is_aligned(p3, sizeof(tDType))) {                                                      \
      if (s1 == sizeof(tDType) && s2 == sizeof(tDType) && s3 == sizeof(tDType)) {              \
        if (p1 == p3) {                                                                        \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((tDType*)p1)[i] = m_bit_xor(((tDType*)p1)[i], ((tDType*)p2)[i]);                  \
          }                                                                                    \
        } else {                                                                               \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((tDType*)p3)[i] = m_bit_xor(((tDType*)p1)[i], ((tDType*)p2)[i]);                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
      if (is_aligned_step(s1, sizeof(tDType)) && is_aligned_step(s2, sizeof(tDType)) &&        \
          is_aligned_step(s3, sizeof(tDType))) {                                               \
        if (s2 == 0) {                                                                         \
          if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                  \
            if (p1 == p3) {                                                                    \
              for (size_t i = 0; i < n; i++) {                                                 \
                ((tDType*)p1)[i] = m_bit_xor(((tDType*)p1)[i], *(tDType*)p2);                  \
              }                                                                                \
            } else {                                                                           \
              for (size_t i = 0; i < n; i++) {                                                 \
                ((tDType*)p3)[i] = m_bit_xor(((tDType*)p1)[i], *(tDType*)p2);                  \
              }                                                                                \
            }                                                                                  \
          } else {                                                                             \
            for (size_t i = 0; i < n; i++) {                                                   \
              *(tDType*)p3 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                            \
              p1 += s1;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        } else {                                                                               \
          if (p1 == p3) {                                                                      \
            for (size_t i = 0; i < n; i++) {                                                   \
              *(tDType*)p1 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                            \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
            }                                                                                  \
          } else {                                                                             \
            for (size_t i = 0; i < n; i++) {                                                   \
              *(tDType*)p3 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                            \
              p1 += s1;                                                                        \
              p2 += s2;                                                                        \
              p3 += s3;                                                                        \
            }                                                                                  \
          }                                                                                    \
        }                                                                                      \
        return;                                                                                \
      }                                                                                        \
    }                                                                                          \
    for (size_t i = 0; i < n; i++) {                                                           \
      tDType x;                                                                                \
      tDType y;                                                                                \
      GET_DATA_STRIDE(p1, s1, tDType, x);                                                      \
      GET_DATA_STRIDE(p2, s2, tDType, y);                                                      \
      const tDType z = m_bit_xor(x, y);                                                        \
      SET_DATA_STRIDE(p3, s3, tDType, z);                                                      \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bit_xor_self(VALUE self, VALUE other) {                                \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_bit_xor, STRIDE_LOOP, 2, 1, ain, aout };                  \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bit_xor(VALUE self, VALUE other) {                                     \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_bit_xor_self(self, other);                                               \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, '^', 1, other);                                                     \
    }                                                                                          \
  }

#define DEF_NARRAY_INT8_BIT_XOR_METHOD_FUNC(tDType, tNAryClass)                                \
  static void iter_##tDType##_bit_xor(na_loop_t* const lp) {                                   \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(tDType) && s3 == sizeof(tDType)) {                                      \
        if (p1 == p3) {                                                                        \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((tDType*)p1)[i] = m_bit_xor(((tDType*)p1)[i], *(tDType*)p2);                      \
          }                                                                                    \
        } else {                                                                               \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((tDType*)p3)[i] = m_bit_xor(((tDType*)p1)[i], *(tDType*)p2);                      \
          }                                                                                    \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(tDType*)p3 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                                \
          p1 += s1;                                                                            \
          p3 += s3;                                                                            \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (p1 == p3) {                                                                          \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(tDType*)p1 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                                \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(tDType*)p3 = m_bit_xor(*(tDType*)p1, *(tDType*)p2);                                \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
          p3 += s3;                                                                            \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
    return;                                                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bit_xor_self(VALUE self, VALUE other) {                                \
    ndfunc_arg_in_t ain[2] = { { tNAryClass, 0 }, { tNAryClass, 0 } };                         \
    ndfunc_arg_out_t aout[1] = { { tNAryClass, 0 } };                                          \
    ndfunc_t ndf = { iter_##tDType##_bit_xor, STRIDE_LOOP, 2, 1, ain, aout };                  \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_bit_xor(VALUE self, VALUE other) {                                     \
    VALUE klass = na_upcast(rb_obj_class(self), rb_obj_class(other));                          \
    if (klass == tNAryClass) {                                                                 \
      return tDType##_bit_xor_self(self, other);                                               \
    } else {                                                                                   \
      VALUE v = rb_funcall(klass, id_cast, 1, self);                                           \
      return rb_funcall(v, '^', 1, other);                                                     \
    }                                                                                          \
  }

#define DEF_NARRAY_ROBJ_BIT_XOR_METHOD_FUNC()                                                  \
  static void iter_robject_bit_xor(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* p1;                                                                                  \
    char* p2;                                                                                  \
    char* p3;                                                                                  \
    ssize_t s1;                                                                                \
    ssize_t s2;                                                                                \
    ssize_t s3;                                                                                \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, p1, s1);                                                                   \
    INIT_PTR(lp, 1, p2, s2);                                                                   \
    INIT_PTR(lp, 2, p3, s3);                                                                   \
    if (s2 == 0) {                                                                             \
      if (s1 == sizeof(robject) && s3 == sizeof(robject)) {                                    \
        if (p1 == p3) {                                                                        \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((robject*)p1)[i] = m_bit_xor(((robject*)p1)[i], *(robject*)p2);                   \
          }                                                                                    \
        } else {                                                                               \
          for (size_t i = 0; i < n; i++) {                                                     \
            ((robject*)p3)[i] = m_bit_xor(((robject*)p1)[i], *(robject*)p2);                   \
          }                                                                                    \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(robject*)p3 = m_bit_xor(*(robject*)p1, *(robject*)p2);                             \
          p1 += s1;                                                                            \
          p3 += s3;                                                                            \
        }                                                                                      \
      }                                                                                        \
    } else {                                                                                   \
      if (p1 == p3) {                                                                          \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(robject*)p1 = m_bit_xor(*(robject*)p1, *(robject*)p2);                             \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
        }                                                                                      \
      } else {                                                                                 \
        for (size_t i = 0; i < n; i++) {                                                       \
          *(robject*)p3 = m_bit_xor(*(robject*)p1, *(robject*)p2);                             \
          p1 += s1;                                                                            \
          p2 += s2;                                                                            \
          p3 += s3;                                                                            \
        }                                                                                      \
      }                                                                                        \
    }                                                                                          \
    return;                                                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE robject_bit_xor_self(VALUE self, VALUE other) {                                 \
    ndfunc_arg_in_t ain[2] = { { numo_cRObject, 0 }, { numo_cRObject, 0 } };                   \
    ndfunc_arg_out_t aout[1] = { { numo_cRObject, 0 } };                                       \
    ndfunc_t ndf = { iter_robject_bit_xor, STRIDE_LOOP, 2, 1, ain, aout };                     \
    return na_ndloop(&ndf, 2, self, other);                                                    \
  }                                                                                            \
                                                                                               \
  static VALUE robject_bit_xor(VALUE self, VALUE other) {                                      \
    return robject_bit_xor_self(self, other);                                                  \
  }

#endif /* NUMO_NARRAY_MH_BIT_XOR_H */
