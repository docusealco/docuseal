#include <ruby.h>
#include <ruby/encoding.h>
#include <time.h>
#include <limits.h>

#include "trilogy-ruby.h"

#define CAST_STACK_SIZE 64

static ID id_BigDecimal, id_Integer, id_new, id_local;

static const char *ruby_encoding_name_map[] = {
    [TRILOGY_ENCODING_ARMSCII8] = NULL,
    [TRILOGY_ENCODING_ASCII] = "US-ASCII",
    [TRILOGY_ENCODING_BIG5] = "Big5",
    [TRILOGY_ENCODING_BINARY] = "BINARY",
    [TRILOGY_ENCODING_CP1250] = "Windows-1250",
    [TRILOGY_ENCODING_CP1251] = "Windows-1251",
    [TRILOGY_ENCODING_CP1256] = "Windows-1256",
    [TRILOGY_ENCODING_CP1257] = "Windows-1257",
    [TRILOGY_ENCODING_CP850] = "CP850",
    [TRILOGY_ENCODING_CP852] = "CP852",
    [TRILOGY_ENCODING_CP866] = "IBM866",
    [TRILOGY_ENCODING_CP932] = "Windows-31J",
    [TRILOGY_ENCODING_DEC8] = NULL,
    [TRILOGY_ENCODING_EUCJPMS] = "eucJP-ms",
    [TRILOGY_ENCODING_EUCKR] = "EUC-KR",
    [TRILOGY_ENCODING_GB2312] = "GB2312",
    [TRILOGY_ENCODING_GBK] = "GBK",
    [TRILOGY_ENCODING_GEOSTD8] = NULL,
    [TRILOGY_ENCODING_GREEK] = "ISO-8859-7",
    [TRILOGY_ENCODING_HEBREW] = "ISO-8859-8",
    [TRILOGY_ENCODING_HP8] = NULL,
    [TRILOGY_ENCODING_KEYBCS2] = NULL,
    [TRILOGY_ENCODING_KOI8R] = "KOI8-R",
    [TRILOGY_ENCODING_KOI8U] = "KOI8-U",
    [TRILOGY_ENCODING_LATIN1] = "ISO-8859-1",
    [TRILOGY_ENCODING_LATIN2] = "ISO-8859-2",
    [TRILOGY_ENCODING_LATIN5] = "ISO-8859-9",
    [TRILOGY_ENCODING_LATIN7] = "ISO-8859-13",
    [TRILOGY_ENCODING_MACCE] = "macCentEuro",
    [TRILOGY_ENCODING_MACROMAN] = "macRoman",
    [TRILOGY_ENCODING_NONE] = NULL,
    [TRILOGY_ENCODING_SJIS] = "Shift_JIS",
    [TRILOGY_ENCODING_SWE7] = NULL,
    [TRILOGY_ENCODING_TIS620] = "TIS-620",
    [TRILOGY_ENCODING_UCS2] = "UTF-16BE",
    [TRILOGY_ENCODING_UJIS] = "eucJP-ms",
    [TRILOGY_ENCODING_UTF16] = "UTF-16BE",
    [TRILOGY_ENCODING_UTF32] = "UTF-32",
    [TRILOGY_ENCODING_UTF8] = "UTF-8",
    [TRILOGY_ENCODING_UTF8MB4] = "UTF-8",

    [TRILOGY_ENCODING_MAX] = NULL,
};

static rb_encoding * encoding_for_charset(TRILOGY_CHARSET_t charset)
{
    static rb_encoding * map[TRILOGY_CHARSET_MAX];

    if (RB_LIKELY(map[charset])) {
        return map[charset];
    }

    const char *encoding_name = ruby_encoding_name_map[trilogy_encoding_from_charset(charset)];
    map[charset] = rb_enc_find(encoding_name);
    if (!map[charset]) {
        map[charset] = rb_ascii8bit_encoding();
    }
    return map[charset];
}

static void cstr_from_value(char *buf, const trilogy_value_t *value, const char *errmsg)
{

    if (value->data_len > CAST_STACK_SIZE - 1) {
        rb_raise(Trilogy_CastError, errmsg, (int)value->data_len, (char *)value->data);
    }

    memcpy(buf, value->data, value->data_len);
    buf[value->data_len] = 0;
}

// For UTC: uses the Hinnant civil_to_days algorithm (C++20 std::chrono
// foundation, handles the full MySQL 1000-9999 year range without timegm).
// For local: uses mktime (standard C) which consults the system timezone.
// http://howardhinnant.github.io/date_algorithms.html
static time_t civil_to_epoch_utc(int year, int month, int day, int hour, int min, int sec)
{
    year -= (month <= 2);
    int era = (year >= 0 ? year : year - 399) / 400;
    unsigned yoe = (unsigned)(year - era * 400);
    unsigned doy = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + (unsigned)day - 1;
    unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    long days = (long)era * 146097 + (long)doe - 719468;
    return (time_t)(days * 86400 + hour * 3600 + min * 60 + sec);
}

