#ifndef TRILOGY_CLIENT_H
#define TRILOGY_CLIENT_H

#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "trilogy/buffer.h"
#include "trilogy/packet_parser.h"
#include "trilogy/protocol.h"
#include "trilogy/socket.h"

/* Trilogy Non-blocking Client API
 *
 * This API is designed for allowing the caller to deal with I/O themselves.
 * The API is split into `_send` and `_recv` calls. Allowing the caller to wait
 * on writeability before calling a `_send` function, and waiting for
 * readability before `_recv` calls. This can especially be useful for
 * applications that live inside of managed runtime or event-loop.
 *
 * Some pseudo-code typical lifecycle of a connection might look something like
 * this:
 *
 *   trilogy_conn_t conn;
 *   trilogy_init(&conn);
 *
 *   trilogy_connect_send(&conn, addrinfo);
 *
 *   trilogy_handshake_t handshake;
 *   trilogy_connect_recv(&conn, &handshake);
 *
 *   trilogy_auth_send(&conn, &handshake, "root", NULL, 0, 0);
 *   int rc = trilogy_auth_recv(&conn, &handshake);
 *   if (rc == TRILOGY_AUTH_SWITCH) {
 *      trilogy_auth_switch_send(&conn, &handshake);
 *     trilogy_auth_recv(&conn, &handshake);
 *   }
 *
 * At this point the connection is open, authenticated, and ready for commands.
 * From here a caller can start issuing commands:
 *
 *   char* db_name = "test";
 *   trilogy_change_db_send(&conn, db_name, strlen(db_name));
 *   trilogy_change_db_recv(&conn);
 *
 * Assuming the connection isn't in an error state, and all responses have been
 * read off the network - it's ready for another command.
 *
 * Specific to the trilogy_query_send/trilogy_query_recv lifecycle - if
 * TRILOGY_HAVE_RESULTS is returned from trilogy_query_recv, the caller *must* read
 * all columns and rows from the server before the connection will be command-
 * ready again. This is a requirement of a MySQL-compatible protocol.
 *
 * trilogy_close_send/trilogy_close_recv may be used to sent a quit command to the
 * server. While this is considered best practice, simply calling trilogy_free
 * to close the socket and free any internal buffers is enough to clean things
 * up.
 */

#define TRILOGY_DEFAULT_BUF_SIZE 32768

/* trilogy_column_t - The Trilogy client's column type.
 */
typedef trilogy_column_packet_t trilogy_column_t;

/* trilogy_conn_t - The Trilogy client's instance type.
 *
 * This type is shared for the non-blocking and blocking versions of the API.
 */
typedef struct {
    uint64_t affected_rows;
    uint64_t last_insert_id;
    uint16_t warning_count;
    char last_gtid[TRILOGY_MAX_LAST_GTID_LEN];
    size_t last_gtid_len;

    uint16_t error_code;
    const char *error_message;
    size_t error_message_len;

    uint32_t capabilities;
    uint16_t server_status;

    trilogy_sock_t *socket;

    // private:
    uint8_t recv_buff[TRILOGY_DEFAULT_BUF_SIZE];
    size_t recv_buff_pos;
    size_t recv_buff_len;

    trilogy_packet_parser_t packet_parser;
    trilogy_buffer_t packet_buffer;
    size_t packet_buffer_written;

    uint64_t column_count;
    bool started_reading_rows;
} trilogy_conn_t;

/* trilogy_init - Initialize a pre-allocated trilogy_conn_t pointer.
 *
 * conn - A pre-allocated trilogy_conn_t pointer.
 *
 * Return values:
 *   TRILOGY_OK     - The trilogy_conn_t pointer was properly initialized
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_init(trilogy_conn_t *conn);

/* trilogy_init_no_buffer - Same as trilogy_init but doesn't allocate the packet buffer
 *
 * conn - A pre-allocated trilogy_conn_t pointer.
 *
 * Return values:
 *   TRILOGY_OK     - The trilogy_conn_t pointer was properly initialized
 */
int trilogy_init_no_buffer(trilogy_conn_t *conn);

