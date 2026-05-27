#ifndef TRILOGY_READER_H
#define TRILOGY_READER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Trilogy Packet Reader API
 *
 * The packet reader API is used to parse MySQL-compatible protocol packets.
 */

/* trilogy_reader_t - The reader API's instance type.
 */
typedef struct {
    const uint8_t *buff;
    size_t len;
    size_t pos;
} trilogy_reader_t;

/* trilogy_reader_init - Initialize a pre-allocated trilogy_reader_t.
 *
 * reader - A pointer to a pre-allocated trilogy_reader_t.
 * buff   - A pointer to a buffer containing MySQL-compatible protocol packet data.
 * len    - The length of `buff` in bytes.
 *
 * Returns nothing.
 */
void trilogy_reader_init(trilogy_reader_t *reader, const uint8_t *buff, size_t len);

#define TRILOGY_READER(buffer, length) ((trilogy_reader_t){.buff = (buffer), .len = (length), .pos = 0});

/* trilogy_reader_get_uint8 - Parse an unsigned 8-bit integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint8_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_uint8(trilogy_reader_t *reader, uint8_t *out);

/* trilogy_reader_get_uint16 - Parse an unsigned 16-bit integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint16_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_uint16(trilogy_reader_t *reader, uint16_t *out);

/* trilogy_reader_get_uint24 - Parse an unsigned 24-bit integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint32_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_uint24(trilogy_reader_t *reader, uint32_t *out);

/* trilogy_reader_get_uint32 - Parse an unsigned 32-bit integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint32_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_uint32(trilogy_reader_t *reader, uint32_t *out);

/* trilogy_reader_get_uint64 - Parse an unsigned 64-bit integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint64_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_uint64(trilogy_reader_t *reader, uint64_t *out);

int trilogy_reader_get_float(trilogy_reader_t *reader, float *out);

int trilogy_reader_get_double(trilogy_reader_t *reader, double *out);

/* trilogy_reader_get_lenenc - Parse an unsigned, length-encoded integer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * out    - Out parameter; A pointer to a uint64_t which will be set to the
 *          value read from the buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_lenenc(trilogy_reader_t *reader, uint64_t *out);

/* trilogy_reader_get_buffer - Parse an opaque set of bytes from the packet,
 * pointing the dereferenced value of `out` to the beginning of the set.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * len    - The number of bytes to attempt to read from the buffer.
 * out    - Out parameter; A pointer to a void* which will be set to the
 *          beginning of the opaque buffer. This will be a pointer into the
 *          buffer that was originally passed to trilogy_reader_init. No copies
 * are made internally.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed and the dereferenced value of
 *                           `out` now points to it.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_buffer(trilogy_reader_t *reader, size_t len, const void **out);

/* trilogy_reader_copy_buffer - Parse an opaque set of bytes from the packet and
 * copy them into `out`. `out` must be allocated with at least `len` bytes.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 * len    - The number of bytes to attempt to read from the buffer.
 * out    - A pointer to the address to copy `len` bytes from the packet buffer
 *          to.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed and copied into the location
 *                           `out` points to.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_copy_buffer(trilogy_reader_t *reader, size_t len, void *out);

/* trilogy_reader_get_lenenc_buffer - Parse an opaque set of bytes from the
 * packet, pointing the dereferenced value of `out` to the beginning of the set.
 * The length of the buffer is defined by a preceding length-encoded integer,
 * who's value will be copied in to `out_len`.
 *
 * reader  - A pointer to a pre-initialized trilogy_reader_t.
 * out_len - Out parameter; The length of the read buffer in bytes.
 * out     - Out parameter; A pointer to a void* which will be set to the
 *           beginning of the opaque buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed and the dereferenced value of
 *                           `out` now points to it.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_lenenc_buffer(trilogy_reader_t *reader, size_t *out_len, const void **out);

/* trilogy_reader_get_string - Parse a C-string from the packet, pointing the
 * dereferenced value of `out` to the beginning of the set.
 *
 * reader  - A pointer to a pre-initialized trilogy_reader_t.
 * out_len - Out parameter; The length of the C-string read from the buffer in
 *           bytes.
 * out     - Out parameter; A pointer to a void* which will be set to the
 *           beginning of the C-string.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed and the dereferenced value of
 *                           `out` now points to it.
 *   TRILOGY_TRUNCATED_PACKET - There isn't enough data left in the buffer.
 */
int trilogy_reader_get_string(trilogy_reader_t *reader, const char **out, size_t *out_len);

/* trilogy_reader_get_eof_buffer - Parse an opaque set of bytes from the packet,
 * pointing the dereferenced value of `out` to the beginning of the set. The
 * buffer pointed to by `out` will contain the remaining un-parsed bytes from
 * the packet buffer.
 *
 * This will just hand the caller back a pointer into the remainder of the
 * buffer, even if there aren't any more bytes left to read. As a result, this
 * function will only ever return TRILOGY_OK.
 *
 * reader  - A pointer to a pre-initialized trilogy_reader_t.
 * out_len - Out parameter; The length of the read buffer in bytes.
 * out     - Out parameter; A pointer to a void* which will be set to the
 *           beginning of the opaque buffer.
 *
 * Return values:
 *   TRILOGY_OK               - The value was parsed and the dereferenced value of
 *                           `out` now points to it.
 */
int trilogy_reader_get_eof_buffer(trilogy_reader_t *reader, size_t *out_len, const void **out);

/* trilogy_reader_eof - Check if the reader is at the end of the buffer.
 *
 * reader - A pointer to a pre-initialized trilogy_reader_t.
 *
 * Returns true if the reader is at the end of the buffer it's reading from,
 * or false if not
 */
bool trilogy_reader_eof(trilogy_reader_t *reader);

/* trilogy_reader_finish - Finalize the reader. This will ensure the entire buffer
 * was parsed, otherwise TRILOGY_EXTRA_DATA_IN_PACKET will be returned.
 *
 * This can be useful to ensure an entire packet is fully read.
 *
 * reader  - A pointer to a pre-initialized trilogy_reader_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The entire buffer was parsed.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the buffer.
 */
int trilogy_reader_finish(trilogy_reader_t *reader);

#endif
