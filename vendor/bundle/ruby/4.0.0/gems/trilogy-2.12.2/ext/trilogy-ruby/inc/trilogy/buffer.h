#ifndef TRILOGY_BUFFER_H
#define TRILOGY_BUFFER_H

#include <stddef.h>
#include <stdint.h>

/* trilogy_buffer_t - A convenience type used for wrapping a reusable chunk of
 * memory.
 */
typedef struct {
    size_t len;
    size_t cap;
    uint8_t *buff;
} trilogy_buffer_t;

/* trilogy_buffer_init - Initialize an trilogy_buffer_t and pre-allocate
 * `initial_capacity` bytes.
 *
 * buffer           - A pointer to an allocated, uninitialized trilogy_buffer_t.
 * initial_capacity - The initial capacity for the buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The buffer was initialized.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_buffer_init(trilogy_buffer_t *buffer, size_t initial_capacity);

/* trilogy_buffer_expand - Make sure there is at least `needed` bytes available in
 * the underlying buffer, resizing it to be larger if necessary.
 *
 * buffer - A pre-initialized trilogy_buffer_t pointer.
 * needed - The amount of space requested to be available in the buffer after
 *          after this call returns.
 *
 * Return values:
 *   TRILOGY_OK     - The buffer is guaranteed to have at least `needed` bytes of
 *                 space available.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_TYPE_OVERFLOW - The amount of buffer spaced needed is larger than the
 *                         what can be represented by `size_t`.
 */
int trilogy_buffer_expand(trilogy_buffer_t *buffer, size_t needed);

/* trilogy_buffer_putc - Appends a byte to the buffer, resizing the underlying
 * allocation if necessary.
 *
 * buffer - A pointer to a pre-initialized trilogy_buffer_t.
 * c      - The byte to append to the buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The character was appended to the buffer
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_buffer_putc(trilogy_buffer_t *buffer, uint8_t c);

/* trilogy_buffer_write - Appends multiple bytes to the buffer, resizing the underlying
 * allocation if necessary.
 *
 * buffer - A pointer to a pre-initialized trilogy_buffer_t.
 * ptr    - The pointer to the byte array.
 * len    - How many bytes to append.
 *
 * Return values:
 *   TRILOGY_OK     - The character was appended to the buffer
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_buffer_write(trilogy_buffer_t *buffer, const uint8_t *ptr, size_t len);

/* trilogy_buffer_free - Free an trilogy_buffer_t's underlying storage. The buffer
 * must be re-initialized with trilogy_buffer_init if it is to be reused. Any
 * operations performed on an unintialized or freed buffer are undefined.
 *
 * buffer - An initialized trilogy_buffer_t.
 */
void trilogy_buffer_free(trilogy_buffer_t *buffer);

#endif
