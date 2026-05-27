#ifndef NUMO_NARRAY_MH_SORT_H
#define NUMO_NARRAY_MH_SORT_H 1

/**
 * qsort.c
 * Ruby/Numo::NArray - Numerical Array class for Ruby
 *   modified by Masahiro TANAKA
 */

/**
 *      qsort.c: standard quicksort algorithm
 *
 *      Modifications from vanilla NetBSD source:
 *        Add do ... while() macro fix
 *        Remove __inline, _DIAGASSERTs, __P
 *        Remove ill-considered "swap_cnt" switch to insertion sort,
 *        in favor of a simple check for presorted input.
 *
 *      CAUTION: if you change this file, see also qsort_arg.c
 *
 *      $PostgreSQL: pgsql/src/port/qsort.c,v 1.12 2006/10/19 20:56:22 tgl Exp $
 */

/**
 * Copyright (c) 1992, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *        notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *        notice, this list of conditions and the following disclaimer in the
 *        documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *        may be used to endorse or promote products derived from this software
 *        without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.      IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef QSORT_INCL
#define QSORT_INCL
#define Min(x, y) ((x) < (y) ? (x) : (y))

/**
 * Qsort routine based on J. L. Bentley and M. D. McIlroy,
 * "Engineering a sort function",
 * Software--Practice and Experience 23 (1993) 1249-1265.
 * We have modified their original by adding a check for already-sorted input,
 * which seems to be a win per discussions on pgsql-hackers around 2006-03-21.
 */
#define swapcode(TYPE, parmi, parmj, n)                                                        \
  do {                                                                                         \
    size_t i = (n) / sizeof(TYPE);                                                             \
    TYPE* pi = (TYPE*)(void*)(parmi);                                                          \
    TYPE* pj = (TYPE*)(void*)(parmj);                                                          \
    do {                                                                                       \
      TYPE t = *pi;                                                                            \
      *pi++ = *pj;                                                                             \
      *pj++ = t;                                                                               \
    } while (--i > 0);                                                                         \
  } while (0)

#ifdef HAVE_STDINT_H
#define SWAPINIT(a, es)                                                                        \
  swaptype = (uintptr_t)(a) % sizeof(long) || (es) % sizeof(long) ? 2                          \
             : (es) == sizeof(long)                               ? 0                          \
                                                                  : 1;
#else
#define SWAPINIT(a, es)                                                                        \
  swaptype = ((char*)(a) - (char*)0) % sizeof(long) || (es) % sizeof(long) ? 2                 \
             : (es) == sizeof(long)                                        ? 0                 \
                                                                           : 1;
#endif

static inline void swapfunc(char* a, char* b, size_t n, int swaptype) {
  if (swaptype <= 1)
    swapcode(long, a, b, n);
  else
    swapcode(char, a, b, n);
}

#define swap(a, b)                                                                             \
  if (swaptype == 0) {                                                                         \
    long t = *(long*)(void*)(a);                                                               \
    *(long*)(void*)(a) = *(long*)(void*)(b);                                                   \
    *(long*)(void*)(b) = t;                                                                    \
  } else                                                                                       \
    swapfunc(a, b, es, swaptype)

#define vecswap(a, b, n)                                                                       \
  if ((n) > 0) swapfunc((a), (b), (size_t)(n), swaptype)

#define med3(a, b, c, _cmpgt)                                                                  \
  (_cmpgt(b, a) ? (_cmpgt(c, b) ? b : (_cmpgt(c, a) ? c : a))                                  \
                : (_cmpgt(b, c) ? b : (_cmpgt(c, a) ? a : c)))
#endif

