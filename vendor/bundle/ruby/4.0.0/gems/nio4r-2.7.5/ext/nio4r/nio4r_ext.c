/*
 * Copyright (c) 2011-2017 Tony Arcieri. Distributed under the MIT License.
 * See LICENSE.txt for further details.
 */

#include "../libev/ev.c"
#include "nio4r.h"

void Init_NIO_Selector();
void Init_NIO_Monitor();
void Init_NIO_ByteBuffer();

void Init_nio4r_ext()
{
    #ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
    #endif

    ev_set_allocator(xrealloc);

    Init_NIO_Selector();
    Init_NIO_Monitor();
    Init_NIO_ByteBuffer();
}
