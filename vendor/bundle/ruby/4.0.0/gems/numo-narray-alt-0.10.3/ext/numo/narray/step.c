/*
  step.c
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 2007-2020 Masahiro TANAKA
*/
#include <math.h>
#include <ruby.h>

#include "numo/narray.h"

#if defined(__FreeBSD__) && __FreeBSD__ < 4
#include <floatingpoint.h>
#endif

#ifdef HAVE_FLOAT_H
#include <float.h>
#endif

#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#ifndef DBL_EPSILON
#define DBL_EPSILON 2.2204460492503131e-16
#endif

#define EXCL(r) RTEST(rb_funcall((r), rb_intern("exclude_end?"), 0))

/*
 *  call-seq:
 *     step.parameters([array_size])    => [start,step,length]
 *
 *  Returns the iteration parameters of <i>step</i>.  If
 *  <i>array_sizse</i> is given, negative array index is considered.
 */

void nary_step_array_index(
  VALUE obj, size_t ary_size, size_t* plen, ssize_t* pbeg, ssize_t* pstep
) {
  size_t len;
  ssize_t beg = 0, step = 1;
  VALUE vbeg, vend, vstep, vlen;
  ssize_t end = ary_size;

  rb_arithmetic_sequence_components_t x;
  rb_arithmetic_sequence_extract(obj, &x);

  vstep = x.step;
  vbeg = x.begin;
  vend = x.end;
  vlen = rb_ivar_get(obj, rb_intern("length"));

  if (RTEST(vbeg)) {
    beg = NUM2SSIZET(vbeg);
    if (beg < 0) {
      beg += ary_size;
    }
  }
  if (RTEST(vend)) {
    end = NUM2SSIZET(vend);
    if (end < 0) {
      end += ary_size;
    }
  }

  // puts("pass 1");

  if (RTEST(vlen)) {
    len = NUM2SIZET(vlen);
    if (len > 0) {
      if (RTEST(vstep)) {
        step = NUM2SSIZET(step);
        if (RTEST(vbeg)) {
          if (RTEST(vend)) {
            rb_raise(rb_eStandardError, "verbose Step object");
          } else {
            end = beg + step * (len - 1);
          }
        } else {
          if (RTEST(vend)) {
            if (EXCL(obj)) {
              if (step > 0) end--;
              if (step < 0) end++;
            }
            beg = end - step * (len - 1);
          } else {
            beg = 0;
            end = step * (len - 1);
          }
        }
      } else { // no step
        step = 1;
        if (RTEST(vbeg)) {
          if (RTEST(vend)) {
            if (EXCL(obj)) {
              if (beg < end) end--;
              if (beg > end) end++;
            }
            if (len > 1) step = (end - beg) / (len - 1);
          } else {
            end = beg + (len - 1);
          }
        } else {
          if (RTEST(vend)) {
            if (EXCL(obj)) {
              end--;
            }
            beg = end - (len - 1);
          } else {
            beg = 0;
            end = len - 1;
          }
        }
      }
    }
  } else { // no len
    if (RTEST(vstep)) {
      step = NUM2SSIZET(vstep);
    } else {
      step = 1;
    }
    if (step > 0) {
      if (!RTEST(vbeg)) {
        beg = 0;
      }
      if (!RTEST(vend)) {
        end = ary_size - 1;
      } else if (EXCL(obj)) {
        end--;
      }
      if (beg <= end) {
        len = (end - beg) / step + 1;
      } else {
        len = 0;
      }
    } else if (step < 0) {
      if (!RTEST(vbeg)) {
        beg = ary_size - 1;
      }
      if (!RTEST(vend)) {
        end = 0;
      } else if (EXCL(obj)) {
        end++;
      }
      if (beg >= end) {
        len = (beg - end) / (-step) + 1;
      } else {
        len = 0;
      }
    } else {
      rb_raise(rb_eStandardError, "step must be non-zero");
    }
  }

  // puts("pass 2");

  if (beg < 0 || beg >= (ssize_t)ary_size || end < 0 || end >= (ssize_t)ary_size) {
    rb_raise(
      rb_eRangeError, "beg=%" SZF "d,end=%" SZF "d is out of array size (%" SZF "u)", beg, end,
      ary_size
    );
  }
  if (plen) *plen = len;
  if (pbeg) *pbeg = beg;
  if (pstep) *pstep = step;
}

void nary_step_sequence(VALUE obj, size_t* plen, double* pbeg, double* pstep) {
  VALUE vend, vstep, vlen;
  double dbeg, dend, dstep = 1, dsize, err;
  size_t size, n;

  rb_arithmetic_sequence_components_t x;
  rb_arithmetic_sequence_extract(obj, &x);

  vstep = x.step;
  dbeg = NUM2DBL(x.begin);
  vend = x.end;
  vlen = rb_ivar_get(obj, rb_intern("length"));

  if (RTEST(vlen)) {
    size = NUM2SIZET(vlen);

    if (!RTEST(vstep)) {
      if (RTEST(vend)) {
        dend = NUM2DBL(vend);
        if (EXCL(obj)) {
          n = size;
        } else {
          n = size - 1;
        }
        if (n > 0) {
          dstep = (dend - dbeg) / n;
        } else {
          dstep = 1;
        }
      } else {
        dstep = 1;
      }
    }
  } else {
    if (!RTEST(vstep)) {
      dstep = 1;
    } else {
      dstep = NUM2DBL(vstep);
    }
    if (RTEST(vend)) {
      dend = NUM2DBL(vend);
      err = (fabs(dbeg) + fabs(dend) + fabs(dend - dbeg)) / fabs(dstep) * DBL_EPSILON;
      if (err > 0.5) err = 0.5;
      dsize = (dend - dbeg) / dstep;
      if (EXCL(obj))
        dsize -= err;
      else
        dsize += err;
      dsize = floor(dsize) + 1;
      if (dsize < 0) dsize = 0;
      if (isinf(dsize) || isnan(dsize)) {
        rb_raise(rb_eArgError, "not finite size");
      }
      size = dsize;
    } else {
      rb_raise(rb_eArgError, "cannot determine length argument");
    }
  }

  if (plen) *plen = size;
  if (pbeg) *pbeg = dbeg;
  if (pstep) *pstep = dstep;
}
