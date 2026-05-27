#ifndef NUMO_NARRAY_MH_EXTRACT_H
#define NUMO_NARRAY_MH_EXTRACT_H 1

#define DEF_NARRAY_EXTRACT_METHOD_FUNC(tDType)                                                 \
  static VALUE tDType##_extract(VALUE self) {                                                  \
    volatile VALUE v;                                                                          \
    char* ptr;                                                                                 \
    narray_t* na;                                                                              \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      ptr = na_get_pointer_for_read(self) + na_get_offset(self);                               \
      v = m_extract(ptr);                                                                      \
      na_release_lock(self);                                                                   \
      return v;                                                                                \
    }                                                                                          \
    return self;                                                                               \
  }

#define DEF_NARRAY_BIT_EXTRACT_METHOD_FUNC()                                                   \
  static VALUE bit_extract(VALUE self) {                                                       \
    BIT_DIGIT* ptr;                                                                            \
    BIT_DIGIT val;                                                                             \
    size_t pos;                                                                                \
    narray_t* na;                                                                              \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      pos = na_get_offset(self);                                                               \
      ptr = (BIT_DIGIT*)na_get_pointer_for_read(self);                                         \
      val = ((*((ptr) + (pos) / NB)) >> ((pos) % NB)) & 1u;                                    \
      na_release_lock(self);                                                                   \
      return INT2FIX(val);                                                                     \
    }                                                                                          \
    return self;                                                                               \
  }

#endif /* NUMO_NARRAY_MH_EXTRACT_H */
