#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/blocking.c"
#include <errno.h>
#include <poll.h>

#include "trilogy/blocking.h"
#include "trilogy/client.h"
#include "trilogy/error.h"

#define CHECKED(expr)                                                                                                  \
    if ((rc = (expr)) < 0) {                                                                                           \
        return rc;                                                                                                     \
    }

static int flush_full(trilogy_conn_t *conn)
{
    int rc;

    while (1) {
        CHECKED(trilogy_sock_wait_write(conn->socket));

        rc = trilogy_flush_writes(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }
    }
}

static int trilogy_connect_auth_switch(trilogy_conn_t *conn, trilogy_handshake_t *handshake)
{
    int rc = trilogy_auth_switch_send(conn, handshake);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_auth_recv(conn, handshake);

        if (rc != TRILOGY_AGAIN) {
            break;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
    return rc;
}

static int trilogy_connect_handshake(trilogy_conn_t *conn)
{
    trilogy_handshake_t handshake;
    int rc;

    while (1) {
        rc = trilogy_connect_recv(conn, &handshake);

        if (rc == TRILOGY_OK) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }

    rc = trilogy_auth_send(conn, &handshake);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_auth_recv(conn, &handshake);

        if (rc != TRILOGY_AGAIN) {
            break;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }

    if (rc == TRILOGY_AUTH_SWITCH) {
        return trilogy_connect_auth_switch(conn, &handshake);
    }
    return rc;
}

int trilogy_connect(trilogy_conn_t *conn, const trilogy_sockopt_t *opts)
{
    int rc = trilogy_connect_send(conn, opts);

    if (rc < 0) {
        return rc;
    }

    return trilogy_connect_handshake(conn);
}

int trilogy_connect_sock(trilogy_conn_t *conn, trilogy_sock_t *sock)
{
    int rc = trilogy_connect_send_socket(conn, sock);

    if (rc < 0) {
        return rc;
    }

    return trilogy_connect_handshake(conn);
}

int trilogy_change_db(trilogy_conn_t *conn, const char *name, size_t name_len)
{
    int rc = trilogy_change_db_send(conn, name, name_len);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_change_db_recv(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_set_option(trilogy_conn_t *conn, const uint16_t option)
{
    int rc = trilogy_set_option_send(conn, option);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_set_option_recv(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_ping(trilogy_conn_t *conn)
{
    int rc = trilogy_ping_send(conn);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_ping_recv(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_query(trilogy_conn_t *conn, const char *query, size_t query_len, uint64_t *column_count_out)
{
    int rc = trilogy_query_send(conn, query, query_len);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_query_recv(conn, column_count_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_read_full_column(trilogy_conn_t *conn, trilogy_column_t *column_out)
{
    int rc;

    while (1) {
        rc = trilogy_read_column(conn, column_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_read_full_row(trilogy_conn_t *conn, trilogy_value_t *values_out)
{
    int rc;

    while (1) {
        rc = trilogy_read_row(conn, values_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_close(trilogy_conn_t *conn)
{
    int rc = trilogy_close_send(conn);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_close_recv(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_stmt_prepare(trilogy_conn_t *conn, const char *stmt, size_t stmt_len, trilogy_stmt_t *stmt_out)
{
    int rc = trilogy_stmt_prepare_send(conn, stmt, stmt_len);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_stmt_prepare_recv(conn, stmt_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_stmt_execute(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint8_t flags, trilogy_binary_value_t *binds,
                         uint64_t *column_count_out)
{
    int rc = trilogy_stmt_execute_send(conn, stmt, flags, binds);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_stmt_execute_recv(conn, column_count_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_stmt_bind_data(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint16_t param_num, uint8_t *data,
                           size_t data_len)
{
    int rc = trilogy_stmt_bind_data_send(conn, stmt, param_num, data, data_len);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    return TRILOGY_OK;
}

int trilogy_stmt_read_full_row(trilogy_conn_t *conn, trilogy_stmt_t *stmt, trilogy_column_packet_t *columns,
                               trilogy_binary_value_t *values_out)
{
    int rc;

    while (1) {
        rc = trilogy_stmt_read_row(conn, stmt, columns, values_out);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_stmt_reset(trilogy_conn_t *conn, trilogy_stmt_t *stmt)
{
    int rc = trilogy_stmt_reset_send(conn, stmt);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    while (1) {
        rc = trilogy_stmt_reset_recv(conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        CHECKED(trilogy_sock_wait_read(conn->socket));
    }
}

int trilogy_stmt_close(trilogy_conn_t *conn, trilogy_stmt_t *stmt)
{
    int rc = trilogy_stmt_close_send(conn, stmt);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_full(conn);
    }

    if (rc < 0) {
        return rc;
    }

    return TRILOGY_OK;
}

#undef CHECKED
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/buffer.c"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "trilogy/allocator.h"
#include "trilogy/buffer.h"
#include "trilogy/error.h"

int trilogy_buffer_init(trilogy_buffer_t *buffer, size_t initial_capacity)
{
    buffer->len = 0;
    buffer->cap = initial_capacity;
    buffer->buff = xmalloc(initial_capacity);

    if (buffer->buff == NULL) {
        return TRILOGY_SYSERR;
    }

    return TRILOGY_OK;
}

#define EXPAND_MULTIPLIER 2

int trilogy_buffer_expand(trilogy_buffer_t *buffer, size_t needed)
{
    // expand buffer if necessary
    if (buffer->len + needed > buffer->cap) {
        if (buffer->buff == NULL)
            return TRILOGY_MEM_ERROR;

        size_t new_cap = buffer->cap;

        while (buffer->len + needed > new_cap) {
            // would this next step cause an overflow?
            if (new_cap > SIZE_MAX / EXPAND_MULTIPLIER)
                return TRILOGY_TYPE_OVERFLOW;

            new_cap *= EXPAND_MULTIPLIER;
        }

        uint8_t *new_buff = xrealloc(buffer->buff, new_cap);
        if (new_buff == NULL)
            return TRILOGY_SYSERR;

        buffer->buff = new_buff;
        buffer->cap = new_cap;
    }

    return TRILOGY_OK;
}

int trilogy_buffer_putc(trilogy_buffer_t *buffer, uint8_t c)
{
    int rc = trilogy_buffer_expand(buffer, 1);

    if (rc) {
        return rc;
    }

    buffer->buff[buffer->len++] = c;

    return TRILOGY_OK;
}

int trilogy_buffer_write(trilogy_buffer_t *buffer, const uint8_t *ptr, size_t len)
{
    int rc = trilogy_buffer_expand(buffer, len);
    if (rc) {
        return rc;
    }

    memcpy(buffer->buff + buffer->len, ptr, len);
    buffer->len += len;

    return TRILOGY_OK;
}

void trilogy_buffer_free(trilogy_buffer_t *buffer)
{
    if (buffer->buff) {
        xfree(buffer->buff);
        buffer->buff = NULL;
        buffer->len = buffer->cap = 0;
    }
}
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/builder.c"
#include "trilogy/builder.h"
#include "trilogy/error.h"
#include "trilogy/packet_parser.h"

#include <stdlib.h>
#include <string.h>

static int write_header(trilogy_builder_t *builder)
{
    int rc = trilogy_buffer_expand(builder->buffer, 4);

    if (rc < 0) {
        return rc;
    }

    builder->header_offset = builder->buffer->len;
    builder->fragment_length = 0;

    builder->buffer->buff[builder->buffer->len++] = 0;
    builder->buffer->buff[builder->buffer->len++] = 0;
    builder->buffer->buff[builder->buffer->len++] = 0;
    builder->buffer->buff[builder->buffer->len++] = builder->seq++;

    return TRILOGY_OK;
}

static int write_continuation_header(trilogy_builder_t *builder)
{
    builder->buffer->buff[builder->header_offset] = 0xff;
    builder->buffer->buff[builder->header_offset + 1] = 0xff;
    builder->buffer->buff[builder->header_offset + 2] = 0xff;

    return write_header(builder);
}

int trilogy_builder_init(trilogy_builder_t *builder, trilogy_buffer_t *buff, uint8_t seq)
{
    builder->buffer = buff;
    builder->buffer->len = 0;

    builder->seq = seq;
    builder->packet_length = 0;
    builder->packet_max_length = SIZE_MAX;

    return write_header(builder);
}

void trilogy_builder_finalize(trilogy_builder_t *builder)
{
    builder->buffer->buff[builder->header_offset + 0] = (builder->fragment_length >> 0) & 0xff;
    builder->buffer->buff[builder->header_offset + 1] = (builder->fragment_length >> 8) & 0xff;
    builder->buffer->buff[builder->header_offset + 2] = (builder->fragment_length >> 16) & 0xff;
}

#define CHECKED(expr)                                                                                                  \
    {                                                                                                                  \
        int rc = (expr);                                                                                               \
        if (rc) {                                                                                                      \
            return rc;                                                                                                 \
        }                                                                                                              \
    }

int trilogy_builder_write_uint8(trilogy_builder_t *builder, uint8_t val)
{
    if (builder->packet_length >= builder->packet_max_length - 1) {
        return TRILOGY_MAX_PACKET_EXCEEDED;
    }

    CHECKED(trilogy_buffer_expand(builder->buffer, 1));

    builder->buffer->buff[builder->buffer->len++] = val;
    builder->fragment_length++;
    builder->packet_length++;

    if (builder->fragment_length == TRILOGY_MAX_PACKET_LEN) {
        CHECKED(write_continuation_header(builder));
    }

    return TRILOGY_OK;
}

int trilogy_builder_write_uint16(trilogy_builder_t *builder, uint16_t val)
{
    CHECKED(trilogy_builder_write_uint8(builder, val & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 8) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_uint24(trilogy_builder_t *builder, uint32_t val)
{
    CHECKED(trilogy_builder_write_uint8(builder, val & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 8) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 16) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_uint32(trilogy_builder_t *builder, uint32_t val)
{
    CHECKED(trilogy_builder_write_uint8(builder, val & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 8) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 16) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 24) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_uint64(trilogy_builder_t *builder, uint64_t val)
{
    CHECKED(trilogy_builder_write_uint8(builder, val & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 8) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 16) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 24) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 32) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 40) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 48) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (val >> 56) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_float(trilogy_builder_t *builder, float val)
{
    union {
        float f;
        uint32_t u;
    } float_val;

    float_val.f = val;

    CHECKED(trilogy_builder_write_uint8(builder, float_val.u & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (float_val.u >> 8) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (float_val.u >> 16) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (float_val.u >> 24) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_double(trilogy_builder_t *builder, double val)
{
    union {
        double d;
        uint64_t u;
    } double_val;

    double_val.d = val;

    CHECKED(trilogy_builder_write_uint8(builder, double_val.u & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 8) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 16) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 24) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 32) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 40) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 48) & 0xff));
    CHECKED(trilogy_builder_write_uint8(builder, (double_val.u >> 56) & 0xff));

    return TRILOGY_OK;
}

int trilogy_builder_write_lenenc(trilogy_builder_t *builder, uint64_t val)
{
    if (val < 251) {
        CHECKED(trilogy_builder_write_uint8(builder, (uint8_t)val));
    } else if (val <= 0xffff) {
        CHECKED(trilogy_builder_write_uint8(builder, 0xfc));
        CHECKED(trilogy_builder_write_uint16(builder, (uint16_t)val));
    } else if (val <= 0xffffff) {
        CHECKED(trilogy_builder_write_uint8(builder, 0xfd));
        CHECKED(trilogy_builder_write_uint24(builder, (uint32_t)val));
    } else { // val <= 0xffffffffffffffff
        CHECKED(trilogy_builder_write_uint8(builder, 0xfe));
        CHECKED(trilogy_builder_write_uint64(builder, val));
    }

    return TRILOGY_OK;
}

int trilogy_builder_write_buffer(trilogy_builder_t *builder, const void *data, size_t len)
{
    const char *ptr = data;

    size_t fragment_remaining = TRILOGY_MAX_PACKET_LEN - builder->fragment_length;

    if (builder->packet_length + len >= builder->packet_max_length) {
        return TRILOGY_MAX_PACKET_EXCEEDED;
    }

    // if this buffer write is not going to straddle a fragment boundary:
    if (len < fragment_remaining) {
        CHECKED(trilogy_buffer_expand(builder->buffer, len));

        memcpy(builder->buffer->buff + builder->buffer->len, ptr, len);

        builder->buffer->len += len;
        builder->fragment_length += len;
        builder->packet_length += len;

        return TRILOGY_OK;
    }

    // otherwise we're going to need to do this in multiple
    while (len >= fragment_remaining) {
        CHECKED(trilogy_buffer_expand(builder->buffer, fragment_remaining));

        memcpy(builder->buffer->buff + builder->buffer->len, ptr, fragment_remaining);

        builder->buffer->len += fragment_remaining;
        builder->fragment_length += fragment_remaining;
        builder->packet_length += fragment_remaining;

        ptr += fragment_remaining;
        len -= fragment_remaining;

        CHECKED(write_continuation_header(builder));
        fragment_remaining = TRILOGY_MAX_PACKET_LEN;
    }

    if (len) {
        CHECKED(trilogy_buffer_expand(builder->buffer, len));

        memcpy(builder->buffer->buff + builder->buffer->len, ptr, len);

        builder->buffer->len += len;
        builder->fragment_length += len;
        builder->packet_length += len;
    }

    return TRILOGY_OK;
}

int trilogy_builder_write_lenenc_buffer(trilogy_builder_t *builder, const void *data, size_t len)
{
    CHECKED(trilogy_builder_write_lenenc(builder, len));

    CHECKED(trilogy_builder_write_buffer(builder, data, len));

    return TRILOGY_OK;
}

int trilogy_builder_write_string(trilogy_builder_t *builder, const char *data)
{
    CHECKED(trilogy_builder_write_buffer(builder, (void *)data, strlen(data)));

    CHECKED(trilogy_builder_write_uint8(builder, 0));

    return TRILOGY_OK;
}

int trilogy_builder_set_max_packet_length(trilogy_builder_t *builder, size_t max_length)
{
    if (builder->packet_length > max_length) {
        return TRILOGY_MAX_PACKET_EXCEEDED;
    }

    builder->packet_max_length = max_length;

    return TRILOGY_OK;
}

#undef CHECKED
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/charset.c"
#include "trilogy/charset.h"

static TRILOGY_ENCODING_t charset_to_encoding_map[] = {
    [TRILOGY_CHARSET_NONE] = TRILOGY_ENCODING_NONE,
    [TRILOGY_CHARSET_BIG5_CHINESE_CI] = TRILOGY_ENCODING_BIG5,
    [TRILOGY_CHARSET_BIG5_BIN] = TRILOGY_ENCODING_BIG5,
    [TRILOGY_CHARSET_LATIN2_CZECH_CS] = TRILOGY_ENCODING_LATIN2,
    [TRILOGY_CHARSET_LATIN2_GENERAL_CI] = TRILOGY_ENCODING_LATIN2,
    [TRILOGY_CHARSET_LATIN2_HUNGARIAN_CI] = TRILOGY_ENCODING_LATIN2,
    [TRILOGY_CHARSET_LATIN2_CROATIAN_CI] = TRILOGY_ENCODING_LATIN2,
    [TRILOGY_CHARSET_LATIN2_BIN] = TRILOGY_ENCODING_LATIN2,
    [TRILOGY_CHARSET_DEC8_SWEDISH_CI] = TRILOGY_ENCODING_DEC8,
    [TRILOGY_CHARSET_DEC8_BIN] = TRILOGY_ENCODING_DEC8,
    [TRILOGY_CHARSET_CP850_GENERAL_CI] = TRILOGY_ENCODING_CP850,
    [TRILOGY_CHARSET_CP850_BIN] = TRILOGY_ENCODING_CP850,
    [TRILOGY_CHARSET_LATIN1_GERMAN1_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_SWEDISH_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_DANISH_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_GERMAN2_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_BIN] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_GENERAL_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_GENERAL_CS] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_LATIN1_SPANISH_CI] = TRILOGY_ENCODING_LATIN1,
    [TRILOGY_CHARSET_HP8_ENGLISH_CI] = TRILOGY_ENCODING_HP8,
    [TRILOGY_CHARSET_HP8_BIN] = TRILOGY_ENCODING_HP8,
    [TRILOGY_CHARSET_KOI8R_GENERAL_CI] = TRILOGY_ENCODING_KOI8R,
    [TRILOGY_CHARSET_KOI8R_BIN] = TRILOGY_ENCODING_KOI8R,
    [TRILOGY_CHARSET_SWE7_SWEDISH_CI] = TRILOGY_ENCODING_SWE7,
    [TRILOGY_CHARSET_SWE7_BIN] = TRILOGY_ENCODING_SWE7,
    [TRILOGY_CHARSET_ASCII_GENERAL_CI] = TRILOGY_ENCODING_ASCII,
    [TRILOGY_CHARSET_ASCII_BIN] = TRILOGY_ENCODING_ASCII,
    [TRILOGY_CHARSET_UJIS_JAPANESE_CI] = TRILOGY_ENCODING_UJIS,
    [TRILOGY_CHARSET_UJIS_BIN] = TRILOGY_ENCODING_UJIS,
    [TRILOGY_CHARSET_SJIS_JAPANESE_CI] = TRILOGY_ENCODING_SJIS,
    [TRILOGY_CHARSET_SJIS_BIN] = TRILOGY_ENCODING_SJIS,
    [TRILOGY_CHARSET_CP1251_BULGARIAN_CI] = TRILOGY_ENCODING_CP1251,
    [TRILOGY_CHARSET_CP1251_UKRAINIAN_CI] = TRILOGY_ENCODING_CP1251,
    [TRILOGY_CHARSET_CP1251_BIN] = TRILOGY_ENCODING_CP1251,
    [TRILOGY_CHARSET_CP1251_GENERAL_CI] = TRILOGY_ENCODING_CP1251,
    [TRILOGY_CHARSET_CP1251_GENERAL_CS] = TRILOGY_ENCODING_CP1251,
    [TRILOGY_CHARSET_HEBREW_GENERAL_CI] = TRILOGY_ENCODING_HEBREW,
    [TRILOGY_CHARSET_HEBREW_BIN] = TRILOGY_ENCODING_HEBREW,
    [TRILOGY_CHARSET_TIS620_THAI_CI] = TRILOGY_ENCODING_TIS620,
    [TRILOGY_CHARSET_TIS620_BIN] = TRILOGY_ENCODING_TIS620,
    [TRILOGY_CHARSET_EUCKR_KOREAN_CI] = TRILOGY_ENCODING_EUCKR,
    [TRILOGY_CHARSET_EUCKR_BIN] = TRILOGY_ENCODING_EUCKR,
    [TRILOGY_CHARSET_LATIN7_ESTONIAN_CS] = TRILOGY_ENCODING_LATIN7,
    [TRILOGY_CHARSET_LATIN7_GENERAL_CI] = TRILOGY_ENCODING_LATIN7,
    [TRILOGY_CHARSET_LATIN7_GENERAL_CS] = TRILOGY_ENCODING_LATIN7,
    [TRILOGY_CHARSET_LATIN7_BIN] = TRILOGY_ENCODING_LATIN7,
    [TRILOGY_CHARSET_KOI8U_GENERAL_CI] = TRILOGY_ENCODING_KOI8U,
    [TRILOGY_CHARSET_KOI8U_BIN] = TRILOGY_ENCODING_KOI8U,
    [TRILOGY_CHARSET_GB2312_CHINESE_CI] = TRILOGY_ENCODING_GB2312,
    [TRILOGY_CHARSET_GB2312_BIN] = TRILOGY_ENCODING_GB2312,
    [TRILOGY_CHARSET_GREEK_GENERAL_CI] = TRILOGY_ENCODING_GREEK,
    [TRILOGY_CHARSET_GREEK_BIN] = TRILOGY_ENCODING_GREEK,
    [TRILOGY_CHARSET_CP1250_GENERAL_CI] = TRILOGY_ENCODING_CP1250,
    [TRILOGY_CHARSET_CP1250_CZECH_CS] = TRILOGY_ENCODING_CP1250,
    [TRILOGY_CHARSET_CP1250_CROATIAN_CI] = TRILOGY_ENCODING_CP1250,
    [TRILOGY_CHARSET_CP1250_BIN] = TRILOGY_ENCODING_CP1250,
    [TRILOGY_CHARSET_CP1250_POLISH_CI] = TRILOGY_ENCODING_CP1250,
    [TRILOGY_CHARSET_GBK_CHINESE_CI] = TRILOGY_ENCODING_GBK,
    [TRILOGY_CHARSET_GBK_BIN] = TRILOGY_ENCODING_GBK,
    [TRILOGY_CHARSET_GB18030_CHINESE_CI] = TRILOGY_ENCODING_GBK,
    [TRILOGY_CHARSET_GB18030_BIN_CI] = TRILOGY_ENCODING_GBK,
    [TRILOGY_CHARSET_GB18030_UNICODE_520_CI] = TRILOGY_ENCODING_GBK,
    [TRILOGY_CHARSET_CP1257_LITHUANIAN_CI] = TRILOGY_ENCODING_CP1257,
    [TRILOGY_CHARSET_CP1257_BIN] = TRILOGY_ENCODING_CP1257,
    [TRILOGY_CHARSET_CP1257_GENERAL_CI] = TRILOGY_ENCODING_CP1257,
    [TRILOGY_CHARSET_LATIN5_TURKISH_CI] = TRILOGY_ENCODING_LATIN5,
    [TRILOGY_CHARSET_LATIN5_BIN] = TRILOGY_ENCODING_LATIN5,
    [TRILOGY_CHARSET_ARMSCII8_GENERAL_CI] = TRILOGY_ENCODING_ARMSCII8,
    [TRILOGY_CHARSET_ARMSCII8_BIN] = TRILOGY_ENCODING_ARMSCII8,
    [TRILOGY_CHARSET_UTF8_GENERAL_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_BIN] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_UNICODE_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_ICELANDIC_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_LATVIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_ROMANIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SLOVENIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_POLISH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_ESTONIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SPANISH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SWEDISH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_TURKISH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_CZECH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_DANISH_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_LITHUANIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SLOVAK_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SPANISH2_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_ROMAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_PERSIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_ESPERANTO_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_HUNGARIAN_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_SINHALA_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UTF8_GENERAL_MYSQL500_CI] = TRILOGY_ENCODING_UTF8,
    [TRILOGY_CHARSET_UCS2_GENERAL_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_BIN] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_UNICODE_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_ICELANDIC_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_LATVIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_ROMANIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SLOVENIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_POLISH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_ESTONIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SPANISH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SWEDISH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_TURKISH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_CZECH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_DANISH_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_LITHUANIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SLOVAK_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SPANISH2_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_ROMAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_PERSIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_ESPERANTO_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_HUNGARIAN_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_SINHALA_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_UCS2_GENERAL_MYSQL500_CI] = TRILOGY_ENCODING_UCS2,
    [TRILOGY_CHARSET_CP866_GENERAL_CI] = TRILOGY_ENCODING_CP866,
    [TRILOGY_CHARSET_CP866_BIN] = TRILOGY_ENCODING_CP866,
    [TRILOGY_CHARSET_KEYBCS2_GENERAL_CI] = TRILOGY_ENCODING_KEYBCS2,
    [TRILOGY_CHARSET_KEYBCS2_BIN] = TRILOGY_ENCODING_KEYBCS2,
    [TRILOGY_CHARSET_MACCE_GENERAL_CI] = TRILOGY_ENCODING_MACCE,
    [TRILOGY_CHARSET_MACCE_BIN] = TRILOGY_ENCODING_MACCE,
    [TRILOGY_CHARSET_MACROMAN_GENERAL_CI] = TRILOGY_ENCODING_MACROMAN,
    [TRILOGY_CHARSET_MACROMAN_BIN] = TRILOGY_ENCODING_MACROMAN,
    [TRILOGY_CHARSET_CP852_GENERAL_CI] = TRILOGY_ENCODING_CP852,
    [TRILOGY_CHARSET_CP852_BIN] = TRILOGY_ENCODING_CP852,
    [TRILOGY_CHARSET_UTF8MB4_GENERAL_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_BIN] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_UNICODE_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_ICELANDIC_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_LATVIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_ROMANIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SLOVENIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_POLISH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_ESTONIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SPANISH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SWEDISH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_TURKISH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_CZECH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_DANISH_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_LITHUANIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SLOVAK_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SPANISH2_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_ROMAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_PERSIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_ESPERANTO_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_HUNGARIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_SINHALA_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_GERMAN2_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_CROATIAN_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_UNICODE_520_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_VIETNAMESE_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF8MB4_0900_AI_CI] = TRILOGY_ENCODING_UTF8MB4,
    [TRILOGY_CHARSET_UTF16_GENERAL_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_BIN] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_UNICODE_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_ICELANDIC_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_LATVIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_ROMANIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SLOVENIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_POLISH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_ESTONIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SPANISH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SWEDISH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_TURKISH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_CZECH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_DANISH_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_LITHUANIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SLOVAK_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SPANISH2_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_ROMAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_PERSIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_ESPERANTO_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_HUNGARIAN_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_UTF16_SINHALA_CI] = TRILOGY_ENCODING_UTF16,
    [TRILOGY_CHARSET_CP1256_GENERAL_CI] = TRILOGY_ENCODING_CP1256,
    [TRILOGY_CHARSET_CP1256_BIN] = TRILOGY_ENCODING_CP1256,
    [TRILOGY_CHARSET_UTF32_GENERAL_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_BIN] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_UNICODE_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_ICELANDIC_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_LATVIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_ROMANIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SLOVENIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_POLISH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_ESTONIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SPANISH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SWEDISH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_TURKISH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_CZECH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_DANISH_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_LITHUANIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SLOVAK_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SPANISH2_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_ROMAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_PERSIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_ESPERANTO_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_HUNGARIAN_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_UTF32_SINHALA_CI] = TRILOGY_ENCODING_UTF32,
    [TRILOGY_CHARSET_BINARY] = TRILOGY_ENCODING_BINARY,
    [TRILOGY_CHARSET_GEOSTD8_GENERAL_CI] = TRILOGY_ENCODING_GEOSTD8,
    [TRILOGY_CHARSET_GEOSTD8_BIN] = TRILOGY_ENCODING_GEOSTD8,
    [TRILOGY_CHARSET_CP932_JAPANESE_CI] = TRILOGY_ENCODING_CP932,
    [TRILOGY_CHARSET_CP932_BIN] = TRILOGY_ENCODING_CP932,
    [TRILOGY_CHARSET_EUCJPMS_JAPANESE_CI] = TRILOGY_ENCODING_EUCJPMS,
    [TRILOGY_CHARSET_EUCJPMS_BIN] = TRILOGY_ENCODING_EUCJPMS,
};

TRILOGY_ENCODING_t trilogy_encoding_from_charset(TRILOGY_CHARSET_t charset) { return charset_to_encoding_map[charset]; }
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/client.c"
#include <fcntl.h>
#include <limits.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <stdlib.h>
#include <string.h>

#include "trilogy/allocator.h"
#include "trilogy/client.h"
#include "trilogy/error.h"

#define CHECKED(expr)                                                                                                  \
    if ((rc = (expr)) < 0) {                                                                                           \
        return rc;                                                                                                     \
    }

static inline TRILOGY_PACKET_TYPE_t current_packet_type(trilogy_conn_t *conn)
{
    return (TRILOGY_PACKET_TYPE_t)conn->packet_buffer.buff[0];
}

static int on_packet_begin(void *opaque)
{
    trilogy_buffer_t *buff = opaque;

    buff->len = 0;

    return 0;
}

static int on_packet_data(void *opaque, const uint8_t *data, size_t len)
{
    trilogy_buffer_t *buff = opaque;
    int rc = TRILOGY_OK;

    rc = trilogy_buffer_expand(buff, len);
    if (rc < 0)
        return rc;

    memcpy(buff->buff + buff->len, data, len);
    buff->len += len;

    return 0;
}

static int on_packet_end(void *opaque)
{
    (void)opaque;

    // pause packet parsing so we can return the packet we just read to the
    // caller
    return 1;
}

static trilogy_packet_parser_callbacks_t packet_parser_callbacks = {
    .on_packet_begin = on_packet_begin,
    .on_packet_data = on_packet_data,
    .on_packet_end = on_packet_end,
};

static int begin_command_phase(trilogy_builder_t *builder, trilogy_conn_t *conn, uint8_t seq)
{
    int rc = trilogy_builder_init(builder, &conn->packet_buffer, seq);
    if (rc < 0) {
        return rc;
    }

    if (conn->socket->opts.max_allowed_packet > 0) {
        trilogy_builder_set_max_packet_length(builder, conn->socket->opts.max_allowed_packet);
    }

    conn->packet_parser.sequence_number = seq + 1;

    return 0;
}

static int read_packet(trilogy_conn_t *conn)
{
    if (conn->recv_buff_pos == conn->recv_buff_len) {
        ssize_t nread = trilogy_sock_read(conn->socket, conn->recv_buff, sizeof(conn->recv_buff));

        if (nread < 0) {
            int rc = (int)nread;
            return rc;
        }

        if (nread == 0) {
            return TRILOGY_CLOSED_CONNECTION;
        }

        conn->recv_buff_len = (size_t)nread;
        conn->recv_buff_pos = 0;
    }

    const uint8_t *ptr = conn->recv_buff + conn->recv_buff_pos;
    size_t len = conn->recv_buff_len - conn->recv_buff_pos;

    int rc;
    conn->recv_buff_pos += trilogy_packet_parser_execute(&conn->packet_parser, ptr, len, &rc);

    if (rc < 0) {
        // an error occurred in one of the callbacks
        return rc;
    }

    if (rc > 0) {
        // on_packet_end paused the parser, meaning we read a complete packet
        return TRILOGY_OK;
    }

    // we didn't read a complete packet yet, return TRILOGY_AGAIN so the caller
    // can retry
    return TRILOGY_AGAIN;
}

static int begin_write(trilogy_conn_t *conn)
{
    conn->packet_buffer_written = 0;

    // perform a single write(2), if this does not end up writing the entire
    // packet buffer, then we'll end up returning TRILOGY_AGAIN here and it'll be
    // up to the caller to pump trilogy_flush_writes() until it returns TRILOGY_OK
    return trilogy_flush_writes(conn);
}

static int flush_current_packet(trilogy_conn_t *conn)
{
    int rc = begin_write(conn);

    while (rc == TRILOGY_AGAIN) {
        rc = trilogy_sock_wait_write(conn->socket);

        if (rc != TRILOGY_OK) {
            return rc;
        }

        rc = trilogy_flush_writes(conn);
    }

    return rc;
}

static int read_packet_blocking(trilogy_conn_t *conn)
{
    int rc;

    while ((rc = read_packet(conn)) == TRILOGY_AGAIN) {
        rc = trilogy_sock_wait_read(conn->socket);

        if (rc != TRILOGY_OK) {
            return rc;
        }
    }

    return rc;
}

int trilogy_init_no_buffer(trilogy_conn_t *conn)
{
    conn->affected_rows = 0;
    conn->last_insert_id = 0;
    conn->warning_count = 0;
    conn->last_gtid_len = 0;

    memset(conn->last_gtid, 0, TRILOGY_MAX_LAST_GTID_LEN);
    conn->error_code = 0;
    conn->error_message = NULL;
    conn->error_message_len = 0;

    conn->capabilities = 0;
    conn->server_status = 0;

    conn->socket = NULL;

    conn->recv_buff_pos = 0;
    conn->recv_buff_len = 0;

    trilogy_packet_parser_init(&conn->packet_parser, &packet_parser_callbacks);
    conn->packet_parser.user_data = &conn->packet_buffer;

    return TRILOGY_OK;
}

int trilogy_init(trilogy_conn_t *conn)
{
    int rc;
    trilogy_init_no_buffer(conn);
    CHECKED(trilogy_buffer_init(&conn->packet_buffer, TRILOGY_DEFAULT_BUF_SIZE));
    return TRILOGY_OK;
}

int trilogy_flush_writes(trilogy_conn_t *conn)
{
    void *ptr = conn->packet_buffer.buff + conn->packet_buffer_written;
    size_t len = conn->packet_buffer.len - conn->packet_buffer_written;

    ssize_t bytes = trilogy_sock_write(conn->socket, ptr, len);

    if (bytes < 0) {
        int rc = (int)bytes;
        return rc;
    }

    conn->packet_buffer_written += (size_t)bytes;

    if (conn->packet_buffer_written < conn->packet_buffer.len) {
        return TRILOGY_AGAIN;
    }

    return TRILOGY_OK;
}

static void set_error(trilogy_conn_t *conn, const trilogy_err_packet_t *packet)
{
    conn->error_code = packet->error_code;
    conn->error_message = packet->error_message;
    conn->error_message_len = packet->error_message_len;
}

static int read_ok_packet(trilogy_conn_t *conn)
{
    trilogy_ok_packet_t ok_packet;

    int rc = trilogy_parse_ok_packet(conn->packet_buffer.buff, conn->packet_buffer.len, conn->capabilities, &ok_packet);

    if (rc != TRILOGY_OK) {
        return rc;
    }

    if (conn->capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41) {
        conn->warning_count = ok_packet.warning_count;
        conn->server_status = ok_packet.status_flags;
    }

    conn->affected_rows = ok_packet.affected_rows;
    conn->last_insert_id = ok_packet.last_insert_id;

    if (ok_packet.last_gtid_len > 0 && ok_packet.last_gtid_len < TRILOGY_MAX_LAST_GTID_LEN) {
        memcpy(conn->last_gtid, ok_packet.last_gtid, ok_packet.last_gtid_len);
        conn->last_gtid_len = ok_packet.last_gtid_len;
    }

    return TRILOGY_OK;
}

static int read_err_packet(trilogy_conn_t *conn)
{
    trilogy_err_packet_t err_packet;

    int rc =
        trilogy_parse_err_packet(conn->packet_buffer.buff, conn->packet_buffer.len, conn->capabilities, &err_packet);

    if (rc != TRILOGY_OK) {
        return rc;
    }

    set_error(conn, &err_packet);

    return TRILOGY_ERR;
}

static int read_deprecated_eof_packet(trilogy_conn_t *conn)
{
    trilogy_eof_packet_t eof_packet;

    int rc =
        trilogy_parse_eof_packet(conn->packet_buffer.buff, conn->packet_buffer.len, conn->capabilities, &eof_packet);

    if (rc != TRILOGY_OK) {
        return rc;
    }

    if (conn->capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41) {
        conn->warning_count = eof_packet.warning_count;
        conn->server_status = eof_packet.status_flags;
    }

    return TRILOGY_EOF;
}

bool is_eof_packet(trilogy_conn_t *conn)
{
    // An EOF packet first byte can mark an EOF/OK packet, a deprecated EOF packet, or a huge data packet.
    if (current_packet_type(conn) == TRILOGY_PACKET_EOF) {
        if (conn->capabilities & TRILOGY_CAPABILITIES_DEPRECATE_EOF) {
            // The EOF/OK packet can contain an info message and/or session state info up to max packet length.
            return conn->packet_buffer.len <= TRILOGY_MAX_PACKET_LEN;
        } else {
            // The deprecated EOF packet must be smaller than 9 bytes (one 8-byte length-encoded integer).
            return conn->packet_buffer.len < 9;
        }
    }
    return false;
}

static int read_eof_packet(trilogy_conn_t *conn)
{
    int rc;

    if (conn->capabilities & TRILOGY_CAPABILITIES_DEPRECATE_EOF) {
        return read_ok_packet(conn);
    } else {
        if ((rc = read_deprecated_eof_packet(conn)) != TRILOGY_EOF) {
            return rc;
        }

        return TRILOGY_OK;
    }
}

static int read_auth_switch_packet(trilogy_conn_t *conn, trilogy_handshake_t *handshake)
{
    trilogy_auth_switch_request_packet_t auth_switch_packet;

    int rc = trilogy_parse_auth_switch_request_packet(conn->packet_buffer.buff, conn->packet_buffer.len,
                                                      conn->capabilities, &auth_switch_packet);

    if (rc != TRILOGY_OK) {
        return rc;
    }

    if (strcmp("mysql_native_password", auth_switch_packet.auth_plugin) &&
        strcmp("caching_sha2_password", auth_switch_packet.auth_plugin) &&
        strcmp("mysql_clear_password", auth_switch_packet.auth_plugin)) {
        // Only support native password, caching sha2 and cleartext password here.
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    memcpy(handshake->auth_plugin, auth_switch_packet.auth_plugin, sizeof(auth_switch_packet.auth_plugin));
    memcpy(handshake->scramble, auth_switch_packet.scramble, sizeof(auth_switch_packet.scramble));
    return TRILOGY_AUTH_SWITCH;
}

static int handle_generic_response(trilogy_conn_t *conn)
{
    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_OK:
        return read_ok_packet(conn);

    case TRILOGY_PACKET_ERR:
        return read_err_packet(conn);

    default:
        return TRILOGY_UNEXPECTED_PACKET;
    }
}

static int read_generic_response(trilogy_conn_t *conn)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    return handle_generic_response(conn);
}

int trilogy_connect_send(trilogy_conn_t *conn, const trilogy_sockopt_t *opts)
{
    trilogy_sock_t *sock = trilogy_sock_new(opts);
    if (sock == NULL) {
        return TRILOGY_ERR;
    }

    int rc = trilogy_sock_resolve(sock);
    if (rc < 0) {
        return rc;
    }

    return trilogy_connect_send_socket(conn, sock);
}

int trilogy_connect_send_socket(trilogy_conn_t *conn, trilogy_sock_t *sock)
{
    int rc = trilogy_sock_connect(sock);
    if (rc < 0)
        return rc;

    conn->socket = sock;
    conn->packet_parser.sequence_number = 0;

    return TRILOGY_OK;
}

int trilogy_connect_set_fd(trilogy_conn_t *conn, trilogy_sock_t *sock, int fd)
{
    trilogy_sock_set_fd(sock, fd);

    conn->socket = sock;
    conn->packet_parser.sequence_number = 0;

    return TRILOGY_OK;
}

int trilogy_connect_recv(trilogy_conn_t *conn, trilogy_handshake_t *handshake_out)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    // In rare cases, the server will actually send an error packet as the
    // initial packet instead of a handshake packet. For example, if there are
    // too many connected clients already.
    if (current_packet_type(conn) == TRILOGY_PACKET_ERR) {
        return read_err_packet(conn);
    }

    rc = trilogy_parse_handshake_packet(conn->packet_buffer.buff, conn->packet_buffer.len, handshake_out);

    if (rc < 0) {
        return rc;
    }

    conn->capabilities = handshake_out->capabilities;
    conn->server_status = handshake_out->server_status;

    return TRILOGY_OK;
}

int trilogy_auth_send(trilogy_conn_t *conn, const trilogy_handshake_t *handshake)
{
    trilogy_builder_t builder;

    int rc = begin_command_phase(&builder, conn, conn->packet_parser.sequence_number);

    if (rc < 0) {
        return rc;
    }

    rc = trilogy_build_auth_packet(&builder, conn->socket->opts.username, conn->socket->opts.password,
                                   conn->socket->opts.password_len, conn->socket->opts.database,
                                   conn->socket->opts.encoding, handshake->auth_plugin, handshake->scramble,
                                   conn->socket->opts.flags);

    if (rc < 0) {
        return rc;
    }

    return begin_write(conn);
}

int trilogy_ssl_request_send(trilogy_conn_t *conn)
{
    trilogy_builder_t builder;

    int rc = begin_command_phase(&builder, conn, conn->packet_parser.sequence_number);

    if (rc < 0) {
        return rc;
    }

    conn->socket->opts.flags |= TRILOGY_CAPABILITIES_SSL;
    rc = trilogy_build_ssl_request_packet(&builder, conn->socket->opts.flags, conn->socket->opts.encoding);

    if (rc < 0) {
        return rc;
    }

    return begin_write(conn);
}

int trilogy_auth_switch_send(trilogy_conn_t *conn, const trilogy_handshake_t *handshake)
{
    trilogy_builder_t builder;

    int rc = begin_command_phase(&builder, conn, conn->packet_parser.sequence_number);

    if (rc < 0) {
        return rc;
    }

    rc = trilogy_build_auth_switch_response_packet(&builder, conn->socket->opts.password,
                                                   conn->socket->opts.password_len, handshake->auth_plugin,
                                                   handshake->scramble, conn->socket->opts.enable_cleartext_plugin);

    if (rc < 0) {
        return rc;
    }

    return begin_write(conn);
}

void trilogy_auth_clear_password(trilogy_conn_t *conn)
{
    if (conn->socket->opts.password) {
        memset(conn->socket->opts.password, 0, conn->socket->opts.password_len);
    }
}

#define CACHING_SHA2_REQUEST_PUBLIC_KEY 2
#define CACHING_SHA2_SCRAMBLE_LEN 20
#define FAST_AUTH_OK 3
#define FAST_AUTH_FAIL 4

static int read_auth_result(trilogy_conn_t *conn)
{
    int rc = read_packet_blocking(conn);

    if (rc < 0) {
        return rc;
    }

    trilogy_auth_clear_password(conn);
    return handle_generic_response(conn);
}

static int send_cleartext_password(trilogy_conn_t *conn)
{
    trilogy_builder_t builder;

    int rc = begin_command_phase(&builder, conn, conn->packet_parser.sequence_number);

    if (rc < 0) {
        return rc;
    }

    if (conn->socket->opts.password_len == 0) {
        rc = trilogy_builder_write_uint8(&builder, 0);

        if (rc < 0) {
            return rc;
        }

        trilogy_builder_finalize(&builder);
        return flush_current_packet(conn);
    }

    rc = trilogy_build_auth_clear_password(&builder, conn->socket->opts.password, conn->socket->opts.password_len);

    if (rc < 0) {
        return rc;
    }

    return flush_current_packet(conn);
}

static int send_auth_buffer(trilogy_conn_t *conn, const void *buff, size_t buff_len)
{
    trilogy_builder_t builder;
    int rc = begin_command_phase(&builder, conn, conn->packet_parser.sequence_number);

    if (rc < 0) {
        return rc;
    }

    rc = trilogy_builder_write_buffer(&builder, buff, buff_len);
    if (rc < 0) {
        return rc;
    }

    trilogy_builder_finalize(&builder);

    return flush_current_packet(conn);
}

static int send_public_key_request(trilogy_conn_t *conn)
{
    uint8_t request = CACHING_SHA2_REQUEST_PUBLIC_KEY;

    return send_auth_buffer(conn, &request, sizeof(request));
}

static int encrypt_password_with_public_key(const uint8_t *scramble, size_t scramble_len, trilogy_conn_t *conn,
                                            const uint8_t *key_data, size_t key_data_len, uint8_t **encrypted_out,
                                            size_t *encrypted_len)
{
    int rc = TRILOGY_OK;
    uint8_t *ciphertext = NULL;
    size_t ciphertext_len = 0;

    if (key_data_len == 0 || key_data_len > INT_MAX) {
        return TRILOGY_AUTH_PLUGIN_ERROR;
    }

    size_t password_len = conn->socket->opts.password_len;
    if (password_len == SIZE_MAX) {
        return TRILOGY_MEM_ERROR;
    }
    size_t plaintext_len = password_len + 1;
    uint8_t *plaintext = xmalloc(plaintext_len);

    if (plaintext == NULL) {
        return TRILOGY_MEM_ERROR;
    }

    if (password_len > 0) {
        memcpy(plaintext, conn->socket->opts.password, password_len);
    }
    plaintext[plaintext_len - 1] = '\0';

    if (scramble_len > 0) {
        for (size_t i = 0; i < plaintext_len; i++) {
            plaintext[i] ^= scramble[i % scramble_len];
        }
    }

    BIO *bio = BIO_new_mem_buf((void *)key_data, (int)key_data_len);
    if (bio == NULL) {
        xfree(plaintext);
        return TRILOGY_OPENSSL_ERR;
    }

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY *public_key = PEM_read_bio_PUBKEY(bio, NULL, NULL, NULL);
#else
    RSA *public_key = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
#endif

    BIO_free(bio);

    if (public_key == NULL) {
        ERR_clear_error();
        memset(plaintext, 0, plaintext_len);
        xfree(plaintext);
        return TRILOGY_AUTH_PLUGIN_ERROR;
    }

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    int key_size = EVP_PKEY_get_size(public_key);
    if (key_size <= 0) {
        EVP_PKEY_free(public_key);
        memset(plaintext, 0, plaintext_len);
        xfree(plaintext);
        return TRILOGY_AUTH_PLUGIN_ERROR;
    }
    ciphertext_len = (size_t)key_size;
#else
    ciphertext_len = (size_t)RSA_size(public_key);
#endif

    /*
       When using RSA_PKCS1_OAEP_PADDING the password length must be less
       than RSA_size(rsa) - 41.
     */
    if (ciphertext_len == 0 || plaintext_len + 41 >= ciphertext_len) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_PKEY_free(public_key);
#else
        RSA_free(public_key);
#endif
        memset(plaintext, 0, plaintext_len);
        xfree(plaintext);
        return TRILOGY_AUTH_PLUGIN_ERROR;
    }

    ciphertext = xmalloc(ciphertext_len);

    if (ciphertext == NULL) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_PKEY_free(public_key);
#else
        RSA_free(public_key);
#endif
        memset(plaintext, 0, plaintext_len);
        xfree(plaintext);
        return TRILOGY_MEM_ERROR;
    }

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(public_key, NULL);
    if (ctx == NULL || EVP_PKEY_encrypt_init(ctx) <= 0 ||
        EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0) {
        rc = TRILOGY_OPENSSL_ERR;
    } else {
        size_t out_len = ciphertext_len;

        if (EVP_PKEY_encrypt(ctx, ciphertext, &out_len, plaintext, plaintext_len) <= 0) {
            rc = TRILOGY_OPENSSL_ERR;
        } else {
            *encrypted_len = out_len;
        }
    }

    if (ctx) {
        EVP_PKEY_CTX_free(ctx);
    }
    EVP_PKEY_free(public_key);
#else
    int out_len = RSA_public_encrypt((int)plaintext_len, plaintext, ciphertext, public_key, RSA_PKCS1_OAEP_PADDING);
    RSA_free(public_key);

    if (out_len < 0) {
        rc = TRILOGY_OPENSSL_ERR;
    } else {
        *encrypted_len = (size_t)out_len;
    }
#endif

    memset(plaintext, 0, plaintext_len);
    xfree(plaintext);

    if (rc == TRILOGY_OK) {
        *encrypted_out = ciphertext;
    } else {
        memset(ciphertext, 0, ciphertext_len);
        xfree(ciphertext);
    }

    return rc;
}

static int handle_fast_auth_fail(trilogy_conn_t *conn, trilogy_handshake_t *handshake, const uint8_t *auth_data,
                                 size_t auth_data_len)
{
    int rc;
    bool use_ssl = (conn->socket->opts.flags & TRILOGY_CAPABILITIES_SSL) != 0;
    bool has_unix_socket = (conn->socket->opts.path != NULL);

    // No password to send, so we can safely respond even without TLS.
    if (conn->socket->opts.password_len == 0) {
        rc = send_cleartext_password(conn);
        if (rc < 0) {
            return rc;
        }

        return read_auth_result(conn);
    }

    if (use_ssl || has_unix_socket) {
        rc = send_cleartext_password(conn);
        if (rc < 0) {
            return rc;
        }

        return read_auth_result(conn);
    }

    const uint8_t *public_key_data = NULL;
    size_t public_key_len = 0;

    if (auth_data_len > 1) {
        public_key_data = auth_data + 1;
        public_key_len = auth_data_len - 1;
    } else {
        rc = send_public_key_request(conn);
        if (rc < 0) {
            return rc;
        }

        rc = read_packet_blocking(conn);
        if (rc < 0) {
            return rc;
        }

        if (current_packet_type(conn) == TRILOGY_PACKET_ERR) {
            return read_err_packet(conn);
        }

        if (current_packet_type(conn) != TRILOGY_PACKET_AUTH_MORE_DATA || conn->packet_buffer.len < 2) {
            return TRILOGY_PROTOCOL_VIOLATION;
        }

        public_key_data = conn->packet_buffer.buff + 1;
        public_key_len = conn->packet_buffer.len - 1;
    }

    uint8_t *encrypted = NULL;
    size_t encrypted_len = 0;

    rc = encrypt_password_with_public_key((const uint8_t *)handshake->scramble, CACHING_SHA2_SCRAMBLE_LEN, conn,
                                          public_key_data, public_key_len, &encrypted, &encrypted_len);

    if (rc < 0) {
        return rc;
    }

    rc = send_auth_buffer(conn, encrypted, encrypted_len);
    memset(encrypted, 0, encrypted_len);
    xfree(encrypted);

    if (rc < 0) {
        return rc;
    }

    return read_auth_result(conn);
}

int trilogy_auth_recv(trilogy_conn_t *conn, trilogy_handshake_t *handshake)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_AUTH_MORE_DATA: {
        const uint8_t *auth_data = conn->packet_buffer.buff + 1;
        size_t auth_data_len = conn->packet_buffer.len - 1;

        if (auth_data_len < 1) {
            return TRILOGY_PROTOCOL_VIOLATION;
        }

        uint8_t byte = auth_data[0];
        switch (byte) {
        case FAST_AUTH_OK:
            return read_auth_result(conn);

        case FAST_AUTH_FAIL:
            return handle_fast_auth_fail(conn, handshake, auth_data, auth_data_len);

        default:
            return TRILOGY_UNEXPECTED_PACKET;
        }
    }

    case TRILOGY_PACKET_EOF:
        // EOF is returned here if an auth switch is requested.
        // We still need the password for the switch, it will be cleared
        // in a follow up call to this function after the switch.
        return read_auth_switch_packet(conn, handshake);

    case TRILOGY_PACKET_OK:
    case TRILOGY_PACKET_ERR:
    default:
        trilogy_auth_clear_password(conn);
        return handle_generic_response(conn);
    }

    return read_generic_response(conn);
}

int trilogy_change_db_send(trilogy_conn_t *conn, const char *name, size_t name_len)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_change_db_packet(&builder, name, name_len);

    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_change_db_recv(trilogy_conn_t *conn) { return read_generic_response(conn); }

int trilogy_set_option_send(trilogy_conn_t *conn, const uint16_t option)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_set_option_packet(&builder, option);

    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_set_option_recv(trilogy_conn_t *conn)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_OK:
    case TRILOGY_PACKET_EOF: // COM_SET_OPTION returns an EOF packet, but it should be treated as an OK packet.
        return read_ok_packet(conn);

    case TRILOGY_PACKET_ERR:
        return read_err_packet(conn);

    default:
        return TRILOGY_UNEXPECTED_PACKET;
    }
}

int trilogy_ping_send(trilogy_conn_t *conn)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_ping_packet(&builder);

    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_ping_recv(trilogy_conn_t *conn) { return read_generic_response(conn); }

int trilogy_query_send(trilogy_conn_t *conn, const char *query, size_t query_len)
{
    int err = 0;

    trilogy_builder_t builder;
    err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_query_packet(&builder, query, query_len);
    if (err < 0) {
        return err;
    }

    conn->packet_parser.sequence_number = builder.seq;

    return begin_write(conn);
}

int trilogy_query_recv(trilogy_conn_t *conn, uint64_t *column_count_out)
{
    int err = read_packet(conn);

    if (err < 0) {
        return err;
    }

    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_OK:
        return read_ok_packet(conn);

    case TRILOGY_PACKET_ERR:
        return read_err_packet(conn);

    default: {
        trilogy_result_packet_t result_packet;
        err = trilogy_parse_result_packet(conn->packet_buffer.buff, conn->packet_buffer.len, &result_packet);

        if (err < 0) {
            return err;
        }

        conn->column_count = result_packet.column_count;
        *column_count_out = result_packet.column_count;
        conn->started_reading_rows = false;

        return TRILOGY_HAVE_RESULTS;
    }
    }
}

int trilogy_read_column(trilogy_conn_t *conn, trilogy_column_t *column_out)
{
    int err = read_packet(conn);

    if (err < 0) {
        return err;
    }

    return trilogy_parse_column_packet(conn->packet_buffer.buff, conn->packet_buffer.len, 0, column_out);
}

static int read_eof(trilogy_conn_t *conn)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    return read_eof_packet(conn);
}

int trilogy_read_row(trilogy_conn_t *conn, trilogy_value_t *values_out)
{
    if (!conn->started_reading_rows) {
        if ((conn->capabilities & TRILOGY_CAPABILITIES_DEPRECATE_EOF) == 0) {
            // we need to skip over the EOF packet that arrives after the column
            // packets
            int rc = read_eof(conn);

            if (rc < 0) {
                return rc;
            }
        }

        conn->started_reading_rows = true;
    }

    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    if (is_eof_packet(conn)) {
        if ((rc = read_eof_packet(conn)) != TRILOGY_OK) {
            return rc;
        }

        return TRILOGY_EOF;
    } else if (current_packet_type(conn) == TRILOGY_PACKET_ERR) {
        return read_err_packet(conn);
    } else {
        return trilogy_parse_row_packet(conn->packet_buffer.buff, conn->packet_buffer.len, conn->column_count,
                                        values_out);
    }
}

int trilogy_drain_results(trilogy_conn_t *conn)
{
    if (!conn->started_reading_rows) {
        // we need to skip over the EOF packet that arrives after the column
        // packets
        int rc = read_eof(conn);

        if (rc < 0) {
            return rc;
        }

        conn->started_reading_rows = true;
    }

    while (1) {
        int rc = read_packet(conn);

        if (rc < 0) {
            return rc;
        }

        if (is_eof_packet(conn)) {
            read_eof_packet(conn);
            return TRILOGY_OK;
        }
    }
}

static const uint8_t escape_lookup_table[256] = {
    ['"'] = '"', ['\0'] = '0', ['\''] = '\'', ['\\'] = '\\', ['\n'] = 'n', ['\r'] = 'r', [26] = 'Z',
};

int trilogy_escape(trilogy_conn_t *conn, const char *str, size_t len, const char **escaped_str_out,
                   size_t *escaped_len_out)
{
    int rc;

    trilogy_buffer_t *b = &conn->packet_buffer;

    b->len = 0;

    // Escaped string will be at least as large as the source string,
    // so might as well pre-expand the buffer.
    CHECKED(trilogy_buffer_expand(b, len));

    const uint8_t *cursor = (const uint8_t *)str;
    const uint8_t *end = cursor + len;

    if (conn->server_status & TRILOGY_SERVER_STATUS_NO_BACKSLASH_ESCAPES) {
        while (cursor < end) {
            uint8_t *next_escape = memchr(cursor, '\'', (size_t)(end - cursor));
            if (next_escape) {
                CHECKED(trilogy_buffer_write(b, cursor, (size_t)(next_escape - cursor)));
                CHECKED(trilogy_buffer_write(b, (uint8_t *)"\'\'", 2));
                cursor = next_escape + 1;
            } else {
                CHECKED(trilogy_buffer_write(b, cursor, (size_t)(end - cursor)));
                break;
            }
        }
    } else {
        while (cursor < end) {
            uint8_t escaped = 0;
            const uint8_t *start = cursor;
            while (cursor < end && !(escaped = escape_lookup_table[*cursor])) {
                cursor++;
            }

            CHECKED(trilogy_buffer_write(b, start, (size_t)(cursor - start)));
            if (escaped) {
                CHECKED(trilogy_buffer_putc(b, '\\'));
                CHECKED(trilogy_buffer_putc(b, escaped));
                cursor++;
            } else {
                break;
            }
        }
    }

    *escaped_str_out = (const char *)b->buff;
    *escaped_len_out = b->len;

    return TRILOGY_OK;
}

int trilogy_close_send(trilogy_conn_t *conn)
{
    trilogy_builder_t builder;
    int rc = begin_command_phase(&builder, conn, 0);
    if (rc < 0) {
        return rc;
    }

    rc = trilogy_build_quit_packet(&builder);

    if (rc < 0) {
        return rc;
    }

    return begin_write(conn);
}

int trilogy_close_recv(trilogy_conn_t *conn)
{
    trilogy_sock_shutdown(conn->socket);

    int rc = read_packet(conn);

    switch (rc) {
    case TRILOGY_CLOSED_CONNECTION:
        return TRILOGY_OK;

    case TRILOGY_OK:
        // we need to handle TRILOGY_OK specially and translate it into
        // TRILOGY_PROTOCOL_VIOLATION so we don't end up returning TRILOGY_OK
        // in the default case
        return TRILOGY_PROTOCOL_VIOLATION;

    default:
        return rc;
    }
}

void trilogy_free(trilogy_conn_t *conn)
{
    if (conn->socket != NULL) {
        trilogy_sock_close(conn->socket);
        conn->socket = NULL;
    }

    trilogy_buffer_free(&conn->packet_buffer);
}

int trilogy_discard(trilogy_conn_t *conn)
{
    int rc = trilogy_sock_shutdown(conn->socket);
    if (rc == TRILOGY_OK) {
        trilogy_free(conn);
    }
    return rc;
}

int trilogy_stmt_prepare_send(trilogy_conn_t *conn, const char *stmt, size_t stmt_len)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_stmt_prepare_packet(&builder, stmt, stmt_len);
    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_stmt_prepare_recv(trilogy_conn_t *conn, trilogy_stmt_t *stmt_out)
{
    int err = read_packet(conn);

    if (err < 0) {
        return err;
    }

    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_OK: {
        err = trilogy_parse_stmt_ok_packet(conn->packet_buffer.buff, conn->packet_buffer.len, stmt_out);

        if (err < 0) {
            return err;
        }

        conn->warning_count = stmt_out->warning_count;

        return TRILOGY_OK;
    }

    case TRILOGY_PACKET_ERR:
        return read_err_packet(conn);

    default:
        return TRILOGY_UNEXPECTED_PACKET;
    }
}

int trilogy_stmt_execute_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint8_t flags, trilogy_binary_value_t *binds)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_stmt_execute_packet(&builder, stmt->id, flags, binds, stmt->parameter_count);

    if (err < 0) {
        return err;
    }

    conn->packet_parser.sequence_number = builder.seq;

    return begin_write(conn);
}

