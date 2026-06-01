#ifndef TRILOGY_INTERNAL_ALLOCATOR_H
#define TRILOGY_INTERNAL_ALLOCATOR_H

/* If you build Trilogy with a custom allocator, configure it with
 * "-D TRILOGY_XALLOCATOR" to use your own allocator that defines xmalloc,
 * xrealloc, xcalloc, and xfree.
 *
 * For example, your `trilogy_xallocator.h` file could look like this:
 *
 * ```
 * #ifndef TRILOGY_XALLOCATOR_H
 * #define TRILOGY_XALLOCATOR_H
 * #define xmalloc          my_malloc
 * #define xrealloc         my_realloc
 * #define xcalloc          my_calloc
 * #define xfree            my_free
 * #endif
 * ```
 */
#ifdef TRILOGY_XALLOCATOR
    #include "trilogy_xallocator.h"
#else
    #ifndef xmalloc
        /* The malloc function that should be used. This can be overridden with
         * the TRILOGY_XALLOCATOR define. */
        #define xmalloc malloc
    #endif

    #ifndef xrealloc
        /* The realloc function that should be used. This can be overridden with
         * the TRILOGY_XALLOCATOR define. */
        #define xrealloc realloc
    #endif

    #ifndef xcalloc
        /* The calloc function that should be used. This can be overridden with
         * the TRILOGY_XALLOCATOR define. */
        #define xcalloc calloc
    #endif

    #ifndef xfree
        /* The free function that should be used. This can be overridden with
         * the TRILOGY_XALLOCATOR define. */
        #define xfree free
    #endif
#endif

#include <string.h>
static inline char *
xstrdup(const char *str)
{
    char *tmp;
    size_t len = strlen(str) + 1;

    tmp = xmalloc(len);
    memcpy(tmp, str, len);

    return tmp;
}

#endif
