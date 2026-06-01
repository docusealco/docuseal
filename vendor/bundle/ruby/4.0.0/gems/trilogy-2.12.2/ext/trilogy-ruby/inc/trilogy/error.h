#ifndef TRILOGY_ERROR_H
#define TRILOGY_ERROR_H

#define TRILOGY_ERROR_CODES(XX)                                                                                        \
    XX(TRILOGY_OK, 0)                                                                                                  \
    XX(TRILOGY_ERR, -1)                                                                                                \
    XX(TRILOGY_EOF, -2)                                                                                                \
    XX(TRILOGY_SYSERR, -3) /* check errno */                                                                           \
    XX(TRILOGY_UNEXPECTED_PACKET, -4)                                                                                  \
    XX(TRILOGY_TRUNCATED_PACKET, -5)                                                                                   \
    XX(TRILOGY_PROTOCOL_VIOLATION, -6)                                                                                 \
    XX(TRILOGY_AUTH_PLUGIN_TOO_LONG, -7)                                                                               \
    XX(TRILOGY_EXTRA_DATA_IN_PACKET, -8)                                                                               \
    XX(TRILOGY_INVALID_CHARSET, -9)                                                                                    \
    XX(TRILOGY_AGAIN, -10)                                                                                             \
    XX(TRILOGY_CLOSED_CONNECTION, -11)                                                                                 \
    XX(TRILOGY_HAVE_RESULTS, -12)                                                                                      \
    XX(TRILOGY_NULL_VALUE, -13)                                                                                        \
    XX(TRILOGY_INVALID_SEQUENCE_ID, -14)                                                                               \
    XX(TRILOGY_TYPE_OVERFLOW, -15)                                                                                     \
    XX(TRILOGY_OPENSSL_ERR, -16) /* check ERR_get_error() */                                                           \
    XX(TRILOGY_UNSUPPORTED, -17)                                                                                       \
    XX(TRILOGY_DNS_ERR, -18)                                                                                           \
    XX(TRILOGY_AUTH_SWITCH, -19)                                                                                       \
    XX(TRILOGY_MAX_PACKET_EXCEEDED, -20)                                                                               \
    XX(TRILOGY_UNKNOWN_TYPE, -21)                                                                                      \
    XX(TRILOGY_TIMEOUT, -22)                                                                                           \
    XX(TRILOGY_AUTH_PLUGIN_ERROR, -23)                                                                                 \
    XX(TRILOGY_MEM_ERROR, -24)

enum {
#define XX(name, code) name = code,
    TRILOGY_ERROR_CODES(XX)
#undef XX
};

/* trilogy_error - Get the string version of an Trilogy error code.
 *
 * This can be useful for logging or debugging as printing the error value
 * integer itself doesn't provide much context.
 *
 * error - An Trilogy error code integer.
 *
 * Returns an error name constant from TRILOGY_ERROR_CODES as a C-string.
 */
const char *trilogy_error(int error);

#endif
