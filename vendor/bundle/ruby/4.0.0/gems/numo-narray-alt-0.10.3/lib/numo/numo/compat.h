#ifndef COMPAT_H
#define COMPAT_H

#if !defined RSTRING_LEN
#define RSTRING_LEN(a) RSTRING(a)->len
#endif
#if !defined RSTRING_PTR
#define RSTRING_PTR(a) RSTRING(a)->ptr
#endif
#if !defined RARRAY_LEN
#define RARRAY_LEN(a) RARRAY(a)->len
#endif
#if !defined RARRAY_PTR
#define RARRAY_PTR(a) RARRAY(a)->ptr
#endif
#if !defined RARRAY_AREF
#define RARRAY_AREF(a, i) RARRAY_PTR(a)[i]
#endif
#if !defined RARRAY_ASET
#define RARRAY_ASET(a, i, v) (RARRAY_PTR(a)[i] = v)
#endif

#endif /* ifndef COMPAT_H */
