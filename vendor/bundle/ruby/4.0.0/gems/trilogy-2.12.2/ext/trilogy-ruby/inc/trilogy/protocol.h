#ifndef TRILOGY_PROTOCOL_H
#define TRILOGY_PROTOCOL_H

#include "trilogy/builder.h"
#include "trilogy/charset.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TRILOGY_CAPABILITIES(XX)                                                                                       \
    XX(TRILOGY_CAPABILITIES_NONE, 0)                                                                                   \
    /* Not used. This flag is assumed by current servers.                                                              \
     *                                                                                                                 \
     * From client: tells the server the client intends to use the newer                                               \
     * password hashing algorithm.                                                                                     \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_LONG_PASSWORD, 0x00000001)                                                                 \
    /* From client: tells the server to set the affected_rows field to the                                             \
     * number of rows found by the query instead of the actual number of rows                                          \
     * updated.                                                                                                        \
     *                                                                                                                 \
     * For example, the following update statement would set affected_rows to                                          \
     * 1: `UPDATE users SET login = "brianmario1" WHERE login = "brianmario";`                                         \
     *                                                                                                                 \
     * But an update statement which didn't actually perform any updates like:                                         \
     *   `UPDATE users SET login = "brianmario" WHERE login = "brianmario";`                                           \
     * would have normally set affected_rows to 0. That's where this flag                                              \
     * comes in to play. By setting this flag during the authentication phase                                          \
     * of a connection - the above query will set affected_rows to 1.                                                  \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_FOUND_ROWS, 0x00000002)                                                                    \
    /* Not used. This flag was only used by the older (pre-4.1) protocol.                                              \
     *                                                                                                                 \
     * From server: the server supports a longer flags field in column                                                 \
     * definition packets.                                                                                             \
     *                                                                                                                 \
     * From client: the client supports longer flags field in column                                                   \
     * definition packets.                                                                                             \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_LONG_FLAG, 0x00000004)                                                                     \
    /* From server: the server supports a database name being passed in the                                            \
     * handshake response packet.                                                                                      \
     *                                                                                                                 \
     * From client: tells the server there is a database name in the handshake                                         \
     * response packet.                                                                                                \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_CONNECT_WITH_DB, 0x00000008)                                                               \
    /* From client: tells the server to not allow `database.table.column`                                              \
     * notation in query syntax.                                                                                       \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_NO_SCHEMA, 0x00000010)                                                                     \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: the server supports compression.                                                                   \
     *                                                                                                                 \
     * From client: tells the server to enable the compression protocol.                                               \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_COMPRESS, 0x00000020)                                                                      \
    /* Not used since 3.22.                                                                                            \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_ODBC, 0x00000040)                                                                          \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: server support `LOAD DATA INFILE` and `LOAD XML`.                                                  \
     *                                                                                                                 \
     * From client: tells the server that the client supports `LOAD DATA LOCAL                                         \
     * INFILE`.                                                                                                        \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_LOCAL_FILES, 0x00000080)                                                                   \
    /* From server: the query parser can ignore spaces before the '('                                                  \
     * character.                                                                                                      \
     *                                                                                                                 \
     * From client: tells the server to ignore spaces before the '('                                                   \
     * character.                                                                                                      \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_IGNORE_SPACE, 0x00000100)                                                                  \
    /* From server: the server supports the 4.1+ protocol.                                                             \
     *                                                                                                                 \
     * From client: the client is using the 4.1+ protocol. This will always be                                         \
     * set, as trilogy only supports the 4.1+ protocol.                                                                \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_PROTOCOL_41, 0x00000200)                                                                   \
    /* Not used.                                                                                                       \
     *                                                                                                                 \
     * From server: the server supports interactive and non-interactive                                                \
     * clients.                                                                                                        \
     *                                                                                                                 \
     * From client: the client is interactive.                                                                         \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_INTERACTIVE, 0x00000400)                                                                   \
    /* From server: the server supports ssl.                                                                           \
     *                                                                                                                 \
     * From client: tells the server it should switch to an ssl connection.                                            \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_SSL, 0x00000800)                                                                           \
    /* From server: the server supports transactions and is capable of reporting transaction status.                   \
     *                                                                                                                 \
     * From client: the client is aware of servers that support transactions.                                          \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_TRANSACTIONS, 0x00002000)                                                                  \
    /* Not used.                                                                                                       \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_RESERVED, 0x00004000)                                                                      \
    /* From server: server supports the 4.1+ protocol's native authentication                                          \
     * scheme.                                                                                                         \
     *                                                                                                                 \
     * From client: client supports the 4.1+ protocol's native authentication                                          \
     * scheme. This will always be set.                                                                                \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_SECURE_CONNECTION, 0x00008000)                                                             \
    /* From server: the server can handle multiple statements per                                                      \
     * query/prepared statement.                                                                                       \
     *                                                                                                                 \
     * From client: tells the server it may send multiple statements per                                               \
     * query/ prepared statement.                                                                                      \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_MULTI_STATEMENTS, 0x00010000)                                                              \
    /* From server: the server is capable of sending multiple result sets from                                         \
     * a query.                                                                                                        \
     *                                                                                                                 \
     * From client: tells the server it's capable of handling multiple result                                          \
     * sets from a query.                                                                                              \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_MULTI_RESULTS, 0x00020000)                                                                 \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: the server is capable of sending multiple result sets from                                         \
     * a prepared statement.                                                                                           \
     *                                                                                                                 \
     * From client: tells the server it's capable of handling multiple result                                          \
     * sets from a prepared statement.                                                                                 \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_PS_MULTI_RESULTS, 0x00040000)                                                              \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: the server supports the pluggable authentication protocol.                                         \
     *                                                                                                                 \
     * From client: tells the server that the client supports the pluggable                                            \
     * authentication protocol.                                                                                        \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_PLUGIN_AUTH, 0x00080000)                                                                   \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: the server allows connection attributes to be set in the                                           \
     * handshake response packet during authentication.                                                                \
     *                                                                                                                 \
     * From client: tells the server that there are connection attributes in                                           \
     * the handshake response.                                                                                         \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_CONNECT_ATTRS, 0x00100000)                                                                 \
    /* Not implemented.                                                                                                \
     *                                                                                                                 \
     * From server: the server is capable of parsing length-encoded data in                                            \
     * the handshake response during authentication.                                                                   \
     *                                                                                                                 \
     * From client: tells the server that the authentication data in the                                               \
     * handshake response is length-encoded.                                                                           \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_PLUGIN_AUTH_LENENC_CLIENT_DATA, 0x00200000)                                                \
    /* From server: the server supports the expired password extension.                                                \
     *                                                                                                                 \
     * From client: the client supports expired passwords.                                                             \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_CAN_HANDLE_EXPIRED_PASSWORDS, 0x00400000)                                                  \
    /* From server: the server may set the                                                                             \
     * TRILOGY_SERVER_STATUS_SESSION_STATE_CHANGED flag in OK packets. Which                                           \
     * will also mean the OK packet includes session-state change data.                                                \
     *                                                                                                                 \
     * From client: tells the server that the client expects the server to                                             \
     * send session-state change data in OK packets.                                                                   \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_SESSION_TRACK, 0x00800000)                                                                 \
    /* From server: the server will send OK packets in place of EOF packets.                                           \
     *                                                                                                                 \
     * From client: tells the server that it expects to be sent OK packets in                                          \
     * place of EOF packets.                                                                                           \
     */                                                                                                                \
    XX(TRILOGY_CAPABILITIES_DEPRECATE_EOF, 0x01000000)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_CAPABILITIES(XX)
