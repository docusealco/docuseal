// Copyright (c) 2012, 2017 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "dump.h"

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#if !IS_WINDOWS
#include <poll.h>
#endif

#include "cache8.h"
#include "mem.h"
#include "odd.h"
#include "oj.h"
#include "trace.h"
#include "util.h"

// Workaround in case INFINITY is not defined in math.h or if the OS is CentOS
#define OJ_INFINITY (1.0 / 0.0)

#define MAX_DEPTH 1000

static const char inf_val[]  = INF_VAL;
static const char ninf_val[] = NINF_VAL;
static const char nan_val[]  = NAN_VAL;

typedef unsigned long ulong;

static size_t hibit_friendly_size(const uint8_t *str, size_t len);
static size_t slash_friendly_size(const uint8_t *str, size_t len);
static size_t xss_friendly_size(const uint8_t *str, size_t len);
static size_t ascii_friendly_size(const uint8_t *str, size_t len);

static const char hex_chars[17] = "0123456789abcdef";

// JSON standard except newlines are no escaped
static char newline_friendly_chars[256] = "\
66666666221622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// JSON standard
static char hibit_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// JSON standard but escape forward slashes `/`
static char slash_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111121111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// High bit set characters are always encoded as unicode. Worse case is 3
// bytes per character in the output. That makes this conservative.
static char ascii_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111116\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333";

// XSS safe mode
static char xss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211161111111121111111111116161\
11111111111111111111111111112111\
11111111111111111111111111111116\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333";

// JSON XSS combo
static char hixss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11611111111111111111111111111111";

// Rails XSS combo
static char rails_xss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211161111111111111111111116161\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11611111111111111111111111111111";

// Rails HTML non-escape
static char rails_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

static void raise_strict(VALUE obj) {
    rb_raise(rb_eTypeError, "Failed to dump %s Object to JSON in strict mode.", rb_class2name(rb_obj_class(obj)));
}

inline static size_t calculate_string_size(const uint8_t *str, size_t len, const char *table) {
    size_t size = 0;
    size_t i    = len;

    for (; 3 < i; i -= 4) {
        size += table[*str++];
        size += table[*str++];
        size += table[*str++];
        size += table[*str++];
    }
    for (; 0 < i; i--) {
        size += table[*str++];
    }
    return size - len * (size_t)'0';
}

inline static size_t newline_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, newline_friendly_chars);
}

#ifdef HAVE_SIMD_NEON
inline static uint8x16x4_t load_uint8x16_4(const unsigned char *table) {
    uint8x16x4_t tab;
    tab.val[0] = vld1q_u8(table);
    tab.val[1] = vld1q_u8(table + 16);
    tab.val[2] = vld1q_u8(table + 32);
    tab.val[3] = vld1q_u8(table + 48);
    return tab;
}

static uint8x16x4_t hibit_friendly_chars_neon[2];
static uint8x16x4_t rails_friendly_chars_neon[2];
static uint8x16x4_t rails_xss_friendly_chars_neon[4];

void initialize_neon(void) {
    // We only need the first 128 bytes of the hibit friendly chars table. Everything above 127 is
    // set to 1. If that ever changes, the code will need to be updated.
    hibit_friendly_chars_neon[0] = load_uint8x16_4((const unsigned char *)hibit_friendly_chars);
    hibit_friendly_chars_neon[1] = load_uint8x16_4((const unsigned char *)hibit_friendly_chars + 64);

    // rails_friendly_chars is the same as hibit_friendly_chars. Only the first 128 bytes have values
    // that are not '1'. If that ever changes, the code will need to be updated.
    rails_friendly_chars_neon[0] = load_uint8x16_4((const unsigned char *)rails_friendly_chars);
    rails_friendly_chars_neon[1] = load_uint8x16_4((const unsigned char *)rails_friendly_chars + 64);

    rails_xss_friendly_chars_neon[0] = load_uint8x16_4((const unsigned char *)rails_xss_friendly_chars);
    rails_xss_friendly_chars_neon[1] = load_uint8x16_4((const unsigned char *)rails_xss_friendly_chars + 64);
    rails_xss_friendly_chars_neon[2] = load_uint8x16_4((const unsigned char *)rails_xss_friendly_chars + 128);
    rails_xss_friendly_chars_neon[3] = load_uint8x16_4((const unsigned char *)rails_xss_friendly_chars + 192);

    // All bytes should be 0 except for those that need more than 1 byte of output. This will allow the
    // code to limit the lookups to the first 128 bytes (values 0 - 127). Bytes above 127 will result
    // in 0 with the vqtbl4q_u8 instruction.
    uint8x16_t one = vdupq_n_u8('1');
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 4; j++) {
            hibit_friendly_chars_neon[i].val[j] = vsubq_u8(hibit_friendly_chars_neon[i].val[j], one);
            rails_friendly_chars_neon[i].val[j] = vsubq_u8(rails_friendly_chars_neon[i].val[j], one);
        }
    }

    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            rails_xss_friendly_chars_neon[i].val[j] = vsubq_u8(rails_xss_friendly_chars_neon[i].val[j], one);
        }
    }
}
#endif

#ifdef HAVE_SIMD_SSE4_2

static __m128i hibit_friendly_chars_sse42[8];

// From: https://stackoverflow.com/questions/36998538/fastest-way-to-horizontally-sum-sse-unsigned-byte-vector
inline static OJ_TARGET_SSE42 uint32_t _mm_sum_epu8(const __m128i v) {
    __m128i vsum = _mm_sad_epu8(v, _mm_setzero_si128());
    return _mm_cvtsi128_si32(vsum) + _mm_extract_epi16(vsum, 4);
}

inline static OJ_TARGET_SSE42 size_t hibit_friendly_size_sse42(const uint8_t *str, size_t len) {
    size_t size = 0;
    size_t i    = 0;

    for (; i + sizeof(__m128i) <= len; i += sizeof(__m128i), str += sizeof(__m128i)) {
        size += sizeof(__m128i);

        __m128i chunk = _mm_loadu_si128((__m128i *)str);
        __m128i tmp   = vector_lookup_sse42(chunk, hibit_friendly_chars_sse42, 8);
        size += _mm_sum_epu8(tmp);
    }
    size_t total = size + calculate_string_size(str, len - i, hibit_friendly_chars);
    return total;
}

void OJ_TARGET_SSE42 initialize_sse42(void) {
    for (int i = 0; i < 8; i++) {
        hibit_friendly_chars_sse42[i] = _mm_sub_epi8(
            _mm_loadu_si128((__m128i *)(hibit_friendly_chars + i * sizeof(__m128i))),
            _mm_set1_epi8('1'));
    }
}

#else

#define SIMD_TARGET