static VALUE trilogy_make_time(int year, int month, int day, int hour, int min, int sec,
                               int usec, int local)
{
    if (local) {
        return rb_funcall(
            rb_cTime, id_local, 7,
            INT2NUM(year), INT2NUM(month), INT2NUM(day),
            INT2NUM(hour), INT2NUM(min), INT2NUM(sec),
            INT2NUM(usec)
        );
    }

    struct timespec ts = {
        .tv_sec = civil_to_epoch_utc(year, month, day, hour, min, sec),
        .tv_nsec = (long)usec * 1000,
    };
    return rb_time_timespec_new(&ts, INT_MAX - 1);
}

// Byte-arithmetic datetime parsing helpers (inspired by Go's go-sql-driver/mysql)
// These avoid sscanf overhead by parsing ASCII digits directly.

static inline int byte_to_digit(const char b)
{
    if (b < '0' || b > '9')
        return -1;
    return b - '0';
}

static inline int parse_2digits(const char *p)
{
    int d1 = byte_to_digit(p[0]);
    int d2 = byte_to_digit(p[1]);
    if (d1 < 0 || d2 < 0)
        return -1;
    return d1 * 10 + d2;
}

static inline int parse_4digits(const char *p)
{
    int d0 = byte_to_digit(p[0]);
    int d1 = byte_to_digit(p[1]);
    int d2 = byte_to_digit(p[2]);
    int d3 = byte_to_digit(p[3]);
    if (d0 < 0 || d1 < 0 || d2 < 0 || d3 < 0)
        return -1;
    return d0 * 1000 + d1 * 100 + d2 * 10 + d3;
}

// Parse 1-6 fractional digits into microseconds (6-digit value).
// "1"       => 100000
// "12"      => 120000
// "123"     => 123000
// "123456"  => 123456
static inline int parse_microseconds(const char *p, size_t len)
{
    int usec = 0;
    int multiplier = 100000;
    for (size_t i = 0; i < len && i < 6; i++) {
        int d = byte_to_digit(p[i]);
        if (d < 0)
            return -1;
        usec += d * multiplier;
        multiplier /= 10;
    }
    return usec;
}

static unsigned long long ull_from_buf(const char *digits, size_t len)
{
    if (!len)
        return 0;

    unsigned long long val = 0;

    while (len--) {
        unsigned digit = *digits++ - '0';
        val = val * 10 + digit;
    }

    return val;
}

static long long ll_from_buf(const char *digits, size_t len)
{
    if (!len)
        return 0;

    if (digits[0] == '-') {
        return -(long long)ull_from_buf(&digits[1], len - 1);
    } else {
        return (long long)ull_from_buf(digits, len);
    }
}