#define DEF_TYPED_QSORT_FUNC(tDType, fQsort, fCmp, fCmpGt)                                     \
  static void tDType##_##fQsort(void* a, size_t n, ssize_t es) {                               \
    char *pa, *pb, *pc, *pd, *pl, *pm, *pn;                                                    \
    int d, r, swaptype, presorted;                                                             \
                                                                                               \
  loop:                                                                                        \
    SWAPINIT(a, es);                                                                           \
    if (n < 7) {                                                                               \
      for (pm = (char*)a + es; pm < (char*)a + n * es; pm += es)                               \
        for (pl = pm; pl > (char*)a && fCmpGt(pl - es, pl); pl -= es) swap(pl, pl - es);       \
      return;                                                                                  \
    }                                                                                          \
    presorted = 1;                                                                             \
    for (pm = (char*)a + es; pm < (char*)a + n * es; pm += es) {                               \
      if (fCmpGt(pm - es, pm)) {                                                               \
        presorted = 0;                                                                         \
        break;                                                                                 \
      }                                                                                        \
    }                                                                                          \
    if (presorted) return;                                                                     \
    pm = (char*)a + (n / 2) * es;                                                              \
    if (n > 7) {                                                                               \
      pl = (char*)a;                                                                           \
      pn = (char*)a + (n - 1) * es;                                                            \
      if (n > 40) {                                                                            \
        d = (int)((n / 8) * es);                                                               \
        pl = med3(pl, pl + d, pl + 2 * d, fCmpGt);                                             \
        pm = med3(pm - d, pm, pm + d, fCmpGt);                                                 \
        pn = med3(pn - 2 * d, pn - d, pn, fCmpGt);                                             \
      }                                                                                        \
      pm = med3(pl, pm, pn, fCmpGt);                                                           \
    }                                                                                          \
    swap(a, pm);                                                                               \
    for (pa = pb = (char*)a + es, pc = pd = (char*)a + (n - 1) * es; pb <= pc;                 \
         pb += es, pc -= es) {                                                                 \
      while (pb <= pc && (r = fCmp(pb, a)) <= 0) {                                             \
        if (r == 0) {                                                                          \
          swap(pa, pb);                                                                        \
          pa += es;                                                                            \
        }                                                                                      \
        pb += es;                                                                              \
      }                                                                                        \
      while (pb <= pc && (r = fCmp(pc, a)) >= 0) {                                             \
        if (r == 0) {                                                                          \
          swap(pc, pd);                                                                        \
          pd -= es;                                                                            \
        }                                                                                      \
        pc -= es;                                                                              \
      }                                                                                        \
      if (pb > pc) break;                                                                      \
      swap(pb, pc);                                                                            \
    }                                                                                          \
    pn = (char*)a + n * es;                                                                    \
    r = (int)Min(pa - (char*)a, pb - pa);                                                      \
    vecswap(a, pb - r, r);                                                                     \
    r = (int)Min(pd - pc, pn - pd - es);                                                       \
    vecswap(pb, pn - r, r);                                                                    \
    if ((r = (int)(pb - pa)) > es) tDType##_##fQsort(a, r / es, es);                           \
    if ((r = (int)(pd - pc)) > es) {                                                           \
      a = pn - r;                                                                              \
      n = r / es;                                                                              \
      goto loop;                                                                               \
    }                                                                                          \
  }

#define DEF_NARRAY_INT_SORT_METHOD_FUNC(tDType)                                                \
  DEF_TYPED_QSORT_FUNC(tDType, qsort, cmp, cmpgt)                                              \
                                                                                               \
  static void iter_##tDType##_sort(na_loop_t* const lp) {                                      \
    size_t n;                                                                                  \
    char* ptr;                                                                                 \
    ssize_t step;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, ptr, step);                                                                \
    tDType##_qsort(ptr, n, step);                                                              \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_sort(int argc, VALUE* argv, VALUE self) {                              \
    if (!TEST_INPLACE(self)) {                                                                 \
      self = na_copy(self);                                                                    \
    }                                                                                          \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_reduce, 0 } };                          \
    ndfunc_t ndf = { iter_##tDType##_sort, NDF_HAS_LOOP | NDF_FLAT_REDUCE, 2, 0, ain, 0 };     \
    VALUE reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                         \
    na_ndloop(&ndf, 2, self, reduce);                                                          \
    return self;                                                                               \
  }