#endif /* HAVE_SIMD_SSE4_2 */

inline static size_t hibit_friendly_size(const uint8_t *str, size_t len) {
#ifdef HAVE_SIMD_NEON
    size_t size = 0;
    size_t i    = 0;

    for (; i + sizeof(uint8x16_t) <= len; i += sizeof(uint8x16_t), str += sizeof(uint8x16_t)) {
        size += sizeof(uint8x16_t);

        // See https://lemire.me/blog/2019/07/23/arbitrary-byte-to-byte-maps-using-arm-neon/
        uint8x16_t chunk  = vld1q_u8(str);
        uint8x16_t tmp1   = vqtbl4q_u8(hibit_friendly_chars_neon[0], chunk);
        uint8x16_t tmp2   = vqtbl4q_u8(hibit_friendly_chars_neon[1], veorq_u8(chunk, vdupq_n_u8(0x40)));
        uint8x16_t result = vorrq_u8(tmp1, tmp2);
        uint8_t    tmp    = vaddvq_u8(result);
        size += tmp;
    }

    size_t total = size + calculate_string_size(str, len - i, hibit_friendly_chars);
    return total;
#elif defined(HAVE_SIMD_SSE4_2)
    if (SIMD_Impl == SIMD_SSE42) {
        if (len >= sizeof(__m128i)) {
            return hibit_friendly_size_sse42(str, len);
        }
    }
    return calculate_string_size(str, len, hibit_friendly_chars);
#else
    return calculate_string_size(str, len, hibit_friendly_chars);
#endif
}

inline static size_t slash_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, slash_friendly_chars);
}

inline static size_t ascii_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, ascii_friendly_chars);
}

inline static size_t xss_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, xss_friendly_chars);
}

inline static size_t hixss_friendly_size(const uint8_t *str, size_t len) {
    size_t size  = 0;
    size_t i     = len;
    bool   check = false;

    for (; 0 < i; str++, i--) {
        size += hixss_friendly_chars[*str];
        if (0 != (0x80 & *str)) {
            check = true;
        }
    }
    return size - len * (size_t)'0' + check;
}

inline static long rails_xss_friendly_size(const uint8_t *str, size_t len) {
    long     size = 0;
    uint32_t hi   = 0;

#ifdef HAVE_SIMD_NEON
    size_t i = 0;

    if (len >= sizeof(uint8x16_t)) {
        uint8x16_t has_some_hibit = vdupq_n_u8(0);
        uint8x16_t hibit          = vdupq_n_u8(0x80);

        for (; i + sizeof(uint8x16_t) <= len; i += sizeof(uint8x16_t), str += sizeof(uint8x16_t)) {
            size += sizeof(uint8x16_t);

            uint8x16_t chunk = vld1q_u8(str);

            // Check to see if any of these bytes have the high bit set.
            has_some_hibit = vorrq_u8(has_some_hibit, vandq_u8(chunk, hibit));

            uint8x16_t tmp1   = vqtbl4q_u8(rails_xss_friendly_chars_neon[0], chunk);
            uint8x16_t tmp2   = vqtbl4q_u8(rails_xss_friendly_chars_neon[1], veorq_u8(chunk, vdupq_n_u8(0x40)));
            uint8x16_t tmp3   = vqtbl4q_u8(rails_xss_friendly_chars_neon[2], veorq_u8(chunk, vdupq_n_u8(0x80)));
            uint8x16_t tmp4   = vqtbl4q_u8(rails_xss_friendly_chars_neon[3], veorq_u8(chunk, vdupq_n_u8(0xc0)));
            uint8x16_t result = vorrq_u8(tmp4, vorrq_u8(tmp3, vorrq_u8(tmp1, tmp2)));
            uint8_t    tmp    = vaddvq_u8(result);
            size += tmp;
        }

        // 'hi' should be set if any of the bytes we processed have the high bit set. It doesn't matter which ones.
        hi = vmaxvq_u8(has_some_hibit) != 0;
    }

    size_t len_remaining = len - i;

    for (; i < len; str++, i++) {
        size += rails_xss_friendly_chars[*str];
        hi |= *str & 0x80;
    }

    size -= (len_remaining * ((size_t)'0'));

    if (0 == hi) {
        return size;
    }
    return -(size);
#else
    size_t i = len;
    for (; 0 < i; str++, i--) {
        size += rails_xss_friendly_chars[*str];
        hi |= *str & 0x80;
    }
    if (0 == hi) {
        return size - len * (size_t)'0';
    }
    return -(size - len * (size_t)'0');
#endif /* HAVE_SIMD_NEON */
}

inline static size_t rails_friendly_size(const uint8_t *str, size_t len) {
    long     size = 0;
    uint32_t hi   = 0;
#ifdef HAVE_SIMD_NEON
    size_t i     = 0;
    long   extra = 0;

    if (len >= sizeof(uint8x16_t)) {
        uint8x16_t has_some_hibit = vdupq_n_u8(0);
        uint8x16_t hibit          = vdupq_n_u8(0x80);

        for (; i + sizeof(uint8x16_t) <= len; i += sizeof(uint8x16_t), str += sizeof(uint8x16_t)) {
            size += sizeof(uint8x16_t);

            // See https://lemire.me/blog/2019/07/23/arbitrary-byte-to-byte-maps-using-arm-neon/
            uint8x16_t chunk = vld1q_u8(str);

            // Check to see if any of these bytes have the high bit set.
            has_some_hibit = vorrq_u8(has_some_hibit, vandq_u8(chunk, hibit));

            uint8x16_t tmp1   = vqtbl4q_u8(rails_friendly_chars_neon[0], chunk);
            uint8x16_t tmp2   = vqtbl4q_u8(rails_friendly_chars_neon[1], veorq_u8(chunk, vdupq_n_u8(0x40)));
            uint8x16_t result = vorrq_u8(tmp1, tmp2);
            uint8_t    tmp    = vaddvq_u8(result);
            size += tmp;
        }

        // 'hi' should be set if any of the bytes we processed have the high bit set. It doesn't matter which ones.
        hi = vmaxvq_u8(has_some_hibit) != 0;
    }

    for (; i < len; str++, i++, extra++) {
        size += rails_friendly_chars[*str];
        hi |= *str & 0x80;
    }

    size -= (extra * ((size_t)'0'));

    if (0 == hi) {
        return size;
    }
    return -(size);
#else
    size_t i = len;
    for (; 0 < i; str++, i--) {
        size += rails_friendly_chars[*str];
        hi |= *str & 0x80;
    }
    if (0 == hi) {
        return size - len * (size_t)'0';
    }
    return -(size - len * (size_t)'0');
#endif /* HAVE_SIMD_NEON */
}