int trilogy_stmt_execute_recv(trilogy_conn_t *conn, uint64_t *column_count_out)
{
    int err = read_packet(conn);

    if (err < 0) {
        return err;
    }

    switch (current_packet_type(conn)) {
    case TRILOGY_PACKET_OK:
        return read_ok_packet(conn);

    case TRILOGY_PACKET_ERR:
        return read_err_packet(conn);

    default: {
        trilogy_result_packet_t result_packet;
        err = trilogy_parse_result_packet(conn->packet_buffer.buff, conn->packet_buffer.len, &result_packet);

        if (err < 0) {
            return err;
        }

        conn->column_count = result_packet.column_count;
        *column_count_out = result_packet.column_count;

        return TRILOGY_OK;
    }
    }
}

int trilogy_stmt_bind_data_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint16_t param_num, uint8_t *data,
                                size_t data_len)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_stmt_bind_data_packet(&builder, stmt->id, param_num, data, data_len);

    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_stmt_read_row(trilogy_conn_t *conn, trilogy_stmt_t *stmt, trilogy_column_packet_t *columns,
                          trilogy_binary_value_t *values_out)
{
    int rc = read_packet(conn);

    if (rc < 0) {
        return rc;
    }

    if (is_eof_packet(conn)) {
        if ((rc = read_eof_packet(conn)) != TRILOGY_OK) {
            return rc;
        }

        return TRILOGY_EOF;
    } else if (current_packet_type(conn) == TRILOGY_PACKET_ERR) {
        return read_err_packet(conn);
    } else {
        return trilogy_parse_stmt_row_packet(conn->packet_buffer.buff, conn->packet_buffer.len, columns,
                                             stmt->column_count, values_out);
    }
}