#undef XX

    /* A convenience bitmask with common client capabilities set. */
    TRILOGY_CAPABILITIES_CLIENT = (TRILOGY_CAPABILITIES_PROTOCOL_41 | TRILOGY_CAPABILITIES_SECURE_CONNECTION |
                                   TRILOGY_CAPABILITIES_DEPRECATE_EOF | TRILOGY_CAPABILITIES_SESSION_TRACK |
                                   TRILOGY_CAPABILITIES_PLUGIN_AUTH | TRILOGY_CAPABILITIES_TRANSACTIONS)
} TRILOGY_CAPABILITIES_t;

#define TRILOGY_SERVER_STATUS(XX)                                                                                      \
    /* The connection session is in a transaction.                                                                     \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_IN_TRANS, 0x0001)                                                                         \
    /* The connection session has `autocommit` enabled. `autocommit` mode                                              \
     * makes the database write any updates to tables immediately. This mode is                                               \
     * enabled by default in. This mode is implicitly disabled for all                                                 \
     * statements between a `START TRANSACTION` and corresponding `COMMIT`. It                                         \
     * can be disabled with the statement: `SET autocommit=0`.                                                         \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_AUTOCOMMIT, 0x0002)                                                                       \
                                                                                                                       \
    /* This flag means there are more results available to be read from the                                            \
     *  result  set. It will be set on the last (EOF/OK) packet from a result                                          \
     * set.                                                                                                            \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_MORE_RESULTS_EXISTS, 0x0008)                                                              \
                                                                                                                       \
    /* No good index was used to perform the query.                                                                    \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_NO_GOOD_INDEX_USED, 0x0010)                                                               \
                                                                                                                       \
    /* No index was used to perform the query.                                                                         \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_NO_INDEX_USED, 0x0020)                                                                    \
                                                                                                                       \
    /* When using the prepared statement protocol, this will be set when a                                             \
     * read- only, non-scrollable cursor was opened from an `execute` command.                                         \
     * It will also be set for replies to `fetch` commands.                                                            \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_CURSOR_EXISTS, 0x0040)                                                                    \
                                                                                                                       \
    /* When using the prepared statement protocol, this will be set when a                                             \
     * read- only cursor has been exhausted. This will be set for replies to                                           \
     * `fetch` commands.                                                                                               \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_LAST_ROW_SENT, 0x0080)                                                                    \
                                                                                                                       \
    /* This will be set if a database was dropped.                                                                     \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_DB_DROPPED, 0x0100)                                                                       \
                                                                                                                       \
    /* This will be set if the `NO_BACKSLASH_ESCAPES` sql mode is enabled. The                                         \
     * caller can enable this mode by using the statement:                                                             \
     * `SET SQL_MODE=NO_BACKSLASH_ESCAPES`.                                                                            \
     *                                                                                                                 \
     * The `NO_BACKSLASH_ESCAPES` sql mode disables the use of the backslash                                           \
     * ('\') character as an escape character.                                                                         \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_NO_BACKSLASH_ESCAPES, 0x0200)                                                             \
                                                                                                                       \
    /* This will be set if a re-prepare of a prepared statement meant that a                                           \
     * different number of columns would be returned as part of the result                                             \
     * set.                                                                                                            \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_METADATA_CHANGED, 0x0400)                                                                 \
                                                                                                                       \
    /* This will be set if the last query that was executed took longer than                                           \
     * the `long_query_time` system variable.                                                                          \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_QUERY_WAS_SLOW, 0x0800)                                                                   \
                                                                                                                       \
    /* The prepared statement result set contains out parameters.                                                      \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_PS_OUT_PARAMS, 0x1000)                                                                    \
                                                                                                                       \
    /* Set if the current multi-statement transaction is a read-only                                                   \
     * transaction. If this is set, `TRILOGY_SERVER_STATUS_IN_TRANS` will be set                                       \
     * as well.                                                                                                        \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_STATUS_IN_TRANS_READONLY, 0x2000)                                                         \
                                                                                                                       \
    /* If set, the OK packet contains includes session-state change data.                                              \
     */                                                                                                                \
    XX(TRILOGY_SERVER_STATUS_SESSION_STATE_CHANGED, 0x4000)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_SERVER_STATUS(XX)
