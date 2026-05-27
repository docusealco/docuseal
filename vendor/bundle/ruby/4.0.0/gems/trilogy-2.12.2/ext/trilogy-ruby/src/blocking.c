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
