#include <stddef.h>

#include "trilogy/error.h"

const char *trilogy_error(int error)
{
    switch (error) {
#define XX(name, code)                                                                                                 \
    case code:                                                                                                         \
        return #name;
        TRILOGY_ERROR_CODES(XX)
#undef XX

    default:
        return NULL;
    }
}