const char *oj_nan_str(VALUE obj, int opt, int mode, bool plus, size_t *lenp) {
    const char *str = NULL;

    if (AutoNan == opt) {
        switch (mode) {
        case CompatMode: opt = WordNan; break;
        case StrictMode: opt = RaiseNan; break;
        default: break;
        }
    }
    switch (opt) {
    case RaiseNan: raise_strict(obj); break;
    case WordNan:
        if (plus) {
            str   = "Infinity";
            *lenp = 8;
        } else {
            str   = "-Infinity";
            *lenp = 9;
        }
        break;
    case NullNan:
        str   = "null";
        *lenp = 4;
        break;
    case HugeNan:
    default:
        if (plus) {
            str   = inf_val;
            *lenp = sizeof(inf_val) - 1;
        } else {
            str   = ninf_val;
            *lenp = sizeof(ninf_val) - 1;
        }
        break;
    }
    return str;
}

inline static void dump_hex(uint8_t c, Out out) {
    uint8_t d = (c >> 4) & 0x0F;

    *out->cur++ = hex_chars[d];
    d           = c & 0x0F;
    *out->cur++ = hex_chars[d];
}

static void raise_invalid_unicode(const char *str, int len, int pos) {
    char    c;
    char    code[32];
    char   *cp = code;
    int     i;
    uint8_t d;

    *cp++ = '[';
    for (i = pos; i < len && i - pos < 5; i++) {
        c     = str[i];
        d     = (c >> 4) & 0x0F;
        *cp++ = hex_chars[d];
        d     = c & 0x0F;
        *cp++ = hex_chars[d];
        *cp++ = ' ';
    }
    cp--;
    *cp++ = ']';
    *cp   = '\0';
    rb_raise(oj_json_generator_error_class, "Invalid Unicode %s at %d", code, pos);
}

static const char *dump_unicode(const char *str, const char *end, Out out, const char *orig) {
    uint32_t code = 0;
    uint8_t  b    = *(uint8_t *)str;
    int      i, cnt;

    if (0xC0 == (0xE0 & b)) {
        cnt  = 1;
        code = b & 0x0000001F;
    } else if (0xE0 == (0xF0 & b)) {
        cnt  = 2;
        code = b & 0x0000000F;
    } else if (0xF0 == (0xF8 & b)) {
        cnt  = 3;
        code = b & 0x00000007;
    } else if (0xF8 == (0xFC & b)) {
        cnt  = 4;
        code = b & 0x00000003;
    } else if (0xFC == (0xFE & b)) {
        cnt  = 5;
        code = b & 0x00000001;
    } else {
        cnt = 0;
        raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
    }
    str++;
    for (; 0 < cnt; cnt--, str++) {
        b = *(uint8_t *)str;
        if (end <= str || 0x80 != (0xC0 & b)) {
            raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
        }
        code = (code << 6) | (b & 0x0000003F);
    }
    if (0x0000FFFF < code) {
        uint32_t c1;

        code -= 0x00010000;
        c1   = ((code >> 10) & 0x000003FF) + 0x0000D800;
        code = (code & 0x000003FF) + 0x0000DC00;
        APPEND_CHARS(out->cur, "\\u", 2);
        for (i = 3; 0 <= i; i--) {
            *out->cur++ = hex_chars[(uint8_t)(c1 >> (i * 4)) & 0x0F];
        }
    }
    APPEND_CHARS(out->cur, "\\u", 2);
    for (i = 3; 0 <= i; i--) {
        *out->cur++ = hex_chars[(uint8_t)(code >> (i * 4)) & 0x0F];
    }
    return str - 1;
}

static const char *check_unicode(const char *str, const char *end, const char *orig) {
    uint8_t b   = *(uint8_t *)str;
    int     cnt = 0;

    if (0xC0 == (0xE0 & b)) {
        cnt = 1;
    } else if (0xE0 == (0xF0 & b)) {
        cnt = 2;
    } else if (0xF0 == (0xF8 & b)) {
        cnt = 3;
    } else if (0xF8 == (0xFC & b)) {
        cnt = 4;
    } else if (0xFC == (0xFE & b)) {
        cnt = 5;
    } else {
        raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
    }
    str++;
    for (; 0 < cnt; cnt--, str++) {
        b = *(uint8_t *)str;
        if (end <= str || 0x80 != (0xC0 & b)) {
            raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
        }
    }
    return str;
}

// Returns 0 if not using circular references, -1 if no further writing is
// needed (duplicate), and a positive value if the object was added to the
// cache.
long oj_check_circular(VALUE obj, Out out) {
    slot_t  id = 0;
    slot_t *slot;

    if (Yes == out->opts->circular) {
        if (0 == (id = oj_cache8_get(out->circ_cache, obj, &slot))) {
            out->circ_cnt++;
            id    = out->circ_cnt;
            *slot = id;
        } else {
            if (ObjectMode == out->opts->mode) {
                assure_size(out, 18);
                APPEND_CHARS(out->cur, "\"^r", 3);
                dump_ulong(id, out);
                *out->cur++ = '"';
            }
            return -1;
        }
    }
    return (long)id;
}

void oj_dump_time(VALUE obj, Out out, int withZone) {
    char      buf[64];
    char     *b = buf + sizeof(buf) - 1;
    long      size;
    char     *dot;
    int       neg = 0;
    long      one = 1000000000;
    long long sec;
    long long nsec;

    // rb_time_timespec as well as rb_time_timeeval have a bug that causes an
    // exception to be raised if a time is before 1970 on 32 bit systems so
    // check the timespec size and use the ruby calls if a 32 bit system.
    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = (long long)ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    *b-- = '\0';
    if (withZone) {
        long tzsecs = NUM2LONG(rb_funcall2(obj, oj_utc_offset_id, 0, 0));
        int  zneg   = (0 > tzsecs);

        if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
            tzsecs = 86400;
        }
        if (zneg) {
            tzsecs = -tzsecs;
        }
        if (0 == tzsecs) {
            *b-- = '0';
        } else {
            for (; 0 < tzsecs; b--, tzsecs /= 10) {
                *b = '0' + (tzsecs % 10);
            }
            if (zneg) {
                *b-- = '-';
            }
        }
        *b-- = 'e';
    }
    if (0 > sec) {
        neg = 1;
        sec = -sec;
        if (0 < nsec) {
            nsec = 1000000000 - nsec;
            sec--;
        }
    }
    dot = b - 9;
    if (0 < out->opts->sec_prec) {
        if (9 > out->opts->sec_prec) {
            int i;

            for (i = 9 - out->opts->sec_prec; 0 < i; i--) {
                dot++;
                nsec = (nsec + 5) / 10;
                one /= 10;
            }
        }
        if (one <= nsec) {
            nsec -= one;
            sec++;
        }
        for (; dot < b; b--, nsec /= 10) {
            *b = '0' + (nsec % 10);
        }
        *b-- = '.';
    }
    if (0 == sec) {
        *b-- = '0';
    } else {
        for (; 0 < sec; b--, sec /= 10) {
            *b = '0' + (sec % 10);
        }
    }
    if (neg) {
        *b-- = '-';
    }
    b++;
    size = sizeof(buf) - (b - buf) - 1;
    assure_size(out, size);
    APPEND_CHARS(out->cur, b, size);
    *out->cur = '\0';
}