#undef XX
} TRILOGY_SERVER_STATUS_t;

#define TRILOGY_TYPES(XX)                                                                                              \
    XX(TRILOGY_TYPE_DECIMAL, 0x00)                                                                                     \
    XX(TRILOGY_TYPE_TINY, 0x01)                                                                                        \
    XX(TRILOGY_TYPE_SHORT, 0x02)                                                                                       \
    XX(TRILOGY_TYPE_LONG, 0x03)                                                                                        \
    XX(TRILOGY_TYPE_FLOAT, 0x04)                                                                                       \
    XX(TRILOGY_TYPE_DOUBLE, 0x05)                                                                                      \
    XX(TRILOGY_TYPE_NULL, 0x06)                                                                                        \
    XX(TRILOGY_TYPE_TIMESTAMP, 0x07)                                                                                   \
    XX(TRILOGY_TYPE_LONGLONG, 0x08)                                                                                    \
    XX(TRILOGY_TYPE_INT24, 0x09)                                                                                       \
    XX(TRILOGY_TYPE_DATE, 0x0a)                                                                                        \
    XX(TRILOGY_TYPE_TIME, 0x0b)                                                                                        \
    XX(TRILOGY_TYPE_DATETIME, 0x0c)                                                                                    \
    XX(TRILOGY_TYPE_YEAR, 0x0d)                                                                                        \
    XX(TRILOGY_TYPE_VARCHAR, 0x0f)                                                                                     \
    XX(TRILOGY_TYPE_BIT, 0x10)                                                                                         \
    XX(TRILOGY_TYPE_VECTOR, 0xf2)                                                                                      \
    XX(TRILOGY_TYPE_JSON, 0xf5)                                                                                        \
    XX(TRILOGY_TYPE_NEWDECIMAL, 0xf6)                                                                                  \
    XX(TRILOGY_TYPE_ENUM, 0xf7)                                                                                        \
    XX(TRILOGY_TYPE_SET, 0xf8)                                                                                         \
    XX(TRILOGY_TYPE_TINY_BLOB, 0xf9)                                                                                   \
    XX(TRILOGY_TYPE_MEDIUM_BLOB, 0xfa)                                                                                 \
    XX(TRILOGY_TYPE_LONG_BLOB, 0xfb)                                                                                   \
    XX(TRILOGY_TYPE_BLOB, 0xfc)                                                                                        \
    XX(TRILOGY_TYPE_VAR_STRING, 0xfd)                                                                                  \
    XX(TRILOGY_TYPE_STRING, 0xfe)                                                                                      \
    XX(TRILOGY_TYPE_GEOMETRY, 0xff)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_TYPES(XX)