#define DEF_NARRAY_FLT_SORT_METHOD_FUNC(tDType)                                                \
  DEF_TYPED_QSORT_FUNC(tDType, qsort_prnan, cmp_prnan, cmpgt_prnan)                            \
                                                                                               \
  static void iter_##tDType##_sort_prnan(na_loop_t* const lp) {                                \
    size_t n;                                                                                  \
    char* ptr;                                                                                 \
    ssize_t step;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, ptr, step);                                                                \
    tDType##_qsort_prnan(ptr, n, step);                                                        \
  }                                                                                            \
                                                                                               \
  DEF_TYPED_QSORT_FUNC(tDType, qsort_ignan, cmp_ignan, cmpgt_ignan)                            \
                                                                                               \
  static void iter_##tDType##_sort_ignan(na_loop_t* const lp) {                                \
    size_t n;                                                                                  \
    char* ptr;                                                                                 \
    ssize_t step;                                                                              \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, ptr, step);                                                                \
    tDType##_qsort_ignan(ptr, n, step);                                                        \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_sort(int argc, VALUE* argv, VALUE self) {                              \
    if (!TEST_INPLACE(self)) {                                                                 \
      self = na_copy(self);                                                                    \
    }                                                                                          \
    ndfunc_arg_in_t ain[2] = { { OVERWRITE, 0 }, { sym_reduce, 0 } };                          \
    ndfunc_t ndf = {                                                                           \
      iter_##tDType##_sort_ignan, NDF_HAS_LOOP | NDF_FLAT_REDUCE, 2, 0, ain, 0                 \
    };                                                                                         \
    VALUE reduce =                                                                             \
      na_reduce_dimension(argc, argv, 1, &self, &ndf, iter_##tDType##_sort_prnan);             \
    na_ndloop(&ndf, 2, self, reduce);                                                          \
    return self;                                                                               \
  }

#define DEF_NARRAY_INT_SORT_INDEX_METHOD_FUNC(tDType, tNAryClass)                              \
  DEF_TYPED_QSORT_FUNC(tDType, index_qsort, cmp, cmpgt)                                        \
                                                                                               \
  static void tDType##_index64_qsort(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort(ptr, n, sizeof(tDType*));                                             \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void tDType##_index32_qsort(na_loop_t* const lp) {                                    \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort(ptr, n, sizeof(tDType*));                                             \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_sort_index(int argc, VALUE* argv, VALUE self) {                        \
    narray_t* na;                                                                              \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
    ndfunc_arg_in_t ain[3] = { { tNAryClass, 0 }, { 0, 0 }, { sym_reduce, 0 } };               \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_CUM, 3, 1, ain, aout };        \
    VALUE idx;                                                                                 \
    VALUE reduce;                                                                              \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      ain[1].type = numo_cInt64;                                                               \
      aout[0].type = numo_cInt64;                                                              \
      idx = nary_new(numo_cInt64, na->ndim, na->shape);                                        \
      ndf.func = tDType##_index64_qsort;                                                       \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    } else {                                                                                   \
      ain[1].type = numo_cInt32;                                                               \
      aout[0].type = numo_cInt32;                                                              \
      idx = nary_new(numo_cInt32, na->ndim, na->shape);                                        \
      ndf.func = tDType##_index32_qsort;                                                       \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, 0);                             \
    }                                                                                          \
    rb_funcall(idx, rb_intern("seq"), 0);                                                      \
    size_t size = na->size * sizeof(void*);                                                    \
    VALUE tmp;                                                                                 \
    char* buf = rb_alloc_tmp_buffer(&tmp, size);                                               \
    VALUE res = na_ndloop3(&ndf, buf, 3, self, idx, reduce);                                   \
    rb_free_tmp_buffer(&tmp);                                                                  \
    return res;                                                                                \
  }