/* trilogy_flush_writes - Attempt to flush the internal packet buffer to the
 * network. This must be used if a `_send` function returns TRILOGY_AGAIN, and
 * should continue to be called until it returns a value other than
 * TRILOGY_AGAIN.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK     - The entire packet buffer has been written to the network.
 *   TRILOGY_AGAIN  - Only part of the packet buffer was written to the network or
 *                    the socket wasn't ready for writing. The caller should wait
 *                    for writabilty using `conn->sock`. Then call this function
 *                    until it returns a different value.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_flush_writes(trilogy_conn_t *conn);

/* trilogy_connect_send - Create a socket and attempt initial connection to the
 * server.
 *
 * conn - A pre-initialized trilogy_conn_t pointer.
 * addr - A pre-initialized trilogy_sockopt_t pointer with the connection
 * parameters.
 *
 * Return values:
 *   TRILOGY_OK     - The socket was created and the initial connection has been
 *                    established.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_connect_send(trilogy_conn_t *conn, const trilogy_sockopt_t *opts);

/* trilogy_connect_send_socket - Attempt initial connection to the server using an
 * existing trilogy_sock_t. The socket must _not_ have been connected yet.
 *
 * sock - An instance of trilogy_sock_t
 *
 * Return values:
 *   TRILOGY_OK     - The socket was created and the initial connection has been
 *                    established.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_connect_send_socket(trilogy_conn_t *conn, trilogy_sock_t *sock);

int trilogy_connect_set_fd(trilogy_conn_t *conn, trilogy_sock_t *sock, int fd);

/* trilogy_connect_recv - Read the initial handshake from the server.
 *
 * This should be called after trilogy_connect_send returns TRILOGY_OK. Calling
 * this at any other time during the connection lifecycle is undefined.
 *
 * conn          - A connected trilogy_conn_t pointer. Using a disconnected
 *                 trilogy_conn_t is undefined.
 * handshake_out - A pre-allocated trilogy_handshake_t pointer. If TRILOGY_OK is
 *                 returned, this struct will be filled out and ready to use.
 *
 * Return values:
 *   TRILOGY_OK                 - The initial handshake packet was read off the
 *                                network.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function again.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_connect_recv(trilogy_conn_t *conn, trilogy_handshake_t *handshake_out);

/* trilogy_ssl_request_send - Send an SSL handshake request to the server.
 *
 * This should be called after a successful connection to the server. Calling
 * this at any other time during the connection lifecycle is undefined. It is an
 * error to call this function if TRILOGY_CAPABILITIES_SSL was not set by the
 * server.
 *
 * conn      - A connected trilogy_conn_t pointer. Using a disconnected
 *             trilogy_conn_t is undefined.
 *
 * Return values:
 *   TRILOGY_OK     - Authorization info was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_ssl_request_send(trilogy_conn_t *conn);

/* trilogy_auth_send - Send a authorization info to the server.
 *
 * This should be called after a successful connection to the server. Calling
 * this at any other time during the connection lifecycle is undefined.
 *
 * conn      - A connected trilogy_conn_t pointer. Using a disconnected
 *             trilogy_conn_t is undefined.
 * handshake - A pre-initialized trilogy_handshake_t pointer.
 *
 * Return values:
 *   TRILOGY_OK     - Authorization info was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_auth_send(trilogy_conn_t *conn, const trilogy_handshake_t *handshake);

/* trilogy_auth_recv - Read the authorization response from the server.
 *
 * This should be called after all data written by trilogy_auth_send is flushed to
 * the network. Calling this at any other time during the connection lifecycle
 * is undefined.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK                 - Authorization completed successfully. The
 *                                connection is ready for commands.
 *   TRILOGY_AUTH_SWITCH        - The server requested an auth switch. Use
 *                                `trilogy_auth_switch_send` to reply with the
 *                                confirmation of the switch.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_auth_recv(trilogy_conn_t *conn, trilogy_handshake_t *handshake);

/* trilogy_auth_switch_send - Send a reply after an authentication switch request.
 *
 * This should be called after the server requests and auth switch. Calling
 * this at any other time during the connection lifecycle is undefined.
 *
 * conn      - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is undefined.
 * handshake - A pre-initialized trilogy_handshake_t pointer.
 *
 * Return values:
 *   TRILOGY_OK     - Authorization info was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_auth_switch_send(trilogy_conn_t *conn, const trilogy_handshake_t *handshake);

/* trilogy_change_db_send - Send a change database command to the server. This
 * will change the default database for this connection.
 *
 * This should only be called while the connection is ready for commands.
 *
 * conn     - A connected trilogy_conn_t pointer. Using a disconnected
 *            trilogy_conn_t is undefined.
 * name     - The name of the database.
 * name_len - The length of the database name in bytes.
 *
 * Return values:
 *   TRILOGY_OK     - The change database command was successfully sent to the
 *                    server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_change_db_send(trilogy_conn_t *conn, const char *name, size_t name_len);

/* trilogy_change_db_recv - Read the change database command response from the
 * server.
 *
 * This should be called after all data written by trilogy_change_db_send is
 * flushed to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK                 - The change database command was successfully
 *                                sent to the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The
 *                                caller should wait for readability using
 *                                `conn->sock`. Then call this function until
 *                                it returns a different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_change_db_recv(trilogy_conn_t *conn);

/* trilogy_set_option_send - Send a set option command to the server. This
 * will change server capabilities based on the option selected.
 *
 * This should only be called while the connection is ready for commands.
 *
 * conn     - A connected trilogy_conn_t pointer. Using a disconnected
 *            trilogy_conn_t is undefined.
 * option   - The server option to send.
 *
 * Return values:
 *   TRILOGY_OK     - The change database command was successfully sent to the
 *                    server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_set_option_send(trilogy_conn_t *conn, const uint16_t option);

/* trilogy_set_option_recv - Read the set option command response from the
 * server.
 *
 * This should be called after all data written by trilogy_set_option_send is
 * flushed to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK                 - The set option command was successfully
 *                                sent to the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The
 *                                caller should wait for readability using
 *                                `conn->sock`. Then call this function until
 *                                it returns a different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_set_option_recv(trilogy_conn_t *conn);

/* trilogy_query_send - Send a query command to the server.
 *
 * This should only be called while the connection is ready for commands.
 *
 * conn      - A connected trilogy_conn_t pointer. Using a disconnected
 *             trilogy_conn_t is undefined.
 * query     - The query string.
 * query_len - The length of query string in bytes.
 *
 * Return values:
 *   TRILOGY_OK     - The query command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should
 *                    wait for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_query_send(trilogy_conn_t *conn, const char *query, size_t query_len);

/* trilogy_query_recv - Read the query command response from the server.
 *
 * This should be called after all data written by trilogy_query_send is flushed
 * to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn             - A connected trilogy_conn_t pointer. Using a disconnected
 *                    trilogy_conn_t is undefined.
 * column_count_out - Out parameter; If TRILOGY_HAVE_RESULTS is returned, this
 *                    will be set to the number of columns in the result set.
 *
 * Return values:
 *   TRILOGY_OK                 - The query response was received and fully read.
 *   TRILOGY_HAVE_RESULTS       - The query response was received and there are
 *                                results to be read.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_query_recv(trilogy_conn_t *conn, uint64_t *column_count_out);

/* trilogy_read_column - Read a column from the result set.
 *
 * This should be called as many times as there are columns in the result set.
 * Calling this more times than that is undefined. This should also only be
 * called after a query command has completed and returned TRILOGY_HAVE_RESULTS.
 * Calling this at any other time during the connection lifecycle is undefined.
 *
 * conn       - A connected trilogy_conn_t pointer. Using a disconnected
 *              trilogy_conn_t is undefined.
 * column_out - Out parameter; A pointer to a pre-allocated trilogy_column_t. If
 *              TRILOGY_OK is returned this will be filled out. This value will be
 *              invalid after any other call to this API. The caller should make
 *              a copy if they want to keep the value around.
 *
 * Return values:
 *   TRILOGY_OK                 - The column was successfully read.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_read_column(trilogy_conn_t *conn, trilogy_column_t *column_out);

/* trilogy_read_row - Read a column from the result set.
 *
 * This should be called after reading all columns from the network. Calling
 * this at any other time during the connection lifecycle is undefined.
 *
 * conn       - A connected trilogy_conn_t pointer. Using a disconnected
 *              trilogy_conn_t is undefined.
 * values_out - Out parameter; A pre-allocated trilogy_value_t pointer, which will
 *              be filled out by this function. It should be allocated with
 *              enough space to hold a trilogy_value_t pointer for each column.
 *              Something like: `(sizeof(trilogy_value_t) * column_count)`. This
 *              pointer is invalid after any other call to this API. The caller
 *              should make a copy of the values inside if they want to keep
 *              them around.
 *
 * Return values:
 *   TRILOGY_OK                 - The query response was received and fully read.
 *   TRILOGY_EOF                - There are no more rows to be read.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_read_row(trilogy_conn_t *conn, trilogy_value_t *values_out);

/* trilogy_drain_results - A convenience function to read and throw away the
 * remaining rows from a result set. Any MySQL-compatible protocol requires that all
 * responses from a command are read off the network before any other commands
 * can be issued. A caller could otherwise do the same thing this function does
 * by calling trilogy_read_row until it returns TRILOGY_EOF. But this call does that
 * in a much more efficient manner by only reading packet frames then throwing
 * them away, skipping the parsing of value information from inside each packet.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK                 - The rest of the result was drained and the
 *                                connection is ready for another command.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_drain_results(trilogy_conn_t *conn);

/* trilogy_ping_send - Send a ping command to the server.
 *
 * This should only be called while the connection is ready for commands.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t
 *        is undefined.
 *
 * Return values:
 *   TRILOGY_OK     - The ping command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_ping_send(trilogy_conn_t *conn);

/* trilogy_ping_recv - Read the ping command response from the server.
 *
 * This should be called after all data written by trilogy_ping_send is flushed to
 * the network. Calling this at any other time during the connection lifecycle
 * is undefined.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK                 - The ping command was successfully sent to the
 *                                server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_ping_recv(trilogy_conn_t *conn);

/* trilogy_escape - Escape a string, making it safe to use in a query.
 *
 * This function assumes the input is in an ASCII-compatible encoding. Passing
 * in a string in any other encoding is undefined and will likely corrupt the
 * input. Potentially leaving the caller open to SQL-injection style attacks.
 *
 * If the TRILOGY_SERVER_STATUS_NO_BACKSLASH_ESCAPES flag is set, it will disable
 * the use of the backslash character ("\") as an escape character. Making
 * backslash an ordinary character like any other.
 *
 * That mode can be enabled at runtime by issuing setting the
 * NO_BACKSLASH_ESCAPES sql mode. This can be done with a query like:
 * "SET SQL_MODE=NO_BACKSLASH_ESCAPES"
 *
 * conn            - A pre-initialized trilogy_conn_t pointer.
 * str             - The string to be escaped.
 * len             - The length of `str` in bytes.
 * escaped_str_out - Out parameter; The dereferenced value of this pointer will
 *                   point to the escaped version of `str` if TRILOGY_OK was
 *                   returned.
 * escaped_len_out - Out parameter; The length of the buffer `escaped_str_out`
 *                   points to if TRILOGY_OK was returned.
 *
 * Return values:
 *   TRILOGY_OK     - The input string has been processed.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_escape(trilogy_conn_t *conn, const char *str, size_t len, const char **escaped_str_out,
                   size_t *escaped_len_out);

/* trilogy_close_send - Send a quit command to the server.
 *
 * conn - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *        undefined.
 *
 * Return values:
 *   TRILOGY_OK     - The quit command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_close_send(trilogy_conn_t *conn);

/* trilogy_close_recv - Read the quit command response from the MySQL-compatible server.
 *
 * This should be called after all data written by trilogy_close_send is flushed
 * to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn - A pre-initialized trilogy_conn_t pointer. It can also be connected but
 *        a disconnected trilogy_conn_t will also return TRILOGY_OK.
 *
 * Return values:
 *   TRILOGY_OK                 - The quit command response successfully read from
 *                                the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 */