#undef XX
} TRILOGY_TYPE_t;

#define TRILOGY_COLUMN_FLAGS(XX)                                                                                       \
    XX(TRILOGY_COLUMN_FLAG_NONE, 0x0)                                                                                  \
    /* The column has the `NOT NULL` flag set. Requiring all values to not be                                          \
     * NULL.                                                                                                           \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_NOT_NULL, 0x1)                                                                              \
    /* The column is part of a primary key.                                                                            \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_PRI_KEY, 0x2)                                                                               \
    /* The column has the `UNIQUE` flag set. Requring all values to be unique.                                         \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_UNIQUE_KEY, 0x4)                                                                            \
    /* The column is part of a key.                                                                                    \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_MULTIPLE_KEY, 0x8)                                                                          \
    /* The column is a blob.                                                                                           \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_BLOB, 0x10)                                                                                 \
    /* The column is a numeric type and has the `UNSIGNED` flag set.                                                   \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_UNSIGNED, 0x20)                                                                             \
    /* The column is flagged as zero fill.                                                                             \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_ZEROFILL, 0x40)                                                                             \
    /* This column is flagged as binary. This will be set for any of the                                               \
     * binary field types like BINARY, VARBINARY, TINYBLOB, BLOB, MEDIUMBLOB                                           \
     * and LONGBLOB.                                                                                                   \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_BINARY, 0x80)                                                                               \
    /* The column is an `ENUM`                                                                                         \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_ENUM, 0x100)                                                                                \
    /* The column is configured to auto-increment.                                                                     \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_AUTO_INCREMENT, 0x200)                                                                      \
    /* The column is a `TIMESTAMP`.                                                                                    \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_TIMESTAMP, 0x400)                                                                           \
    /* The column is a `SET`.                                                                                          \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_SET, 0x800)                                                                                 \
    /* The column has no default value configured.                                                                     \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_NO_DEFAULT_VALUE, 0x1000)                                                                   \
    /* The column is configured to set it's value to `NOW()` on row update.                                            \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_ON_UPDATE_NOW, 0x2000)                                                                      \
    /* The column is used in a partition function.                                                                     \
     */                                                                                                                \
    XX(TRILOGY_COLUMN_FLAG_IN_PART_FUNC, 0x80000)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_COLUMN_FLAGS(XX)
#undef XX
} TRILOGY_COLUMN_FLAG_t;

// Typical response packet types
typedef enum {
    TRILOGY_PACKET_OK = 0x0,
    TRILOGY_PACKET_AUTH_MORE_DATA = 0x01,
    TRILOGY_PACKET_EOF = 0xfe,
    TRILOGY_PACKET_ERR = 0xff,
    TRILOGY_PACKET_UNKNOWN
} TRILOGY_PACKET_TYPE_t;

/*
 * source_uuid:transaction_id
 * (UUID string) ":" (bigint string)
 *      36      + 1 +      20        = 57
 */
#define TRILOGY_MAX_LAST_GTID_LEN 57

#define TRILOGY_SESSION_TRACK(XX)                                                                                      \
    XX(TRILOGY_SESSION_TRACK_SYSTEM_VARIABLES, 0x00)                                                                   \
    XX(TRILOGY_SESSION_TRACK_SCHEMA, 0x01)                                                                             \
    XX(TRILOGY_SESSION_TRACK_STATE_CHANGE, 0x02)                                                                       \
    XX(TRILOGY_SESSION_TRACK_GTIDS, 0x03)                                                                              \
    XX(TRILOGY_SESSION_TRACK_TRANSACTION_CHARACTERISTICS, 0x04)                                                        \
    XX(TRILOGY_SESSION_TRACK_TRANSACTION_STATE, 0x05)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_SESSION_TRACK(XX)
#undef XX
} TRILOGY_SESSION_TRACK_TYPE_t;

#define TRILOGY_SET_SERVER_OPTION(XX)                                                                                  \
    XX(TRILOGY_SET_SERVER_MULTI_STATEMENTS_ON, 0x00)                                                                   \
    XX(TRILOGY_SET_SERVER_MULTI_STATEMENTS_OFF, 0x01)                                                                  \

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_SET_SERVER_OPTION(XX)
#undef XX
} TRILOGY_SET_SERVER_OPTION_TYPE_t;