void oj_dump_ruby_time(VALUE obj, Out out) {
    volatile VALUE rstr = oj_safe_string_convert(obj);

    oj_dump_cstr(RSTRING_PTR(rstr), RSTRING_LEN(rstr), 0, 0, out);
}

void oj_dump_xml_time(VALUE obj, Out out) {
    char             buf[64];
    struct _timeInfo ti;
    long             one = 1000000000;
    int64_t          sec;
    long long        nsec;
    long             tzsecs = NUM2LONG(rb_funcall2(obj, oj_utc_offset_id, 0, 0));
    int              tzhour, tzmin;
    char             tzsign = '+';

    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    assure_size(out, 36);
    if (9 > out->opts->sec_prec) {
        int i;

        // This is pretty lame but to be compatible with rails and active
        // support rounding is not done but instead a floor is done when
        // second precision is 3 just to be like rails. sigh.
        if (3 == out->opts->sec_prec) {
            nsec /= 1000000;
            one = 1000;
        } else {
            for (i = 9 - out->opts->sec_prec; 0 < i; i--) {
                nsec = (nsec + 5) / 10;
                one /= 10;
            }
            if (one <= nsec) {
                nsec -= one;
                sec++;
            }
        }
    }
    // 2012-01-05T23:58:07.123456000+09:00
    // tm = localtime(&sec);
    sec += tzsecs;
    sec_as_time((int64_t)sec, &ti);
    if (0 > tzsecs) {
        tzsign = '-';
        tzhour = (int)(tzsecs / -3600);
        tzmin  = (int)(tzsecs / -60) - (tzhour * 60);
    } else {
        tzhour = (int)(tzsecs / 3600);
        tzmin  = (int)(tzsecs / 60) - (tzhour * 60);
    }
    if ((0 == nsec && !out->opts->sec_prec_set) || 0 == out->opts->sec_prec) {
        if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
            int len = sprintf(buf, "%04d-%02d-%02dT%02d:%02d:%02dZ", ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec);
            oj_dump_cstr(buf, len, 0, 0, out);
        } else {
            int len = sprintf(buf,
                              "%04d-%02d-%02dT%02d:%02d:%02d%c%02d:%02d",
                              ti.year,
                              ti.mon,
                              ti.day,
                              ti.hour,
                              ti.min,
                              ti.sec,
                              tzsign,
                              tzhour,
                              tzmin);
            oj_dump_cstr(buf, len, 0, 0, out);
        }
    } else if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
        char format[64] = "%04d-%02d-%02dT%02d:%02d:%02d.%09ldZ";
        int  len;

        if (9 > out->opts->sec_prec) {
            format[32] = '0' + out->opts->sec_prec;
        }
        len = sprintf(buf, format, ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec, (long)nsec);
        oj_dump_cstr(buf, len, 0, 0, out);
    } else {
        char format[64] = "%04d-%02d-%02dT%02d:%02d:%02d.%09ld%c%02d:%02d";
        int  len;

        if (9 > out->opts->sec_prec) {
            format[32] = '0' + out->opts->sec_prec;
        }
        len = sprintf(buf, format, ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec, (long)nsec, tzsign, tzhour, tzmin);
        oj_dump_cstr(buf, len, 0, 0, out);
    }
}

void oj_dump_obj_to_json(VALUE obj, Options copts, Out out) {
    oj_dump_obj_to_json_using_params(obj, copts, out, 0, 0);
}

void oj_dump_obj_to_json_using_params(VALUE obj, Options copts, Out out, int argc, VALUE *argv) {
    if (0 == out->buf) {
        oj_out_init(out);
    }
    out->circ_cnt = 0;
    out->opts     = copts;
    out->hash_cnt = 0;
    out->indent   = copts->indent;
    out->argc     = argc;
    out->argv     = argv;
    out->ropts    = NULL;
    if (Yes == copts->circular) {
        oj_cache8_new(&out->circ_cache);
    }
    switch (copts->mode) {
    case StrictMode: oj_dump_strict_val(obj, 0, out); break;
    case NullMode: oj_dump_null_val(obj, 0, out); break;
    case ObjectMode: oj_dump_obj_val(obj, 0, out); break;
    case CompatMode: oj_dump_compat_val(obj, 0, out, Yes == copts->to_json); break;
    case RailsMode: oj_dump_rails_val(obj, 0, out); break;
    case CustomMode: oj_dump_custom_val(obj, 0, out, true); break;
    case WabMode: oj_dump_wab_val(obj, 0, out); break;
    default: oj_dump_custom_val(obj, 0, out, true); break;
    }
    if (0 < out->indent) {
        switch (*(out->cur - 1)) {
        case ']':
        case '}': assure_size(out, 1); *out->cur++ = '\n';
        default: break;
        }
    }
    *out->cur = '\0';
    if (Yes == copts->circular) {
        oj_cache8_delete(out->circ_cache);
    }
}

void oj_write_obj_to_file(VALUE obj, const char *path, Options copts) {
    struct _out out;
    size_t      size;
    FILE       *f;
    int         ok;

    oj_out_init(&out);

    out.omit_nil = copts->dump_opts.omit_nil;
    oj_dump_obj_to_json(obj, copts, &out);
    size = out.cur - out.buf;
    if (0 == (f = fopen(path, "w"))) {
        oj_out_free(&out);
        rb_raise(rb_eIOError, "%s", strerror(errno));
    }
    ok = (size == fwrite(out.buf, 1, size, f));

    oj_out_free(&out);

    if (!ok) {
        int err = ferror(f);
        fclose(f);

        rb_raise(rb_eIOError, "Write failed. [%d:%s]", err, strerror(err));
    }
    fclose(f);
}

#if !IS_WINDOWS
static void write_ready(int fd) {
    struct pollfd pp;
    int           i;

    pp.fd      = fd;
    pp.events  = POLLERR | POLLOUT;
    pp.revents = 0;
    if (0 >= (i = poll(&pp, 1, 5000))) {
        if (0 == i || EAGAIN == errno) {
            rb_raise(rb_eIOError, "write timed out");
        }
        rb_raise(rb_eIOError, "write failed. %d %s.", errno, strerror(errno));
    }
}
#endif