int trilogy_close_recv(trilogy_conn_t *conn);

/* trilogy_free - Close the connection and free any internal buffers.
 *
 * conn - A pre-initialized trilogy_conn_t pointer.
 *
 * Returns nothing.
 */
void trilogy_free(trilogy_conn_t *conn);

/* trilogy_free - Discard the connection and free any internal buffers.
 *
 * The server won't be notified that connection was closed. This is useful to
 * silently close connections that were inherited after forking without disrupting
 * the parent's process connections.
 *
 * conn - A pre-initialized trilogy_conn_t pointer.
 *
 * Return values:
 *   TRILOGY_OK                 - The connection was successfuly discarded and freed.
 *   TRILOGY_SYSERR             - A system error occurred, check errno. The connection wasn't freed.
 */
int trilogy_discard(trilogy_conn_t *conn);

/* trilogy_stmt_prepare_send - Send a prepared statement prepare command to the server.
 *
 * conn     - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *            undefined.
 * stmt     - A pointer to the buffer containing the statement to prepare.
 * stmt_len - The length of the data buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The quit command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_stmt_prepare_send(trilogy_conn_t *conn, const char *stmt, size_t stmt_len);

/* trilogy_stmt_t - The trilogy client's prepared statement type.
 */
typedef trilogy_stmt_ok_packet_t trilogy_stmt_t;

