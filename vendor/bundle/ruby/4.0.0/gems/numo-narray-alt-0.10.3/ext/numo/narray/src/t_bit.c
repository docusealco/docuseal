/*
  t_bit.c
  Ruby/Numo::NArray - Numerical Array class for Ruby

  created on: 2017-03-11
  Copyright (C) 2017-2020 Masahiro Tanaka
*/
#include <assert.h>
#include <ruby.h>

#include "SFMT.h"
#include "numo/narray.h"
#include "numo/template.h"

#define m_map(x) m_num_to_data(rb_yield(m_data_to_num(x)))

#ifdef __SSE2__
#include <emmintrin.h>
#define SIMD_ALIGNMENT_SIZE 16
#endif

static ID id_cast;
static ID id_divmod;
static ID id_eq;
static ID id_mulsum;
static ID id_ne;
static ID id_to_a;

#include <numo/types/bit.h>

VALUE cT;
extern VALUE cRT;

#include "mh/extract.h"
#include "mh/aref.h"
#include "mh/coerce_cast.h"
#include "mh/to_a.h"
#include "mh/fill.h"
#include "mh/format.h"
#include "mh/format_to_a.h"
#include "mh/inspect.h"
#include "mh/each.h"
#include "mh/each_with_index.h"
#include "mh/mean.h"
#include "mh/var.h"
#include "mh/stddev.h"
#include "mh/rms.h"

DEF_NARRAY_BIT_EXTRACT_METHOD_FUNC()
DEF_NARRAY_BIT_AREF_METHOD_FUNC()
DEF_NARRAY_COERCE_CAST_METHOD_FUNC(bit)
DEF_NARRAY_BIT_TO_A_METHOD_FUNC()
DEF_NARRAY_BIT_FILL_METHOD_FUNC()
DEF_NARRAY_BIT_FORMAT_METHOD_FUNC()
DEF_NARRAY_BIT_FORMAT_TO_A_METHOD_FUNC()
DEF_NARRAY_BIT_INSPECT_METHOD_FUNC()
DEF_NARRAY_BIT_EACH_METHOD_FUNC()
DEF_NARRAY_BIT_EACH_WITH_INDEX_METHOD_FUNC()
DEF_NARRAY_BIT_MEAN_METHOD_FUNC()
DEF_NARRAY_BIT_VAR_METHOD_FUNC()
DEF_NARRAY_BIT_STDDEV_METHOD_FUNC()
DEF_NARRAY_BIT_RMS_METHOD_FUNC()

static VALUE bit_store(VALUE, VALUE);

static size_t bit_memsize(const void* ptr) {
  size_t size = sizeof(narray_data_t);
  const narray_data_t* na = (const narray_data_t*)ptr;

  assert(na->base.type == NARRAY_DATA_T);

  if (na->ptr != NULL) {

    size += ((na->base.size - 1) / 8 / sizeof(BIT_DIGIT) + 1) * sizeof(BIT_DIGIT);
  }
  if (na->base.size > 0) {
    if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
      size += sizeof(size_t) * na->base.ndim;
    }
  }
  return size;
}

static void bit_free(void* ptr) {
  narray_data_t* na = (narray_data_t*)ptr;

  assert(na->base.type == NARRAY_DATA_T);

  if (na->ptr != NULL) {
    if (na->owned) {
      xfree(na->ptr);
    }
    na->ptr = NULL;
  }
  if (na->base.shape != NULL && na->base.shape != &(na->base.size)) {
    xfree(na->base.shape);
    na->base.shape = NULL;
  }
  xfree(na);
}

static narray_type_info_t bit_info = {

  1, // element_bits
  0, // element_bytes
  1, // element_stride (in bits)

};

static const rb_data_type_t bit_data_type = {
  "Numo::Bit",
  {
    0,
    bit_free,
    bit_memsize,
  },
  &na_data_type,
  &bit_info,
  RUBY_TYPED_FROZEN_SHAREABLE, // flags
};

static VALUE bit_s_alloc_func(VALUE klass) {
  narray_data_t* na = ALLOC(narray_data_t);

  na->base.ndim = 0;
  na->base.type = NARRAY_DATA_T;
  na->base.flag[0] = NA_FL0_INIT;
  na->base.flag[1] = NA_FL1_INIT;
  na->base.size = 0;
  na->base.shape = NULL;
  na->base.reduce = INT2FIX(0);
  na->ptr = NULL;
  na->owned = FALSE;
  return TypedData_Wrap_Struct(klass, &bit_data_type, (void*)na);
}

static VALUE bit_allocate(VALUE self) {
  narray_t* na;
  char* ptr;

  GetNArray(self, na);

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    ptr = NA_DATA_PTR(na);
    if (na->size > 0 && ptr == NULL) {
      ptr = xmalloc(((na->size - 1) / 8 / sizeof(BIT_DIGIT) + 1) * sizeof(BIT_DIGIT));
      NA_DATA_PTR(na) = ptr;
      NA_DATA_OWNED(na) = TRUE;
    }
    break;
  case NARRAY_VIEW_T:
    rb_funcall(NA_VIEW_DATA(na), rb_intern("allocate"), 0);
    break;
  default:
    rb_raise(rb_eRuntimeError, "invalid narray type");
  }
  return self;
}

static VALUE bit_new_dim0(dtype x) {
  VALUE v;
  dtype* ptr;

  v = nary_new(cT, 0, NULL);
  ptr = (dtype*)(char*)na_get_pointer_for_write(v);
  *ptr = x;
  na_release_lock(v);
  return v;
}

static VALUE bit_store_numeric(VALUE self, VALUE obj) {
  dtype x;
  x = m_num_to_data(obj);
  obj = bit_new_dim0(x);
  bit_store(self, obj);
  return self;
}