int trilogy_stmt_reset_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_stmt_reset_packet(&builder, stmt->id);
    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

int trilogy_stmt_reset_recv(trilogy_conn_t *conn) { return read_generic_response(conn); }

int trilogy_stmt_close_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt)
{
    trilogy_builder_t builder;
    int err = begin_command_phase(&builder, conn, 0);
    if (err < 0) {
        return err;
    }

    err = trilogy_build_stmt_close_packet(&builder, stmt->id);

    if (err < 0) {
        return err;
    }

    return begin_write(conn);
}

#undef CHECKED
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/error.c"
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
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/packet_parser.c"
#include "trilogy/packet_parser.h"
#include "trilogy/error.h"

enum {
    S_LEN_0 = 0,
    S_LEN_1 = 1,
    S_LEN_2 = 2,
    S_SEQ = 3,
    S_PAYLOAD = 4,
};

void trilogy_packet_parser_init(trilogy_packet_parser_t *parser, const trilogy_packet_parser_callbacks_t *callbacks)
{
    parser->user_data = NULL;
    parser->callbacks = callbacks;
    parser->state = S_LEN_0;
    parser->fragment = 0;
    parser->deferred_end_callback = 0;
    parser->sequence_number = 0;
}

size_t trilogy_packet_parser_execute(trilogy_packet_parser_t *parser, const uint8_t *buff, size_t len, int *error)
{
    size_t i = 0;

    if (parser->deferred_end_callback) {
        parser->deferred_end_callback = 0;

        int rc = parser->callbacks->on_packet_end(parser->user_data);

        if (rc) {
            *error = rc;
            return 0;
        }
    }

    while (i < len) {
        uint8_t cur_byte = buff[i];

        switch (parser->state) {
        case S_LEN_0: {
            parser->bytes_remaining = cur_byte;
            parser->state = S_LEN_1;

            i++;
            break;
        }
        case S_LEN_1: {
            parser->bytes_remaining |= cur_byte << 8;
            parser->state = S_LEN_2;

            i++;
            break;
        }
        case S_LEN_2: {
            parser->bytes_remaining |= cur_byte << 16;

            int was_fragment = parser->fragment;

            parser->fragment = (parser->bytes_remaining == TRILOGY_MAX_PACKET_LEN);

            parser->state = S_SEQ;
            i++;

            if (!was_fragment) {
                int rc = parser->callbacks->on_packet_begin(parser->user_data);

                if (rc) {
                    *error = rc;
                    return i;
                }
            }

            break;
        }
        case S_SEQ: {
            if (cur_byte != parser->sequence_number && cur_byte > 0) {
                *error = TRILOGY_INVALID_SEQUENCE_ID;
                return i;
            }

            parser->sequence_number++;
            parser->state = S_PAYLOAD;

            i++;

            if (parser->bytes_remaining == 0) {
                goto end_of_payload;
            }

            break;
        }
        case S_PAYLOAD: {
            const uint8_t *ptr = buff + i;
            size_t chunk_length = len - i;

            if (chunk_length > parser->bytes_remaining) {
                chunk_length = parser->bytes_remaining;
            }

            i += chunk_length;
            parser->bytes_remaining -= chunk_length;

            int rc = parser->callbacks->on_packet_data(parser->user_data, ptr, chunk_length);

            if (rc) {
                if (parser->bytes_remaining == 0) {
                    parser->deferred_end_callback = 1;
                }

                *error = rc;
                return i;
            }

            if (parser->bytes_remaining == 0) {
                goto end_of_payload;
            }

            break;
        }
        end_of_payload : {
            parser->state = S_LEN_0;

            if (!parser->fragment) {
                int rc = parser->callbacks->on_packet_end(parser->user_data);

                if (rc) {
                    *error = rc;
                    return i;
                }
            }

            break;
        }
        }
    }

    *error = 0;
    return i;
}
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/protocol.c"
#include <openssl/evp.h>

