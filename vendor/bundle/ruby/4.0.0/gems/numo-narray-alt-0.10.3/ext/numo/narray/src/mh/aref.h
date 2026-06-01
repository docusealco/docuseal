#ifndef NUMO_NARRAY_MH_AREF_H
#define NUMO_NARRAY_MH_AREF_H 1

#define DEF_NARRAY_AREF_METHOD_FUNC(tDType)                                                    \
  static VALUE tDType##_aref(int argc, VALUE* argv, VALUE self) {                              \
    size_t pos;                                                                                \
    int nd = na_get_result_dimension(self, argc, argv, sizeof(tDType), &pos);                  \
    if (nd) {                                                                                  \
      return na_aref_main(argc, argv, self, 0, nd);                                            \
    }                                                                                          \
    char* ptr = na_get_pointer_for_read(self) + pos;                                           \
    return m_extract(ptr);                                                                     \
  }

#define DEF_NARRAY_BIT_AREF_METHOD_FUNC()                                                      \
  static VALUE bit_aref(int argc, VALUE* argv, VALUE self) {                                   \
    size_t pos;                                                                                \
    int nd = na_get_result_dimension(self, argc, argv, 1, &pos);                               \
    if (nd) {                                                                                  \
      return na_aref_main(argc, argv, self, 0, nd);                                            \
    }                                                                                          \
    char* ptr = na_get_pointer_for_read(self);                                                 \
    BIT_DIGIT x;                                                                               \
    LOAD_BIT(ptr, pos, x);                                                                     \
    return m_data_to_num(x);                                                                   \
  }

#endif /* NUMO_NARRAY_MH_AREF_H */