/* trilogy_stmt_prepare_recv - Read the prepared statement prepare command response
 * from the MySQL-compatible server.
 *
 * This should be called after all data written by trilogy_stmt_prepare_send is flushed
 * to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * Following a successful call to this function, the caller will also need to read off
 * `trilogy_stmt_t.column_count` parameters as column packets, then
 * `trilogy_stmt_t.column_count` columns as column packets. This must be done before
 * the socket will be command-ready again.
 *
 * conn     - A pre-initialized trilogy_conn_t pointer. It can also be connected but
 *          a disconnected trilogy_conn_t will also return TRILOGY_OK.
 * stmt_out - A pointer to a pre-allocated trilogy_stmt_t.
 *
 * Return values:
 *   TRILOGY_OK                 - The prepare command response successfully read from
 *                                the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 */
int trilogy_stmt_prepare_recv(trilogy_conn_t *conn, trilogy_stmt_t *stmt_out);

/* trilogy_stmt_bind_data_send - Send a prepared statement bind long data command to the server.
 *
 * There is no pairing `trilogy_stmt_bind_data_recv` fucntion to this one because the server
 * doesn't send a response to this command.
 *
 * conn      - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *             undefined.
 * stmt      - Pointer to a valid trilogy_stmt_t, representing the prepared statement for which
 *             to bind the supplied parameter data to.
 * param_num - The parameter index for which the supplied data should be bound to.
 * data      - A pointer to the buffer containing the data to be bound.
 * data_len  - The length of the data buffer.
 *
 * Return values:
 *   TRILOGY_OK     - The bind data command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_stmt_bind_data_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint16_t param_num, uint8_t *data,
                                size_t data_len);

/* trilogy_stmt_execute_send - Send a prepared statement execute command to the server.
 *
 * conn  - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *         undefined.
 * stmt  - Pointer to a valid trilogy_stmt_t, representing the prepared statement you're
 *         requesting to execute.
 * flags - The flags (TRILOGY_STMT_FLAGS_t) to be used with this execute command packet.
 * binds - Pointer to an array of trilogy_binary_value_t's. The array size should match that
 *         of `trilogy_stmt_t.column_count`.
 *
 * Return values:
 *   TRILOGY_OK     - The execute command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_stmt_execute_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt, uint8_t flags, trilogy_binary_value_t *binds);

/* trilogy_stmt_execute_recv - Read the prepared statement execute command response
 * from the MySQL-compatible server.
 *
 * This should be called after all data written by trilogy_stmt_execute_send is flushed
 * to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn             - A pre-initialized trilogy_conn_t pointer. It can also be connected but
 *                    a disconnected trilogy_conn_t will also return TRILOGY_OK.
 * column_count_out - Out parameter; A pointer to a pre-allocated uint64_t. Represents the
 *                    number of columns in the response.
 *
 * Return values:
 *   TRILOGY_OK                 - The prepare command response successfully read from
 *                                the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 */