#include "trilogy/builder.h"
#include "trilogy/error.h"
#include "trilogy/packet_parser.h"
#include "trilogy/protocol.h"
#include "trilogy/reader.h"

#define TRILOGY_CMD_QUIT 0x01
#define TRILOGY_CMD_CHANGE_DB 0x02
#define TRILOGY_CMD_QUERY 0x03
#define TRILOGY_CMD_PING 0x0e
#define TRILOGY_CMD_SET_OPTION 0x1b

#define TRILOGY_CMD_STMT_PREPARE 0x16
#define TRILOGY_CMD_STMT_EXECUTE 0x17
#define TRILOGY_CMD_STMT_SEND_LONG_DATA 0x18
#define TRILOGY_CMD_STMT_CLOSE 0x19
#define TRILOGY_CMD_STMT_RESET 0x1a

#define SCRAMBLE_LEN 20

static size_t min(size_t a, size_t b)
{
    if (a < b) {
        return a;
    } else {
        return b;
    }
}

#define CHECKED(expr)                                                                                                  \
    if ((rc = (expr)) < 0) {                                                                                           \
        goto fail;                                                                                                     \
    }

int trilogy_parse_ok_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_ok_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet type
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    CHECKED(trilogy_reader_get_lenenc(&reader, &out_packet->affected_rows));

    CHECKED(trilogy_reader_get_lenenc(&reader, &out_packet->last_insert_id));

    out_packet->status_flags = 0;
    out_packet->warning_count = 0;
    out_packet->txn_status_flags = 0;
    out_packet->session_status = NULL;
    out_packet->session_status_len = 0;
    out_packet->session_state_changes = NULL;
    out_packet->session_state_changes_len = 0;
    out_packet->info = NULL;
    out_packet->info_len = 0;
    out_packet->last_gtid_len = 0;

    if (capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41) {
        CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->status_flags));
        CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->warning_count));
    } else if (capabilities & TRILOGY_CAPABILITIES_TRANSACTIONS) {
        CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->txn_status_flags));
    }

    if (capabilities & TRILOGY_CAPABILITIES_SESSION_TRACK && !trilogy_reader_eof(&reader)) {
        CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->session_status_len,
                                                 (const void **)&out_packet->session_status));

        if (out_packet->status_flags & TRILOGY_SERVER_STATUS_SESSION_STATE_CHANGED) {
            CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->session_state_changes_len,
                                                     (const void **)&out_packet->session_state_changes));

            TRILOGY_SESSION_TRACK_TYPE_t type = 0;
            const char *state_info = NULL;
            size_t state_info_len = 0;

            trilogy_reader_t state_reader = TRILOGY_READER((const uint8_t *)out_packet->session_state_changes,
                                                           out_packet->session_state_changes_len);

            while (!trilogy_reader_eof(&state_reader)) {
                CHECKED(trilogy_reader_get_uint8(&state_reader, (uint8_t *)&type));
                CHECKED(trilogy_reader_get_lenenc_buffer(&state_reader, &state_info_len, (const void **)&state_info));

                switch (type) {
                case TRILOGY_SESSION_TRACK_GTIDS: {
                    trilogy_reader_t gtid_reader = TRILOGY_READER((const uint8_t *)state_info, state_info_len);
                    // There's a type with value TRILOGY_SESSION_TRACK_GTIDS tag
                    // at the beginning here we can ignore since we already had
                    // the type one level higher as well.
                    CHECKED(trilogy_reader_get_uint8(&gtid_reader, NULL));
                    CHECKED(trilogy_reader_get_lenenc_buffer(&gtid_reader, &out_packet->last_gtid_len,
                                                             (const void **)&out_packet->last_gtid));
                    if (out_packet->last_gtid_len > TRILOGY_MAX_LAST_GTID_LEN) {
                        return TRILOGY_PROTOCOL_VIOLATION;
                    }
                    break;
                }
                default:
                    break;
                }
            }
        }
    } else {
        CHECKED(trilogy_reader_get_eof_buffer(&reader, &out_packet->info_len, (const void **)&out_packet->info));
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_eof_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_eof_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet type
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    if (capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41) {
        CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->warning_count));
        CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->status_flags));
    } else {
        out_packet->status_flags = 0;
        out_packet->warning_count = 0;
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_err_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_err_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet type
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->error_code));

    if (capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41) {
        CHECKED(trilogy_reader_get_uint8(&reader, out_packet->sql_state_marker));
        CHECKED(trilogy_reader_copy_buffer(&reader, 5, out_packet->sql_state));
    } else {
        memset(out_packet->sql_state_marker, 0, sizeof out_packet->sql_state_marker);
        memset(out_packet->sql_state, 0, sizeof out_packet->sql_state);
    }

    CHECKED(trilogy_reader_get_eof_buffer(&reader, &out_packet->error_message_len,
                                          (const void **)&out_packet->error_message));

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_auth_switch_request_packet(const uint8_t *buff, size_t len, uint32_t capabilities,
                                             trilogy_auth_switch_request_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet type
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    if (capabilities & TRILOGY_CAPABILITIES_PLUGIN_AUTH) {
        const char *auth_plugin;
        size_t auth_plugin_len;

        CHECKED(trilogy_reader_get_string(&reader, &auth_plugin, &auth_plugin_len));
        if (auth_plugin_len > sizeof(out_packet->auth_plugin) - 1) {
            return TRILOGY_AUTH_PLUGIN_TOO_LONG;
        }
        memcpy(out_packet->auth_plugin, auth_plugin, auth_plugin_len + 1);

        const char *auth_data;
        size_t auth_data_len;
        CHECKED(trilogy_reader_get_eof_buffer(&reader, &auth_data_len, (const void **)&auth_data));
        if (auth_data_len > 21) {
            auth_data_len = 21;
        }
        memcpy(out_packet->scramble, auth_data, auth_data_len);
    } else {
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_handshake_packet(const uint8_t *buff, size_t len, trilogy_handshake_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    CHECKED(trilogy_reader_get_uint8(&reader, &out_packet->proto_version));
    if (out_packet->proto_version != 0xa) {
        // incompatible protocol version
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    const char *server_version;
    size_t server_version_len;

    CHECKED(trilogy_reader_get_string(&reader, &server_version, &server_version_len));
    server_version_len = min(server_version_len, sizeof(out_packet->server_version) - 1);
    memcpy(out_packet->server_version, server_version, server_version_len);
    out_packet->server_version[server_version_len] = '\0';

    CHECKED(trilogy_reader_get_uint32(&reader, &out_packet->conn_id));

    CHECKED(trilogy_reader_copy_buffer(&reader, 8, out_packet->scramble));

    // this should be a NULL filler
    uint8_t filler = 0;
    CHECKED(trilogy_reader_get_uint8(&reader, &filler));
    if (filler != '\0') {
        // corrupt handshake packet
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    // lower two bytes of capabilities flags
    uint16_t caps_part = 0;
    CHECKED(trilogy_reader_get_uint16(&reader, &caps_part));
    out_packet->capabilities = caps_part;

    if (!(out_packet->capabilities & TRILOGY_CAPABILITIES_PROTOCOL_41)) {
        // incompatible protocol version
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    uint8_t server_charset;
    CHECKED(trilogy_reader_get_uint8(&reader, &server_charset));

    out_packet->server_charset = server_charset;

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->server_status));

    // upper 16 bits of capabilities flags

    CHECKED(trilogy_reader_get_uint16(&reader, &caps_part));
    out_packet->capabilities |= ((uint32_t)caps_part << 16);

    uint8_t auth_data_len = 0;
    CHECKED(trilogy_reader_get_uint8(&reader, &auth_data_len));
    if (!(out_packet->capabilities & TRILOGY_CAPABILITIES_PLUGIN_AUTH)) {
        // this should be a NULL filler
        if (auth_data_len != '\0') {
            // corrupt handshake packet
            return TRILOGY_PROTOCOL_VIOLATION;
        }
    }

    // This space is reserved. It should be all NULL bytes but some tools or
    // future versions of MySQL-compatible clients may use it. This library
    // opts to skip the validation as some servers don't respect the protocol.
    CHECKED(trilogy_reader_get_buffer(&reader, 10, NULL));

    if (out_packet->capabilities & TRILOGY_CAPABILITIES_SECURE_CONNECTION && auth_data_len > 8) {
        uint8_t remaining_auth_data_len = auth_data_len - 8;

        // The auth plugins we support all provide exactly 21 bytes of
        // auth_data. Reject any other values for auth_data_len.
        if (SCRAMBLE_LEN + 1 != auth_data_len) {
            return TRILOGY_PROTOCOL_VIOLATION;
        }

        CHECKED(trilogy_reader_copy_buffer(&reader, remaining_auth_data_len, out_packet->scramble + 8));
    } else {
        // only support 4.1 protocol or newer with secure connection
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    if (out_packet->capabilities & TRILOGY_CAPABILITIES_PLUGIN_AUTH) {
        const char *auth_plugin;
        size_t auth_plugin_len;

        CHECKED(trilogy_reader_get_string(&reader, &auth_plugin, &auth_plugin_len));
        if (auth_plugin_len > sizeof(out_packet->auth_plugin) - 1) {
            return TRILOGY_AUTH_PLUGIN_TOO_LONG;
        }

        memcpy(out_packet->auth_plugin, auth_plugin, auth_plugin_len + 1);
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_result_packet(const uint8_t *buff, size_t len, trilogy_result_packet_t *out_packet)
{
    int rc = 0;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    CHECKED(trilogy_reader_get_lenenc(&reader, &out_packet->column_count));

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_row_packet(const uint8_t *buff, size_t len, uint64_t column_count, trilogy_value_t *out_values)
{
    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    for (uint64_t i = 0; i < column_count; i++) {
        void *data = NULL;
        size_t data_len = 0;

        int rc = trilogy_reader_get_lenenc_buffer(&reader, &data_len, (const void **)&data);

        switch (rc) {
        case TRILOGY_OK:
            out_values[i].is_null = false;
            out_values[i].data = data;
            out_values[i].data_len = data_len;
            break;

        case TRILOGY_NULL_VALUE:
            out_values[i].is_null = true;
            out_values[i].data_len = 0;
            break;

        default:
            return rc;
        }
    }

    return trilogy_reader_finish(&reader);
}

int trilogy_parse_column_packet(const uint8_t *buff, size_t len, bool field_list, trilogy_column_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->catalog_len, (const void **)&out_packet->catalog));

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->schema_len, (const void **)&out_packet->schema));

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->table_len, (const void **)&out_packet->table));

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->original_table_len,
                                             (const void **)&out_packet->original_table));

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->name_len, (const void **)&out_packet->name));

    CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->original_name_len,
                                             (const void **)&out_packet->original_name));

    // skip length of fixed length field until we have something to use it for
    CHECKED(trilogy_reader_get_lenenc(&reader, NULL));

    uint16_t charset;
    CHECKED(trilogy_reader_get_uint16(&reader, &charset));

    out_packet->charset = charset;

    CHECKED(trilogy_reader_get_uint32(&reader, &out_packet->len));

    uint8_t type;
    CHECKED(trilogy_reader_get_uint8(&reader, &type));
    out_packet->type = type;

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->flags));

    CHECKED(trilogy_reader_get_uint8(&reader, &out_packet->decimals));

    // skip NULL filler
    CHECKED(trilogy_reader_get_uint16(&reader, NULL));

    out_packet->default_value_len = 0;

    if (field_list) {
        CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_packet->default_value_len,
                                                 (const void **)&out_packet->default_value));
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

