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