void oj_write_obj_to_stream(VALUE obj, VALUE stream, Options copts) {
    struct _out out;
    ssize_t     size;
    VALUE       clas = rb_obj_class(stream);
#if !IS_WINDOWS
    int   fd;
    VALUE s;
#endif

    oj_out_init(&out);

    out.omit_nil = copts->dump_opts.omit_nil;
    oj_dump_obj_to_json(obj, copts, &out);
    size = out.cur - out.buf;
    if (oj_stringio_class == clas) {
        rb_funcall(stream, oj_write_id, 1, rb_str_new(out.buf, size));
#if !IS_WINDOWS
    } else if (rb_respond_to(stream, oj_fileno_id) && Qnil != (s = rb_funcall(stream, oj_fileno_id, 0)) &&
               0 != (fd = FIX2INT(s))) {
        ssize_t cnt;
        ssize_t total = 0;

        while (true) {
            if (0 > (cnt = write(fd, out.buf + total, size - total))) {
                if (EAGAIN != errno) {
                    rb_raise(rb_eIOError, "write failed. %d %s.", errno, strerror(errno));
                    break;
                }
            }
            total += cnt;
            if (size <= total) {
                // Completed
                break;
            }
            write_ready(fd);
        }
#endif
    } else if (rb_respond_to(stream, oj_write_id)) {
        rb_funcall(stream, oj_write_id, 1, rb_str_new(out.buf, size));
    } else {
        oj_out_free(&out);
        rb_raise(rb_eArgError, "to_stream() expected an IO Object.");
    }
    oj_out_free(&out);
}

void oj_dump_str(VALUE obj, int depth, Out out, bool as_ok) {
    int idx = RB_ENCODING_GET(obj);

    if (oj_utf8_encoding_index != idx) {
        rb_encoding *enc = rb_enc_from_index(idx);
        obj              = rb_str_conv_enc(obj, enc, oj_utf8_encoding);
    }
    oj_dump_cstr(RSTRING_PTR(obj), RSTRING_LEN(obj), 0, 0, out);
}

void oj_dump_sym(VALUE obj, int depth, Out out, bool as_ok) {
    volatile VALUE s = rb_sym2str(obj);

    oj_dump_cstr(RSTRING_PTR(s), RSTRING_LEN(s), 0, 0, out);
}

static void debug_raise(const char *orig, size_t cnt, int line) {
    char        buf[1024];
    char       *b     = buf;
    const char *s     = orig;
    const char *s_end = s + cnt;

    if (32 < s_end - s) {
        s_end = s + 32;
    }
    for (; s < s_end; s++) {
        b += sprintf(b, " %02x", *s);
    }
    *b = '\0';
    rb_raise(oj_json_generator_error_class, "Partial character in string. %s @ %d", buf, line);
}

void oj_dump_raw_json(VALUE obj, int depth, Out out) {
    if (oj_string_writer_class == rb_obj_class(obj)) {
        StrWriter sw;
        size_t    len;

        sw  = oj_str_writer_unwrap(obj);
        len = sw->out.cur - sw->out.buf;

        if (0 < len) {
            len--;
        }
        oj_dump_raw(sw->out.buf, len, out);
    } else {
        volatile VALUE jv;

        TRACE(out->opts->trace, "raw_json", obj, depth + 1, TraceRubyIn);
        jv = rb_funcall(obj, oj_raw_json_id, 2, RB_INT2NUM(depth), RB_INT2NUM(out->indent));
        TRACE(out->opts->trace, "raw_json", obj, depth + 1, TraceRubyOut);
        oj_dump_raw(RSTRING_PTR(jv), (size_t)RSTRING_LEN(jv), out);
    }
}

#if defined(__clang__) || defined(__GNUC__)
#define FORCE_INLINE __attribute__((always_inline))
#else
#define FORCE_INLINE
#endif

#ifdef HAVE_SIMD_NEON
typedef struct _neon_match_result {
    uint8x16_t needs_escape;
    bool       has_some_hibit;
    bool       do_unicode_validation;
} neon_match_result;

static inline FORCE_INLINE neon_match_result
neon_update(const char *str, uint8x16x4_t *cmap_neon, int neon_table_size, bool do_unicode_validation, bool has_hi) {
    neon_match_result result = {.has_some_hibit = false, .do_unicode_validation = false};

    uint8x16_t chunk    = vld1q_u8((const unsigned char *)str);
    uint8x16_t tmp1     = vqtbl4q_u8(cmap_neon[0], chunk);
    uint8x16_t tmp2     = vqtbl4q_u8(cmap_neon[1], veorq_u8(chunk, vdupq_n_u8(0x40)));
    result.needs_escape = vorrq_u8(tmp1, tmp2);
    if (neon_table_size > 2) {
        uint8x16_t tmp3     = vqtbl4q_u8(cmap_neon[2], veorq_u8(chunk, vdupq_n_u8(0x80)));
        uint8x16_t tmp4     = vqtbl4q_u8(cmap_neon[3], veorq_u8(chunk, vdupq_n_u8(0xc0)));
        result.needs_escape = vorrq_u8(result.needs_escape, vorrq_u8(tmp4, tmp3));
    }
    if (has_hi && do_unicode_validation) {
        uint8x16_t has_some_hibit    = vandq_u8(chunk, vdupq_n_u8(0x80));
        result.has_some_hibit        = vmaxvq_u8(has_some_hibit) != 0;
        result.do_unicode_validation = has_hi && do_unicode_validation && result.has_some_hibit;
    }
    return result;
}

#elif defined(HAVE_SIMD_SSE4_2)
typedef struct _sse42_match_result {
    __m128i actions;
    bool    needs_escape;
    int     escape_mask;
    bool    has_some_hibit;
    bool    do_unicode_validation;
} sse42_match_result;

static inline OJ_TARGET_SSE42 sse42_match_result
sse42_update(const char *str, __m128i *cmap_sse42, int sse42_tab_size, bool do_unicode_validation, bool has_hi) {
    sse42_match_result result = {.has_some_hibit = false, .do_unicode_validation = false};

    __m128i chunk        = _mm_loadu_si128((__m128i *)str);
    __m128i actions      = vector_lookup_sse42(chunk, cmap_sse42, sse42_tab_size);
    __m128i needs_escape = _mm_xor_si128(_mm_cmpeq_epi8(actions, _mm_setzero_si128()), _mm_set1_epi8(0xFF));
    result.actions       = _mm_add_epi8(actions, _mm_set1_epi8('1'));

    result.escape_mask  = _mm_movemask_epi8(needs_escape);
    result.needs_escape = result.escape_mask != 0;
    if (has_hi && do_unicode_validation) {
        __m128i has_some_hibit       = _mm_and_si128(chunk, _mm_set1_epi8(0x80));
        result.has_some_hibit        = _mm_movemask_epi8(has_some_hibit) != 0;
        result.do_unicode_validation = has_hi && do_unicode_validation && result.has_some_hibit;
    }
    return result;
}