int trilogy_parse_stmt_ok_packet(const uint8_t *buff, size_t len, trilogy_stmt_ok_packet_t *out_packet)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet type
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    CHECKED(trilogy_reader_get_uint32(&reader, &out_packet->id));

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->column_count));

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->parameter_count));

    uint8_t filler;

    CHECKED(trilogy_reader_get_uint8(&reader, &filler));

    if (filler != 0) {
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    CHECKED(trilogy_reader_get_uint16(&reader, &out_packet->warning_count));

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

static void trilogy_pack_scramble_native_hash(const char *scramble, const char *password, size_t password_len,
                                              uint8_t *buffer, unsigned int *buffer_len)
{
    EVP_MD_CTX *ctx;
    const EVP_MD *alg;
    unsigned int hash_size_tmp1;
    unsigned int hash_size_tmp2;
    unsigned int x;

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL
    ctx = EVP_MD_CTX_new();
#else
    ctx = EVP_MD_CTX_create();
    EVP_MD_CTX_init(ctx);
#endif
    alg = EVP_sha1();
    hash_size_tmp1 = 0;
    hash_size_tmp2 = 0;
    uint8_t hash_tmp1[EVP_MAX_MD_SIZE];
    uint8_t hash_tmp2[EVP_MAX_MD_SIZE];

    /* First hash the password. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, (unsigned char *)(password), password_len);
    EVP_DigestFinal_ex(ctx, hash_tmp1, &hash_size_tmp1);

    /* Second, hash the password hash. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, hash_tmp1, (size_t)hash_size_tmp1);
    EVP_DigestFinal_ex(ctx, hash_tmp2, &hash_size_tmp2);

    /* Third, hash the scramble and the double password hash. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, (unsigned char *)scramble, SCRAMBLE_LEN);
    EVP_DigestUpdate(ctx, hash_tmp2, (size_t)hash_size_tmp2);
    EVP_DigestFinal_ex(ctx, buffer, buffer_len);

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL
    EVP_MD_CTX_free(ctx);
#else
    EVP_MD_CTX_destroy(ctx);
#endif

    /* Fourth, xor the last hash against the first password hash. */
    for (x = 0; x < *buffer_len; x++) {
        buffer[x] = buffer[x] ^ hash_tmp1[x];
    }
}

static void trilogy_pack_scramble_sha2_hash(const char *scramble, const char *password, size_t password_len,
                                            uint8_t *buffer, unsigned int *buffer_len)
{
    EVP_MD_CTX *ctx;
    const EVP_MD *alg;
    unsigned int hash_size_tmp1;
    unsigned int hash_size_tmp2;
    unsigned int x;

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL
    ctx = EVP_MD_CTX_new();
#else
    ctx = EVP_MD_CTX_create();
    EVP_MD_CTX_init(ctx);
#endif
    alg = EVP_sha256();
    hash_size_tmp1 = 0;
    hash_size_tmp2 = 0;
    uint8_t hash_tmp1[EVP_MAX_MD_SIZE];
    uint8_t hash_tmp2[EVP_MAX_MD_SIZE];

    /* First hash the password. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, (unsigned char *)(password), password_len);
    EVP_DigestFinal_ex(ctx, hash_tmp1, &hash_size_tmp1);

    /* Second, hash the password hash. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, hash_tmp1, (size_t)hash_size_tmp1);
    EVP_DigestFinal_ex(ctx, hash_tmp2, &hash_size_tmp2);

    /* Third, hash the scramble and the double password hash. */
    EVP_DigestInit_ex(ctx, alg, NULL);
    EVP_DigestUpdate(ctx, hash_tmp2, (size_t)hash_size_tmp2);
    EVP_DigestUpdate(ctx, (unsigned char *)scramble, SCRAMBLE_LEN);
    EVP_DigestFinal_ex(ctx, buffer, buffer_len);

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL
    EVP_MD_CTX_free(ctx);
#else
    EVP_MD_CTX_destroy(ctx);
#endif

    /* Fourth, xor the first and last hash. */
    for (x = 0; x < *buffer_len; x++) {
        buffer[x] = hash_tmp1[x] ^ buffer[x];
    }
}

int trilogy_build_auth_packet(trilogy_builder_t *builder, const char *user, const char *pass, size_t pass_len,
                              const char *database, TRILOGY_CHARSET_t client_encoding, const char *auth_plugin,
                              const char *scramble, TRILOGY_CAPABILITIES_t flags)
{
    int rc = TRILOGY_OK;

    const char *default_auth_plugin = "mysql_native_password";

    uint32_t capabilities = flags;
    // Add the default set of capabilities for this client
    capabilities |= TRILOGY_CAPABILITIES_CLIENT;

    uint32_t max_packet_len = TRILOGY_MAX_PACKET_LEN;

    unsigned int auth_response_len = 0;
    uint8_t auth_response[EVP_MAX_MD_SIZE];

    if (database) {
        capabilities |= TRILOGY_CAPABILITIES_CONNECT_WITH_DB;
    }

    CHECKED(trilogy_builder_write_uint32(builder, capabilities));

    CHECKED(trilogy_builder_write_uint32(builder, max_packet_len));

    CHECKED(trilogy_builder_write_uint8(builder, client_encoding));

    static const char zeroes[23] = {0};
    CHECKED(trilogy_builder_write_buffer(builder, zeroes, 23));

    if (user) {
        CHECKED(trilogy_builder_write_string(builder, user));
    } else {
        CHECKED(trilogy_builder_write_string(builder, "root"));
    }

    if (pass_len > 0) {
        // Fallback to te default unless we have SHA2 requested
        if (!strcmp("caching_sha2_password", auth_plugin)) {
            trilogy_pack_scramble_sha2_hash(scramble, pass, pass_len, auth_response, &auth_response_len);
        } else {
            trilogy_pack_scramble_native_hash(scramble, pass, pass_len, auth_response, &auth_response_len);
            auth_plugin = default_auth_plugin;
        }
    }

    // auth data len
    CHECKED(trilogy_builder_write_uint8(builder, (uint8_t)auth_response_len));

    if (auth_response_len > 0) {
        CHECKED(trilogy_builder_write_buffer(builder, auth_response, auth_response_len));
    }

    if (database) {
        CHECKED(trilogy_builder_write_string(builder, database));
    }

    if (capabilities & TRILOGY_CAPABILITIES_PLUGIN_AUTH) {
        CHECKED(trilogy_builder_write_string(builder, auth_plugin));
    }

    trilogy_builder_finalize(builder);

fail:
    return rc;
}

int trilogy_build_auth_clear_password(trilogy_builder_t *builder, const char *pass, size_t pass_len) {
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_buffer(builder, pass, pass_len));
    CHECKED(trilogy_builder_write_uint8(builder, 0));
    trilogy_builder_finalize(builder);

fail:
    return rc;
}

int trilogy_build_auth_switch_response_packet(trilogy_builder_t *builder, const char *pass, size_t pass_len,
                                              const char *auth_plugin, const char *scramble, const bool enable_cleartext_plugin)
{
    int rc = TRILOGY_OK;
    unsigned int auth_response_len = 0;
    uint8_t auth_response[EVP_MAX_MD_SIZE];

    if (pass_len > 0) {
        if (!strcmp("mysql_clear_password", auth_plugin)) {
            if (enable_cleartext_plugin) {
                CHECKED(trilogy_builder_write_buffer(builder, pass, pass_len));
            } else {
                return TRILOGY_AUTH_PLUGIN_ERROR;
            }
        } else {
            if (!strcmp("caching_sha2_password", auth_plugin)) {
                trilogy_pack_scramble_sha2_hash(scramble, pass, pass_len, auth_response, &auth_response_len);
            } else if (!strcmp("mysql_native_password", auth_plugin)) {
                trilogy_pack_scramble_native_hash(scramble, pass, pass_len, auth_response, &auth_response_len);
            } else {
                return TRILOGY_AUTH_PLUGIN_ERROR;
            }

            CHECKED(trilogy_builder_write_buffer(builder, auth_response, auth_response_len));
        }
    }

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;
fail:
    return rc;
}

int trilogy_build_ping_packet(trilogy_builder_t *builder)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_PING));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_query_packet(trilogy_builder_t *builder, const char *sql, size_t sql_len)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_QUERY));

    CHECKED(trilogy_builder_write_buffer(builder, sql, sql_len));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_change_db_packet(trilogy_builder_t *builder, const char *name, size_t name_len)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_CHANGE_DB));

    CHECKED(trilogy_builder_write_buffer(builder, name, name_len));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_quit_packet(trilogy_builder_t *builder)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_QUIT));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_set_option_packet(trilogy_builder_t *builder, const uint16_t option)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_SET_OPTION));
    CHECKED(trilogy_builder_write_uint16(builder, option));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}


int trilogy_build_ssl_request_packet(trilogy_builder_t *builder, TRILOGY_CAPABILITIES_t flags,
                                     TRILOGY_CHARSET_t client_encoding)
{
    static const char zeroes[23] = {0};

    const uint32_t max_packet_len = TRILOGY_MAX_PACKET_LEN;
    const uint32_t capabilities = flags | TRILOGY_CAPABILITIES_CLIENT | TRILOGY_CAPABILITIES_SSL;

    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint32(builder, capabilities));
    CHECKED(trilogy_builder_write_uint32(builder, max_packet_len));
    CHECKED(trilogy_builder_write_uint8(builder, client_encoding));
    CHECKED(trilogy_builder_write_buffer(builder, zeroes, 23));
    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_stmt_prepare_packet(trilogy_builder_t *builder, const char *sql, size_t sql_len)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_STMT_PREPARE));

    CHECKED(trilogy_builder_write_buffer(builder, sql, sql_len));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_stmt_execute_packet(trilogy_builder_t *builder, uint32_t stmt_id, uint8_t flags,
                                      trilogy_binary_value_t *binds, uint16_t num_binds)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_STMT_EXECUTE));

    CHECKED(trilogy_builder_write_uint32(builder, stmt_id));

    CHECKED(trilogy_builder_write_uint8(builder, flags));

    // apparently, iteration-count is always 1
    CHECKED(trilogy_builder_write_uint32(builder, 1));

    int i;

    if (num_binds > 0) {
        if (binds == NULL) {
            return TRILOGY_PROTOCOL_VIOLATION;
        }

        uint8_t current_bits = 0;

        for (i = 0; i < num_binds; i++) {
            if (binds[i].is_null) {
                current_bits |= 1 << (i % 8);
            }

            // If we hit a byte boundary, write the bits we have so far and continue
            if ((i % 8) == 7) {
                CHECKED(trilogy_builder_write_uint8(builder, current_bits))

                current_bits = 0;
            }
        }

        // If there would have been any remainder bits, finally write those as well
        if (num_binds % 8) {
            CHECKED(trilogy_builder_write_uint8(builder, current_bits))
        }

        // new params bound flag
        CHECKED(trilogy_builder_write_uint8(builder, 0x1));

        for (i = 0; i < num_binds; i++) {
            CHECKED(trilogy_builder_write_uint8(builder, binds[i].type));

            if (binds[i].is_unsigned) {
                CHECKED(trilogy_builder_write_uint8(builder, 0x80));
            } else {
                CHECKED(trilogy_builder_write_uint8(builder, 0x00));
            }
        }

        for (i = 0; i < num_binds; i++) {
            trilogy_binary_value_t val = binds[i];

            switch (val.type) {
            case TRILOGY_TYPE_TINY:
                CHECKED(trilogy_builder_write_uint8(builder, val.as.uint8));

                break;
            case TRILOGY_TYPE_SHORT:
                CHECKED(trilogy_builder_write_uint16(builder, val.as.uint16));

                break;
            case TRILOGY_TYPE_INT24:
            case TRILOGY_TYPE_LONG:
                CHECKED(trilogy_builder_write_uint32(builder, val.as.uint32));

                break;
            case TRILOGY_TYPE_LONGLONG:
                CHECKED(trilogy_builder_write_uint64(builder, val.as.uint64));

                break;
            case TRILOGY_TYPE_FLOAT:
                CHECKED(trilogy_builder_write_float(builder, val.as.flt));

                break;
            case TRILOGY_TYPE_DOUBLE:
                CHECKED(trilogy_builder_write_double(builder, val.as.dbl));

                break;
            case TRILOGY_TYPE_YEAR:
                CHECKED(trilogy_builder_write_uint16(builder, val.as.year));

                break;
            case TRILOGY_TYPE_TIME: {
                uint8_t field_len = 0;

                if (val.as.time.micro_seconds) {
                    field_len = 12;
                } else if (val.as.time.hour || val.as.time.minute || val.as.time.second) {
                    field_len = 8;
                } else {
                    field_len = 0;
                }

                CHECKED(trilogy_builder_write_uint8(builder, field_len));

                if (field_len > 0) {
                    CHECKED(trilogy_builder_write_uint8(builder, val.as.time.is_negative));

                    CHECKED(trilogy_builder_write_uint32(builder, val.as.time.days));

                    CHECKED(trilogy_builder_write_uint8(builder, val.as.time.hour));

                    CHECKED(trilogy_builder_write_uint8(builder, val.as.time.minute));

                    CHECKED(trilogy_builder_write_uint8(builder, val.as.time.second));

                    if (field_len > 8) {
                        CHECKED(trilogy_builder_write_uint32(builder, val.as.time.micro_seconds));
                    }
                }

                break;
            }
            case TRILOGY_TYPE_DATE:
            case TRILOGY_TYPE_DATETIME:
            case TRILOGY_TYPE_TIMESTAMP: {
                uint8_t field_len = 0;

                if (val.as.date.datetime.micro_seconds) {
                    field_len = 11;
                } else if (val.as.date.datetime.hour || val.as.date.datetime.minute || val.as.date.datetime.second) {
                    field_len = 7;
                } else if (val.as.date.year || val.as.date.month || val.as.date.day) {
                    field_len = 4;
                } else {
                    field_len = 0;
                }

                CHECKED(trilogy_builder_write_uint8(builder, field_len));

                if (field_len > 0) {
                    CHECKED(trilogy_builder_write_uint16(builder, val.as.date.year));

                    CHECKED(trilogy_builder_write_uint8(builder, val.as.date.month));

                    CHECKED(trilogy_builder_write_uint8(builder, val.as.date.day));

                    if (field_len > 4) {
                        CHECKED(trilogy_builder_write_uint8(builder, val.as.date.datetime.hour));

                        CHECKED(trilogy_builder_write_uint8(builder, val.as.date.datetime.minute));

                        CHECKED(trilogy_builder_write_uint8(builder, val.as.date.datetime.second));

                        if (field_len > 7) {
                            CHECKED(trilogy_builder_write_uint32(builder, val.as.date.datetime.micro_seconds));
                        }
                    }
                }

                break;
            }
            case TRILOGY_TYPE_DECIMAL:
            case TRILOGY_TYPE_VARCHAR:
            case TRILOGY_TYPE_BIT:
            case TRILOGY_TYPE_NEWDECIMAL:
            case TRILOGY_TYPE_ENUM:
            case TRILOGY_TYPE_SET:
            case TRILOGY_TYPE_TINY_BLOB:
            case TRILOGY_TYPE_BLOB:
            case TRILOGY_TYPE_MEDIUM_BLOB:
            case TRILOGY_TYPE_LONG_BLOB:
            case TRILOGY_TYPE_VAR_STRING:
            case TRILOGY_TYPE_STRING:
            case TRILOGY_TYPE_GEOMETRY:
            case TRILOGY_TYPE_JSON:
            case TRILOGY_TYPE_VECTOR:
                CHECKED(trilogy_builder_write_lenenc_buffer(builder, val.as.str.data, val.as.str.len));

                break;
            case TRILOGY_TYPE_NULL:
                // already handled by the null bitmap
                break;
            default:
                return TRILOGY_UNKNOWN_TYPE;
            }
        }
    }

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_stmt_bind_data_packet(trilogy_builder_t *builder, uint32_t stmt_id, uint16_t param_id, uint8_t *data,
                                        size_t data_len)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_STMT_SEND_LONG_DATA));

    CHECKED(trilogy_builder_write_uint32(builder, stmt_id));

    CHECKED(trilogy_builder_write_uint16(builder, param_id));

    CHECKED(trilogy_builder_write_buffer(builder, data, data_len));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_stmt_reset_packet(trilogy_builder_t *builder, uint32_t stmt_id)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_STMT_RESET));

    CHECKED(trilogy_builder_write_uint32(builder, stmt_id));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

