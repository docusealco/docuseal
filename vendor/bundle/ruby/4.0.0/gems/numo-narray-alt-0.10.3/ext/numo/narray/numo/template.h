/*
  template.h
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#ifndef TEMPLATE_H
#define TEMPLATE_H

#define INIT_COUNTER(lp, c)                                                                    \
  { c = (lp)->n[0]; }

#define NDL_CNT(lp) ((lp)->n[0])
#define NDL_PTR(lp, i) ((lp)->args[i].ptr + (lp)->args[i].iter[0].pos)
#define NDL_STEP(lp, i) ((lp)->args[i].iter[0].step)
#define NDL_IDX(lp, i) ((lp)->args[i].iter[0].idx)
#define NDL_ESZ(lp, i) ((lp)->args[i].elmsz)
#define NDL_SHAPE(lp, i) ((lp)->args[i].shape)

#define INIT_PTR(lp, i, pt, st)                                                                \
  {                                                                                            \
    pt = ((lp)->args[i]).ptr + ((lp)->args[i].iter[0]).pos;                                    \
    st = ((lp)->args[i].iter[0]).step;                                                         \
  }

#define INIT_PTR_IDX(lp, i, pt, st, id)                                                        \
  {                                                                                            \
    pt = ((lp)->args[i]).ptr + ((lp)->args[i].iter[0]).pos;                                    \
    st = ((lp)->args[i].iter[0]).step;                                                         \
    id = ((lp)->args[i].iter[0]).idx;                                                          \
  }

#define INIT_ELMSIZE(lp, i, es)                                                                \
  { es = ((lp)->args[i]).elmsz; }

#define INIT_PTR_BIT(lp, i, ad, ps, st)                                                        \
  {                                                                                            \
    ps = ((lp)->args[i].iter[0]).pos;                                                          \
    ad = (BIT_DIGIT*)(((lp)->args[i]).ptr);                                                    \
    st = ((lp)->args[i].iter[0]).step;                                                         \
  }

#define INIT_PTR_BIT_IDX(lp, i, ad, ps, st, id)                                                \
  {                                                                                            \
    ps = ((lp)->args[i].iter[0]).pos;                                                          \
    ad = (BIT_DIGIT*)(((lp)->args[i]).ptr);                                                    \
    st = ((lp)->args[i].iter[0]).step;                                                         \
    id = ((lp)->args[i].iter[0]).idx;                                                          \
  }

#define GET_DATA(ptr, type, val)                                                               \
  { val = *(type*)(ptr); }

#define SET_DATA(ptr, type, val)                                                               \
  { *(type*)(ptr) = val; }

#define GET_DATA_STRIDE(ptr, step, type, val)                                                  \
  {                                                                                            \
    val = *(type*)(ptr);                                                                       \
    ptr += step;                                                                               \
  }

#define GET_DATA_INDEX(ptr, idx, type, val)                                                    \
  {                                                                                            \
    val = *(type*)(ptr + *idx);                                                                \
    idx++;                                                                                     \
  }

#define SET_DATA_STRIDE(ptr, step, type, val)                                                  \
  {                                                                                            \
    *(type*)(ptr) = val;                                                                       \
    ptr += step;                                                                               \
  }

#define SET_DATA_INDEX(ptr, idx, type, val)                                                    \
  {                                                                                            \
    *(type*)(ptr + *idx) = val;                                                                \
    idx++;                                                                                     \
  }

#define LOAD_BIT(adr, pos, val)                                                                \
  {                                                                                            \
    size_t dig = (pos) / NB;                                                                   \
    int bit = (pos) % NB;                                                                      \
    val = (((BIT_DIGIT*)(adr))[dig] >> (bit)) & 1u;                                            \
  }

#define LOAD_BIT_STEP(adr, pos, step, idx, val)                                                \
  {                                                                                            \
    size_t dig;                                                                                \
    int bit;                                                                                   \
    if (idx) {                                                                                 \
      dig = ((pos) + *(idx)) / NB;                                                             \
      bit = ((pos) + *(idx)) % NB;                                                             \
      idx++;                                                                                   \
    } else {                                                                                   \
      dig = (pos) / NB;                                                                        \
      bit = (pos) % NB;                                                                        \
      pos += step;                                                                             \
    }                                                                                          \
    val = (((BIT_DIGIT*)(adr))[dig] >> bit) & 1u;                                              \
  }

#define STORE_BIT(adr, pos, val)                                                               \
  {                                                                                            \
    size_t dig = (pos) / NB;                                                                   \
    int bit = (pos) % NB;                                                                      \
    ((BIT_DIGIT*)(adr))[dig] =                                                                 \
      (((BIT_DIGIT*)(adr))[dig] & ~(1u << (bit))) | (((val) & 1u) << (bit));                   \
  }

#define STORE_BIT_STEP(adr, pos, step, idx, val)                                               \
  {                                                                                            \
    size_t dig;                                                                                \
    int bit;                                                                                   \
    if (idx) {                                                                                 \
      dig = ((pos) + *(idx)) / NB;                                                             \
      bit = ((pos) + *(idx)) % NB;                                                             \
      idx++;                                                                                   \
    } else {                                                                                   \
      dig = (pos) / NB;                                                                        \
      bit = (pos) % NB;                                                                        \
      pos += step;                                                                             \
    }                                                                                          \
    ((BIT_DIGIT*)(adr))[dig] =                                                                 \
      (((BIT_DIGIT*)(adr))[dig] & ~(1u << (bit))) | (((val) & 1u) << (bit));                   \
  }

static inline int is_aligned(const void* ptr, const size_t alignment) {
  return ((size_t)(ptr) & ((alignment)-1)) == 0;
}

static inline int is_aligned_step(const ssize_t step, const size_t alignment) {
  return ((step) & ((alignment)-1)) == 0;
}

static inline int get_count_of_elements_not_aligned_to_simd_size(
  const void* ptr, const size_t alignment, const size_t element_size
) {
  size_t cnt = (size_t)(ptr) & ((alignment)-1);
  return (int)(cnt == 0 ? 0 : (alignment - cnt) / element_size);
}

static inline int is_same_aligned2(const void* ptr1, const void* ptr2, const size_t alignment) {
  return ((size_t)(ptr1) & ((alignment)-1)) == ((size_t)(ptr2) & ((alignment)-1));
}

static inline int
is_same_aligned3(const void* ptr1, const void* ptr2, const void* ptr3, const size_t alignment) {
  return (((size_t)(ptr1) & ((alignment)-1)) == ((size_t)(ptr2) & ((alignment)-1))) &&
         (((size_t)(ptr1) & ((alignment)-1)) == ((size_t)(ptr3) & ((alignment)-1)));
}

#endif /* ifndef TEMPLATE_H */
