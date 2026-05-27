#ifndef TRILOGY_SOCKET_H
#define TRILOGY_SOCKET_H

#include "trilogy/error.h"
#include "trilogy/protocol.h"
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>
#include <stdbool.h>
#include <sys/time.h>

typedef enum {
    TRILOGY_WAIT_READ = 0,
    TRILOGY_WAIT_WRITE = 1,
    TRILOGY_WAIT_HANDSHAKE = 2,
    TRILOGY_WAIT_CONNECT = 3,
} trilogy_wait_t;

// We use the most strict mode as value 1 so if anyone ever
// treats this as a boolean, they get the most strict behavior
// by default.
typedef enum {
    TRILOGY_SSL_DISABLED = 0,
    TRILOGY_SSL_VERIFY_IDENTITY = 1,
    TRILOGY_SSL_VERIFY_CA = 2,
    TRILOGY_SSL_REQUIRED_NOVERIFY = 3,
    TRILOGY_SSL_PREFERRED_NOVERIFY = 4,
} trilogy_ssl_mode_t;

typedef enum {
    TRILOGY_TLS_VERSION_UNDEF = 0,
    TRILOGY_TLS_VERSION_10 = 1,
    TRILOGY_TLS_VERSION_11 = 2,
    TRILOGY_TLS_VERSION_12 = 3,
    TRILOGY_TLS_VERSION_13 = 4,
} trilogy_tls_version_t;

typedef struct {
    char *hostname;
    char *path;
    char *database;
    char *username;
    char *password;
    size_t password_len;
    uint8_t encoding;

    trilogy_ssl_mode_t ssl_mode;
    trilogy_tls_version_t tls_min_version;
    trilogy_tls_version_t tls_max_version;
    uint16_t port;

    char *ssl_ca;
    char *ssl_capath;
    char *ssl_cert;
    char *ssl_cipher;
    char *ssl_crl;
    char *ssl_crlpath;
    char *ssl_key;
    char *tls_ciphersuites;

    struct timeval connect_timeout;
    struct timeval read_timeout;
    struct timeval write_timeout;

    bool keepalive_enabled;
    uint16_t keepalive_idle;
    uint16_t keepalive_count;
    uint16_t keepalive_interval;

    bool enable_cleartext_plugin;

    TRILOGY_CAPABILITIES_t flags;

    size_t max_allowed_packet;
} trilogy_sockopt_t;

typedef struct trilogy_sock_t {
    int (*connect_cb)(struct trilogy_sock_t *self);
    ssize_t (*read_cb)(struct trilogy_sock_t *self, void *buf, size_t nread);
    ssize_t (*write_cb)(struct trilogy_sock_t *self, const void *buf, size_t nwrite);
    int (*wait_cb)(struct trilogy_sock_t *self, trilogy_wait_t wait);
    int (*shutdown_cb)(struct trilogy_sock_t *self);
    int (*close_cb)(struct trilogy_sock_t *self);
    int (*fd_cb)(struct trilogy_sock_t *self);

    trilogy_sockopt_t opts;
} trilogy_sock_t;

static inline int trilogy_sock_connect(trilogy_sock_t *sock) { return sock->connect_cb(sock); }

void trilogy_sock_set_fd(trilogy_sock_t *sock, int fd);

static inline ssize_t trilogy_sock_read(trilogy_sock_t *sock, void *buf, size_t n)
{
    return sock->read_cb(sock, buf, n);
}

static inline ssize_t trilogy_sock_write(trilogy_sock_t *sock, const void *buf, size_t n)
{
    return sock->write_cb(sock, buf, n);
}

static inline int trilogy_sock_wait(trilogy_sock_t *sock, trilogy_wait_t wait) { return sock->wait_cb(sock, wait); }

static inline int trilogy_sock_wait_read(trilogy_sock_t *sock) { return sock->wait_cb(sock, TRILOGY_WAIT_READ); }

static inline int trilogy_sock_wait_write(trilogy_sock_t *sock) { return sock->wait_cb(sock, TRILOGY_WAIT_WRITE); }

static inline int trilogy_sock_shutdown(trilogy_sock_t *sock) { return sock->shutdown_cb(sock); }

static inline int trilogy_sock_close(trilogy_sock_t *sock) { return sock->close_cb(sock); }

static inline int trilogy_sock_fd(trilogy_sock_t *sock) { return sock->fd_cb(sock); }

trilogy_sock_t *trilogy_sock_new(const trilogy_sockopt_t *opts);
int trilogy_sock_resolve(trilogy_sock_t *raw);
int trilogy_sock_upgrade_ssl(trilogy_sock_t *raw);

/* trilogy_sock_check - Verify if the socket is still alive and not disconnected.
 *
 * This check is very cheap to do and reduces the number of errors when for
 * example the server has restarted since the connection was opened. In connection
 * pooling implementations, this check can be done before the connection is
 * returned.
 *
 * raw - A connected trilogy_sock_t pointer. Using a disconnected trilogy_sock_t is undefined.
 *
 * Return values:
 *   TRILOGY_OK                - The connection is alive on the client side and can be.
 *   TRILOGY_CLOSED_CONNECTION - The connection is closed.
 *   TRILOGY_SYSERR            - A system error occurred, check errno.
 */
int trilogy_sock_check(trilogy_sock_t *raw);

#endif