int trilogy_stmt_execute_recv(trilogy_conn_t *conn, uint64_t *column_count_out);

/* trilogy_stmt_read_row - Read a row from the prepared statement execute response.
 *
 * This should only be called after a sucessful call to trilogy_stmt_execute_recv.
 * You should continue calling this until TRILOGY_EOF is returned. Denoting the end
 * of the result set.
 *
 * conn         - A pre-initialized trilogy_conn_t pointer. It can also be connected but
 *                a disconnected trilogy_conn_t will also return TRILOGY_OK.
 * stmt         - Pointer to a valid trilogy_stmt_t, representing the prepared statement you're
 *                requesting to execute.
 * columns      - The list of columns from the prepared statement.
 * column_count - The number of columns in prepared statement.
 * values_out   - Out parameter; A pointer to a pre-allocated array of
 *                trilogy_binary_value_t's. There must be enough space to fit all of the
 *                values. This can be computed with:
 *                `(sizeof(trilogy_binary_value_t) * column_count)`.
 *
 * Return values:
 *   TRILOGY_OK                 - The prepare command response successfully read from
 *                                the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_EOF                - There are no more rows to read from the result set.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - Invalid length parsed for a TIME/DATETIME/TIMESTAMP value.
 *   TRILOGY_UNKNOWN_TYPE       - An unsupported or unknown MySQL type was seen.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 */