/* trilogy_build_auth_packet - Build a handshake response (or authentication)
 * packet.
 *
 * This should be sent in response to the initial handshake packet the server
 * sends upon connection.
 *
 * builder          - A pointer to a pre-initialized trilogy_builder_t.
 * user             - The username to use for authentication. Must be a C-string.
 * pass             - The password to use for authentication. Optional, and can be NULL.
 * pass_len         - The length of password in bytes.
 * database         - The initial database to connect to. Optional, and can be NULL.
 * client_encoding  - The charset to use for the connection.
 * auth_plugin      - Plugin authentication mechanism that the server requested.
 * scramble         - The scramble value the server sent in the initial handshake.
 * flags            - Bitmask of TRILOGY_CAPABILITIES_t flags.
 *                    The TRILOGY_CAPABILITIES_PROTOCOL_41 and
 *                    TRILOGY_CAPABILITIES_SECURE_CONNECTION flags will always be set
 *                    internally.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_auth_packet(trilogy_builder_t *builder, const char *user, const char *pass, size_t pass_len,
                              const char *database, TRILOGY_CHARSET_t client_encoding, const char *auth_plugin,
                              const char *scramble, TRILOGY_CAPABILITIES_t flags);

/* trilogy_build_auth_switch_response_packet - Build a response for when
 * authentication switching it requested.
 *
 * This should be sent in response to the initial switch request packet the server
 * sends upon connection.
 *
 * builder     - A pointer to a pre-initialized trilogy_builder_t.
 * pass        - The password to use for authentication.
 * pass_len    - The length of password in bytes.
 * auth_plugin - Plugin authentication mechanism that the server requested.
 * scramble    - The scramble value received from the server.
 * enable_cleartext_plugin - Send cleartext password if requested by server.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 *   TRILOGY_AUTH_PLUGIN_ERROR - The server requested auth plugin is not supported.
 */
int trilogy_build_auth_switch_response_packet(trilogy_builder_t *builder, const char *pass, size_t pass_len,
                                              const char *auth_plugin, const char *scramble, const bool enable_cleartext_plugin);

/* trilogy_build_change_db_packet - Build a change database command packet. This
 * command will change the default database for the connection.
 *
 * builder  - A pointer to a pre-initialized trilogy_builder_t.
 * name     - The name of the database to set as the default.
 * name_len - The length of name in bytes.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_change_db_packet(trilogy_builder_t *builder, const char *name, size_t name_len);

/* trilogy_build_set_option_packet - Build a set option command packet. This
 * command will enable/disable server capabilities for the connection. Options
 * must be one of `enum_mysql_set_option`.
 *
 * builder  - A pointer to a pre-initialized trilogy_builder_t.
 * option   - An integer corresponding to the operation to perform.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_set_option_packet(trilogy_builder_t *builder, const uint16_t option);

/* trilogy_build_ping_packet - Build a ping command packet.
 *
 * builder - A pointer to a pre-initialized trilogy_builder_t.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_ping_packet(trilogy_builder_t *builder);

/* trilogy_build_query_packet - Build a query command packet.
 *
 * builder   - A pointer to a pre-initialized trilogy_builder_t.
 * query     - The query string to be used by the command.
 * query_len - The length of query in bytes.
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_query_packet(trilogy_builder_t *builder, const char *sql, size_t sql_len);

/* trilogy_build_quit_packet - Build a quit command packet.
 *
 * builder - A pointer to a pre-initialized trilogy_builder_t.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                   builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_quit_packet(trilogy_builder_t *builder);

/* trilogy_build_ssl_request_packet - Build an SSL request packet.
 *
 * This should be sent in response to the initial handshake packet the server
 * sends upon connection, where an auth packet would normally be sent. A regular
 * auth packet is to be sent after the SSL handshake completes.
 *
 * builder         - A pointer to a pre-initialized trilogy_builder_t.
 * flags           - Bitmask of TRILOGY_CAPABILITIES_t flags.
 *                   The TRILOGY_CAPABILITIES_PROTOCOL_41 and
 *                   TRILOGY_CAPABILITIES_SECURE_CONNECTION flags will always be set
 *                   internally.
 *                   The TRILOGY_CAPABILITIES_SSL flag will also be set.
 * client_encoding - The charset to use for the connection.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_ssl_request_packet(trilogy_builder_t *builder, TRILOGY_CAPABILITIES_t flags,
                                     TRILOGY_CHARSET_t client_encoding);

#define TRILOGY_SERVER_VERSION_SIZE 32

typedef struct {
    uint8_t proto_version;
    char server_version[TRILOGY_SERVER_VERSION_SIZE];
    uint32_t conn_id;
    char scramble[21];
    uint32_t capabilities;
    TRILOGY_CHARSET_t server_charset;
    uint16_t server_status;
    char auth_plugin[32];
} trilogy_handshake_t;

typedef struct {
    uint64_t affected_rows;
    uint64_t last_insert_id;
    uint16_t status_flags;
    uint16_t warning_count;
    uint16_t txn_status_flags;
    const char *session_status;
    size_t session_status_len;
    const char *session_state_changes;
    size_t session_state_changes_len;
    const char *info;
    size_t info_len;
    const char *last_gtid;
    size_t last_gtid_len;
} trilogy_ok_packet_t;

/* trilogy_stmt_ok_packet_t - Represents a MySQL binary protocol prepare response packet.
 */
