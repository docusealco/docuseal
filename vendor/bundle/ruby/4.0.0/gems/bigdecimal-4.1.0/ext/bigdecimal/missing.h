#ifndef MISSING_H
#define MISSING_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#ifndef RB_UNUSED_VAR
# if defined(_MSC_VER) && _MSC_VER >= 1911
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__has_cpp_attribute) && __has_cpp_attribute(maybe_unused)
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__has_c_attribute) && __has_c_attribute(maybe_unused)
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__GNUC__)
#  define RB_UNUSED_VAR(x) x __attribute__ ((unused))

# else
#  define RB_UNUSED_VAR(x) x
# endif
#endif /* RB_UNUSED_VAR */

#if defined(_MSC_VER) && _MSC_VER >= 1310
# define HAVE___ASSUME 1

#elif defined(__INTEL_COMPILER) && __INTEL_COMPILER >= 1300
# define HAVE___ASSUME 1
#endif

#ifndef UNREACHABLE
# if __has_builtin(__builtin_unreachable)
#  define UNREACHABLE __builtin_unreachable()

# elif defined(HAVE___ASSUME)
#  define UNREACHABLE __assume(0)

# else
#  define UNREACHABLE		/* unreachable */
# endif
#endif /* UNREACHABLE */

/* bool */

#ifndef __bool_true_false_are_defined
# include <stdbool.h>
#endif

/* dtoa */
char *BigDecimal_dtoa(double d_, int mode, int ndigits, int *decpt, int *sign, char **rve);

/* complex */

#ifndef HAVE_RB_COMPLEX_REAL
static inline VALUE
rb_complex_real_fallback(VALUE cmp)
{
#ifdef RCOMPLEX
  return RCOMPLEX(cmp)->real;
#else
  return rb_funcall(cmp, rb_intern("real"), 0);
#endif
}
#define rb_complex_real rb_complex_real_fallback
#endif

#ifndef HAVE_RB_COMPLEX_IMAG
static inline VALUE
rb_complex_imag_fallback(VALUE cmp)
{
# ifdef RCOMPLEX
  return RCOMPLEX(cmp)->imag;
# else
  return rb_funcall(cmp, rb_intern("imag"), 0);
# endif
}
#define rb_complex_imag rb_complex_imag_fallback
#endif

/* st */

#ifndef ST2FIX
# undef RB_ST2FIX
# define RB_ST2FIX(h) LONG2FIX((long)(h))
# define ST2FIX(h) RB_ST2FIX(h)
#endif

/* warning */

#if !defined(HAVE_RB_CATEGORY_WARN) || !defined(HAVE_CONST_RB_WARN_CATEGORY_DEPRECATED)
#   define rb_category_warn(category, ...) rb_warn(__VA_ARGS__)
#endif

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* MISSING_H */