int trilogy_stmt_read_row(trilogy_conn_t *conn, trilogy_stmt_t *stmt, trilogy_column_packet_t *columns,
                          trilogy_binary_value_t *values_out);

/* trilogy_stmt_reset_send - Send a prepared statement reset command to the server.
 *
 * conn  - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *         undefined.
 * stmt  - Pointer to a valid trilogy_stmt_t, representing the prepared statement you're
 *         requesting to reset.
 *
 * Return values:
 *   TRILOGY_OK     - The reset command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_stmt_reset_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt);

/* trilogy_stmt_reset_recv - Read the prepared statement reset command response
 * from the MySQL-compatible server.
 *
 * This should be called after all data written by trilogy_stmt_reset_send is flushed
 * to the network. Calling this at any other time during the connection
 * lifecycle is undefined.
 *
 * conn - A pre-initialized trilogy_conn_t pointer. It can also be connected but
 *      a disconnected trilogy_conn_t will also return TRILOGY_OK.
 *
 * Return values:
 *   TRILOGY_OK                 - The reset command response successfully read from
 *                                the server.
 *   TRILOGY_AGAIN              - The socket wasn't ready for reading. The caller
 *                                should wait for readability using `conn->sock`.
 *                                Then call this function until it returns a
 *                                different value.
 *   TRILOGY_UNEXPECTED_PACKET  - The response packet wasn't what was expected.
 *   TRILOGY_PROTOCOL_VIOLATION - An error occurred while processing a network
 *                                packet.
 *   TRILOGY_SYSERR             - A system error occurred, check errno.
 *   TRILOGY_CLOSED_CONNECTION  - The connection is closed.
 */
int trilogy_stmt_reset_recv(trilogy_conn_t *conn);

/* trilogy_stmt_close_send - Send a prepared statement close command to the server.
 *
 * There is no pairing `trilogy_stmt_close_recv` fucntion to this one because the server
 * doesn't send a response to this command.
 *
 * conn  - A connected trilogy_conn_t pointer. Using a disconnected trilogy_conn_t is
 *         undefined.
 * stmt  - Pointer to a valid trilogy_stmt_t, representing the prepared statement you're
 *         requesting to close.
 *
 * Return values:
 *   TRILOGY_OK     - The close command was successfully sent to the server.
 *   TRILOGY_AGAIN  - The socket wasn't ready for writing. The caller should wait
 *                    for writeability using `conn->sock`. Then call
 *                    trilogy_flush_writes.
 *   TRILOGY_SYSERR - A system error occurred, check errno.
 */
int trilogy_stmt_close_send(trilogy_conn_t *conn, trilogy_stmt_t *stmt);

#endif