typedef struct {
    uint32_t id;
    uint16_t column_count;
    uint16_t parameter_count;
    uint16_t warning_count;
} trilogy_stmt_ok_packet_t;

typedef struct {
    uint16_t warning_count;
    uint16_t status_flags;
} trilogy_eof_packet_t;

typedef struct {
    uint16_t error_code;
    uint8_t sql_state_marker[1];
    uint8_t sql_state[5];
    const char *error_message;
    size_t error_message_len;
} trilogy_err_packet_t;

typedef struct {
    char auth_plugin[32];
    char scramble[21];
} trilogy_auth_switch_request_packet_t;

typedef struct {
    const char *catalog;
    size_t catalog_len;
    const char *schema;
    size_t schema_len;
    const char *table;
    size_t table_len;
    const char *original_table;
    size_t original_table_len;
    const char *name;
    size_t name_len;
    const char *original_name;
    size_t original_name_len;
    TRILOGY_CHARSET_t charset;
    uint32_t len;
    TRILOGY_TYPE_t type;
    uint16_t flags;
    uint8_t decimals;
    const char *default_value;
    size_t default_value_len;
} trilogy_column_packet_t;

typedef struct {
    uint64_t column_count;
} trilogy_result_packet_t;

typedef struct {
    bool is_null;
    const void *data;
    size_t data_len;
} trilogy_value_t;

/* trilogy_binary_value_t - MySQL binary protocol value type
 *
 */
typedef struct {
    // Flag denoting the value is NULL.
    bool is_null;

    /* Flag denoting the numeric value is unsigned.
     * If this is true, the unsigned numerical value types should be used
     * from the `as` union below.
     *
     * For example, if the value's MySQL type is TRILOGY_TYPE_LONGLONG and
     * `is_unsigned` is `true`, the caller should use the `.as.uint64` field
     * below to access the properly unsigned value.
     */
    bool is_unsigned;

    // The MySQL column type of this value.
    TRILOGY_TYPE_t type;

    /* This union is used for accessing the underlying binary type for the value.
     * Each field member is documented with the MySQL column/value type it maps to.
     */
    union {
        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_DOUBLE
         */
        double dbl;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_LONGLONG
         *
         * Refer to the `is_unsigned` field above to see which member below should
         * be used to access the value.
         */
        int64_t int64;
        uint64_t uint64;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_FLOAT
         */
        float flt;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_LONG
         * TRILOGY_TYPE_INT24
         *
         * Refer to the `is_unsigned` field above to see which member below should
         * be used to access the value.
         */
        uint32_t uint32;
        int32_t int32;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_SHORT
         *
         * Refer to the `is_unsigned` field above to see which member below should
         * be used to access the value.
         */
        uint16_t uint16;
        int16_t int16;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_TINY
         *
         * Refer to the `is_unsigned` field above to see which member below should
         * be used to access the value.
         */
        uint8_t uint8;
        int8_t int8;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_STRING
         * TRILOGY_TYPE_VARCHAR
         * TRILOGY_TYPE_VAR_STRING
         * TRILOGY_TYPE_ENUM
         * TRILOGY_TYPE_SET
         * TRILOGY_TYPE_LONG_BLOB
         * TRILOGY_TYPE_MEDIUM_BLOB
         * TRILOGY_TYPE_BLOB
         * TRILOGY_TYPE_TINY_BLOB
         * TRILOGY_TYPE_GEOMETRY
         * TRILOGY_TYPE_BIT
         * TRILOGY_TYPE_DECIMAL
         * TRILOGY_TYPE_NEWDECIMAL
         */
        struct {
            const void *data;
            size_t len;
        } str;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_YEAR
         */
        uint16_t year;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_DATE
         * TRILOGY_TYPE_DATETIME
         * TRILOGY_TYPE_TIMESTAMP
         */
        struct {
            uint16_t year;
            uint8_t month, day;
            struct {
                uint8_t hour, minute, second;
                uint32_t micro_seconds;
            } datetime;
        } date;

        /* MySQL types that use this field:
         *
         * TRILOGY_TYPE_TIME
         */
        struct {
            bool is_negative;
            uint32_t days;
            uint8_t hour, minute, second;
            uint32_t micro_seconds;
        } time;
    } as;
} trilogy_binary_value_t;