#endif /* HAVE_SIMD_NEON */

static inline FORCE_INLINE const char *process_character(char         action,
                                                         const char  *str,
                                                         const char  *end,
                                                         Out          out,
                                                         const char  *orig,
                                                         bool         do_unicode_validation,
                                                         const char **check_start_) {
    const char *check_start = *check_start_;
    switch (action) {
    case '1':
        if (do_unicode_validation && check_start <= str) {
            if (0 != (0x80 & (uint8_t)*str)) {
                if (0xC0 == (0xC0 & (uint8_t)*str)) {
                    *check_start_ = check_unicode(str, end, orig);
                } else {
                    raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
                }
            }
        }
        *out->cur++ = *str;
        break;
    case '2':
        *out->cur++ = '\\';
        switch (*str) {
        case '\\': *out->cur++ = '\\'; break;
        case '\b': *out->cur++ = 'b'; break;
        case '\t': *out->cur++ = 't'; break;
        case '\n': *out->cur++ = 'n'; break;
        case '\f': *out->cur++ = 'f'; break;
        case '\r': *out->cur++ = 'r'; break;
        default: *out->cur++ = *str; break;
        }
        break;
    case '3':  // Unicode
        if (0xe2 == (uint8_t)*str && do_unicode_validation && 2 <= end - str) {
            if (0x80 == (uint8_t)str[1] && (0xa8 == (uint8_t)str[2] || 0xa9 == (uint8_t)str[2])) {
                str = dump_unicode(str, end, out, orig);
            } else {
                *check_start_ = check_unicode(str, end, orig);
                *out->cur++   = *str;
            }
            break;
        }
        str = dump_unicode(str, end, out, orig);
        break;
    case '6':  // control characters
        if (*(uint8_t *)str < 0x80) {
            if (0 == (uint8_t)*str && out->opts->dump_opts.omit_null_byte) {
                break;
            }
            APPEND_CHARS(out->cur, "\\u00", 4);
            dump_hex((uint8_t)*str, out);
        } else {
            if (0xe2 == (uint8_t)*str && do_unicode_validation && 2 <= end - str) {
                if (0x80 == (uint8_t)str[1] && (0xa8 == (uint8_t)str[2] || 0xa9 == (uint8_t)str[2])) {
                    str = dump_unicode(str, end, out, orig);
                } else {
                    *check_start_ = check_unicode(str, end, orig);
                    *out->cur++   = *str;
                }
                break;
            }
            str = dump_unicode(str, end, out, orig);
        }
        break;
    default: break;  // ignore, should never happen if the table is correct
    }

    return str;
}