#define DEF_NARRAY_FLT_SORT_INDEX_METHOD_FUNC(tDType, tNAryClass)                              \
  DEF_TYPED_QSORT_FUNC(tDType, index_qsort_ignan, cmp_ignan, cmpgt_ignan)                      \
                                                                                               \
  static void tDType##_index64_qsort_ignan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort_ignan(ptr, n, sizeof(tDType*));                                       \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void tDType##_index32_qsort_ignan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort_ignan(ptr, n, sizeof(tDType*));                                       \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  DEF_TYPED_QSORT_FUNC(tDType, index_qsort_prnan, cmp_prnan, cmpgt_prnan)                      \
                                                                                               \
  static void tDType##_index64_qsort_prnan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort_prnan(ptr, n, sizeof(tDType*));                                       \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int64_t*)o_ptr = *(int64_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static void tDType##_index32_qsort_prnan(na_loop_t* const lp) {                              \
    size_t n;                                                                                  \
    char* d_ptr;                                                                               \
    char* i_ptr;                                                                               \
    char* o_ptr;                                                                               \
    ssize_t d_step;                                                                            \
    ssize_t i_step;                                                                            \
    ssize_t o_step;                                                                            \
    INIT_COUNTER(lp, n);                                                                       \
    INIT_PTR(lp, 0, d_ptr, d_step);                                                            \
    INIT_PTR(lp, 1, i_ptr, i_step);                                                            \
    INIT_PTR(lp, 2, o_ptr, o_step);                                                            \
    if (n == 1) {                                                                              \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr);                                                   \
      return;                                                                                  \
    }                                                                                          \
    char** ptr = (char**)(lp->opt_ptr);                                                        \
    for (size_t i = 0; i < n; i++) {                                                           \
      ptr[i] = d_ptr + d_step * i;                                                             \
    }                                                                                          \
    tDType##_index_qsort_prnan(ptr, n, sizeof(tDType*));                                       \
    size_t idx;                                                                                \
    for (size_t i = 0; i < n; i++) {                                                           \
      idx = (ptr[i] - d_ptr) / d_step;                                                         \
      *(int32_t*)o_ptr = *(int32_t*)(i_ptr + i_step * idx);                                    \
      o_ptr += o_step;                                                                         \
    }                                                                                          \
  }                                                                                            \
                                                                                               \
  static VALUE tDType##_sort_index(int argc, VALUE* argv, VALUE self) {                        \
    narray_t* na;                                                                              \
    GetNArray(self, na);                                                                       \
    if (na->ndim == 0) {                                                                       \
      return INT2FIX(0);                                                                       \
    }                                                                                          \
    ndfunc_arg_in_t ain[3] = { { tNAryClass, 0 }, { 0, 0 }, { sym_reduce, 0 } };               \
    ndfunc_arg_out_t aout[1] = { { 0, 0, 0 } };                                                \
    ndfunc_t ndf = { 0, STRIDE_LOOP_NIP | NDF_FLAT_REDUCE | NDF_CUM, 3, 1, ain, aout };        \
    VALUE idx;                                                                                 \
    VALUE reduce;                                                                              \
    if (na->size > (~(u_int32_t)0)) {                                                          \
      ain[1].type = numo_cInt64;                                                               \
      aout[0].type = numo_cInt64;                                                              \
      idx = nary_new(numo_cInt64, na->ndim, na->shape);                                        \
      ndf.func = tDType##_index64_qsort_ignan;                                                 \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, tDType##_index64_qsort_prnan);  \
    } else {                                                                                   \
      ain[1].type = numo_cInt32;                                                               \
      aout[0].type = numo_cInt32;                                                              \
      idx = nary_new(numo_cInt32, na->ndim, na->shape);                                        \
      ndf.func = tDType##_index32_qsort_ignan;                                                 \
      reduce = na_reduce_dimension(argc, argv, 1, &self, &ndf, tDType##_index32_qsort_prnan);  \
    }                                                                                          \
    rb_funcall(idx, rb_intern("seq"), 0);                                                      \
    size_t size = na->size * sizeof(void*);                                                    \
    VALUE tmp;                                                                                 \
    char* buf = rb_alloc_tmp_buffer(&tmp, size);                                               \
    VALUE res = na_ndloop3(&ndf, buf, 3, self, idx, reduce);                                   \
    rb_free_tmp_buffer(&tmp);                                                                  \
    return res;                                                                                \
  }

#endif /* NUMO_NARRAY_MH_SORT_H */