/* trilogy_build_stmt_prepare_packet - Build a prepared statement prepare command packet.
 *
 * builder   - A pointer to a pre-initialized trilogy_builder_t.
 * query     - The query string to be used by the prepared statement.
 * query_len - The length of query in bytes.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_stmt_prepare_packet(trilogy_builder_t *builder, const char *sql, size_t sql_len);

// Prepared statement flags
typedef enum {
    TRILOGY_CURSOR_TYPE_NO_CURSOR  = 0x00,
    TRILOGY_CURSOR_TYPE_READ_ONLY  = 0x01,
    TRILOGY_CURSOR_TYPE_FOR_UPDATE = 0x02,
    TRILOGY_CURSOR_TYPE_SCROLLABLE = 0x04,
    TRILOGY_CURSOR_TYPE_UNKNOWN
} TRILOGY_STMT_FLAGS_t;

/* trilogy_build_stmt_execute_packet - Build a prepared statement execute command packet.
 *
 * builder   - A pointer to a pre-initialized trilogy_builder_t.
 * stmt_id   - The statement id for which to build the execute packet with.
 * flags     - The flags (TRILOGY_STMT_FLAGS_t) to be used with this execute command packet.
 * binds     - Pointer to an array of trilogy_binary_value_t's.
 * num_binds - The number of elements in the binds array above.
 *
 * Return values:
 *   TRILOGY_OK                 - The packet was successfully built and written to the
 *                                builder's internal buffer.
 *   TRILOGY_PROTOCOL_VIOLATION - num_binds is > 0 but binds is NULL.
 *   TRILOGY_UNKNOWN_TYPE       - An unsupported or unknown MySQL type was used in the list
 *                                of binds.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_build_stmt_execute_packet(trilogy_builder_t *builder, uint32_t stmt_id, uint8_t flags,
                                      trilogy_binary_value_t *binds, uint16_t num_binds);

/* trilogy_build_stmt_bind_data_packet - Build a prepared statement bind long data command packet.
 *
 * builder  - A pointer to a pre-initialized trilogy_builder_t.
 * stmt_id  - The statement id for which to build the bind data packet with.
 * param_id - The parameter index for which the supplied data should be bound to.
 * data     - A pointer to the buffer containing the data to be bound.
 * data_len - The length of the data buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_stmt_bind_data_packet(trilogy_builder_t *builder, uint32_t stmt_id, uint16_t param_id, uint8_t *data,
                                        size_t data_len);

/* trilogy_build_stmt_reset_packet - Build a prepared statement reset command packet.
 *
 * builder - A pointer to a pre-initialized trilogy_builder_t.
 * stmt_id - The statement id for which to build the reset packet with.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_stmt_reset_packet(trilogy_builder_t *builder, uint32_t stmt_id);

/* trilogy_build_stmt_close_packet - Build a prepared statement close command packet.
 *
 * builder - A pointer to a pre-initialized trilogy_builder_t.
 * stmt_id - The statement id for which to build the close packet with.
 *
 * Return values:
 *   TRILOGY_OK     - The packet was successfully built and written to the
 *                    builder's internal buffer.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_build_stmt_close_packet(trilogy_builder_t *builder, uint32_t stmt_id);

/* The following parsing functions assume the buffer and length passed in point
 * to one full MySQL-compatible packet. If the buffer contains more than one packet or
 * has any extra data at the end, these functions will return
 * TRILOGY_EXTRA_DATA_IN_PACKET.
 */

/* trilogy_parse_handshake_packet - Parse an initial handshake packet from a
 * buffer.
 *
 * buff       - A pointer to the buffer containing the initial handshake packet
 *              data.
 * len        - The length of buff in bytes.
 * out_packet - Out parameter; A pointer to a pre-allocated trilogy_handshake_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_PROTOCOL_VIOLATION   - The protocol version parsed wasn't what
 *                                  the Trilogy API supports (0xa); Or the
 *                                  packet is corrupt.
 *   TRILOGY_INVALID_CHARSET      - The charset parsed isn't in the range
 *                                  supported by the Trilogy API.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_handshake_packet(const uint8_t *buff, size_t len, trilogy_handshake_t *out_packet);

/* trilogy_parse_ok_packet - Parse an OK packet.
 *
 * buff         - A pointer to the buffer containing the OK packet data.
 * len          - The length of buff in bytes.
 * capabilities - A bitmask of TRILOGY_CAPABILITIES_t flags.
 * out_packet   - Out parameter; A pointer to a pre-allocated trilogy_ok_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_ok_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_ok_packet_t *out_packet);

/* trilogy_parse_eof_packet - Parse an EOF packet.
 *
 * buff         - A pointer to the buffer containing the EOF packet data.
 * len          - The lenght of buff in bytes.
 * capabilities - A bitmask of TRILOGY_CAPABILITIES_t flags.
 * out_packet   - Out parameter; A pointer to a pre-allocated
 * trilogy_eof_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_eof_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_eof_packet_t *out_packet);

/* trilogy_parse_err_packet - Parse an ERR packet.
 *
 * buff         - A pointer to the buffer containing the ERR packet data.
 * len          - The length of buffer in bytes.
 * capabilities - A bitmask of TRILOGY_CAPABILITIES_t flags.
 * out_packet   - Out parameter; A pointer to a pre-allocated
 *                trilogy_err_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_err_packet(const uint8_t *buff, size_t len, uint32_t capabilities, trilogy_err_packet_t *out_packet);

/* trilogy_parse_auth_switch_request_packet - Parse an AuthSwitchRequest packet.
 *
 * buff         - A pointer to the buffer containing the AuthSwitchRequest packet data.
 * len          - The length of buffer in bytes.
 * capabilities - A bitmask of TRILOGY_CAPABILITIES_t flags.
 * out_packet   - Out parameter; A pointer to a pre-allocated
 *                trilogy_auth_switch_request_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_auth_switch_request_packet(const uint8_t *buff, size_t len, uint32_t capabilities,
                                             trilogy_auth_switch_request_packet_t *out_packet);

/* trilogy_parse_result_packet - Parse a result packet.
 *
 * buff       - A pointer to the buffer containing the result packet data.
 * len        - The length of buffer in bytes.
 * out_packet - Out parameter; A pointer to a pre-allocated
 *              trilogy_result_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 * parameter has been filled in. TRILOGY_TRUNCATED_PACKET     - There isn't enough
 * data in the buffer to parse the packet. TRILOGY_EXTRA_DATA_IN_PACKET - There
 * are unparsed bytes left in the buffer.
 */