VALUE
rb_trilogy_cast_value(const trilogy_value_t *value, const struct column_info *column,
                      const struct rb_trilogy_cast_options *options)
{
    if (value->is_null) {
        return Qnil;
    }

    if (options->cast) {
        switch (column->type) {
        case TRILOGY_TYPE_BIT: {
            if (options->cast_booleans && column->len == 1) {
                return *(const char *)value->data == 1 ? Qtrue : Qfalse;
            }
            break;
        }
        case TRILOGY_TYPE_TINY: {
            if (options->cast_booleans && column->len == 1) {
                return *(const char *)value->data != '0' ? Qtrue : Qfalse;
            }
            /* fall through */
        }
        case TRILOGY_TYPE_SHORT:
        case TRILOGY_TYPE_LONG:
        case TRILOGY_TYPE_LONGLONG:
        case TRILOGY_TYPE_INT24:
        case TRILOGY_TYPE_YEAR: {
            if (column->flags & TRILOGY_COLUMN_FLAG_UNSIGNED) {
                unsigned long long num = ull_from_buf(value->data, value->data_len);
                return ULL2NUM(num);
            } else {
                long long num = ll_from_buf(value->data, value->data_len);
                return LL2NUM(num);
            }
        }
        case TRILOGY_TYPE_DECIMAL:
        case TRILOGY_TYPE_NEWDECIMAL: {
            // TODO - optimize so we don't have to allocate a ruby string for
            // decimal columns
            VALUE str = rb_str_new(value->data, value->data_len);
            if (column->decimals == 0 && !options->cast_decimals_to_bigdecimals) {
                return rb_funcall(rb_mKernel, id_Integer, 1, str);
            } else {
                return rb_funcall(rb_mKernel, id_BigDecimal, 1, str);
            }
        }
        case TRILOGY_TYPE_FLOAT:
        case TRILOGY_TYPE_DOUBLE: {
            char cstr[CAST_STACK_SIZE];
            cstr_from_value(cstr, value, "Invalid double value: %.*s");

            char *err;
            double dbl = strtod(cstr, &err);

            if (*err != 0) {
                rb_raise(Trilogy_CastError, "Invalid double value: %.*s", (int)value->data_len, (char *)value->data);
            }
            return rb_float_new(dbl);
        }
        case TRILOGY_TYPE_TIMESTAMP:
        case TRILOGY_TYPE_DATETIME: {
            const char *p = (const char *)value->data;
            size_t len = value->data_len;
            int year, month, day, hour = 0, min = 0, sec = 0, usec = 0;

            // Length-based dispatch like Go's parseDateTime:
            // 10 = "YYYY-MM-DD"
            // 19 = "YYYY-MM-DD HH:MM:SS"
            // 21-26 = "YYYY-MM-DD HH:MM:SS.F" through "YYYY-MM-DD HH:MM:SS.FFFFFF"
            if (len < 10)
                return Qnil;

            year = parse_4digits(p);
            if (year < 0 || p[4] != '-')
                return Qnil;

            month = parse_2digits(p + 5);
            if (month < 0 || p[7] != '-')
                return Qnil;

            day = parse_2digits(p + 8);
            if (day < 0)
                return Qnil;

            if (len >= 19) {
                if (p[10] != ' ')
                    return Qnil;

                hour = parse_2digits(p + 11);
                if (hour < 0 || p[13] != ':')
                    return Qnil;

                min = parse_2digits(p + 14);
                if (min < 0 || p[16] != ':')
                    return Qnil;

                sec = parse_2digits(p + 17);
                if (sec < 0)
                    return Qnil;

                if (len > 19) {
                    if (p[19] != '.' || len < 21 || len > 26)
                        return Qnil;

                    usec = parse_microseconds(p + 20, len - 20);
                    if (usec < 0)
                        return Qnil;
                }
            } else if (len != 10) {
                return Qnil;
            }

            if (year == 0 && month == 0 && day == 0 && hour == 0 && min == 0 && sec == 0) {
                return Qnil;
            }

            if (month < 1 || day < 1) {
                rb_raise(Trilogy_CastError, "Invalid date: %.*s", (int)value->data_len, (char *)value->data);
            }

            return trilogy_make_time(year, month, day, hour, min, sec, usec,
                                    options->database_local_time);
        }
        case TRILOGY_TYPE_DATE: {
            const char *p = (const char *)value->data;
            size_t len = value->data_len;

            if (len != 10)
                return Qnil;

            int year = parse_4digits(p);
            if (year < 0 || p[4] != '-')
                return Qnil;

            int month = parse_2digits(p + 5);
            if (month < 0 || p[7] != '-')
                return Qnil;

            int day = parse_2digits(p + 8);
            if (day < 0)
                return Qnil;

            VALUE Date = rb_const_get(rb_cObject, rb_intern("Date"));

            if (year == 0 && month == 0 && day == 0) {
                return Qnil;
            }

            if (month < 1 || day < 1) {
                rb_raise(Trilogy_CastError, "Invalid date: %.*s", (int)value->data_len, (char *)value->data);
            }

            return rb_funcall(Date, id_new, 3, INT2NUM(year), INT2NUM(month), INT2NUM(day));
        }
        case TRILOGY_TYPE_TIME: {
            const char *p = (const char *)value->data;
            size_t len = value->data_len;

            // Expected: "HH:MM:SS" (8) or "HH:MM:SS.F" through "HH:MM:SS.FFFFFF" (10-15)
            if (len < 8)
                return Qnil;

            int hour = parse_2digits(p);
            if (hour < 0 || p[2] != ':')
                return Qnil;

            int min = parse_2digits(p + 3);
            if (min < 0 || p[5] != ':')
                return Qnil;

            int sec = parse_2digits(p + 6);
            if (sec < 0)
                return Qnil;

            int usec = 0;
            if (len > 8) {
                if (p[8] != '.' || len < 10 || len > 15)
                    return Qnil;

                usec = parse_microseconds(p + 9, len - 9);
                if (usec < 0)
                    return Qnil;
            }

            return trilogy_make_time(2000, 1, 1, hour, min, sec, usec,
                                    options->database_local_time);
        }
        default:
            break;
        }
    }

    // for all other types, just return a string
    return rb_enc_str_new(value->data, value->data_len, encoding_for_charset(column->charset));
}

void rb_trilogy_cast_init(void)
{
    rb_require("bigdecimal");
    rb_require("date");

    id_BigDecimal = rb_intern("BigDecimal");
    id_Integer = rb_intern("Integer");
    id_new = rb_intern("new");
    id_local = rb_intern("local");
}