int trilogy_build_stmt_close_packet(trilogy_builder_t *builder, uint32_t stmt_id)
{
    int rc = TRILOGY_OK;

    CHECKED(trilogy_builder_write_uint8(builder, TRILOGY_CMD_STMT_CLOSE));

    CHECKED(trilogy_builder_write_uint32(builder, stmt_id));

    trilogy_builder_finalize(builder);

    return TRILOGY_OK;

fail:
    return rc;
}

static inline int is_null(uint8_t *null_bitmap, uint64_t bitmap_len, uint64_t column_offset, bool *col_is_null)
{
    if (column_offset > (bitmap_len * 8) - 1) {
        return TRILOGY_PROTOCOL_VIOLATION;
    }

    column_offset += 2;

    uint64_t byte_offset = column_offset / 8;

    // for the binary protocol result row packet, we need to offset the bit check
    // by 2
    *col_is_null = (null_bitmap[byte_offset] & (1 << (column_offset % 8))) != 0;

    return TRILOGY_OK;
}

int trilogy_parse_stmt_row_packet(const uint8_t *buff, size_t len, trilogy_column_packet_t *columns,
                                  uint64_t column_count, trilogy_binary_value_t *out_values)
{
    int rc;

    trilogy_reader_t reader = TRILOGY_READER(buff, len);

    // skip packet header
    CHECKED(trilogy_reader_get_uint8(&reader, NULL));

    uint8_t *null_bitmap = NULL;
    uint64_t bitmap_len = (column_count + 7 + 2) / 8;

    CHECKED(trilogy_reader_get_buffer(&reader, bitmap_len, (const void **)&null_bitmap));

    for (uint64_t i = 0; i < column_count; i++) {
        CHECKED(is_null(null_bitmap, bitmap_len, i, &out_values[i].is_null));
        if (out_values[i].is_null) {
            out_values[i].type = TRILOGY_TYPE_NULL;
        } else {
            out_values[i].is_null = false;

            out_values[i].type = columns[i].type;

            if (columns[i].flags & TRILOGY_COLUMN_FLAG_UNSIGNED) {
                out_values[i].is_unsigned = true;
            }

            switch (columns[i].type) {
            case TRILOGY_TYPE_STRING:
            case TRILOGY_TYPE_VARCHAR:
            case TRILOGY_TYPE_VAR_STRING:
            case TRILOGY_TYPE_ENUM:
            case TRILOGY_TYPE_SET:
            case TRILOGY_TYPE_LONG_BLOB:
            case TRILOGY_TYPE_MEDIUM_BLOB:
            case TRILOGY_TYPE_BLOB:
            case TRILOGY_TYPE_TINY_BLOB:
            case TRILOGY_TYPE_GEOMETRY:
            case TRILOGY_TYPE_BIT:
            case TRILOGY_TYPE_DECIMAL:
            case TRILOGY_TYPE_NEWDECIMAL:
            case TRILOGY_TYPE_JSON:
            case TRILOGY_TYPE_VECTOR:
                CHECKED(trilogy_reader_get_lenenc_buffer(&reader, &out_values[i].as.str.len,
                                                      (const void **)&out_values[i].as.str.data));

                break;
            case TRILOGY_TYPE_LONGLONG:
                CHECKED(trilogy_reader_get_uint64(&reader, &out_values[i].as.uint64));

                break;
            case TRILOGY_TYPE_DOUBLE:
                CHECKED(trilogy_reader_get_double(&reader, &out_values[i].as.dbl));

                break;
            case TRILOGY_TYPE_LONG:
            case TRILOGY_TYPE_INT24:
                CHECKED(trilogy_reader_get_uint32(&reader, &out_values[i].as.uint32));

                break;
            case TRILOGY_TYPE_FLOAT:
                CHECKED(trilogy_reader_get_float(&reader, &out_values[i].as.flt));

                break;
            case TRILOGY_TYPE_SHORT:
                CHECKED(trilogy_reader_get_uint16(&reader, &out_values[i].as.uint16));

                break;
            case TRILOGY_TYPE_YEAR:
                CHECKED(trilogy_reader_get_uint16(&reader, &out_values[i].as.year));

                break;
            case TRILOGY_TYPE_TINY:
                CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.uint8));

                break;
            case TRILOGY_TYPE_DATE:
            case TRILOGY_TYPE_DATETIME:
            case TRILOGY_TYPE_TIMESTAMP: {
                uint8_t time_len;

                CHECKED(trilogy_reader_get_uint8(&reader, &time_len));

                out_values[i].as.date.year = 0;
                out_values[i].as.date.month = 0;
                out_values[i].as.date.day = 0;
                out_values[i].as.date.datetime.hour = 0;
                out_values[i].as.date.datetime.minute = 0;
                out_values[i].as.date.datetime.second = 0;
                out_values[i].as.date.datetime.micro_seconds = 0;

                switch (time_len) {
                case 0:
                    break;
                case 4:
                    CHECKED(trilogy_reader_get_uint16(&reader, &out_values[i].as.date.year));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.month));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.day));

                    break;
                case 7:
                    CHECKED(trilogy_reader_get_uint16(&reader, &out_values[i].as.date.year));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.month));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.day));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.hour));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.minute));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.second));

                    break;
                case 11:
                    CHECKED(trilogy_reader_get_uint16(&reader, &out_values[i].as.date.year));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.month));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.day));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.hour));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.minute));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.date.datetime.second));
                    CHECKED(trilogy_reader_get_uint32(&reader, &out_values[i].as.date.datetime.micro_seconds));

                    break;
                default:
                    return TRILOGY_PROTOCOL_VIOLATION;
                }

                break;
            }
            case TRILOGY_TYPE_TIME: {
                uint8_t time_len;

                CHECKED(trilogy_reader_get_uint8(&reader, &time_len));

                out_values[i].as.time.is_negative = false;
                out_values[i].as.time.days = 0;
                out_values[i].as.time.hour = 0;
                out_values[i].as.time.minute = 0;
                out_values[i].as.time.second = 0;
                out_values[i].as.time.micro_seconds = 0;

                switch (time_len) {
                case 0:
                    break;
                case 8: {
                    uint8_t is_negative;

                    CHECKED(trilogy_reader_get_uint8(&reader, &is_negative));

                    out_values[i].as.time.is_negative = is_negative == 1;

                    CHECKED(trilogy_reader_get_uint32(&reader, &out_values[i].as.time.days));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.hour));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.minute));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.second));

                    break;
                }
                case 12: {
                    uint8_t is_negative;

                    CHECKED(trilogy_reader_get_uint8(&reader, &is_negative));

                    out_values[i].as.time.is_negative = is_negative == 1;

                    CHECKED(trilogy_reader_get_uint32(&reader, &out_values[i].as.time.days));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.hour));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.minute));
                    CHECKED(trilogy_reader_get_uint8(&reader, &out_values[i].as.time.second));
                    CHECKED(trilogy_reader_get_uint32(&reader, &out_values[i].as.time.micro_seconds));

                    break;
                }
                default:
                    return TRILOGY_PROTOCOL_VIOLATION;
                }

                break;
            }
            case TRILOGY_TYPE_NULL:
            default:
                // we cover TRILOGY_TYPE_NULL here because we should never hit this case
                // explicitly as it should be covered in the null bitmap
                return TRILOGY_UNKNOWN_TYPE;
            }
        }
    }

    return trilogy_reader_finish(&reader);

fail:
    return rc;
}

#undef CHECKED
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/reader.c"
#include "trilogy/reader.h"
#include "trilogy/error.h"

#include <string.h>

#define CHECK(bytes)                                                                                                   \
    if ((bytes) > (reader->len - reader->pos)) {                                                                       \
        return TRILOGY_TRUNCATED_PACKET;                                                                               \
    }

void trilogy_reader_init(trilogy_reader_t *reader, const uint8_t *buff, size_t len)
{
    reader->buff = buff;
    reader->len = len;
    reader->pos = 0;
}

static uint8_t next_uint8(trilogy_reader_t *reader) { return reader->buff[reader->pos++]; }

int trilogy_reader_get_uint8(trilogy_reader_t *reader, uint8_t *out)
{
    CHECK(1);

    uint8_t a = next_uint8(reader);

    if (out) {
        *out = a;
    }

    return TRILOGY_OK;
}

int trilogy_reader_get_uint16(trilogy_reader_t *reader, uint16_t *out)
{
    CHECK(2);

    uint16_t a = next_uint8(reader);
    uint16_t b = next_uint8(reader);

    if (out) {
        *out = (uint16_t)(a | (b << 8));
    }

    return TRILOGY_OK;
}

int trilogy_reader_get_uint24(trilogy_reader_t *reader, uint32_t *out)
{
    CHECK(3);

    uint32_t a = next_uint8(reader);
    uint32_t b = next_uint8(reader);
    uint32_t c = next_uint8(reader);

    if (out) {
        *out = a | (b << 8) | (c << 16);
    }

    return TRILOGY_OK;
}

int trilogy_reader_get_uint32(trilogy_reader_t *reader, uint32_t *out)
{
    CHECK(4);

    uint32_t a = next_uint8(reader);
    uint32_t b = next_uint8(reader);
    uint32_t c = next_uint8(reader);
    uint32_t d = next_uint8(reader);

    if (out) {
        *out = a | (b << 8) | (c << 16) | (d << 24);
    }

    return TRILOGY_OK;
}

int trilogy_reader_get_uint64(trilogy_reader_t *reader, uint64_t *out)
{
    CHECK(8);

    uint64_t a = next_uint8(reader);
    uint64_t b = next_uint8(reader);
    uint64_t c = next_uint8(reader);
    uint64_t d = next_uint8(reader);
    uint64_t e = next_uint8(reader);
    uint64_t f = next_uint8(reader);
    uint64_t g = next_uint8(reader);
    uint64_t h = next_uint8(reader);

    if (out) {
        *out = a | (b << 8) | (c << 16) | (d << 24) | (e << 32) | (f << 40) | (g << 48) | (h << 56);
    }

    return TRILOGY_OK;
}

int trilogy_reader_get_float(trilogy_reader_t *reader, float *out)
{
    CHECK(4);

    union {
        float f;
        uint32_t u;
    } float_val;

    int rc = trilogy_reader_get_uint32(reader, &float_val.u);
    if (rc != TRILOGY_OK) {
        return rc;
    }

    *out = float_val.f;

    return TRILOGY_OK;
}

int trilogy_reader_get_double(trilogy_reader_t *reader, double *out)
{
    CHECK(8);

    union {
        double d;
        uint64_t u;
    } double_val;

    int rc = trilogy_reader_get_uint64(reader, &double_val.u);
    if (rc != TRILOGY_OK) {
        return rc;
    }

    *out = double_val.d;

    return TRILOGY_OK;
}

int trilogy_reader_get_lenenc(trilogy_reader_t *reader, uint64_t *out)
{
    CHECK(1);

    uint8_t leader = next_uint8(reader);

    if (leader < 0xfb) {
        if (out) {
            *out = leader;
        }

        return TRILOGY_OK;
    }

    switch (leader) {
    case 0xfb:
        return TRILOGY_NULL_VALUE;

    case 0xfc: {
        uint16_t u16 = 0;
        int rc = trilogy_reader_get_uint16(reader, &u16);

        if (out) {
            *out = u16;
        }

        return rc;
    }

    case 0xfd: {
        uint32_t u24 = 0;
        int rc = trilogy_reader_get_uint24(reader, &u24);

        if (out) {
            *out = u24;
        }

        return rc;
    }

    case 0xfe:
        return trilogy_reader_get_uint64(reader, out);

    default:
        return TRILOGY_PROTOCOL_VIOLATION;
    }
}

int trilogy_reader_get_buffer(trilogy_reader_t *reader, size_t len, const void **out)
{
    CHECK(len);

    if (out) {
        *out = (const void *)(reader->buff + reader->pos);
    }

    reader->pos += len;

    return TRILOGY_OK;
}

int trilogy_reader_copy_buffer(trilogy_reader_t *reader, size_t len, void *out)
{
    CHECK(len);

    if (out) {
        memcpy(out, reader->buff + reader->pos, len);
    }

    reader->pos += len;

    return TRILOGY_OK;
}

int trilogy_reader_get_lenenc_buffer(trilogy_reader_t *reader, size_t *out_len, const void **out)
{
    uint64_t len;

    int rc = trilogy_reader_get_lenenc(reader, &len);

    if (rc) {
        return rc;
    }

    // check len is not larger than the amount of bytes left before downcasting
    // to size_t (which may be smaller than uint64_t on some architectures)
    if (len > (uint64_t)(reader->len - reader->pos)) {
        return TRILOGY_TRUNCATED_PACKET;
    }

    if (out_len) {
        *out_len = (size_t)len;
    }

    return trilogy_reader_get_buffer(reader, (size_t)len, out);
}

int trilogy_reader_get_string(trilogy_reader_t *reader, const char **out, size_t *out_len)
{
    const uint8_t *pos = reader->buff + reader->pos;

    const uint8_t *end = memchr(pos, 0, reader->len - reader->pos);

    if (!end) {
        return TRILOGY_TRUNCATED_PACKET;
    }

    if (out) {
        *out = (const char *)pos;
    }

    size_t len = (size_t)(end - pos);

    if (out_len) {
        *out_len = len;
    }

    reader->pos += len + 1;

    return TRILOGY_OK;
}

int trilogy_reader_get_eof_buffer(trilogy_reader_t *reader, size_t *out_len, const void **out)
{
    if (out_len) {
        *out_len = reader->len - reader->pos;
    }

    if (out) {
        *out = reader->buff + reader->pos;
    }

    reader->pos = reader->len;

    return TRILOGY_OK;
}

bool trilogy_reader_eof(trilogy_reader_t *reader) { return !(reader->pos < reader->len); }

int trilogy_reader_finish(trilogy_reader_t *reader)
{
    if (reader->pos < reader->len) {
        return TRILOGY_EXTRA_DATA_IN_PACKET;
    } else {
        return TRILOGY_OK;
    }
}
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/socket.c"
#include <netdb.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include "trilogy/allocator.h"
#include "trilogy/error.h"
#include "trilogy/socket.h"

#if OPENSSL_VERSION_NUMBER < 0x1000200fL
#include "trilogy/vendor/openssl_hostname_validation.h"
#endif

struct trilogy_sock {
    trilogy_sock_t base;
    struct addrinfo *addr;
    SSL *ssl;
    int fd;
    bool freeaddrinfo;
};

void trilogy_sock_set_fd(trilogy_sock_t *_sock, int fd)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    sock->fd = fd;
}

static int _cb_raw_fd(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    return sock->fd;
}