int trilogy_parse_result_packet(const uint8_t *buff, size_t len, trilogy_result_packet_t *out_packet);

/* trilogy_parse_column_packet - Parse a column info packet.
 *
 * buff         - A pointer to the buffer containing the column packet data.
 * len          - The length of buffer in bytes.
 * field_list   - Boolean to tell the parser it should expect default value
 *                information at the end of the packet. This will be the case
 *                when parsing column info packets in response to a field list
 *                command.
 * out_packet   - Out parameter; A pointer to a pre-allocated
 *                trilogy_column_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 * parameter has been filled in. TRILOGY_TRUNCATED_PACKET     - There isn't enough
 * data in the buffer to parse the packet. TRILOGY_EXTRA_DATA_IN_PACKET - There
 * are unparsed bytes left in the buffer.
 */
int trilogy_parse_column_packet(const uint8_t *buff, size_t len, bool field_list, trilogy_column_packet_t *out_packet);

/* trilogy_parse_row_packet - Parse a row packet.
 *
 * buff         - A pointer to the buffer containing the result packet data.
 * len          - The length of buffer in bytes.
 * column_count - The number of columns in the response. This parser needs this
 *                in order to know how many values to parse.
 * out_packet   - Out parameter; A pointer to a pre-allocated array of
 *                trilogy_value_t's. There must be enough space to fit all of the
 *                values. This can be computed with:
 *                `(sizeof(trilogy_value_t) * column_count)`.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_row_packet(const uint8_t *buff, size_t len, uint64_t column_count, trilogy_value_t *out_values);

/* trilogy_parse_stmt_ok_packet - Parse a prepared statement ok packet.
 *
 * buff         - A pointer to the buffer containing the result packet data.
 * len          - The length of buffer in bytes.
 * out_packet   - Out parameter; A pointer to a pre-allocated trilogy_stmt_ok_packet_t.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_PROTOCOL_VIOLATION   - Filler byte was something other than zero.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_stmt_ok_packet(const uint8_t *buff, size_t len, trilogy_stmt_ok_packet_t *out_packet);

/* trilogy_parse_stmt_row_packet - Parse a prepared statement row packet.
 *
 * buff         - A pointer to the buffer containing the result packet data.
 * len          - The length of buffer in bytes.
 * columns      - The list of columns from the prepared statement. This parser needs
 *                this in order to match up the value types.
 * column_count - The number of columns in prepared statement. This parser needs this
 *                in order to know how many values to parse.
 * out_values   - Out parameter; A pointer to a pre-allocated array of
 *                trilogy_binary_value_t's. There must be enough space to fit all of the
 *                values. This can be computed with:
 *                `(sizeof(trilogy_binary_value_t) * column_count)`.
 *
 * Return values:
 *   TRILOGY_OK                   - The packet was was parsed and the out
 *                                  parameter has been filled in.
 *   TRILOGY_TRUNCATED_PACKET     - There isn't enough data in the buffer
 *                                  to parse the packet.
 *   TRILOGY_PROTOCOL_VIOLATION   - Invalid length parsed for a TIME/DATETIME/TIMESTAMP value.
 *   TRILOGY_UNKNOWN_TYPE         - An unsupported or unknown MySQL type was seen in the packet.
 *   TRILOGY_EXTRA_DATA_IN_PACKET - There are unparsed bytes left in the
 *                                  buffer.
 */
int trilogy_parse_stmt_row_packet(const uint8_t *buff, size_t len, trilogy_column_packet_t *columns,
                                  uint64_t column_count, trilogy_binary_value_t *out_values);

int trilogy_build_auth_clear_password(trilogy_builder_t *builder, const char *pass, size_t pass_len);

#endif
