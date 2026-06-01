#ifndef TRILOGY_BUILDER_H
#define TRILOGY_BUILDER_H

#include <stddef.h>
#include <stdint.h>

#include "trilogy/buffer.h"

/* Trilogy Packet Builder API
 *
 * The builder API is used for building protocol packet buffers.
 */

/* trilogy_builder_t - The builder API's instance type.
 */
typedef struct {
    trilogy_buffer_t *buffer;
    size_t header_offset;
    size_t packet_length;
    size_t packet_max_length;
    uint32_t fragment_length;
    uint8_t seq;
} trilogy_builder_t;

/* trilogy_builder_init - Initialize a pre-allocated trilogy_builder_t
 *
 * builder - A pre-allocated trilogy_builder_t pointer
 * buffer  - A pre-initialized trilogy_buffer_t pointer
 * seq     - The initial sequence number for the packet to be built. This is
 *           the initial number because the builder API will automatically
 *           split buffers that are larger than TRILOGY_MAX_PACKET_LEN into
 *           multiple packets and increment the sequence number in each packet
 *           following the initial.
 *
 * Return values:
 *   TRILOGY_OK     - The builder was successfully initialized.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_builder_init(trilogy_builder_t *builder, trilogy_buffer_t *buffer, uint8_t seq);

/* trilogy_builder_finalize - Finalize internal buffer state, ensuring all of the
 * packets inside are valid and ready for use over the wire.
 *
 * builder - A pre-initialized trilogy_builder_t pointer.
 *
 * Returns nothing.
 */
void trilogy_builder_finalize(trilogy_builder_t *builder);

/* trilogy_builder_write_uint8 - Append an unsigned 8-bit integer to the packet
 * buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer.
 * val     - The value to append to the buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_uint8(trilogy_builder_t *builder, uint8_t val);

/* trilogy_builder_write_uint16 - Append an unsigned 16-bit integer to the packet
 * buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer.
 * val     - The value to append to the buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_uint16(trilogy_builder_t *builder, uint16_t val);

/* trilogy_builder_write_uint24 - Append an unsigned 24-bit integer to the packet
 * buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer.
 * val     - The value to append to the buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_uint24(trilogy_builder_t *builder, uint32_t val);

/* trilogy_builder_write_uint32 - Append an unsigned 32-bit integer to the packet
 * buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * val     - The value to append to the buffer
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_uint32(trilogy_builder_t *builder, uint32_t val);

/* trilogy_builder_write_uint64 - Append an unsigned 64-bit integer to the packet
 * buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * val     - The value to append to the buffer
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_uint64(trilogy_builder_t *builder, uint64_t val);

/* trilogy_builder_write_float - Append a float to the packet buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * val     - The value to append to the buffer
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_float(trilogy_builder_t *builder, float val);

/* trilogy_builder_write_double - Append a double to the packet buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * val     - The value to append to the buffer
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_double(trilogy_builder_t *builder, double val);

/* trilogy_builder_write_lenenc - Append a length-encoded integer to the packet
 * buffer.
 *
 * The actual number of bytes appended to the buffer depends on the value passed
 * in.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * val     - The value to append to the buffer
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_lenenc(trilogy_builder_t *builder, uint64_t val);

/* trilogy_builder_write_buffer - Append opaque bytes to the packet buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * data    - A pointer to the opaque data to be appended
 * len     - The number of bytes to append from the location in memory the
 *           `data` parameter points to.
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_buffer(trilogy_builder_t *builder, const void *data, size_t len);

/* trilogy_builder_write_lenenc_buffer - Append opaque bytes to the packet buffer,
 * prepended by its length as a length-encoded integer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * data    - A pointer to the opaque data to be appended
 * len     - The number of bytes to append from the location in memory the
 *           `data` parameter points to.
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_lenenc_buffer(trilogy_builder_t *builder, const void *data, size_t len);

/* trilogy_builder_write_string - Append a C-string to the packet buffer.
 *
 * builder - A pre-initialized trilogy_builder_t pointer
 * data    - A pointer to the C-string to append
 *
 * Return values:
 *   TRILOGY_OK     - The value was appended to the packet buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_MAX_PACKET_EXCEEDED - Appending this value would exceed the maximum
 *                                 packet size.
 */
int trilogy_builder_write_string(trilogy_builder_t *builder, const char *data);

/* trilogy_builder_set_max_packet_length - Set the maximum packet length for
 * the builder. Writing data to the builder that would cause the packet length
 * to exceed this value will cause the builder to error.
 *
 * builder    - A pre-initialized trilogy_builder_t pointer
 * max_length - The new maximum packet length to set
 *
 * Return values:
 *   TRILOGY_OK                  - The maximum packet length was set.
 *   TRILOGY_MAX_PACKET_EXCEEDED - The current packet length is already
 *                                 larger than the requested maximum.
 */
int trilogy_builder_set_max_packet_length(trilogy_builder_t *builder, size_t max_length);

#endif