static int _cb_wait(trilogy_sock_t *_sock, trilogy_wait_t wait)
{
    struct pollfd pfd = {.fd = trilogy_sock_fd(_sock)};

    switch (wait) {
    case TRILOGY_WAIT_HANDSHAKE:
    case TRILOGY_WAIT_READ:
        pfd.events = POLLIN;
        break;
    case TRILOGY_WAIT_CONNECT:
    case TRILOGY_WAIT_WRITE:
        pfd.events = POLLOUT;
        break;
    default:
        return TRILOGY_ERR;
    }

    while (1) {
        int rc = poll(&pfd, 1, -1);

        if (rc < 0) {
            if (errno == EINTR) {
                continue;
            }
            return TRILOGY_SYSERR;
        }

        return TRILOGY_OK;
    }
}

static ssize_t _cb_raw_read(trilogy_sock_t *_sock, void *buf, size_t nread)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    ssize_t data_read = read(sock->fd, buf, nread);
    if (data_read < 0) {
        if (errno == EINTR || errno == EAGAIN) {
            return (ssize_t)TRILOGY_AGAIN;
        } else {
            return (ssize_t)TRILOGY_SYSERR;
        }
    }
    return data_read;
}

static ssize_t _cb_raw_write(trilogy_sock_t *_sock, const void *buf, size_t nwrite)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    ssize_t data_written = write(sock->fd, buf, nwrite);
    if (data_written < 0) {
        if (errno == EINTR || errno == EAGAIN) {
            return (ssize_t)TRILOGY_AGAIN;
        }

        if (errno == EPIPE) {
            return (ssize_t)TRILOGY_CLOSED_CONNECTION;
        }

        return (ssize_t)TRILOGY_SYSERR;
    }
    return data_written;
}

static int _cb_raw_close(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    int rc = 0;
    if (sock->fd != -1) {
        rc = close(sock->fd);
    }

    if (sock->addr) {
        if (sock->freeaddrinfo) {
            freeaddrinfo(sock->addr);
        } else {
            /* We created these with xcalloc so must free them instead of calling freeaddrinfo */
            xfree(sock->addr->ai_addr);
            xfree(sock->addr);
        }
    }

    xfree(sock->base.opts.hostname);
    xfree(sock->base.opts.path);
    xfree(sock->base.opts.database);
    xfree(sock->base.opts.username);
    xfree(sock->base.opts.password);
    xfree(sock->base.opts.ssl_ca);
    xfree(sock->base.opts.ssl_capath);
    xfree(sock->base.opts.ssl_cert);
    xfree(sock->base.opts.ssl_cipher);
    xfree(sock->base.opts.ssl_crl);
    xfree(sock->base.opts.ssl_crlpath);
    xfree(sock->base.opts.ssl_key);
    xfree(sock->base.opts.tls_ciphersuites);

    xfree(sock);
    return rc;
}

static int _cb_shutdown_connect(trilogy_sock_t *_sock) {
    (void)_sock;
    return TRILOGY_CLOSED_CONNECTION;
}
static ssize_t _cb_shutdown_write(trilogy_sock_t *_sock, const void *buf, size_t nwrite) {
    (void)_sock;
    (void)buf;
    (void)nwrite;
    return TRILOGY_CLOSED_CONNECTION;
}
static ssize_t _cb_shutdown_read(trilogy_sock_t *_sock, void *buf, size_t nread) {
    (void)_sock;
    (void)buf;
    (void)nread;
    return TRILOGY_CLOSED_CONNECTION;
}
static int _cb_shutdown_wait(trilogy_sock_t *_sock, trilogy_wait_t wait) {
    (void)_sock;
    (void)wait;
    return TRILOGY_OK;
}
static int _cb_shutdown_shutdown(trilogy_sock_t *_sock) {
    (void)_sock;
    return TRILOGY_OK;
}

// Shutdown will close the underlying socket fd and replace all I/O operations with stubs which perform no action.
static int _cb_raw_shutdown(trilogy_sock_t *_sock) {
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    // Replace all operations with stubs which return immediately
    sock->base.connect_cb = _cb_shutdown_connect;
    sock->base.read_cb = _cb_shutdown_read;
    sock->base.write_cb = _cb_shutdown_write;
    sock->base.wait_cb = _cb_shutdown_wait;
    sock->base.shutdown_cb = _cb_shutdown_shutdown;

    // These "raw" callbacks won't attempt further operations on the socket and work correctly with fd set to -1
    sock->base.close_cb = _cb_raw_close;
    sock->base.fd_cb = _cb_raw_fd;

    if (sock->fd != -1)
        close(sock->fd);
    sock->fd = -1;

    return TRILOGY_OK;
}

static int set_nonblocking_fd(int sock)
{
    int flags = fcntl(sock, F_GETFL, 0);

    if (flags < 0) {
        return TRILOGY_SYSERR;
    }

    if (fcntl(sock, F_SETFL, flags | O_NONBLOCK) < 0) {
        return TRILOGY_SYSERR;
    }

    return TRILOGY_OK;
}

static int raw_connect_internal(struct trilogy_sock *sock, const struct addrinfo *ai)
{
    int sockerr;
    socklen_t sockerr_len = sizeof(sockerr);
    int rc = TRILOGY_SYSERR;

    sock->fd = socket(ai->ai_family, SOCK_STREAM, ai->ai_protocol);
    if (sock->fd < 0) {
        return TRILOGY_SYSERR;
    }

#ifdef TCP_NODELAY
    if (sock->addr->ai_family != PF_UNIX) {
        int flags = 1;
        if (setsockopt(sock->fd, IPPROTO_TCP, TCP_NODELAY, (void *)&flags, sizeof(flags)) < 0) {
            goto fail;
        }
    }
#endif
    if (sock->base.opts.keepalive_enabled) {
        int flags = 1;
        if (setsockopt(sock->fd, SOL_SOCKET, SO_KEEPALIVE, (void *)&flags, sizeof(flags)) < 0) {
            goto fail;
        }
#ifdef TCP_KEEPIDLE
        if (sock->base.opts.keepalive_idle > 0) {
            flags = sock->base.opts.keepalive_idle;
            if (setsockopt(sock->fd, IPPROTO_TCP, TCP_KEEPIDLE, (void *)&flags, sizeof(flags)) < 0) {
                goto fail;
            }
        }
#endif
#ifdef TCP_KEEPINTVL
        if (sock->base.opts.keepalive_interval > 0) {
            flags = sock->base.opts.keepalive_interval;
            if (setsockopt(sock->fd, IPPROTO_TCP, TCP_KEEPINTVL, (void *)&flags, sizeof(flags)) < 0) {
                goto fail;
            }
        }
#endif
#ifdef TCP_KEEPCNT
        if (sock->base.opts.keepalive_count > 0) {
            flags = sock->base.opts.keepalive_count;
            if (setsockopt(sock->fd, IPPROTO_TCP, TCP_KEEPCNT, (void *)&flags, sizeof(flags)) < 0) {
                goto fail;
            }
        }
#endif
    }

    if (set_nonblocking_fd(sock->fd) < 0) {
        goto fail;
    }

    if (connect(sock->fd, ai->ai_addr, ai->ai_addrlen) < 0) {
        if (errno != EINPROGRESS && errno != EAGAIN) {
            goto fail;
        }
    }

    if ((rc = trilogy_sock_wait((trilogy_sock_t *)sock, TRILOGY_WAIT_CONNECT)) < 0) {
        goto failrc;
    }

    if (getsockopt(sock->fd, SOL_SOCKET, SO_ERROR, &sockerr, &sockerr_len) < 0) {
        goto fail;
    }

    if (sockerr != 0) {
        // the socket failed to connect; since `getsockopt` doesn't set `errno`
        // to a meaningful value, we must set it manually because clients always
        // expect to find the error code there
        errno = sockerr;
        goto fail;
    }

    return TRILOGY_OK;

fail:
    rc = TRILOGY_SYSERR;
failrc:
    close(sock->fd);
    sock->fd = -1;
    return rc;
}

static int _cb_raw_connect(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    const struct addrinfo *ai = sock->addr;

    for (; ai; ai = ai->ai_next) {
        int rc = raw_connect_internal(sock, ai);
        if (rc == TRILOGY_OK)
            return TRILOGY_OK;
        else if (!ai->ai_next)
            return rc;
    }

    return TRILOGY_ERR;
}

static char *strdupnullok(const char *str)
{
    if (str == NULL) {
        return NULL;
    }
    return xstrdup(str);
}

trilogy_sock_t *trilogy_sock_new(const trilogy_sockopt_t *opts)
{
    struct trilogy_sock *sock = xmalloc(sizeof(struct trilogy_sock));

    sock->base.connect_cb = _cb_raw_connect;
    sock->base.read_cb = _cb_raw_read;
    sock->base.write_cb = _cb_raw_write;
    sock->base.wait_cb = _cb_wait;
    sock->base.shutdown_cb = _cb_raw_shutdown;
    sock->base.close_cb = _cb_raw_close;
    sock->base.fd_cb = _cb_raw_fd;
    sock->base.opts = *opts;

    sock->base.opts.hostname = strdupnullok(opts->hostname);
    sock->base.opts.path = strdupnullok(opts->path);
    sock->base.opts.database = strdupnullok(opts->database);
    sock->base.opts.username = strdupnullok(opts->username);

    if (sock->base.opts.password) {
        sock->base.opts.password = xmalloc(opts->password_len);
        memcpy(sock->base.opts.password, opts->password, opts->password_len);
    }

    sock->base.opts.ssl_ca = strdupnullok(opts->ssl_ca);
    sock->base.opts.ssl_capath = strdupnullok(opts->ssl_capath);
    sock->base.opts.ssl_cert = strdupnullok(opts->ssl_cert);
    sock->base.opts.ssl_cipher = strdupnullok(opts->ssl_cipher);
    sock->base.opts.ssl_crl = strdupnullok(opts->ssl_crl);
    sock->base.opts.ssl_crlpath = strdupnullok(opts->ssl_crlpath);
    sock->base.opts.ssl_key = strdupnullok(opts->ssl_key);
    sock->base.opts.tls_ciphersuites = strdupnullok(opts->tls_ciphersuites);

    sock->fd = -1;
    sock->addr = NULL;
    sock->ssl = NULL;

    return (trilogy_sock_t *)sock;
}

int trilogy_sock_resolve(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    if (sock->base.opts.hostname != NULL) {
        struct addrinfo hint = {.ai_family = PF_UNSPEC, .ai_socktype = SOCK_STREAM};

        char port[6];
        snprintf(port, sizeof(port), "%hu", sock->base.opts.port);

        sock->freeaddrinfo = true;
        if (getaddrinfo(sock->base.opts.hostname, port, &hint, &sock->addr) != 0) {
            return TRILOGY_DNS_ERR;
        }
    } else if (sock->base.opts.path != NULL) {
        struct sockaddr_un *sa;

        if (strlen(sock->base.opts.path) + 1 > sizeof(sa->sun_path)) {
            goto fail;
        }

        sa = xcalloc(1, sizeof(struct sockaddr_un));
        sa->sun_family = AF_UNIX;
        strcpy(sa->sun_path, sock->base.opts.path);

        sock->addr = xcalloc(1, sizeof(struct addrinfo));
        sock->addr->ai_family = PF_UNIX;
        sock->addr->ai_socktype = SOCK_STREAM;
        sock->addr->ai_addr = (struct sockaddr *)sa;
        sock->addr->ai_addrlen = sizeof(struct sockaddr_un);
        sock->freeaddrinfo = false;
    } else {
        goto fail;
    }

    return TRILOGY_OK;

fail:
    _cb_raw_close(_sock);
    return TRILOGY_ERR;
}

static ssize_t ssl_io_return(struct trilogy_sock *sock, ssize_t ret)
{
    if (ret <= 0) {
        int rc = SSL_get_error(sock->ssl, (int)ret);
        if (rc == SSL_ERROR_WANT_WRITE || rc == SSL_ERROR_WANT_READ) {
            return (ssize_t)TRILOGY_AGAIN;
        } else if (rc == SSL_ERROR_ZERO_RETURN) {
            // Server has closed the connection for writing by sending the close_notify alert
            return (ssize_t)TRILOGY_CLOSED_CONNECTION;
        } else if (rc == SSL_ERROR_SYSCALL && !ERR_peek_error()) {
            if (errno == 0) {
                // On OpenSSL <= 1.1.1, SSL_ERROR_SYSCALL with an errno value
                // of 0 indicates unexpected EOF from the peer.
                return (ssize_t)TRILOGY_CLOSED_CONNECTION;
            } else {
                return (ssize_t)TRILOGY_SYSERR;
            }
        }
        return (ssize_t)TRILOGY_OPENSSL_ERR;
    }
    return ret;
}

static ssize_t _cb_ssl_read(trilogy_sock_t *_sock, void *buf, size_t nread)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    // This shouldn't be necessary, but protects against other libraries in the same process incorrectly leaving errors
    // in the queue.
    ERR_clear_error();

    ssize_t data_read = (ssize_t)SSL_read(sock->ssl, buf, (int)nread);
    return ssl_io_return(sock, data_read);
}

static ssize_t _cb_ssl_write(trilogy_sock_t *_sock, const void *buf, size_t nwrite)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    // This shouldn't be necessary, but protects against other libraries in the same process incorrectly leaving errors
    // in the queue.
    ERR_clear_error();

    ssize_t data_written = (ssize_t)SSL_write(sock->ssl, buf, (int)nwrite);
    return ssl_io_return(sock, data_written);
}

static int _cb_ssl_shutdown(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    // If we have an SSL socket, it's invalid here and
    // we need to close it. The OpenSSL explicitly states
    // not to call SSL_shutdown on a broken SSL socket.
    SSL_free(sock->ssl);
    sock->ssl = NULL;

    // This will rewrite the handlers
    return _cb_raw_shutdown(_sock);
}

static int _cb_ssl_close(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    if (sock->ssl != NULL) {
        if (SSL_in_init(sock->ssl) == 0) {
            (void)SSL_shutdown(sock->ssl);
            // SSL_shutdown might return WANT_WRITE or WANT_READ. Ideally we would retry but we don't want to block.
            // It may also push an error onto the OpenSSL error queue, so clear that.
            ERR_clear_error();
        }
        SSL_free(sock->ssl);
        sock->ssl = NULL;
    }
    return _cb_raw_close(_sock);
}

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL

static int trilogy_tls_version_map[] = {0, TLS1_VERSION, TLS1_1_VERSION, TLS1_2_VERSION
#ifdef TLS1_3_VERSION
                                        ,
                                        TLS1_3_VERSION
#else
                                        ,
                                        0
#endif
};

long trilogy_set_min_proto_version(SSL_CTX *ctx, trilogy_tls_version_t version)
{
    int ssl_ver = trilogy_tls_version_map[version];
    if (ssl_ver == 0) {
        ERR_put_error(ERR_LIB_SSL, SSL_F_SSL_CTX_SET_SSL_VERSION, SSL_R_UNSUPPORTED_PROTOCOL, NULL, 0);
        return 0;
    }
    return SSL_CTX_set_min_proto_version(ctx, ssl_ver);
}

long trilogy_set_max_proto_version(SSL_CTX *ctx, trilogy_tls_version_t version)
{
    int ssl_ver = trilogy_tls_version_map[version];
    if (ssl_ver == 0) {
        ERR_put_error(ERR_LIB_SSL, SSL_F_SSL_CTX_SET_SSL_VERSION, SSL_R_UNSUPPORTED_PROTOCOL, NULL, 0);
        return 0;
    }
    return SSL_CTX_set_max_proto_version(ctx, ssl_ver);
}
#else

int trilogy_set_min_proto_version(SSL_CTX *ctx, trilogy_tls_version_t version)
{
    long opts = SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3;
    switch (version) {
    case TRILOGY_TLS_VERSION_13:
        opts |= SSL_OP_NO_TLSv1_2;
    case TRILOGY_TLS_VERSION_12:
        opts |= SSL_OP_NO_TLSv1_1;
    case TRILOGY_TLS_VERSION_11:
        opts |= SSL_OP_NO_TLSv1;
    default:
        break;
    }
    // No need to handle 1.3 here since OpenSSL < 1.1.0 doesn't support that
    // anyway
    SSL_CTX_set_options(ctx, opts);
    return 1;
}

int trilogy_set_max_proto_version(SSL_CTX *ctx, trilogy_tls_version_t version)
{
    long opts = SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3;
    switch (version) {
    case TRILOGY_TLS_VERSION_10:
        opts |= SSL_OP_NO_TLSv1_1;
    case TRILOGY_TLS_VERSION_11:
        opts |= SSL_OP_NO_TLSv1_2;
    default:
        break;
    }
    SSL_CTX_set_options(ctx, opts);
    return 1;
}
#endif