void oj_dump_cstr(const char *str, size_t cnt, bool is_sym, bool escape1, Out out) {
    size_t size;
    char  *cmap;
#ifdef HAVE_SIMD_NEON
    uint8x16x4_t *cmap_neon       = NULL;
    int           neon_table_size = 0;
#elif defined(HAVE_SIMD_SSE4_2)
    __m128i *cmap_sse42 = NULL;
    int      sse42_tab_size;
#endif /* HAVE_SIMD_NEON */
    const char *orig                  = str;
    bool        has_hi                = false;
    bool        do_unicode_validation = false;

    switch (out->opts->escape_mode) {
    case NLEsc:
        cmap = newline_friendly_chars;
        size = newline_friendly_size((uint8_t *)str, cnt);
        break;
    case ASCIIEsc:
        cmap = ascii_friendly_chars;
        size = ascii_friendly_size((uint8_t *)str, cnt);
        break;
    case SlashEsc:
        has_hi = true;
        cmap   = slash_friendly_chars;
        size   = slash_friendly_size((uint8_t *)str, cnt);
        break;
    case XSSEsc:
        cmap = xss_friendly_chars;
        size = xss_friendly_size((uint8_t *)str, cnt);
        break;
    case JXEsc:
        cmap                  = hixss_friendly_chars;
        size                  = hixss_friendly_size((uint8_t *)str, cnt);
        do_unicode_validation = true;
        break;
    case RailsXEsc: {
        long sz;

        cmap = rails_xss_friendly_chars;
#ifdef HAVE_SIMD_NEON
        cmap_neon       = rails_xss_friendly_chars_neon;
        neon_table_size = 4;
#endif /* HAVE_NEON_SIMD */
        sz = rails_xss_friendly_size((uint8_t *)str, cnt);
        if (sz < 0) {
            has_hi = true;
            size   = (size_t)-sz;
        } else {
            size = (size_t)sz;
        }
        do_unicode_validation = true;
        break;
    }
    case RailsEsc: {
        long sz;
        cmap = rails_friendly_chars;
#ifdef HAVE_SIMD_NEON
        cmap_neon       = rails_friendly_chars_neon;
        neon_table_size = 2;
#endif /* HAVE_NEON_SIMD */
        sz = rails_friendly_size((uint8_t *)str, cnt);
        if (sz < 0) {
            has_hi = true;
            size   = (size_t)-sz;
        } else {
            size = (size_t)sz;
        }
        do_unicode_validation = true;
        break;
    }
    case JSONEsc:
    default: cmap = hibit_friendly_chars;
#ifdef HAVE_SIMD_NEON
        cmap_neon       = hibit_friendly_chars_neon;
        neon_table_size = 2;
#elif defined(HAVE_SIMD_SSE4_2)
        cmap_sse42     = hibit_friendly_chars_sse42;
        sse42_tab_size = 8;
#endif /* HAVE_NEON_SIMD */
        size = hibit_friendly_size((uint8_t *)str, cnt);
    }
    assure_size(out, size + BUFFER_EXTRA);
    *out->cur++ = '"';

    if (escape1) {
        APPEND_CHARS(out->cur, "\\u00", 4);
        dump_hex((uint8_t)*str, out);
        cnt--;
        size--;
        str++;
        is_sym = 0;  // just to make sure
    }
    if (cnt == size && !has_hi) {
        if (is_sym) {
            *out->cur++ = ':';
        }
        APPEND_CHARS(out->cur, str, cnt);
        *out->cur++ = '"';
    } else {
        const char *end         = str + cnt;
        const char *check_start = str;

        if (is_sym) {
            *out->cur++ = ':';
        }

#if defined(HAVE_SIMD_NEON) || defined(HAVE_SIMD_SSE4_2)

#define SEARCH_FLUSH                                  \
    if (str > cursor) {                               \
        APPEND_CHARS(out->cur, cursor, str - cursor); \
        cursor = str;                                 \
    }

        const char *chunk_start;
        const char *chunk_end;
        const char *cursor = str;
        char        matches[16];
#endif /* HAVE_SIMD_NEON || HAVE_SIMD_SSE4_2 */

#if defined(HAVE_SIMD_NEON)
        bool use_simd = (cmap_neon != NULL && cnt >= (sizeof(uint8x16_t))) ? true : false;
#elif defined(HAVE_SIMD_SSE4_2)
        bool use_simd = false;
        if (SIMD_Impl == SIMD_SSE42) {
            use_simd = (cmap_sse42 != NULL && cnt >= (sizeof(__m128i))) ? true : false;
        }
#endif

#ifdef HAVE_SIMD_NEON
        if (use_simd) {
            while (str < end) {
                const char *chunk_ptr = NULL;
                if (str + sizeof(uint8x16_t) <= end) {
                    chunk_ptr   = str;
                    chunk_start = str;
                    chunk_end   = str + sizeof(uint8x16_t);
                } else if ((end - str) >= SIMD_MINIMUM_THRESHOLD) {
                    memset(out->cur, 'A', sizeof(uint8x16_t));
                    memcpy(out->cur, str, (end - str));
                    chunk_ptr   = out->cur;
                    chunk_start = str;
                    chunk_end   = end;
                } else {
                    break;
                }
                neon_match_result result = neon_update(chunk_ptr,
                                                       cmap_neon,
                                                       neon_table_size,
                                                       do_unicode_validation,
                                                       has_hi);
                if ((result.do_unicode_validation) || vmaxvq_u8(result.needs_escape) != 0) {
                    SEARCH_FLUSH;
                    uint8x16_t actions     = vaddq_u8(result.needs_escape, vdupq_n_u8('1'));
                    uint8_t    num_matches = vaddvq_u8(vandq_u8(result.needs_escape, vdupq_n_u8(0x1)));
                    vst1q_u8((unsigned char *)matches, actions);
                    bool process_each = result.do_unicode_validation || (num_matches > sizeof(uint8x16_t) / 2);
                    // If no byte in this chunk had the high bit set then we can skip
                    // all of the '1' bytes by directly copying them to the output.
                    if (!process_each) {
                        while (str < chunk_end) {
                            long i = str - chunk_start;
                            char action;
                            while (str < chunk_end && (action = matches[i++]) == '1') {
                                *out->cur++ = *str++;
                            }
                            cursor = str;
                            if (str >= chunk_end) {
                                break;
                            }
                            str = process_character(action, str, end, out, orig, do_unicode_validation, &check_start);
                            str++;
                        }
                    } else {
                        while (str < chunk_end) {
                            long match_index = str - chunk_start;
                            str              = process_character(matches[match_index],
                                                    str,
                                                    end,
                                                    out,
                                                    orig,
                                                    do_unicode_validation,
                                                    &check_start);
                            str++;
                        }
                    }
                    cursor = str;
                    continue;
                }
                str = chunk_end;
            }
            SEARCH_FLUSH;
        }
#endif

#ifdef HAVE_SIMD_SSE4_2
        if (SIMD_Impl == SIMD_SSE42) {
            if (use_simd) {
                while (str < end) {
                    const char *chunk_ptr = NULL;
                    if (str + sizeof(__m128i) <= end) {
                        chunk_ptr   = str;
                        chunk_start = str;
                        chunk_end   = str + sizeof(__m128i);
                    } else if ((end - str) >= SIMD_MINIMUM_THRESHOLD) {
                        memset(out->cur, 'A', sizeof(__m128i));
                        memcpy(out->cur, str, (end - str));
                        chunk_ptr   = out->cur;
                        chunk_start = str;
                        chunk_end   = end;
                    } else {
                        break;
                    }
                    sse42_match_result result = sse42_update(chunk_ptr,
                                                             cmap_sse42,
                                                             sse42_tab_size,
                                                             do_unicode_validation,
                                                             has_hi);
                    if ((result.do_unicode_validation) || result.needs_escape) {
                        SEARCH_FLUSH;
                        _mm_storeu_si128((__m128i *)matches, result.actions);
                        while (str < chunk_end) {
                            long match_index = str - chunk_start;
                            str              = process_character(matches[match_index],
                                                    str,
                                                    end,
                                                    out,
                                                    orig,
                                                    do_unicode_validation,
                                                    &check_start);
                            str++;
                        }
                        cursor = str;
                        continue;
                    }
                    str = chunk_end;
                }
                SEARCH_FLUSH;
            }
        }
#endif /* HAVE_SIMD_SSE4_2 */

        for (; str < end; str++) {
            str = process_character(cmap[(uint8_t)*str], str, end, out, orig, do_unicode_validation, &check_start);
        }
        *out->cur++ = '"';
    }
    if (do_unicode_validation && 0 < str - orig && 0 != (0x80 & *(str - 1))) {
        uint8_t c = (uint8_t)*(str - 1);
        int     i;
        int     scnt = (int)(str - orig);

        // Last utf-8 characters must be 0x10xxxxxx. The start must be
        // 0x110xxxxx for 2 characters, 0x1110xxxx for 3, and 0x11110xxx for
        // 4.
        if (0 != (0x40 & c)) {
            debug_raise(orig, cnt, __LINE__);
        }
        for (i = 1; i < (int)scnt && i < 4; i++) {
            c = str[-1 - i];
            if (0x80 != (0xC0 & c)) {
                switch (i) {
                case 1:
                    if (0xC0 != (0xE0 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                case 2:
                    if (0xE0 != (0xF0 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                case 3:
                    if (0xF0 != (0xF8 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                default:  // can't get here
                    break;
                }
                break;
            }
        }
        if (i == (int)scnt || 4 <= i) {
            debug_raise(orig, cnt, __LINE__);
        }
    }
    *out->cur = '\0';
}

void oj_dump_class(VALUE obj, int depth, Out out, bool as_ok) {
    const char *s = rb_class2name(obj);

    oj_dump_cstr(s, strlen(s), 0, 0, out);
}

void oj_dump_obj_to_s(VALUE obj, Out out) {
    volatile VALUE rstr = oj_safe_string_convert(obj);

    oj_dump_cstr(RSTRING_PTR(rstr), RSTRING_LEN(rstr), 0, 0, out);
}

void oj_dump_raw(const char *str, size_t cnt, Out out) {
    assure_size(out, cnt + 10);
    APPEND_CHARS(out->cur, str, cnt);
    *out->cur = '\0';
}

void oj_out_init(Out out) {
    out->buf       = out->stack_buffer;
    out->cur       = out->buf;
    out->end       = out->buf + sizeof(out->stack_buffer) - BUFFER_EXTRA;
    out->allocated = false;
}

void oj_out_free(Out out) {
    if (out->allocated) {
        OJ_R_FREE(out->buf);  // TBD
    }
}

void oj_grow_out(Out out, size_t len) {
    size_t size = out->end - out->buf;
    long   pos  = out->cur - out->buf;
    char  *buf  = out->buf;

    size *= 2;
    if (size <= len * 2 + pos) {
        size += len;
    }
    if (out->allocated) {
        OJ_R_REALLOC_N(buf, char, (size + BUFFER_EXTRA));
    } else {
        buf            = OJ_R_ALLOC_N(char, (size + BUFFER_EXTRA));
        out->allocated = true;
        memcpy(buf, out->buf, out->end - out->buf + BUFFER_EXTRA);
    }
    if (0 == buf) {
        rb_raise(rb_eNoMemError, "Failed to create string. [%d:%s]", ENOSPC, strerror(ENOSPC));
    }
    out->buf = buf;
    out->end = buf + size;
    out->cur = out->buf + pos;
}

void oj_dump_nil(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 4);
    APPEND_CHARS(out->cur, "null", 4);
    *out->cur = '\0';
}

void oj_dump_true(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 4);
    APPEND_CHARS(out->cur, "true", 4);
    *out->cur = '\0';
}

void oj_dump_false(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 5);
    APPEND_CHARS(out->cur, "false", 5);
    *out->cur = '\0';
}

static const char digits_table[] = "\
00010203040506070809\
10111213141516171819\
20212223242526272829\
30313233343536373839\
40414243444546474849\
50515253545556575859\
60616263646566676869\
70717273747576777879\
80818283848586878889\
90919293949596979899";

char *oj_longlong_to_string(long long num, bool negative, char *buf) {
    while (100 <= num) {
        unsigned idx = num % 100 * 2;
        *buf--       = digits_table[idx + 1];
        *buf--       = digits_table[idx];
        num /= 100;
    }
    if (num < 10) {
        *buf-- = num + '0';
    } else {
        *buf-- = digits_table[num * 2 + 1];
        *buf-- = digits_table[num * 2];
    }

    if (negative) {
        *buf = '-';
    } else {
        buf++;
    }
    return buf;
}

void oj_dump_fixnum(VALUE obj, int depth, Out out, bool as_ok) {
    char      buf[32];
    char     *b              = buf + sizeof(buf) - 1;
    long long num            = NUM2LL(obj);
    bool      neg            = false;
    size_t    cnt            = 0;
    bool      dump_as_string = false;

    if (out->opts->int_range_max != 0 && out->opts->int_range_min != 0 &&
        (out->opts->int_range_max < num || out->opts->int_range_min > num)) {
        dump_as_string = true;
    }
    if (0 > num) {
        neg = true;
        num = -num;
    }
    *b-- = '\0';

    if (dump_as_string) {
        *b-- = '"';
    }
    if (0 < num) {
        b = oj_longlong_to_string(num, neg, b);
    } else {
        *b = '0';
    }
    if (dump_as_string) {
        *--b = '"';
    }
    cnt = sizeof(buf) - (b - buf) - 1;
    assure_size(out, cnt);
    APPEND_CHARS(out->cur, b, cnt);
    *out->cur = '\0';
}

void oj_dump_bignum(VALUE obj, int depth, Out out, bool as_ok) {
    volatile VALUE rs             = rb_big2str(obj, 10);
    size_t         cnt            = RSTRING_LEN(rs);
    bool           dump_as_string = false;

    if (out->opts->int_range_max != 0 || out->opts->int_range_min != 0) {  // Bignum cannot be inside of Fixnum range
        dump_as_string = true;
        assure_size(out, cnt + 2);
        *out->cur++ = '"';
    } else {
        assure_size(out, cnt);
    }
    APPEND_CHARS(out->cur, RSTRING_PTR(rs), cnt);
    if (dump_as_string) {
        *out->cur++ = '"';
    }
    *out->cur = '\0';
}

// Removed dependencies on math due to problems with CentOS 5.4.
void oj_dump_float(VALUE obj, int depth, Out out, bool as_ok) {
    char   buf[64];
    char  *b;
    double d   = rb_num2dbl(obj);
    size_t cnt = 0;

    if (0.0 == d) {
        b    = buf;
        *b++ = '0';
        *b++ = '.';
        *b++ = '0';
        *b++ = '\0';
        cnt  = 3;
    } else if (OJ_INFINITY == d) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, inf_val);
            cnt = sizeof(inf_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case CompatMode: nd = WordNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                case CustomMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "Infinity");
                cnt = 8;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, inf_val);
                cnt = sizeof(inf_val) - 1;
                break;
            }
        }
    } else if (-OJ_INFINITY == d) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, ninf_val);
            cnt = sizeof(ninf_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case CompatMode: nd = WordNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "-Infinity");
                cnt = 9;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, ninf_val);
                cnt = sizeof(ninf_val) - 1;
                break;
            }
        }
    } else if (isnan(d)) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, nan_val);
            cnt = sizeof(nan_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case ObjectMode: nd = HugeNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "NaN");
                cnt = 3;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, nan_val);
                cnt = sizeof(nan_val) - 1;
                break;
            }
        }
    } else if (d == (double)(long long int)d) {
        cnt = snprintf(buf, sizeof(buf), "%.1f", d);
    } else if (0 == out->opts->float_prec) {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        cnt = RSTRING_LEN(rstr);
        if ((int)sizeof(buf) <= cnt) {
            cnt = sizeof(buf) - 1;
        }
        memcpy(buf, RSTRING_PTR(rstr), cnt);
        buf[cnt] = '\0';
    } else {
        cnt = oj_dump_float_printf(buf, sizeof(buf), obj, d, out->opts->float_fmt);
    }
    assure_size(out, cnt);
    APPEND_CHARS(out->cur, buf, cnt);
    *out->cur = '\0';
}

size_t oj_dump_float_printf(char *buf, size_t blen, VALUE obj, double d, const char *format) {
    size_t cnt = snprintf(buf, blen, format, d);

    // Round off issues at 16 significant digits so check for obvious ones of
    // 0001 and 9999.
    if (17 <= cnt && (0 == strcmp("0001", buf + cnt - 4) || 0 == strcmp("9999", buf + cnt - 4))) {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        strcpy(buf, RSTRING_PTR(rstr));
        cnt = RSTRING_LEN(rstr);
    }
    return cnt;
}