static void iter_bit_store_bit(na_loop_t* const lp) {
  size_t n;
  ssize_t p1, p3;
  ssize_t s1, s3;
  size_t *idx1, *idx3;
  int o1, l1, r1, len;
  BIT_DIGIT *a1, *a3;
  BIT_DIGIT x;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a3, p3, s3, idx3);
  INIT_PTR_BIT_IDX(lp, 1, a1, p1, s1, idx1);
  if (s1 != 1 || s3 != 1 || idx1 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      STORE_BIT_STEP(a3, p3, s3, idx3, x);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > (ssize_t)NB) x |= *(a1 + 1) << r1;
      a1++;
      *a3 = (x & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        *(a3++) = x;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        *(a3++) = x;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      *a3 = (x & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

static VALUE bit_store_bit(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_bit, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_dfloat(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  double x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, double, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, double, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, double, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, double, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_dfloat(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_dfloat, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_sfloat(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  float x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, float, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, float, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, float, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, float, x);
        y = m_from_real(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_sfloat(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_sfloat, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_int64(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  int64_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int64_t, x);
        y = m_from_int64(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int64_t, x);
        y = m_from_int64(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int64_t, x);
        y = m_from_int64(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int64_t, x);
        y = m_from_int64(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_int64(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_int64, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_int32(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  int32_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int32_t, x);
        y = m_from_int32(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int32_t, x);
        y = m_from_int32(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int32_t, x);
        y = m_from_int32(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int32_t, x);
        y = m_from_int32(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_int32(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_int32, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_int16(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  int16_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_int16(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_int16, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_int8(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  int8_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_int8(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_int8, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_uint64(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  u_int64_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int64_t, x);
        y = m_from_uint64(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int64_t, x);
        y = m_from_uint64(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int64_t, x);
        y = m_from_uint64(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int64_t, x);
        y = m_from_uint64(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_uint64(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_uint64, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_uint32(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  u_int32_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int32_t, x);
        y = m_from_uint32(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int32_t, x);
        y = m_from_uint32(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int32_t, x);
        y = m_from_uint32(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int32_t, x);
        y = m_from_uint32(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_uint32(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_uint32, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_uint16(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  u_int16_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int16_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_uint16(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_uint16, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_uint8(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  u_int8_t x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, u_int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, u_int8_t, x);
        y = m_from_sint(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_uint8(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_uint8, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_robject(na_loop_t* const lp) {
  ssize_t i, s1, s2;
  size_t p1;
  char* p2;
  size_t *idx1, *idx2;
  VALUE x;
  BIT_DIGIT* a1;
  BIT_DIGIT y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_IDX(lp, 1, p2, s2, idx2);

  if (idx2) {
    if (idx1) {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, VALUE, x);
        y = m_num_to_data(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_INDEX(p2, idx2, VALUE, x);
        y = m_num_to_data(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  } else {
    if (idx1) {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, VALUE, x);
        y = m_num_to_data(x);
        STORE_BIT(a1, p1 + *idx1, y);
        idx1++;
      }
    } else {
      for (; i--;) {
        GET_DATA_STRIDE(p2, s2, VALUE, x);
        y = m_num_to_data(x);
        STORE_BIT(a1, p1, y);
        p1 += s1;
      }
    }
  }
}

static VALUE bit_store_robject(VALUE self, VALUE obj) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_store_robject, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop(&ndf, 2, self, obj);
  return self;
}

static void iter_bit_store_array(na_loop_t* const lp) {
  size_t i, n;
  size_t i1, n1;
  VALUE v1, *ptr;
  BIT_DIGIT* a1;
  size_t p1;
  size_t s1, *idx1;
  VALUE x;
  double y;
  BIT_DIGIT z;
  size_t len, c;
  double beg, step;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  v1 = lp->args[1].value;
  i = 0;

  if (lp->args[1].ptr) {
    if (v1 == Qtrue) {
      iter_bit_store_bit(lp);
      i = lp->args[1].shape[0];
      if (idx1) {
        idx1 += i;
      } else {
        p1 += s1 * i;
      }
    }
    goto loop_end;
  }

  ptr = &v1;

  switch (TYPE(v1)) {
  case T_ARRAY:
    n1 = RARRAY_LEN(v1);
    ptr = RARRAY_PTR(v1);
    break;
  case T_NIL:
    n1 = 0;
    break;
  default:
    n1 = 1;
  }

  if (idx1) {
    for (i = i1 = 0; i1 < n1 && i < n; i++, i1++) {
      x = ptr[i1];
      if (rb_obj_is_kind_of(x, rb_cRange) || rb_obj_is_kind_of(x, rb_cArithSeq)) {
        nary_step_sequence(x, &len, &beg, &step);
        for (c = 0; c < len && i < n; c++, i++) {
          y = beg + step * c;
          z = m_from_double(y);
          STORE_BIT(a1, p1 + *idx1, z);
          idx1++;
        }
      }
      if (TYPE(x) != T_ARRAY) {
        if (x == Qnil) x = INT2FIX(0);
        z = m_num_to_data(x);
        STORE_BIT(a1, p1 + *idx1, z);
        idx1++;
      }
    }
  } else {
    for (i = i1 = 0; i1 < n1 && i < n; i++, i1++) {
      x = ptr[i1];
      if (rb_obj_is_kind_of(x, rb_cRange) || rb_obj_is_kind_of(x, rb_cArithSeq)) {
        nary_step_sequence(x, &len, &beg, &step);
        for (c = 0; c < len && i < n; c++, i++) {
          y = beg + step * c;
          z = m_from_double(y);
          STORE_BIT(a1, p1, z);
          p1 += s1;
        }
      }
      if (TYPE(x) != T_ARRAY) {
        z = m_num_to_data(x);
        STORE_BIT(a1, p1, z);
        p1 += s1;
      }
    }
  }

loop_end:
  z = m_zero;
  if (idx1) {
    for (; i < n; i++) {
      STORE_BIT(a1, p1 + *idx1, z);
      idx1++;
    }
  } else {
    for (; i < n; i++) {
      STORE_BIT(a1, p1, z);
      p1 += s1;
    }
  }
}

static VALUE bit_store_array(VALUE self, VALUE rary) {
  ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { rb_cArray, 0 } };
  ndfunc_t ndf = { iter_bit_store_array, FULL_LOOP, 2, 0, ain, 0 };

  na_ndloop_store_rarray(&ndf, self, rary);
  return self;
}

/*
  Store elements to Numo::Bit from other.
  @overload store(other)
    @param [Object] other
    @return [Numo::Bit] self
*/
static VALUE bit_store(VALUE self, VALUE obj) {
  VALUE r, klass;

  klass = rb_obj_class(obj);

  if (klass == numo_cBit) {
    bit_store_bit(self, obj);
    return self;
  }

  if (IS_INTEGER_CLASS(klass) || klass == rb_cFloat || klass == rb_cComplex) {
    bit_store_numeric(self, obj);
    return self;
  }

  if (klass == numo_cDFloat) {
    bit_store_dfloat(self, obj);
    return self;
  }

  if (klass == numo_cSFloat) {
    bit_store_sfloat(self, obj);
    return self;
  }

  if (klass == numo_cInt64) {
    bit_store_int64(self, obj);
    return self;
  }

  if (klass == numo_cInt32) {
    bit_store_int32(self, obj);
    return self;
  }

  if (klass == numo_cInt16) {
    bit_store_int16(self, obj);
    return self;
  }

  if (klass == numo_cInt8) {
    bit_store_int8(self, obj);
    return self;
  }

  if (klass == numo_cUInt64) {
    bit_store_uint64(self, obj);
    return self;
  }

  if (klass == numo_cUInt32) {
    bit_store_uint32(self, obj);
    return self;
  }

  if (klass == numo_cUInt16) {
    bit_store_uint16(self, obj);
    return self;
  }

  if (klass == numo_cUInt8) {
    bit_store_uint8(self, obj);
    return self;
  }

  if (klass == numo_cRObject) {
    bit_store_robject(self, obj);
    return self;
  }

  if (klass == rb_cArray) {
    bit_store_array(self, obj);
    return self;
  }

  if (IsNArray(obj)) {
    r = rb_funcall(obj, rb_intern("coerce_cast"), 1, cT);
    if (rb_obj_class(r) == cT) {
      bit_store(self, r);
      return self;
    }
  }

  rb_raise(
    nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)),
    rb_class2name(rb_obj_class(self))
  );

  return self;
}

/*
  Convert a data value of obj (with a single element) to dtype.
*/
static dtype bit_extract_data(VALUE obj) {
  narray_t* na;
  dtype x;
  char* ptr;
  size_t pos;
  VALUE r, klass;

  if (IsNArray(obj)) {
    GetNArray(obj, na);
    if (na->size != 1) {
      rb_raise(nary_eShapeError, "narray size should be 1");
    }
    klass = rb_obj_class(obj);
    ptr = na_get_pointer_for_read(obj);
    pos = na_get_offset(obj);

    if (klass == numo_cBit) {
      {
        BIT_DIGIT b;
        LOAD_BIT(ptr, pos, b);
        x = m_from_sint(b);
      };
      return x;
    }

    if (klass == numo_cDFloat) {
      x = m_from_real(*(double*)(ptr + pos));
      return x;
    }

    if (klass == numo_cSFloat) {
      x = m_from_real(*(float*)(ptr + pos));
      return x;
    }

    if (klass == numo_cInt64) {
      x = m_from_int64(*(int64_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cInt32) {
      x = m_from_int32(*(int32_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cInt16) {
      x = m_from_sint(*(int16_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cInt8) {
      x = m_from_sint(*(int8_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cUInt64) {
      x = m_from_uint64(*(u_int64_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cUInt32) {
      x = m_from_uint32(*(u_int32_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cUInt16) {
      x = m_from_sint(*(u_int16_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cUInt8) {
      x = m_from_sint(*(u_int8_t*)(ptr + pos));
      return x;
    }

    if (klass == numo_cRObject) {
      x = m_num_to_data(*(VALUE*)(ptr + pos));
      return x;
    }

    // coerce
    r = rb_funcall(obj, rb_intern("coerce_cast"), 1, cT);
    if (rb_obj_class(r) == cT) {
      return bit_extract_data(r);
    }

    rb_raise(
      nary_eCastError, "unknown conversion from %s to %s", rb_class2name(rb_obj_class(obj)),
      rb_class2name(cT)
    );
  }
  if (TYPE(obj) == T_ARRAY) {
    if (RARRAY_LEN(obj) != 1) {
      rb_raise(nary_eShapeError, "array size should be 1");
    }
    return m_num_to_data(RARRAY_AREF(obj, 0));
  }
  return m_num_to_data(obj);
}

static VALUE bit_cast_array(VALUE rary) {
  VALUE nary;
  narray_t* na;

  nary = na_s_new_like(cT, rary);
  GetNArray(nary, na);
  if (na->size > 0) {
    bit_store_array(nary, rary);
  }
  return nary;
}

/*
  Cast object to Numo::Bit.
  @overload [](elements)
  @overload cast(array)
    @param [Numeric,Array] elements
    @param [Array] array
    @return [Numo::Bit]
*/
static VALUE bit_s_cast(VALUE type, VALUE obj) {
  VALUE v;
  narray_t* na;
  dtype x;

  if (rb_obj_class(obj) == cT) {
    return obj;
  }
  if (RTEST(rb_obj_is_kind_of(obj, rb_cNumeric))) {
    x = m_num_to_data(obj);
    return bit_new_dim0(x);
  }
  if (RTEST(rb_obj_is_kind_of(obj, rb_cArray))) {
    return bit_cast_array(obj);
  }
  if (IsNArray(obj)) {
    GetNArray(obj, na);
    v = nary_new(cT, NA_NDIM(na), NA_SHAPE(na));
    if (NA_SIZE(na) > 0) {
      bit_store(v, obj);
    }
    return v;
  }
  if (rb_respond_to(obj, id_to_a)) {
    obj = rb_funcall(obj, id_to_a, 0);
    if (TYPE(obj) != T_ARRAY) {
      rb_raise(rb_eTypeError, "`to_a' did not return Array");
    }
    return bit_cast_array(obj);
  }

  rb_raise(nary_eCastError, "cannot cast to %s", rb_class2name(type));
  return Qnil;
}

/*
  Multi-dimensional element assignment.
  @overload []=(dim0,...,dimL,val)
    @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,Symbol]
    dim0,...,dimL  multi-dimensional indices.
    @param [Numeric,Numo::NArray,Array] val  Value(s) to be set to self.
    @return [Numeric,Numo::NArray,Array] returns `val` (last argument).
  @see Numo::NArray#[]=
  @see #[]

  @example
      a = Numo::Bit.new(4,5).fill(0)
      # => Numo::Bit#shape=[4,5]
      # [[0, 0, 0, 0, 0],
      #  [0, 0, 0, 0, 0],
      #  [0, 0, 0, 0, 0],
      #  [0, 0, 0, 0, 0]]

      a[(0..-1)%2,(1..-1)%2] = 1
      a
      # => Numo::Bit#shape=[4,5]
      # [[0, 1, 0, 1, 0],
      #  [0, 0, 0, 0, 0],
      #  [0, 1, 0, 1, 0],
      #  [0, 0, 0, 0, 0]]
*/
static VALUE bit_aset(int argc, VALUE* argv, VALUE self) {
  int nd;
  size_t pos;
  char* ptr;
  VALUE a;
  dtype x;

  argc--;
  if (argc == 0) {
    bit_store(self, argv[argc]);
  } else {
    nd = na_get_result_dimension(self, argc, argv, 1, &pos);
    if (nd) {
      a = na_aref_main(argc, argv, self, 0, nd);
      bit_store(a, argv[argc]);
    } else {
      x = bit_extract_data(argv[argc]);
      ptr = na_get_pointer_for_read_write(self);
      STORE_BIT(ptr, pos, x);
    }
  }
  return argv[argc];
}

static void iter_bit_copy(na_loop_t* const lp) {
  size_t n;
  size_t p1, p3;
  ssize_t s1, s3;
  size_t *idx1, *idx3;
  int o1, l1, r1, len;
  BIT_DIGIT *a1, *a3;
  BIT_DIGIT x;
  BIT_DIGIT y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a3, p3, s3, idx3);
  if (s1 != 1 || s3 != 1 || idx1 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      y = m_copy(x);
      STORE_BIT_STEP(a3, p3, s3, idx3, y);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      y = m_copy(x);
      *a3 = (y & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = m_copy(x);
        *(a3++) = y;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        y = m_copy(x);
        *(a3++) = y;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      y = m_copy(x);
      *a3 = (y & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Unary copy.
  @overload copy
    @return [Numo::Bit] copy of self.
*/
static VALUE bit_copy(VALUE self) {
  ndfunc_arg_in_t ain[1] = { { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_copy, FULL_LOOP, 1, 1, ain, aout };

  return na_ndloop(&ndf, 1, self);
}

static void iter_bit_not(na_loop_t* const lp) {
  size_t n;
  size_t p1, p3;
  ssize_t s1, s3;
  size_t *idx1, *idx3;
  int o1, l1, r1, len;
  BIT_DIGIT *a1, *a3;
  BIT_DIGIT x;
  BIT_DIGIT y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a3, p3, s3, idx3);
  if (s1 != 1 || s3 != 1 || idx1 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      y = m_not(x);
      STORE_BIT_STEP(a3, p3, s3, idx3, y);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      y = m_not(x);
      *a3 = (y & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = m_not(x);
        *(a3++) = y;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        y = m_not(x);
        *(a3++) = y;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      y = m_not(x);
      *a3 = (y & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Unary not.
  @overload not
    @return [Numo::Bit] not of self.
*/
static VALUE bit_not(VALUE self) {
  ndfunc_arg_in_t ain[1] = { { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_not, FULL_LOOP, 1, 1, ain, aout };

  return na_ndloop(&ndf, 1, self);
}

static void iter_bit_and(na_loop_t* const lp) {
  size_t n;
  size_t p1, p2, p3;
  ssize_t s1, s2, s3;
  size_t *idx1, *idx2, *idx3;
  int o1, o2, l1, l2, r1, r2, len;
  BIT_DIGIT *a1, *a2, *a3;
  BIT_DIGIT x, y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  INIT_PTR_BIT_IDX(lp, 2, a3, p3, s3, idx3);
  if (s1 != 1 || s2 != 1 || s3 != 1 || idx1 || idx2 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      LOAD_BIT_STEP(a2, p2, s2, idx2, y);
      x = m_and(x, y);
      STORE_BIT_STEP(a3, p3, s3, idx3, x);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a2 += p2 / NB;
    p2 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    o2 = (int)(p2 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    l2 = NB + o2;
    r2 = NB - o2;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      if (o2 >= 0)
        y = *a2 >> o2;
      else
        y = *a2 << -o2;
      if (p2 + len > NB) y |= *(a2 + 1) << r2;
      a2++;
      x = m_and(x, y);
      *a3 = (x & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0 && o2 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = *(a2++);
        x = m_and(x, y);
        *(a3++) = x;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        if (o2 == 0) {
          y = *a2;
        } else if (o2 > 0) {
          y = *a2 >> o2 | *(a2 + 1) << r2;
        } else {
          y = *a2 << -o2 | *(a2 - 1) >> l2;
        }
        a2++;
        x = m_and(x, y);
        *(a3++) = x;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      if (o2 == 0) {
        y = *a2;
      } else if (o2 > 0) {
        y = *a2 >> o2;
        if ((int)n > r2) {
          y |= *(a2 + 1) << r2;
        }
      } else {
        y = *(a2 - 1) >> l2;
        if ((int)n > -o2) {
          y |= *a2 << -o2;
        }
      }
      x = m_and(x, y);
      *a3 = (x & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Binary and.
  @overload & other
    @param [Numo::NArray,Numeric] other
    @return [Numo::NArray] and of self and other.
*/
static VALUE bit_and(VALUE self, VALUE other) {
  ndfunc_arg_in_t ain[2] = { { cT, 0 }, { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_and, FULL_LOOP, 2, 1, ain, aout };

  return na_ndloop(&ndf, 2, self, other);
}

static void iter_bit_or(na_loop_t* const lp) {
  size_t n;
  size_t p1, p2, p3;
  ssize_t s1, s2, s3;
  size_t *idx1, *idx2, *idx3;
  int o1, o2, l1, l2, r1, r2, len;
  BIT_DIGIT *a1, *a2, *a3;
  BIT_DIGIT x, y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  INIT_PTR_BIT_IDX(lp, 2, a3, p3, s3, idx3);
  if (s1 != 1 || s2 != 1 || s3 != 1 || idx1 || idx2 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      LOAD_BIT_STEP(a2, p2, s2, idx2, y);
      x = m_or(x, y);
      STORE_BIT_STEP(a3, p3, s3, idx3, x);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a2 += p2 / NB;
    p2 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    o2 = (int)(p2 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    l2 = NB + o2;
    r2 = NB - o2;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      if (o2 >= 0)
        y = *a2 >> o2;
      else
        y = *a2 << -o2;
      if (p2 + len > NB) y |= *(a2 + 1) << r2;
      a2++;
      x = m_or(x, y);
      *a3 = (x & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0 && o2 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = *(a2++);
        x = m_or(x, y);
        *(a3++) = x;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        if (o2 == 0) {
          y = *a2;
        } else if (o2 > 0) {
          y = *a2 >> o2 | *(a2 + 1) << r2;
        } else {
          y = *a2 << -o2 | *(a2 - 1) >> l2;
        }
        a2++;
        x = m_or(x, y);
        *(a3++) = x;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      if (o2 == 0) {
        y = *a2;
      } else if (o2 > 0) {
        y = *a2 >> o2;
        if ((int)n > r2) {
          y |= *(a2 + 1) << r2;
        }
      } else {
        y = *(a2 - 1) >> l2;
        if ((int)n > -o2) {
          y |= *a2 << -o2;
        }
      }
      x = m_or(x, y);
      *a3 = (x & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Binary or.
  @overload | other
    @param [Numo::NArray,Numeric] other
    @return [Numo::NArray] or of self and other.
*/
static VALUE bit_or(VALUE self, VALUE other) {
  ndfunc_arg_in_t ain[2] = { { cT, 0 }, { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_or, FULL_LOOP, 2, 1, ain, aout };

  return na_ndloop(&ndf, 2, self, other);
}

static void iter_bit_xor(na_loop_t* const lp) {
  size_t n;
  size_t p1, p2, p3;
  ssize_t s1, s2, s3;
  size_t *idx1, *idx2, *idx3;
  int o1, o2, l1, l2, r1, r2, len;
  BIT_DIGIT *a1, *a2, *a3;
  BIT_DIGIT x, y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  INIT_PTR_BIT_IDX(lp, 2, a3, p3, s3, idx3);
  if (s1 != 1 || s2 != 1 || s3 != 1 || idx1 || idx2 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      LOAD_BIT_STEP(a2, p2, s2, idx2, y);
      x = m_xor(x, y);
      STORE_BIT_STEP(a3, p3, s3, idx3, x);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a2 += p2 / NB;
    p2 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    o2 = (int)(p2 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    l2 = NB + o2;
    r2 = NB - o2;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      if (o2 >= 0)
        y = *a2 >> o2;
      else
        y = *a2 << -o2;
      if (p2 + len > NB) y |= *(a2 + 1) << r2;
      a2++;
      x = m_xor(x, y);
      *a3 = (x & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0 && o2 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = *(a2++);
        x = m_xor(x, y);
        *(a3++) = x;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        if (o2 == 0) {
          y = *a2;
        } else if (o2 > 0) {
          y = *a2 >> o2 | *(a2 + 1) << r2;
        } else {
          y = *a2 << -o2 | *(a2 - 1) >> l2;
        }
        a2++;
        x = m_xor(x, y);
        *(a3++) = x;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      if (o2 == 0) {
        y = *a2;
      } else if (o2 > 0) {
        y = *a2 >> o2;
        if ((int)n > r2) {
          y |= *(a2 + 1) << r2;
        }
      } else {
        y = *(a2 - 1) >> l2;
        if ((int)n > -o2) {
          y |= *a2 << -o2;
        }
      }
      x = m_xor(x, y);
      *a3 = (x & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Binary xor.
  @overload ^ other
    @param [Numo::NArray,Numeric] other
    @return [Numo::NArray] xor of self and other.
*/
static VALUE bit_xor(VALUE self, VALUE other) {
  ndfunc_arg_in_t ain[2] = { { cT, 0 }, { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_xor, FULL_LOOP, 2, 1, ain, aout };

  return na_ndloop(&ndf, 2, self, other);
}

static void iter_bit_eq(na_loop_t* const lp) {
  size_t n;
  size_t p1, p2, p3;
  ssize_t s1, s2, s3;
  size_t *idx1, *idx2, *idx3;
  int o1, o2, l1, l2, r1, r2, len;
  BIT_DIGIT *a1, *a2, *a3;
  BIT_DIGIT x, y;

  INIT_COUNTER(lp, n);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  INIT_PTR_BIT_IDX(lp, 2, a3, p3, s3, idx3);
  if (s1 != 1 || s2 != 1 || s3 != 1 || idx1 || idx2 || idx3) {
    for (; n--;) {
      LOAD_BIT_STEP(a1, p1, s1, idx1, x);
      LOAD_BIT_STEP(a2, p2, s2, idx2, y);
      x = m_eq(x, y);
      STORE_BIT_STEP(a3, p3, s3, idx3, x);
    }
  } else {
    a1 += p1 / NB;
    p1 %= NB;
    a2 += p2 / NB;
    p2 %= NB;
    a3 += p3 / NB;
    p3 %= NB;
    o1 = (int)(p1 - p3);
    o2 = (int)(p2 - p3);
    l1 = NB + o1;
    r1 = NB - o1;
    l2 = NB + o2;
    r2 = NB - o2;
    if (p3 > 0 || n < NB) {
      len = (int)(NB - p3);
      if ((int)n < len) len = (int)n;
      if (o1 >= 0)
        x = *a1 >> o1;
      else
        x = *a1 << -o1;
      if (p1 + len > NB) x |= *(a1 + 1) << r1;
      a1++;
      if (o2 >= 0)
        y = *a2 >> o2;
      else
        y = *a2 << -o2;
      if (p2 + len > NB) y |= *(a2 + 1) << r2;
      a2++;
      x = m_eq(x, y);
      *a3 = (x & (SLB(len) << p3)) | (*a3 & ~(SLB(len) << p3));
      a3++;
      n -= len;
    }
    if (o1 == 0 && o2 == 0) {
      for (; n >= NB; n -= NB) {
        x = *(a1++);
        y = *(a2++);
        x = m_eq(x, y);
        *(a3++) = x;
      }
    } else {
      for (; n >= NB; n -= NB) {
        if (o1 == 0) {
          x = *a1;
        } else if (o1 > 0) {
          x = *a1 >> o1 | *(a1 + 1) << r1;
        } else {
          x = *a1 << -o1 | *(a1 - 1) >> l1;
        }
        a1++;
        if (o2 == 0) {
          y = *a2;
        } else if (o2 > 0) {
          y = *a2 >> o2 | *(a2 + 1) << r2;
        } else {
          y = *a2 << -o2 | *(a2 - 1) >> l2;
        }
        a2++;
        x = m_eq(x, y);
        *(a3++) = x;
      }
    }
    if (n > 0) {
      if (o1 == 0) {
        x = *a1;
      } else if (o1 > 0) {
        x = *a1 >> o1;
        if ((int)n > r1) {
          x |= *(a1 + 1) << r1;
        }
      } else {
        x = *(a1 - 1) >> l1;
        if ((int)n > -o1) {
          x |= *a1 << -o1;
        }
      }
      if (o2 == 0) {
        y = *a2;
      } else if (o2 > 0) {
        y = *a2 >> o2;
        if ((int)n > r2) {
          y |= *(a2 + 1) << r2;
        }
      } else {
        y = *(a2 - 1) >> l2;
        if ((int)n > -o2) {
          y |= *a2 << -o2;
        }
      }
      x = m_eq(x, y);
      *a3 = (x & SLB(n)) | (*a3 & BALL << n);
    }
  }
}

/*
  Binary eq.
  @overload eq other
    @param [Numo::NArray,Numeric] other
    @return [Numo::NArray] eq of self and other.
*/
static VALUE bit_eq(VALUE self, VALUE other) {
  ndfunc_arg_in_t ain[2] = { { cT, 0 }, { cT, 0 } };
  ndfunc_arg_out_t aout[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_eq, FULL_LOOP, 2, 1, ain, aout };

  return na_ndloop(&ndf, 2, self, other);
}

#undef int_t
#define int_t int64_t

static void iter_bit_count_true(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT* a1;
  size_t p1;
  char* p2;
  ssize_t s1, s2;
  size_t* idx1;
  BIT_DIGIT x = 0;
  int_t y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR(lp, 1, p2, s2);
  if (s2 == 0) {
    GET_DATA(p2, int_t, y);
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, x);
        idx1++;
        if (m_count_true(x)) {
          y++;
        }
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, x);
        p1 += s1;
        if (m_count_true(x)) {
          y++;
        }
      }
    }
    *(int_t*)p2 = y;
  } else {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, x);
        idx1++;
        if (m_count_true(x)) {
          GET_DATA(p2, int_t, y);
          y++;
          SET_DATA(p2, int_t, y);
        }
        p2 += s2;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, x);
        p1 += s1;
        if (m_count_true(x)) {
          GET_DATA(p2, int_t, y);
          y++;
          SET_DATA(p2, int_t, y);
        }
        p2 += s2;
      }
    }
  }
}

/*
  Returns the number of bits.
  If argument is supplied, return Int-array counted along the axes.
  @overload count_true(axis:nil, keepdims:false)
    @param [Integer,Array,Range] axis (keyword) axes to be counted.
    @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in the result array
    as dimensions with size one.
    @return [Numo::Int64]
*/
static VALUE bit_count_true(int argc, VALUE* argv, VALUE self) {
  VALUE v, reduce;
  narray_t* na;
  ndfunc_arg_in_t ain[3] = { { cT, 0 }, { sym_reduce, 0 }, { sym_init, 0 } };
  ndfunc_arg_out_t aout[1] = { { numo_cInt64, 0 } };
  ndfunc_t ndf = { iter_bit_count_true, FULL_LOOP_NIP, 3, 1, ain, aout };

  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    return INT2FIX(0);
  }
  reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);
  v = na_ndloop(&ndf, 3, self, reduce, INT2FIX(0));
  return rb_funcall(v, rb_intern("extract"), 0);
}

#undef int_t
#define int_t int64_t

static void iter_bit_count_false(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT* a1;
  size_t p1;
  char* p2;
  ssize_t s1, s2;
  size_t* idx1;
  BIT_DIGIT x = 0;
  int_t y;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR(lp, 1, p2, s2);
  if (s2 == 0) {
    GET_DATA(p2, int_t, y);
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, x);
        idx1++;
        if (m_count_false(x)) {
          y++;
        }
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, x);
        p1 += s1;
        if (m_count_false(x)) {
          y++;
        }
      }
    }
    *(int_t*)p2 = y;
  } else {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, x);
        idx1++;
        if (m_count_false(x)) {
          GET_DATA(p2, int_t, y);
          y++;
          SET_DATA(p2, int_t, y);
        }
        p2 += s2;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, x);
        p1 += s1;
        if (m_count_false(x)) {
          GET_DATA(p2, int_t, y);
          y++;
          SET_DATA(p2, int_t, y);
        }
        p2 += s2;
      }
    }
  }
}

/*
  Returns the number of bits.
  If argument is supplied, return Int-array counted along the axes.
  @overload count_false(axis:nil, keepdims:false)
    @param [Integer,Array,Range] axis (keyword) axes to be counted.
    @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in the result array
    as dimensions with size one.
    @return [Numo::Int64]
*/
static VALUE bit_count_false(int argc, VALUE* argv, VALUE self) {
  VALUE v, reduce;
  narray_t* na;
  ndfunc_arg_in_t ain[3] = { { cT, 0 }, { sym_reduce, 0 }, { sym_init, 0 } };
  ndfunc_arg_out_t aout[1] = { { numo_cInt64, 0 } };
  ndfunc_t ndf = { iter_bit_count_false, FULL_LOOP_NIP, 3, 1, ain, aout };

  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    return INT2FIX(0);
  }
  reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);
  v = na_ndloop(&ndf, 3, self, reduce, INT2FIX(0));
  return rb_funcall(v, rb_intern("extract"), 0);
}

static void iter_bit_all_p(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT *a1, *a2;
  size_t p1, p2;
  ssize_t s1, s2;
  size_t *idx1, *idx2;
  BIT_DIGIT x = 0, y = 0;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  if (idx2) {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a2, p2 + *idx2, y);
        if (y == 1) {
          LOAD_BIT(a1, p1 + *idx1, x);
          if (x != 1) {
            STORE_BIT(a2, p2 + *idx2, x);
          }
        }
        idx1++;
        idx2++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a2, p2 + *idx2, y);
        if (y == 1) {
          LOAD_BIT(a1, p1, x);
          if (x != 1) {
            STORE_BIT(a2, p2 + *idx2, x);
          }
        }
        p1 += s1;
        idx2++;
      }
    }
  } else if (s2) {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a2, p2, y);
        if (y == 1) {
          LOAD_BIT(a1, p1 + *idx1, x);
          if (x != 1) {
            STORE_BIT(a2, p2, x);
          }
        }
        idx1++;
        p2 += s2;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a2, p2, y);
        if (y == 1) {
          LOAD_BIT(a1, p1, x);
          if (x != 1) {
            STORE_BIT(a2, p2, x);
          }
        }
        p1 += s1;
        p2 += s2;
      }
    }
  } else {
    LOAD_BIT(a2, p2, x);
    if (x != 1) {
      return;
    }
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, y);
        if (y != 1) {
          STORE_BIT(a2, p2, y);
          return;
        }
        idx1++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, y);
        if (y != 1) {
          STORE_BIT(a2, p2, y);
          return;
        }
        p1 += s1;
      }
    }
  }
}

/*
  Return true if all of bits are one (true).
  If argument is supplied, return Bit-array reduced along the axes.
  @overload all?(axis:nil, keepdims:false)
    @param [Integer,Array,Range] axis (keyword) axes to be reduced.
    @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in the result array
    as dimensions with size one.
    @return [Numo::Bit] .
*/
static VALUE bit_all_p(int argc, VALUE* argv, VALUE self) {
  VALUE v, reduce;
  narray_t* na;
  ndfunc_arg_in_t ain[3] = { { cT, 0 }, { sym_reduce, 0 }, { sym_init, 0 } };
  ndfunc_arg_out_t aout[1] = { { numo_cBit, 0 } };
  ndfunc_t ndf = { iter_bit_all_p, FULL_LOOP_NIP, 3, 1, ain, aout };

  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    return Qfalse;
  }
  reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);
  v = na_ndloop(&ndf, 3, self, reduce, INT2FIX(1));
  if (argc > 0) {
    return v;
  }
  v = bit_extract(v);
  switch (v) {
  case INT2FIX(0):
    return Qfalse;
  case INT2FIX(1):
    return Qtrue;
  default:
    rb_bug("unexpected result");
    return v;
  }
}

static void iter_bit_any_p(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT *a1, *a2;
  size_t p1, p2;
  ssize_t s1, s2;
  size_t *idx1, *idx2;
  BIT_DIGIT x = 0, y = 0;

  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a1, p1, s1, idx1);
  INIT_PTR_BIT_IDX(lp, 1, a2, p2, s2, idx2);
  if (idx2) {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a2, p2 + *idx2, y);
        if (y == 0) {
          LOAD_BIT(a1, p1 + *idx1, x);
          if (x != 0) {
            STORE_BIT(a2, p2 + *idx2, x);
          }
        }
        idx1++;
        idx2++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a2, p2 + *idx2, y);
        if (y == 0) {
          LOAD_BIT(a1, p1, x);
          if (x != 0) {
            STORE_BIT(a2, p2 + *idx2, x);
          }
        }
        p1 += s1;
        idx2++;
      }
    }
  } else if (s2) {
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a2, p2, y);
        if (y == 0) {
          LOAD_BIT(a1, p1 + *idx1, x);
          if (x != 0) {
            STORE_BIT(a2, p2, x);
          }
        }
        idx1++;
        p2 += s2;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a2, p2, y);
        if (y == 0) {
          LOAD_BIT(a1, p1, x);
          if (x != 0) {
            STORE_BIT(a2, p2, x);
          }
        }
        p1 += s1;
        p2 += s2;
      }
    }
  } else {
    LOAD_BIT(a2, p2, x);
    if (x != 0) {
      return;
    }
    if (idx1) {
      for (; i--;) {
        LOAD_BIT(a1, p1 + *idx1, y);
        if (y != 0) {
          STORE_BIT(a2, p2, y);
          return;
        }
        idx1++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a1, p1, y);
        if (y != 0) {
          STORE_BIT(a2, p2, y);
          return;
        }
        p1 += s1;
      }
    }
  }
}

/*

  Return true if any of bits is one (true).
  If argument is supplied, return Bit-array reduced along the axes.
  @overload any?(axis:nil, keepdims:false)
    @param [Integer,Array,Range] axis (keyword) axes to be reduced.
    @param [TrueClass] keepdims (keyword) If true, the reduced axes are left in the result array
    as dimensions with size one.
    @return [Numo::Bit] .
*/
static VALUE bit_any_p(int argc, VALUE* argv, VALUE self) {
  VALUE v, reduce;
  narray_t* na;
  ndfunc_arg_in_t ain[3] = { { cT, 0 }, { sym_reduce, 0 }, { sym_init, 0 } };
  ndfunc_arg_out_t aout[1] = { { numo_cBit, 0 } };
  ndfunc_t ndf = { iter_bit_any_p, FULL_LOOP_NIP, 3, 1, ain, aout };

  GetNArray(self, na);
  if (NA_SIZE(na) == 0) {
    return Qfalse;
  }
  reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);
  v = na_ndloop(&ndf, 3, self, reduce, INT2FIX(0));
  if (argc > 0) {
    return v;
  }
  v = bit_extract(v);
  switch (v) {
  case INT2FIX(0):
    return Qfalse;
  case INT2FIX(1):
    return Qtrue;
  default:
    rb_bug("unexpected result");
    return v;
  }
}

static VALUE bit_none_p(int argc, VALUE* argv, VALUE self) {
  VALUE v;

  v = bit_any_p(argc, argv, self);

  if (v == Qtrue) {
    return Qfalse;
  } else if (v == Qfalse) {
    return Qtrue;
  }
  return bit_not(v);
}

typedef struct {
  size_t count;
  char* idx0;
  char* idx1;
  size_t elmsz;
} where_opt_t;

#define STORE_INT(ptr, esz, x) memcpy(ptr, &(x), esz)

static void iter_bit_where(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT* a;
  size_t p;
  ssize_t s;
  size_t* idx;
  BIT_DIGIT x = 0;
  char* idx1;
  size_t count;
  size_t e;
  where_opt_t* g;

  g = (where_opt_t*)(lp->opt_ptr);
  count = g->count;
  idx1 = g->idx1;
  e = g->elmsz;
  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a, p, s, idx);
  if (idx) {
    for (; i--;) {
      LOAD_BIT(a, p + *idx, x);
      idx++;
      if (x != 0) {
        STORE_INT(idx1, e, count);
        idx1 += e;
      }
      count++;
    }
  } else {
    for (; i--;) {
      LOAD_BIT(a, p, x);
      p += s;
      if (x != 0) {
        STORE_INT(idx1, e, count);
        idx1 += e;
      }
      count++;
    }
  }
  g->count = count;
  g->idx1 = idx1;
}

/*
  Returns the array of index where the bit is one (true).
  @overload where
    @return [Numo::Int32,Numo::Int64]
*/
static VALUE bit_where(VALUE self) {
  volatile VALUE idx_1;
  size_t size, n_1;
  where_opt_t* g;

  ndfunc_arg_in_t ain[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_where, FULL_LOOP, 1, 0, ain, 0 };

  size = RNARRAY_SIZE(self);
  n_1 = NUM2SIZET(bit_count_true(0, NULL, self));
  g = ALLOCA_N(where_opt_t, 1);
  g->count = 0;
  if (size > 4294967295ul) {
    idx_1 = nary_new(numo_cInt64, 1, &n_1);
    g->elmsz = 8;
  } else {
    idx_1 = nary_new(numo_cInt32, 1, &n_1);
    g->elmsz = 4;
  }
  g->idx1 = na_get_pointer_for_write(idx_1);
  g->idx0 = NULL;
  na_ndloop3(&ndf, g, 1, self);
  na_release_lock(idx_1);
  return idx_1;
}

static void iter_bit_where2(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT* a;
  size_t p;
  ssize_t s;
  size_t* idx;
  BIT_DIGIT x = 0;
  char *idx0, *idx1;
  size_t count;
  size_t e;
  where_opt_t* g;

  g = (where_opt_t*)(lp->opt_ptr);
  count = g->count;
  idx0 = g->idx0;
  idx1 = g->idx1;
  e = g->elmsz;
  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a, p, s, idx);
  if (idx) {
    for (; i--;) {
      LOAD_BIT(a, p + *idx, x);
      idx++;
      if (x == 0) {
        STORE_INT(idx0, e, count);
        idx0 += e;
      } else {
        STORE_INT(idx1, e, count);
        idx1 += e;
      }
      count++;
    }
  } else {
    for (; i--;) {
      LOAD_BIT(a, p, x);
      p += s;
      if (x == 0) {
        STORE_INT(idx0, e, count);
        idx0 += e;
      } else {
        STORE_INT(idx1, e, count);
        idx1 += e;
      }
      count++;
    }
  }
  g->count = count;
  g->idx0 = idx0;
  g->idx1 = idx1;
}

/*
  Returns two index arrays.
  The first array contains index where the bit is one (true).
  The second array contains index where the bit is zero (false).
  @overload where2
    @return [Numo::Int32,Numo::Int64]*2
*/
static VALUE bit_where2(VALUE self) {
  VALUE idx_1, idx_0;
  size_t size, n_1, n_0;
  where_opt_t* g;

  ndfunc_arg_in_t ain[1] = { { cT, 0 } };
  ndfunc_t ndf = { iter_bit_where2, FULL_LOOP, 1, 0, ain, 0 };

  size = RNARRAY_SIZE(self);
  n_1 = NUM2SIZET(bit_count_true(0, NULL, self));
  n_0 = size - n_1;
  g = ALLOCA_N(where_opt_t, 1);
  g->count = 0;
  if (size > 4294967295ul) {
    idx_1 = nary_new(numo_cInt64, 1, &n_1);
    idx_0 = nary_new(numo_cInt64, 1, &n_0);
    g->elmsz = 8;
  } else {
    idx_1 = nary_new(numo_cInt32, 1, &n_1);
    idx_0 = nary_new(numo_cInt32, 1, &n_0);
    g->elmsz = 4;
  }
  g->idx1 = na_get_pointer_for_write(idx_1);
  g->idx0 = na_get_pointer_for_write(idx_0);
  na_ndloop3(&ndf, g, 1, self);
  na_release_lock(idx_0);
  na_release_lock(idx_1);
  return rb_assoc_new(idx_1, idx_0);
}

static void iter_bit_mask(na_loop_t* const lp) {
  size_t i;
  BIT_DIGIT* a;
  size_t p1, p2;
  ssize_t s1, s2;
  size_t *idx1, *idx2, *pidx;
  BIT_DIGIT x = 0;
  size_t count;
  where_opt_t* g;

  g = (where_opt_t*)(lp->opt_ptr);
  count = g->count;
  pidx = (size_t*)(g->idx1);
  INIT_COUNTER(lp, i);
  INIT_PTR_BIT_IDX(lp, 0, a, p1, s1, idx1);
  // INIT_PTR_IDX(lp, 1, p2, s2, idx2);
  p2 = lp->args[1].iter[0].pos;
  s2 = lp->args[1].iter[0].step;
  idx2 = lp->args[1].iter[0].idx;

  if (idx1) {
    if (idx2) {
      for (; i--;) {
        LOAD_BIT(a, p1 + *idx1, x);
        idx1++;
        if (x) {
          *(pidx++) = p2 + *idx2;
          count++;
        }
        idx2++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a, p1 + *idx1, x);
        idx1++;
        if (x) {
          *(pidx++) = p2;
          count++;
        }
        p2 += s2;
      }
    }
  } else {
    if (idx2) {
      for (; i--;) {
        LOAD_BIT(a, p1, x);
        p1 += s1;
        if (x) {
          *(pidx++) = p2 + *idx2;
          count++;
        }
        idx2++;
      }
    } else {
      for (; i--;) {
        LOAD_BIT(a, p1, x);
        p1 += s1;
        if (x) {
          *(pidx++) = p2;
          count++;
        }
        p2 += s2;
      }
    }
  }
  g->count = count;
  g->idx1 = (char*)pidx;
}

#if SIZEOF_VOIDP == 8
#define cIndex numo_cInt64
#elif SIZEOF_VOIDP == 4
#define cIndex numo_cInt32
#endif

static void shape_error(void) {
  rb_raise(nary_eShapeError, "mask and masked arrays must have the same shape");
}

/*
  Return subarray of argument masked with self bit array.
  @overload mask(array)
    @param [Numo::NArray] array  narray to be masked.
    @return [Numo::NArray]  view of masked array.
*/
static VALUE bit_mask(VALUE mask, VALUE val) {
  int i;
  VALUE idx_1, view;
  narray_data_t* nidx;
  narray_view_t *nv, *nv_val;
  narray_t *na, *na_mask;
  stridx_t stridx0;
  size_t n_1;
  where_opt_t g;
  ndfunc_arg_in_t ain[2] = { { cT, 0 }, { Qnil, 0 } };
  ndfunc_t ndf = { iter_bit_mask, FULL_LOOP, 2, 0, ain, 0 };

  // cast val to NArray
  if (!rb_obj_is_kind_of(val, numo_cNArray)) {
    val = rb_funcall(numo_cNArray, id_cast, 1, val);
  }
  // shapes of mask and val must be same
  GetNArray(val, na);
  GetNArray(mask, na_mask);
  if (na_mask->ndim != na->ndim) {
    shape_error();
  }
  for (i = 0; i < na->ndim; i++) {
    if (na_mask->shape[i] != na->shape[i]) {
      shape_error();
    }
  }

  n_1 = NUM2SIZET(bit_count_true(0, NULL, mask));
  idx_1 = nary_new(cIndex, 1, &n_1);
  g.count = 0;
  g.elmsz = SIZEOF_VOIDP;
  g.idx1 = na_get_pointer_for_write(idx_1);
  g.idx0 = NULL;
  na_ndloop3(&ndf, &g, 2, mask, val);

  view = na_s_allocate_view(rb_obj_class(val));
  GetNArrayView(view, nv);
  na_setup_shape((narray_t*)nv, 1, &n_1);

  GetNArrayData(idx_1, nidx);
  SDX_SET_INDEX(stridx0, (size_t*)nidx->ptr);
  nidx->ptr = NULL;
  RB_GC_GUARD(idx_1);

  nv->stridx = ALLOC_N(stridx_t, 1);
  nv->stridx[0] = stridx0;
  nv->offset = 0;

  switch (NA_TYPE(na)) {
  case NARRAY_DATA_T:
    nv->data = val;
    break;
  case NARRAY_VIEW_T:
    GetNArrayView(val, nv_val);
    nv->data = nv_val->data;
    break;
  default:
    rb_raise(rb_eRuntimeError, "invalid NA_TYPE: %d", NA_TYPE(na));
  }

  return view;
}

void Init_numo_bit(void) {
  VALUE hCast, mNumo;

  mNumo = rb_define_module("Numo");

  id_cast = rb_intern("cast");
  id_divmod = rb_intern("divmod");
  id_eq = rb_intern("eq");
  id_mulsum = rb_intern("mulsum");
  id_ne = rb_intern("ne");
  id_to_a = rb_intern("to_a");

  /**
   * Document-class: Numo::Bit
   *
   * Binary digit (bit) N-dimensional array class.
   */
  cT = rb_define_class_under(mNumo, "Bit", cNArray);

  hCast = rb_hash_new();
  /* Upcasting rules of Bit. */
  rb_define_const(cT, "UPCAST", hCast);
  rb_hash_aset(hCast, rb_cArray, cT);

  rb_hash_aset(hCast, rb_cInteger, cT);
  rb_hash_aset(hCast, rb_cFloat, numo_cDFloat);
  rb_hash_aset(hCast, rb_cComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cRObject, numo_cRObject);
  rb_hash_aset(hCast, numo_cDComplex, numo_cDComplex);
  rb_hash_aset(hCast, numo_cSComplex, numo_cSComplex);
  rb_hash_aset(hCast, numo_cDFloat, numo_cDFloat);
  rb_hash_aset(hCast, numo_cSFloat, numo_cSFloat);
  rb_hash_aset(hCast, numo_cInt64, numo_cInt64);
  rb_hash_aset(hCast, numo_cInt32, numo_cInt32);
  rb_hash_aset(hCast, numo_cInt16, numo_cInt16);
  rb_hash_aset(hCast, numo_cInt8, numo_cInt8);
  rb_hash_aset(hCast, numo_cUInt64, numo_cUInt64);
  rb_hash_aset(hCast, numo_cUInt32, numo_cUInt32);
  rb_hash_aset(hCast, numo_cUInt16, numo_cUInt16);
  rb_hash_aset(hCast, numo_cUInt8, numo_cUInt8);
  rb_obj_freeze(hCast);

  /* Element size of Bit in bits. */
  rb_define_const(cT, "ELEMENT_BIT_SIZE", INT2FIX(1));
  /* Element size of Bit in bytes. */
  rb_define_const(cT, "ELEMENT_BYTE_SIZE", rb_float_new(1.0 / 8));
  /* Stride size of contiguous Bit array. */
  rb_define_const(cT, "CONTIGUOUS_STRIDE", INT2FIX(1));
  rb_define_alloc_func(cT, bit_s_alloc_func);
  rb_define_method(cT, "allocate", bit_allocate, 0);
  /**
   * Extract an element only if self is a dimensionless NArray.
   * @overload extract
   *   @return [Numeric,Numo::NArray]
   *   --- Extract element value as Ruby Object if self is a dimensionless NArray,
   *   otherwise returns self.
   */
  rb_define_method(cT, "extract", bit_extract, 0);

  rb_define_method(cT, "store", bit_store, 1);

  rb_define_singleton_method(cT, "cast", bit_s_cast, 1);
  /**
   * Multi-dimensional element reference.
   * @overload [](dim0,...,dimL)
   *   @param [Numeric,Range,Array,Numo::Int32,Numo::Int64,Numo::Bit,TrueClass,FalseClass,
   *     Symbol]
   *   dim0,...,dimL  multi-dimensional indices.
   *   @return [Numeric,Numo::Bit] an element or NArray view.
   * @see Numo::NArray#[]
   * @see #[]=
   *
   * @example
   *     a = Numo::Int32.new(3,4).seq
   *     # => Numo::Int32#shape=[3,4]
   *     # [[0, 1, 2, 3],
   *     #  [4, 5, 6, 7],
   *     #  [8, 9, 10, 11]]
   *
   *     b = (a%2).eq(0)
   *     # => Numo::Bit#shape=[3,4]
   *     # [[1, 0, 1, 0],
   *     #  [1, 0, 1, 0],
   *     #  [1, 0, 1, 0]]
   *
   *     b[true,(0..-1)%2]
   *     # => Numo::Bit(view)#shape=[3,2]
   *     # [[1, 1],
   *     #  [1, 1],
   *     #  [1, 1]]
   *
   *     b[1,1]
   *     # => 0
   */
  rb_define_method(cT, "[]", bit_aref, -1);
  rb_define_method(cT, "[]=", bit_aset, -1);
  /**
   * return NArray with cast to the type of self.
   * @overload coerce_cast(type)
   *   @return [nil]
   */
  rb_define_method(cT, "coerce_cast", bit_coerce_cast, 1);
  /**
   * Convert self to Array.
   * @overload to_a
   *   @return [Array]
   */
  rb_define_method(cT, "to_a", bit_to_a, 0);
  /**
   * Fill elements with other.
   * @overload fill other
   *   @param [Numeric] other
   *   @return [Numo::Bit] self.
   */
  rb_define_method(cT, "fill", bit_fill, 1);
  /**
   * Format elements into strings.
   * @overload format format
   *   @param [String] format
   *   @return [Numo::RObject] array of formatted strings.
   */
  rb_define_method(cT, "format", bit_format, -1);
  /**
   * Format elements into strings.
   * @overload format_to_a format
   *   @param [String] format
   *   @return [Array] array of formatted strings.
   */
  rb_define_method(cT, "format_to_a", bit_format_to_a, -1);
  /**
   * Returns a string containing a human-readable representation of NArray.
   * @overload inspect
   *   @return [String]
   */
  rb_define_method(cT, "inspect", bit_inspect, 0);
  /**
   * Calls the given block once for each element in self,
   * passing that element as a parameter.
   * @overload each
   *   @return [Numo::NArray] self
   *   For a block {|x| ... }
   *   @yield [x]  x is element of NArray.
   */
  rb_define_method(cT, "each", bit_each, 0);
  /**
   * Invokes the given block once for each element of self,
   * passing that element and indices along each axis as parameters.
   * @overload each_with_index
   *   @return [Numo::NArray] self
   *   For a block {|x,i,j,...| ... }
   *   @yield [x,i,j,...]  x is an element, i,j,... are multidimensional indices.
   */
  rb_define_method(cT, "each_with_index", bit_each_with_index, 0);
  rb_define_method(cT, "copy", bit_copy, 0);
  rb_define_method(cT, "~", bit_not, 0);
  rb_define_method(cT, "&", bit_and, 1);
  rb_define_method(cT, "|", bit_or, 1);
  rb_define_method(cT, "^", bit_xor, 1);
  rb_define_method(cT, "eq", bit_eq, 1);
  rb_define_method(cT, "count_true", bit_count_true, -1);
  rb_define_alias(cT, "count_1", "count_true");
  rb_define_alias(cT, "count", "count_true");
  rb_define_method(cT, "count_false", bit_count_false, -1);
  rb_define_alias(cT, "count_0", "count_false");
  rb_define_method(cT, "all?", bit_all_p, -1);
  rb_define_method(cT, "any?", bit_any_p, -1);
  rb_define_method(cT, "none?", bit_none_p, -1);
  rb_define_method(cT, "where", bit_where, 0);
  rb_define_method(cT, "where2", bit_where2, 0);
  rb_define_method(cT, "mask", bit_mask, 1);
  rb_define_singleton_method(cT, "[]", bit_s_cast, -2);
  /**
   * mean of self.
   * @overload mean(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs mean along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of mean.
   */
  rb_define_method(cT, "mean", bit_mean, -1);
  /**
   * var of self.
   * @overload var(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs var along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of var.
   */
  rb_define_method(cT, "var", bit_var, -1);
  /**
   * stddev of self.
   * @overload stddev(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs stddev along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of stddev.
   */
  rb_define_method(cT, "stddev", bit_stddev, -1);
  /**
   * rms of self.
   * @overload rms(axis: nil, keepdims: false, nan: false)
   *   @param axis [Numeric, Array, Range] Performs rms along the axis.
   *   @param keepdims [Boolean] If true, the reduced axes are left in the result array as
   *     dimensions with size one.
   *   @param nan [Boolean] If true, apply NaN-aware algorithm
   *     (avoid NaN for sum/mean etc, or, return NaN for min/max etc).
   *   @return [Numo::DFloat] returns result of rms.
   */
  rb_define_method(cT, "rms", bit_rms, -1);
}