static SSL_CTX *trilogy_ssl_ctx(const trilogy_sockopt_t *opts)
{
    SSL_CTX *ssl_ctx = SSL_CTX_new(SSLv23_client_method());

    // Now handle all the custom options that we're given.
    if (opts->tls_min_version != TRILOGY_TLS_VERSION_UNDEF) {
        if (!trilogy_set_min_proto_version(ssl_ctx, opts->tls_min_version)) {
            goto fail;
        }
    } else {
        if (!trilogy_set_min_proto_version(ssl_ctx, TRILOGY_TLS_VERSION_12)) {
            goto fail;
        }
    }

    if (opts->tls_max_version != TRILOGY_TLS_VERSION_UNDEF) {
        if (!trilogy_set_max_proto_version(ssl_ctx, opts->tls_max_version)) {
            goto fail;
        }
    }

    if (opts->ssl_cipher) {
        if (!SSL_CTX_set_cipher_list(ssl_ctx, opts->ssl_cipher)) {
            goto fail;
        }
    } else {
        // Use a secure cipher list, based on TLS 1.2 and with authenticated
        // encryption.
        if (!SSL_CTX_set_cipher_list(ssl_ctx, "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:"
                                              "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:"
                                              "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305")) {
            goto fail;
        }
    }

#if OPENSSL_VERSION_NUMBER >= 0x1010100fL
    if (opts->tls_ciphersuites) {
        if (!SSL_CTX_set_ciphersuites(ssl_ctx, opts->tls_ciphersuites)) {
            goto fail;
        }
    }
#endif

    switch (opts->ssl_mode) {
    case TRILOGY_SSL_DISABLED:
        break;
    case TRILOGY_SSL_VERIFY_IDENTITY:
    case TRILOGY_SSL_VERIFY_CA:
        SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_PEER, NULL);
        break;
    case TRILOGY_SSL_REQUIRED_NOVERIFY:
    case TRILOGY_SSL_PREFERRED_NOVERIFY:
        SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, NULL);
        break;
    }

    if (opts->ssl_ca || opts->ssl_capath) {
        if (!SSL_CTX_load_verify_locations(ssl_ctx, opts->ssl_ca, opts->ssl_capath)) {
            goto fail;
        }
    } else {
        // Use the default systems paths to verify the certificate
        if (!SSL_CTX_set_default_verify_paths(ssl_ctx)) {
            goto fail;
        }
    }

    if (opts->ssl_cert || opts->ssl_key) {
        if (opts->ssl_key) {
            if (!SSL_CTX_use_PrivateKey_file(ssl_ctx, opts->ssl_key, SSL_FILETYPE_PEM)) {
                goto fail;
            }
        }
        if (opts->ssl_cert) {
            if (!SSL_CTX_use_certificate_chain_file(ssl_ctx, opts->ssl_cert)) {
                goto fail;
            }
        }

        if (!SSL_CTX_check_private_key(ssl_ctx)) {
            goto fail;
        }
    }

    if (opts->ssl_crl || opts->ssl_crlpath) {
        X509_STORE *store = SSL_CTX_get_cert_store(ssl_ctx);

        if (!X509_STORE_load_locations(store, opts->ssl_crl, opts->ssl_crlpath)) {
            goto fail;
        }

        if (!X509_STORE_set_flags(store, X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL)) {
            goto fail;
        }
    }
    return ssl_ctx;

fail:
    SSL_CTX_free(ssl_ctx);
    return NULL;
}

int trilogy_sock_upgrade_ssl(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;

    // This shouldn't be necessary, but protects against other libraries in the same process incorrectly leaving errors
    // in the queue.
    ERR_clear_error();

    SSL_CTX *ctx = trilogy_ssl_ctx(&sock->base.opts);

    if (!ctx) {
        return TRILOGY_OPENSSL_ERR;
    }

    sock->ssl = SSL_new(ctx);
    SSL_CTX_free(ctx);

    if (sock->base.opts.ssl_mode == TRILOGY_SSL_VERIFY_IDENTITY && sock->base.opts.hostname == NULL) {
        // If hostname validation is requested and no hostname provided, treat it as an error.
#ifdef SSL_F_TLS_PROCESS_SERVER_CERTIFICATE
        ERR_put_error(ERR_LIB_SSL, SSL_F_TLS_PROCESS_SERVER_CERTIFICATE, SSL_R_CERTIFICATE_VERIFY_FAILED, NULL, 0);
#else
        ERR_put_error(ERR_LIB_SSL, SSL_F_SSL3_GET_SERVER_CERTIFICATE, SSL_R_CERTIFICATE_VERIFY_FAILED, NULL, 0);
#endif
        goto fail;
    }

    // Set the SNI hostname for the connection
    if (sock->base.opts.hostname != NULL) {
        if (!SSL_set_tlsext_host_name(sock->ssl, sock->base.opts.hostname)) {
            goto fail;
        }
    }

    // Newer API available since 1.0.2, so we don't have to do manual work.
#if OPENSSL_VERSION_NUMBER >= 0x1000200fL
    if (sock->base.opts.ssl_mode == TRILOGY_SSL_VERIFY_IDENTITY) {
        X509_VERIFY_PARAM *param = SSL_get0_param(sock->ssl);
        const char *hostname = sock->base.opts.hostname;
        X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
        if (!X509_VERIFY_PARAM_set1_host(param, hostname, strlen(hostname))) {
            goto fail;
        }
    }
#endif

    if (!SSL_set_fd(sock->ssl, sock->fd))
        goto fail;

    for (;;) {
        // This shouldn't be necessary, but protects against other libraries in the same process incorrectly leaving errors
        // in the queue.
        ERR_clear_error();

        int ret = SSL_connect(sock->ssl);
        if (ret == 1) {
#if OPENSSL_VERSION_NUMBER < 0x1000200fL
            if (sock->base.opts.ssl_mode == TRILOGY_SSL_VERIFY_IDENTITY) {
                if (validate_hostname(sock->base.opts.hostname, SSL_get_peer_certificate(sock->ssl)) != MatchFound) {
                    // Fake the error message to be the same as it would be on 1.0.2 and newer.
                    ERR_put_error(ERR_LIB_SSL, SSL_F_SSL3_GET_SERVER_CERTIFICATE, SSL_R_CERTIFICATE_VERIFY_FAILED, NULL,
                                  0);
                    goto fail;
                }
            }
#endif
            break;
        }

        switch (SSL_get_error(sock->ssl, ret)) {
        case SSL_ERROR_WANT_READ:
            if (trilogy_sock_wait_read(_sock) < 0)
                goto fail;
            break;

        case SSL_ERROR_WANT_WRITE:
            if (trilogy_sock_wait_write(_sock) < 0)
                goto fail;
            break;

        default:
            goto fail;
        }
    }

    sock->base.read_cb = _cb_ssl_read;
    sock->base.write_cb = _cb_ssl_write;
    sock->base.shutdown_cb = _cb_ssl_shutdown;
    sock->base.close_cb = _cb_ssl_close;
    return TRILOGY_OK;

fail:
    SSL_free(sock->ssl);
    sock->ssl = NULL;
    return TRILOGY_OPENSSL_ERR;
}

int trilogy_sock_check(trilogy_sock_t *_sock)
{
    struct trilogy_sock *sock = (struct trilogy_sock *)_sock;
    char buf[1];
    while (1) {
        ssize_t data_read = recv(sock->fd, buf, 1, MSG_PEEK);
        if (data_read > 0) {
            return TRILOGY_OK;
        }
        if (data_read == 0) {
            return TRILOGY_CLOSED_CONNECTION;
        }
        if (errno == EINTR) {
            continue;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return TRILOGY_OK;
        }
        return TRILOGY_SYSERR;
    }
}
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/vendor/curl_hostcheck.c"
/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 1998 - 2012, Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at http://curl.haxx.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 ***************************************************************************/

/* This file is an amalgamation of hostcheck.c and most of rawstr.c
   from cURL.  The contents of the COPYING file mentioned above are:
COPYRIGHT AND PERMISSION NOTICE
Copyright (c) 1996 - 2013, Daniel Stenberg, <daniel@haxx.se>.
All rights reserved.
Permission to use, copy, modify, and distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright
notice and this permission notice appear in all copies.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.
Except as contained in this notice, the name of a copyright holder shall not
be used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization of the copyright holder.
*/

#include "trilogy/vendor/curl_hostcheck.h"
#include <string.h>

/* Portable, consistent toupper (remember EBCDIC). Do not use toupper() because
   its behavior is altered by the current locale. */
static char Curl_raw_toupper(char in)
{
    switch (in) {
    case 'a':
        return 'A';
    case 'b':
        return 'B';
    case 'c':
        return 'C';
    case 'd':
        return 'D';
    case 'e':
        return 'E';
    case 'f':
        return 'F';
    case 'g':
        return 'G';
    case 'h':
        return 'H';
    case 'i':
        return 'I';
    case 'j':
        return 'J';
    case 'k':
        return 'K';
    case 'l':
        return 'L';
    case 'm':
        return 'M';
    case 'n':
        return 'N';
    case 'o':
        return 'O';
    case 'p':
        return 'P';
    case 'q':
        return 'Q';
    case 'r':
        return 'R';
    case 's':
        return 'S';
    case 't':
        return 'T';
    case 'u':
        return 'U';
    case 'v':
        return 'V';
    case 'w':
        return 'W';
    case 'x':
        return 'X';
    case 'y':
        return 'Y';
    case 'z':
        return 'Z';
    }
    return in;
}

/*
 * Curl_raw_equal() is for doing "raw" case insensitive strings. This is meant
 * to be locale independent and only compare strings we know are safe for
 * this.  See http://daniel.haxx.se/blog/2008/10/15/strcasecmp-in-turkish/ for
 * some further explanation to why this function is necessary.
 *
 * The function is capable of comparing a-z case insensitively even for
 * non-ascii.
 */

static int Curl_raw_equal(const char *first, const char *second)
{
    while (*first && *second) {
        if (Curl_raw_toupper(*first) != Curl_raw_toupper(*second))
            /* get out of the loop as soon as they don't match */
            break;
        first++;
        second++;
    }
    /* we do the comparison here (possibly again), just to make sure that if the
       loop above is skipped because one of the strings reached zero, we must
       not return this as a successful match */
    return (Curl_raw_toupper(*first) == Curl_raw_toupper(*second));
}

static int Curl_raw_nequal(const char *first, const char *second, size_t max)
{
    while (*first && *second && max) {
        if (Curl_raw_toupper(*first) != Curl_raw_toupper(*second)) {
            break;
        }
        max--;
        first++;
        second++;
    }
    if (0 == max)
        return 1; /* they are equal this far */

    return Curl_raw_toupper(*first) == Curl_raw_toupper(*second);
}

/*
 * Match a hostname against a wildcard pattern.
 * E.g.
 *  "foo.host.com" matches "*.host.com".
 *
 * We use the matching rule described in RFC6125, section 6.4.3.
 * http://tools.ietf.org/html/rfc6125#section-6.4.3
 */

static int hostmatch(const char *hostname, const char *pattern)
{
    const char *pattern_label_end, *pattern_wildcard, *hostname_label_end;
    int wildcard_enabled;
    size_t prefixlen, suffixlen;
    pattern_wildcard = strchr(pattern, '*');
    if (pattern_wildcard == NULL)
        return Curl_raw_equal(pattern, hostname) ? CURL_HOST_MATCH : CURL_HOST_NOMATCH;

    /* We require at least 2 dots in pattern to avoid too wide wildcard
       match. */
    wildcard_enabled = 1;
    pattern_label_end = strchr(pattern, '.');
    if (pattern_label_end == NULL || strchr(pattern_label_end + 1, '.') == NULL ||
        pattern_wildcard > pattern_label_end || Curl_raw_nequal(pattern, "xn--", 4)) {
        wildcard_enabled = 0;
    }
    if (!wildcard_enabled)
        return Curl_raw_equal(pattern, hostname) ? CURL_HOST_MATCH : CURL_HOST_NOMATCH;

    hostname_label_end = strchr(hostname, '.');
    if (hostname_label_end == NULL || !Curl_raw_equal(pattern_label_end, hostname_label_end))
        return CURL_HOST_NOMATCH;

    /* The wildcard must match at least one character, so the left-most
       label of the hostname is at least as large as the left-most label
       of the pattern. */
    if (hostname_label_end - hostname < pattern_label_end - pattern)
        return CURL_HOST_NOMATCH;

    prefixlen = (size_t)(pattern_wildcard - pattern);
    suffixlen = (size_t)(pattern_label_end - (pattern_wildcard + 1));
    return Curl_raw_nequal(pattern, hostname, prefixlen) &&
                   Curl_raw_nequal(pattern_wildcard + 1, hostname_label_end - suffixlen, suffixlen)
               ? CURL_HOST_MATCH
               : CURL_HOST_NOMATCH;
}

int Curl_cert_hostcheck(const char *match_pattern, const char *hostname)
{
    if (!match_pattern || !*match_pattern || !hostname || !*hostname) /* sanity check */
        return 0;

    if (Curl_raw_equal(hostname, match_pattern)) /* trivial case */
        return 1;

    if (hostmatch(hostname, match_pattern) == CURL_HOST_MATCH)
        return 1;
    return 0;
}
#line 1 "/app/vendor/bundle/ruby/4.0.0/gems/trilogy-2.12.2/ext/trilogy-ruby/src/vendor/openssl_hostname_validation.c"
/* Obtained from: https://github.com/iSECPartners/ssl-conservatory */

/*
Copyright (C) 2012, iSEC Partners.
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/*
 * Helper functions to perform basic hostname validation using OpenSSL.
 *
 * Please read "everything-you-wanted-to-know-about-openssl.pdf" before
 * attempting to use this code. This whitepaper describes how the code works,
 * how it should be used, and what its limitations are.
 *
 * Author:  Alban Diquet
 * License: See LICENSE
 *
 */

// Get rid of OSX 10.7 and greater deprecation warnings.
#if defined(__APPLE__) && defined(__clang__)
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#endif

#include <openssl/ssl.h>
#include <openssl/x509v3.h>
#include <string.h>

#include "trilogy/vendor/curl_hostcheck.h"
#include "trilogy/vendor/openssl_hostname_validation.h"

#define HOSTNAME_MAX_SIZE 255

#if (OPENSSL_VERSION_NUMBER < 0x10100000L) ||                                                                          \
    (defined(LIBRESSL_VERSION_NUMBER) && LIBRESSL_VERSION_NUMBER < 0x20700000L)
#define ASN1_STRING_get0_data ASN1_STRING_data
#endif

/**
 * Tries to find a match for hostname in the certificate's Common Name field.
 *
 * Returns MatchFound if a match was found.
 * Returns MatchNotFound if no matches were found.
 * Returns MalformedCertificate if the Common Name had a NUL character embedded
 * in it. Returns Error if the Common Name could not be extracted.
 */
static HostnameValidationResult matches_common_name(const char *hostname, const X509 *server_cert)
{
    int common_name_loc = -1;
    X509_NAME_ENTRY *common_name_entry = NULL;
    ASN1_STRING *common_name_asn1 = NULL;
    const char *common_name_str = NULL;

    // Find the position of the CN field in the Subject field of the certificate
    common_name_loc = X509_NAME_get_index_by_NID(X509_get_subject_name((X509 *)server_cert), NID_commonName, -1);
    if (common_name_loc < 0) {
        return Error;
    }

    // Extract the CN field
    common_name_entry = X509_NAME_get_entry(X509_get_subject_name((X509 *)server_cert), common_name_loc);
    if (common_name_entry == NULL) {
        return Error;
    }

    // Convert the CN field to a C string
    common_name_asn1 = X509_NAME_ENTRY_get_data(common_name_entry);
    if (common_name_asn1 == NULL) {
        return Error;
    }
    common_name_str = (char *)ASN1_STRING_get0_data(common_name_asn1);

    // Make sure there isn't an embedded NUL character in the CN
    if ((size_t)ASN1_STRING_length(common_name_asn1) != strlen(common_name_str)) {
        return MalformedCertificate;
    }

    // Compare expected hostname with the CN
    if (Curl_cert_hostcheck(common_name_str, hostname) == CURL_HOST_MATCH) {
        return MatchFound;
    } else {
        return MatchNotFound;
    }
}

/**
 * Tries to find a match for hostname in the certificate's Subject Alternative
 * Name extension.
 *
 * Returns MatchFound if a match was found.
 * Returns MatchNotFound if no matches were found.
 * Returns MalformedCertificate if any of the hostnames had a NUL character
 * embedded in it. Returns NoSANPresent if the SAN extension was not present in
 * the certificate.
 */
static HostnameValidationResult matches_subject_alternative_name(const char *hostname, const X509 *server_cert)
{
    HostnameValidationResult result = MatchNotFound;
    int i;
    int san_names_nb = -1;
    STACK_OF(GENERAL_NAME) *san_names = NULL;

    // Try to extract the names within the SAN extension from the certificate
    san_names = X509_get_ext_d2i((X509 *)server_cert, NID_subject_alt_name, NULL, NULL);
    if (san_names == NULL) {
        return NoSANPresent;
    }
    san_names_nb = sk_GENERAL_NAME_num(san_names);

    // Check each name within the extension
    for (i = 0; i < san_names_nb; i++) {
        const GENERAL_NAME *current_name = sk_GENERAL_NAME_value(san_names, i);

        if (current_name->type == GEN_DNS) {
            // Current name is a DNS name, let's check it
            const char *dns_name = (char *)ASN1_STRING_get0_data(current_name->d.dNSName);

            // Make sure there isn't an embedded NUL character in the DNS name
            if ((size_t)ASN1_STRING_length(current_name->d.dNSName) != strlen(dns_name)) {
                result = MalformedCertificate;
                break;
            } else { // Compare expected hostname with the DNS name
                if (Curl_cert_hostcheck(dns_name, hostname) == CURL_HOST_MATCH) {
                    result = MatchFound;
                    break;
                }
            }
        }
    }
    sk_GENERAL_NAME_pop_free(san_names, GENERAL_NAME_free);

    return result;
}

/**
 * Validates the server's identity by looking for the expected hostname in the
 * server's certificate. As described in RFC 6125, it first tries to find a
 * match in the Subject Alternative Name extension. If the extension is not
 * present in the certificate, it checks the Common Name instead.
 *
 * Returns MatchFound if a match was found.
 * Returns MatchNotFound if no matches were found.
 * Returns MalformedCertificate if any of the hostnames had a NUL character
 * embedded in it. Returns Error if there was an error.
 */
HostnameValidationResult validate_hostname(const char *hostname, const X509 *server_cert)
{
    HostnameValidationResult result;

    if ((hostname == NULL) || (server_cert == NULL))
        return Error;

    // First try the Subject Alternative Names extension
    result = matches_subject_alternative_name(hostname, server_cert);
    if (result == NoSANPresent) {
        // Extension was not found: try the Common Name
        result = matches_common_name(hostname, server_cert);
    }

    return result;
}
