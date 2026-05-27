#include <arpa/inet.h>
#include <errno.h>
#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/io.h>
#include <ruby/thread.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>

#include <unistd.h>
#include <fcntl.h>

#include "trilogy-ruby.h"

typedef struct _buffer_pool_entry_struct {
    size_t cap;
    uint8_t *buff;
} buffer_pool_entry;

typedef struct _buffer_pool_struct {
    size_t capa;
    size_t len;
    buffer_pool_entry *entries;
} buffer_pool;

#ifndef HAVE_RB_RACTOR_LOCAL_STORAGE_VALUE_NEWKEY
static VALUE _global_buffer_pool = Qnil;
#endif

#define BUFFER_POOL_MAX_SIZE 8

static void buffer_pool_free(void *data)
{
#ifndef HAVE_RB_RACTOR_LOCAL_STORAGE_VALUE_NEWKEY
    _global_buffer_pool = Qnil;
#endif

    buffer_pool *pool = (buffer_pool *)data;
    if (pool->capa) {
        for (size_t index = 0; index < pool->len; index++) {
            xfree(pool->entries[index].buff);
        }
        xfree(pool->entries);
    }
    xfree(pool);
}

static size_t buffer_pool_memsize(const void *data)
{
    const buffer_pool *pool = (const buffer_pool *)data;

    size_t memsize = sizeof(buffer_pool) + sizeof(buffer_pool_entry) * pool->capa;

    if (pool->capa) {
        for (size_t index = 0; index < pool->len; index++) {
            memsize += pool->entries[index].cap;
        }
    }

    return memsize;
}

static const rb_data_type_t buffer_pool_type = {
    .wrap_struct_name = "trilogy/buffer_pool",
    .function = {
        .dmark = NULL,
        .dfree = buffer_pool_free,
        .dsize = buffer_pool_memsize,
    },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static VALUE create_rb_buffer_pool(void)
{
    buffer_pool *pool;
    return TypedData_Make_Struct(Qfalse, buffer_pool, &buffer_pool_type, pool);
}

#ifdef HAVE_RB_RACTOR_LOCAL_STORAGE_VALUE_NEWKEY
#include <ruby/ractor.h>
static rb_ractor_local_key_t buffer_pool_key;

static VALUE get_rb_buffer_pool(void)
{
    VALUE pool;
    if (!rb_ractor_local_storage_value_lookup(buffer_pool_key, &pool)) {
        pool = create_rb_buffer_pool();
        rb_ractor_local_storage_value_set(buffer_pool_key, pool);
    }
    return pool;
}
#else
static VALUE get_rb_buffer_pool(void)
{
    if (NIL_P(_global_buffer_pool)) {
        _global_buffer_pool = create_rb_buffer_pool();
    }
    return _global_buffer_pool;
}
#endif

static inline buffer_pool *get_buffer_pool(void)
{
    buffer_pool *pool;
    VALUE rb_pool = get_rb_buffer_pool();
    if (NIL_P(rb_pool)) {
        return NULL;
    }

    TypedData_Get_Struct(rb_pool, buffer_pool, &buffer_pool_type, pool);
    return pool;
}

static void buffer_checkout(trilogy_buffer_t *buffer, size_t initial_capacity)
{
    buffer_pool * pool = get_buffer_pool();
    if (pool->len) {
        pool->len--;
        buffer->buff = pool->entries[pool->len].buff;
        buffer->cap = pool->entries[pool->len].cap;
    } else {
        buffer->buff = xmalloc(initial_capacity);
        buffer->cap = initial_capacity;
    }
}

static bool buffer_checkin(trilogy_buffer_t *buffer)
{
    buffer_pool * pool = get_buffer_pool();

    if (pool->len >= BUFFER_POOL_MAX_SIZE) {
        xfree(buffer->buff);
        buffer->buff = NULL;
        buffer->cap = 0;
        return false;
    }

    if (!pool->capa) {
        pool->entries = RB_ALLOC_N(buffer_pool_entry, 16);
        pool->capa = 16;
    } else if (pool->len >= pool->capa) {
        pool->capa *= 2;
        RB_REALLOC_N(pool->entries, buffer_pool_entry, pool->capa);
    }

    pool->entries[pool->len].buff = buffer->buff;
    pool->entries[pool->len].cap = buffer->cap;
    pool->len++;

    buffer->buff = NULL;
    buffer->cap = 0;

    return true;
}

VALUE Trilogy_CastError;
static VALUE Trilogy_BaseConnectionError, Trilogy_ProtocolError, Trilogy_SSLError, Trilogy_QueryError,
    Trilogy_ConnectionClosedError,
    Trilogy_TimeoutError, Trilogy_SyscallError, Trilogy_Result, Trilogy_EOFError, Trilogy_AuthPluginError;

static ID id_socket, id_host, id_port, id_username, id_password, id_found_rows, id_connect_timeout, id_read_timeout,
    id_write_timeout, id_keepalive_enabled, id_keepalive_idle, id_keepalive_interval, id_keepalive_count,
    id_password, id_database, id_enable_cleartext_plugin,
    id_ssl_ca, id_ssl_capath, id_ssl_cert, id_ssl_cipher, id_ssl_crl, id_ssl_crlpath, id_ssl_key,
    id_ssl_mode, id_tls_ciphersuites, id_tls_min_version, id_tls_max_version, id_multi_statement, id_multi_result,
    id_from_code, id_from_errno, id_max_allowed_packet;

struct trilogy_ctx {
    trilogy_conn_t conn;
    rb_encoding *encoding;
    unsigned int query_flags;
    char server_version[TRILOGY_SERVER_VERSION_SIZE + 1];
};

static void rb_trilogy_acquire_buffer(struct trilogy_ctx *ctx)
{
    if (!ctx->conn.packet_buffer.buff) {
        buffer_checkout(&ctx->conn.packet_buffer, TRILOGY_DEFAULT_BUF_SIZE);
    }
}

static void rb_trilogy_release_buffer(struct trilogy_ctx *ctx)
{
    if (ctx->conn.packet_buffer.buff) {
        buffer_checkin(&ctx->conn.packet_buffer);
    }
}

static void free_trilogy(void *ptr)
{
    struct trilogy_ctx *ctx = ptr;

    trilogy_free(&ctx->conn);
    xfree(ptr);
}

static size_t trilogy_memsize(const void *ptr) {
    const struct trilogy_ctx *ctx = ptr;
    size_t memsize = sizeof(struct trilogy_ctx);
    if (ctx->conn.socket != NULL) {
        memsize += sizeof(trilogy_sock_t);
    }
    memsize += ctx->conn.packet_buffer.cap;
    return memsize;
}

static const rb_data_type_t trilogy_data_type = {
    .wrap_struct_name = "trilogy",
    .function = {
        .dmark = NULL,
        .dfree = free_trilogy,
        .dsize = trilogy_memsize,
    },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static struct trilogy_ctx *get_ctx(VALUE obj)
{
    struct trilogy_ctx *ctx;
    TypedData_Get_Struct(obj, struct trilogy_ctx, &trilogy_data_type, ctx);
    return ctx;
}

static struct trilogy_ctx *get_open_ctx(VALUE obj)
{
    struct trilogy_ctx *ctx = get_ctx(obj);

    if (ctx->conn.socket == NULL) {
        rb_raise(Trilogy_ConnectionClosedError, "Attempted to use closed connection");
    }

    return ctx;
}

NORETURN(static void trilogy_syserr_fail_str(int, VALUE));
static void trilogy_syserr_fail_str(int e, VALUE msg)
{
    if (e == EPIPE) {
        // Backwards compatibility: This error message is a bit odd, but includes "TRILOGY_CLOSED_CONNECTION" to match legacy string matching
        rb_raise(Trilogy_EOFError, "%" PRIsVALUE ": TRILOGY_CLOSED_CONNECTION: EPIPE", msg);
    } else {
        VALUE exc = rb_funcall(Trilogy_SyscallError, id_from_errno, 2, INT2NUM(e), msg);
        rb_exc_raise(exc);
    }
}

static int trilogy_error_recoverable_p(int rc)
{
    // TRILOGY_OPENSSL_ERR and TRILOGY_SYSERR (which can result from an SSL error) must shut down the socket, as further
    // SSL calls would be invalid.
    // TRILOGY_ERR, which represents an error message sent to us from the server, is recoverable.
    // TRILOGY_MAX_PACKET_EXCEEDED is also recoverable as we do not send data when it occurs.
    // For other exceptions we will also close the socket to prevent further use, as the connection is probably in an
    // invalid state.
    return rc == TRILOGY_ERR || rc == TRILOGY_MAX_PACKET_EXCEEDED;
}

NORETURN(static void handle_trilogy_error(struct trilogy_ctx *, int, const char *, ...));
static void handle_trilogy_error(struct trilogy_ctx *ctx, int rc, const char *msg, ...)
{
    va_list args;
    va_start(args, msg);
    VALUE rbmsg = rb_vsprintf(msg, args);
    va_end(args);

    rb_trilogy_release_buffer(ctx);

    if (!trilogy_error_recoverable_p(rc)) {
        if (ctx->conn.socket != NULL) {
            // trilogy_sock_shutdown may affect errno
            int errno_was = errno;
            trilogy_sock_shutdown(ctx->conn.socket);
            errno = errno_was;
        }
    }

    switch (rc) {
    case TRILOGY_SYSERR:
        trilogy_syserr_fail_str(errno, rbmsg);

    case TRILOGY_TIMEOUT:
        rb_raise(Trilogy_TimeoutError, "%" PRIsVALUE, rbmsg);

    case TRILOGY_ERR: {
        VALUE conn_message = rb_str_new(ctx->conn.error_message, ctx->conn.error_message_len);
        VALUE message = rb_sprintf("%" PRIsVALUE " (%" PRIsVALUE ")", conn_message, rbmsg);
        VALUE exc = rb_funcall(Trilogy_ProtocolError, id_from_code, 2, message, INT2NUM(ctx->conn.error_code));
        rb_exc_raise(exc);
    }

    case TRILOGY_OPENSSL_ERR: {
        unsigned long ossl_error = ERR_get_error();
        ERR_clear_error();
        if (ERR_GET_LIB(ossl_error) == ERR_LIB_SYS) {
            int err_reason = ERR_GET_REASON(ossl_error);
            trilogy_syserr_fail_str(err_reason, rbmsg);
        }
        rb_raise(Trilogy_SSLError, "%" PRIsVALUE ": SSL Error: %s", rbmsg, ERR_reason_error_string(ossl_error));
    }

    case TRILOGY_DNS_ERR: {
        rb_raise(Trilogy_BaseConnectionError, "%" PRIsVALUE ": TRILOGY_DNS_ERROR", rbmsg);
    }

    case TRILOGY_CLOSED_CONNECTION: {
        rb_raise(Trilogy_EOFError, "%" PRIsVALUE ": TRILOGY_CLOSED_CONNECTION", rbmsg);
    }

    case TRILOGY_AUTH_PLUGIN_ERROR: {
        rb_raise(Trilogy_AuthPluginError, "%" PRIsVALUE ": TRILOGY_AUTH_PLUGIN_ERROR", rbmsg);
    }

    case TRILOGY_UNSUPPORTED: {
        rb_raise(Trilogy_BaseConnectionError, "%" PRIsVALUE ": TRILOGY_UNSUPPORTED", rbmsg);
    }

    default:
        rb_raise(Trilogy_QueryError, "%" PRIsVALUE ": %s", rbmsg, trilogy_error(rc));
    }
}

static VALUE allocate_trilogy(VALUE klass)
{
    struct trilogy_ctx *ctx;

    VALUE obj = TypedData_Make_Struct(klass, struct trilogy_ctx, &trilogy_data_type, ctx);

    ctx->query_flags = TRILOGY_FLAGS_DEFAULT;

    if (trilogy_init_no_buffer(&ctx->conn) < 0) {
        VALUE rbmsg = rb_str_new("trilogy_init", 13);
        trilogy_syserr_fail_str(errno, rbmsg);
    }

    return obj;
}

static int flush_writes(struct trilogy_ctx *ctx)
{
    while (1) {
        int rc = trilogy_flush_writes(&ctx->conn);

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        rc = trilogy_sock_wait_write(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            return rc;
        }
    }
}

static struct timeval double_to_timeval(double secs)
{
    double whole_secs = floor(secs);

    return (struct timeval){
        .tv_sec = whole_secs,
        .tv_usec = floor((secs - whole_secs) * 1000000),
    };
}

static double timeval_to_double(struct timeval tv)
{
    return (double)tv.tv_sec + ((double)tv.tv_usec) / 1000000.0;
}

struct rb_trilogy_wait_args {
    struct timeval *timeout;
    int wait_flag;
    int fd;
    int rc;
};

static VALUE rb_trilogy_wait_protected(VALUE vargs) {
    struct rb_trilogy_wait_args *args = (void *)vargs;

    args->rc = rb_wait_for_single_fd(args->fd, args->wait_flag, args->timeout);

    return Qnil;
}

static int _cb_ruby_wait(trilogy_sock_t *sock, trilogy_wait_t wait)
{
    struct timeval *timeout = NULL;
    int wait_flag = 0;

    switch (wait) {
    case TRILOGY_WAIT_READ:
        timeout = &sock->opts.read_timeout;
        wait_flag = RB_WAITFD_IN;
        break;

    case TRILOGY_WAIT_WRITE:
        timeout = &sock->opts.write_timeout;
        wait_flag = RB_WAITFD_OUT;
        break;

    case TRILOGY_WAIT_CONNECT:
        // wait for connection to be writable
        timeout = &sock->opts.connect_timeout;
        if (timeout->tv_sec == 0 && timeout->tv_usec == 0) {
            // We used to use the write timeout for this, so if a connect timeout isn't configured, default to that.
            timeout = &sock->opts.write_timeout;
        }
        wait_flag = RB_WAITFD_OUT;
        break;

    case TRILOGY_WAIT_HANDSHAKE:
        // wait for handshake packet on initial connection
        timeout = &sock->opts.connect_timeout;
        wait_flag = RB_WAITFD_IN;
        break;

    default:
        return TRILOGY_ERR;
    }

    if (timeout->tv_sec == 0 && timeout->tv_usec == 0) {
        timeout = NULL;
    }

    struct rb_trilogy_wait_args args;
    args.fd = trilogy_sock_fd(sock);
    args.wait_flag = wait_flag;
    args.timeout = timeout;
    args.rc = 0;

    int state = 0;
    rb_protect(rb_trilogy_wait_protected, (VALUE)&args, &state);
    if (state) {
        trilogy_sock_shutdown(sock);
        rb_jump_tag(state);
    }

    // rc here comes from rb_wait_for_single_fd which (similar to poll(3)) returns 0 to indicate that the call timed out
    // or -1 to indicate a system error with errno set.
    if (args.rc < 0)
        return TRILOGY_SYSERR;
    if (args.rc == 0)
        return TRILOGY_TIMEOUT;

    return TRILOGY_OK;
}

static int try_connect(struct trilogy_ctx *ctx, trilogy_handshake_t *handshake, const trilogy_sockopt_t *opts, int fd)
{
    if (fd < 0) {
        return TRILOGY_ERR;
    }

    trilogy_sock_t *sock = trilogy_sock_new(opts);
    if (sock == NULL) {
        return TRILOGY_ERR;
    }

    int rc;

    /* replace the default wait callback with our GVL-aware callback so we can
escape the GVL on each wait operation without going through call_without_gvl */
    sock->wait_cb = _cb_ruby_wait;

    int newfd = dup(fd);
    if (newfd < 0) {
        return TRILOGY_ERR;
    }

    rc = trilogy_connect_set_fd(&ctx->conn, sock, newfd);
    if (rc < 0) {
        trilogy_sock_close(sock);
        return rc;
    }

    while (1) {
        rc = trilogy_connect_recv(&ctx->conn, handshake);

        if (rc == TRILOGY_OK) {
            return rc;
        }

        if (rc != TRILOGY_AGAIN) {
            return rc;
        }

        rc = trilogy_sock_wait(ctx->conn.socket, TRILOGY_WAIT_HANDSHAKE);
        if (rc != TRILOGY_OK) {
            return rc;
        }
    }
}

static void auth_switch(struct trilogy_ctx *ctx, trilogy_handshake_t *handshake)
{
    int rc = trilogy_auth_switch_send(&ctx->conn, handshake);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc != TRILOGY_OK) {
        handle_trilogy_error(ctx, rc, "trilogy_auth_switch_send");
    }

    while (1) {
        rc = trilogy_auth_recv(&ctx->conn, handshake);

        if (rc == TRILOGY_OK) {
            return;
        }

        if (rc != TRILOGY_AGAIN) {
            if (rc == TRILOGY_UNSUPPORTED) {
                handle_trilogy_error(ctx, rc, "trilogy_auth_recv: caching_sha2_password requires either TCP with TLS or a unix socket");
            }
            else {
                handle_trilogy_error(ctx, rc, "trilogy_auth_recv");
            }
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_auth_recv");
        }
    }
}

static void authenticate(struct trilogy_ctx *ctx, trilogy_handshake_t *handshake, trilogy_ssl_mode_t ssl_mode)
{
    int rc;

    if (ssl_mode != TRILOGY_SSL_DISABLED) {
        if (handshake->capabilities & TRILOGY_CAPABILITIES_SSL) {
            rc = trilogy_ssl_request_send(&ctx->conn);
            if (rc == TRILOGY_AGAIN) {
                rc = flush_writes(ctx);
            }

            if (rc != TRILOGY_OK) {
                handle_trilogy_error(ctx, rc, "trilogy_ssl_request_send");
            }

            rc = trilogy_sock_upgrade_ssl(ctx->conn.socket);
            if (rc != TRILOGY_OK) {
                handle_trilogy_error(ctx, rc, "trilogy_ssl_upgrade");
            }
        } else {
            if (ssl_mode != TRILOGY_SSL_PREFERRED_NOVERIFY) {
                rb_raise(Trilogy_SSLError, "SSL required, not supported by server");
            }
        }
    }

    rc = trilogy_auth_send(&ctx->conn, handshake);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc != TRILOGY_OK) {
        handle_trilogy_error(ctx, rc, "trilogy_auth_send");
    }

    while (1) {
        rc = trilogy_auth_recv(&ctx->conn, handshake);

        if (rc == TRILOGY_OK || rc == TRILOGY_AUTH_SWITCH) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            handle_trilogy_error(ctx, rc, "trilogy_auth_recv");
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_auth_recv");
        }
    }

    if (rc == TRILOGY_AUTH_SWITCH) {
        auth_switch(ctx, handshake);
    }
}

#ifndef HAVE_RB_IO_DESCRIPTOR /* Ruby < 3.1 */
static int rb_io_descriptor(VALUE io)
{
    rb_io_t *fptr;
    GetOpenFile(io, fptr);
    rb_io_check_closed(fptr);
    return fptr->fd;
}
#endif

static VALUE rb_trilogy_connect(VALUE self, VALUE raw_socket, VALUE encoding, VALUE charset, VALUE opts)
{
    struct trilogy_ctx *ctx = get_ctx(self);
    trilogy_sockopt_t connopt = {0};
    trilogy_handshake_t handshake;
    VALUE val;

    ctx->encoding = rb_to_encoding(encoding);
    connopt.encoding = NUM2INT(charset);

    Check_Type(opts, T_HASH);

    if ((val = rb_hash_lookup(opts, ID2SYM(id_ssl_mode))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.ssl_mode = (trilogy_ssl_mode_t)NUM2INT(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_connect_timeout))) != Qnil) {
        connopt.connect_timeout = double_to_timeval(NUM2DBL(val));
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_read_timeout))) != Qnil) {
        connopt.read_timeout = double_to_timeval(NUM2DBL(val));
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_write_timeout))) != Qnil) {
        connopt.write_timeout = double_to_timeval(NUM2DBL(val));
    }

    if (RTEST(rb_hash_aref(opts, ID2SYM(id_keepalive_enabled)))) {
        connopt.keepalive_enabled = true;
    }

    if ((val = rb_hash_lookup(opts, ID2SYM(id_keepalive_idle))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.keepalive_idle = NUM2USHORT(val);
    }

    if ((val = rb_hash_lookup(opts, ID2SYM(id_keepalive_count))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.keepalive_count = NUM2USHORT(val);
    }

    if ((val = rb_hash_lookup(opts, ID2SYM(id_keepalive_interval))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.keepalive_interval = NUM2USHORT(val);
    }

    if ((val = rb_hash_lookup(opts, ID2SYM(id_max_allowed_packet))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.max_allowed_packet = NUM2SIZET(val);
    }

    if ((val = rb_hash_lookup(opts, ID2SYM(id_host))) != Qnil) {
        Check_Type(val, T_STRING);

        connopt.hostname = StringValueCStr(val);
        connopt.port = 3306;

        if ((val = rb_hash_lookup(opts, ID2SYM(id_port))) != Qnil) {
            Check_Type(val, T_FIXNUM);
            connopt.port = NUM2USHORT(val);
        }
    } else {
        connopt.path = (char *)"/tmp/mysql.sock";

        if ((val = rb_hash_lookup(opts, ID2SYM(id_socket))) != Qnil) {
            Check_Type(val, T_STRING);
            connopt.path = StringValueCStr(val);
        }
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_username))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.username = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_password))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.password = RSTRING_PTR(val);
        connopt.password_len = RSTRING_LEN(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_database))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.database = StringValueCStr(val);
        connopt.flags |= TRILOGY_CAPABILITIES_CONNECT_WITH_DB;
    }

    if (RTEST(rb_hash_aref(opts, ID2SYM(id_enable_cleartext_plugin)))) {
        connopt.enable_cleartext_plugin = true;
    }

    if (RTEST(rb_hash_aref(opts, ID2SYM(id_found_rows)))) {
        connopt.flags |= TRILOGY_CAPABILITIES_FOUND_ROWS;
    }

    if (rb_hash_aref(opts, ID2SYM(id_multi_result)) != Qfalse) {
        connopt.flags |= TRILOGY_CAPABILITIES_MULTI_RESULTS;
    }

    if (RTEST(rb_hash_aref(opts, ID2SYM(id_multi_statement)))) {
        connopt.flags |= TRILOGY_CAPABILITIES_MULTI_STATEMENTS;
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_ca))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_ca = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_capath))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_capath = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_cert))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_cert = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_cipher))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_cipher = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_crl))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_crl = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_crlpath))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_crlpath = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_ssl_key))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.ssl_key = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_tls_ciphersuites))) != Qnil) {
        Check_Type(val, T_STRING);
        connopt.tls_ciphersuites = StringValueCStr(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_tls_min_version))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.tls_min_version = NUM2INT(val);
    }

    if ((val = rb_hash_aref(opts, ID2SYM(id_tls_max_version))) != Qnil) {
        Check_Type(val, T_FIXNUM);
        connopt.tls_max_version = NUM2INT(val);
    }

    VALUE io = rb_io_get_io(raw_socket);

    rb_io_t *fptr;
    GetOpenFile(io, fptr);
    rb_io_check_readable(fptr);
    rb_io_check_writable(fptr);

    int fd = rb_io_descriptor(io);

    rb_trilogy_acquire_buffer(ctx);
    int rc = try_connect(ctx, &handshake, &connopt, fd);
    if (rc != TRILOGY_OK) {
        if (connopt.path) {
            handle_trilogy_error(ctx, rc, "trilogy_connect - unable to connect to %s", connopt.path);
        } else {
            handle_trilogy_error(ctx, rc, "trilogy_connect - unable to connect to %s:%hu", connopt.hostname,
                                 connopt.port);
        }
    }

    memcpy(ctx->server_version, handshake.server_version, TRILOGY_SERVER_VERSION_SIZE);
    ctx->server_version[TRILOGY_SERVER_VERSION_SIZE] = 0;

    authenticate(ctx, &handshake, connopt.ssl_mode);

    rb_trilogy_release_buffer(ctx);

    return Qnil;
}

static VALUE rb_trilogy_change_db(VALUE self, VALUE database)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    StringValue(database);

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_change_db_send(&ctx->conn, RSTRING_PTR(database), RSTRING_LEN(database));

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc != TRILOGY_OK) {
        handle_trilogy_error(ctx, rc, "trilogy_change_db_send");
    }

    while (1) {
        rc = trilogy_change_db_recv(&ctx->conn);

        if (rc == TRILOGY_OK) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            handle_trilogy_error(ctx, rc, "trilogy_change_db_recv");
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_change_db_recv");
        }
    }

    rb_trilogy_release_buffer(ctx);

    return Qtrue;
}

static VALUE rb_trilogy_set_server_option(VALUE self, VALUE option)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_set_option_send(&ctx->conn, NUM2INT(option));

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc != TRILOGY_OK) {
        handle_trilogy_error(ctx, rc, "trilogy_set_option_send");
    }

    while (1) {
        rc = trilogy_set_option_recv(&ctx->conn);

        if (rc == TRILOGY_OK) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            handle_trilogy_error(ctx, rc, "trilogy_set_option_recv");
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_set_option_recv");
        }
    }

    rb_trilogy_release_buffer(ctx);

    return Qtrue;
}


static void load_query_options(unsigned int query_flags, struct rb_trilogy_cast_options *cast_options)
{
    cast_options->cast = (query_flags & TRILOGY_FLAGS_CAST) != 0;
    cast_options->cast_booleans = (query_flags & TRILOGY_FLAGS_CAST_BOOLEANS) != 0;
    cast_options->cast_decimals_to_bigdecimals = (query_flags & TRILOGY_FLAGS_CAST_ALL_DECIMALS_TO_BIGDECIMALS) != 0;
    cast_options->database_local_time = (query_flags & TRILOGY_FLAGS_LOCAL_TIMEZONE) != 0;
    cast_options->flatten_rows = (query_flags & TRILOGY_FLAGS_FLATTEN_ROWS) != 0;
}

struct read_query_response_state {
    struct rb_trilogy_cast_options *cast_options;
    struct trilogy_ctx *ctx;

    // Error state for tracking
    const char *msg;
    int rc;
};

static void get_timespec_monotonic(struct timespec *ts)
{
#if defined(HAVE_CLOCK_GETTIME) && defined(CLOCK_MONOTONIC)
    if (clock_gettime(CLOCK_MONOTONIC, ts) == -1) {
        rb_sys_fail("clock_gettime");
    }
#else
    struct timeval tv;
    if (gettimeofday(&tv, 0) < 0) {
        rb_sys_fail("gettimeofday");
    }
    ts->tv_sec = tv.tv_sec;
    ts->tv_nsec = tv.tv_usec * 1000;
#endif
}

static VALUE read_query_error(struct read_query_response_state *args, int rc, const char *msg)
{
    args->rc = rc;
    args->msg = msg;
    return Qundef;
}

static VALUE read_query_response(VALUE vargs)
{
    struct read_query_response_state *args = (void *)vargs;
    struct trilogy_ctx *ctx = args->ctx;

    struct timespec start;
    get_timespec_monotonic(&start);

    uint64_t column_count = 0;

    int rc;

    while (1) {
        rc = trilogy_query_recv(&ctx->conn, &column_count);

        if (rc == TRILOGY_OK || rc == TRILOGY_HAVE_RESULTS) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            return read_query_error(args, rc, "trilogy_query_recv");
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_query_recv");
        }
    }

    struct timespec finish;
    get_timespec_monotonic(&finish);

    double query_time = finish.tv_sec - start.tv_sec;
    query_time += (double)(finish.tv_nsec - start.tv_nsec) / 1000000000.0;

    VALUE column_names = 0;

    VALUE rows = rb_ary_new();

    VALUE last_insert_id = Qnil, affected_rows = Qnil;
    if (rc == TRILOGY_OK) {
        last_insert_id = ULL2NUM(ctx->conn.last_insert_id);
        affected_rows = ULL2NUM(ctx->conn.affected_rows);
    }
    else {
        VALUE rb_column_info;
        struct column_info *column_info = ALLOCV_N(struct column_info, rb_column_info, column_count);
        VALUE rb_ruby_values;
        VALUE *row_ruby_values = ALLOCV_N(VALUE, rb_ruby_values, column_count);

        for (uint64_t i = 0; i < column_count; i++) {
            trilogy_column_t column;

            while (1) {
                rc = trilogy_read_column(&ctx->conn, &column);

                if (rc == TRILOGY_OK) {
                    break;
                }

                if (rc != TRILOGY_AGAIN) {
                    return read_query_error(args, rc, "trilogy_read_column");
                }

                rc = trilogy_sock_wait_read(ctx->conn.socket);
                if (rc != TRILOGY_OK) {
                    return read_query_error(args, rc, "trilogy_read_column");
                }
            }

    #ifdef HAVE_RB_ENC_INTERNED_STR
            row_ruby_values[i] = rb_enc_interned_str(column.name, column.name_len, ctx->encoding);
    #else
            row_ruby_values[i] = rb_enc_str_new(column.name, column.name_len, ctx->encoding);
            OBJ_FREEZE(row_ruby_values[i]);
    #endif

            column_info[i].type = column.type;
            column_info[i].flags = column.flags;
            column_info[i].len = column.len;
            column_info[i].charset = column.charset;
            column_info[i].decimals = column.decimals;
        }

        column_names = rb_ary_new_from_values(column_count, row_ruby_values);

        VALUE rb_trilogy_values;
        trilogy_value_t *row_trilogy_values = ALLOCV_N(trilogy_value_t, rb_trilogy_values, column_count);

        while (1) {
            int rc = trilogy_read_row(&ctx->conn, row_trilogy_values);

            if (rc == TRILOGY_AGAIN) {
                rc = trilogy_sock_wait_read(ctx->conn.socket);
                if (rc != TRILOGY_OK) {
                    return read_query_error(args, rc, "trilogy_read_row");
                }
                continue;
            }

            if (rc == TRILOGY_EOF) {
                break;
            }

            if (rc != TRILOGY_OK) {
                return read_query_error(args, rc, "trilogy_read_row");
            }

            for (uint64_t i = 0; i < column_count; i++) {
                row_ruby_values[i] = rb_trilogy_cast_value(row_trilogy_values + i, column_info + i, args->cast_options);
            }

            if (args->cast_options->flatten_rows) {
                rb_ary_cat(rows, row_ruby_values, column_count);
            } else {
                rb_ary_push(rows, rb_ary_new_from_values(column_count, row_ruby_values));
            }
        }

        ALLOCV_END(rb_column_info);
        ALLOCV_END(rb_trilogy_values);
        ALLOCV_END(rb_ruby_values);
    }

    return rb_class_new_instance(
        6,
        (VALUE []){
            column_names,
            rows,
            DBL2NUM(query_time),
            (ctx->conn.server_status & TRILOGY_SERVER_STATUS_IN_TRANS) ? Qtrue : Qfalse,
            affected_rows,
            last_insert_id,
        },
        Trilogy_Result
    );
}

static VALUE execute_read_query_response(struct trilogy_ctx *ctx)
{
    struct rb_trilogy_cast_options cast_options;
    load_query_options(ctx->query_flags, &cast_options);

    struct read_query_response_state args = {
        .cast_options = &cast_options,
        .ctx = ctx,
        .rc = TRILOGY_OK,
        .msg = NULL,
    };

    int state = 0;
    VALUE result = rb_protect(read_query_response, (VALUE)&args, &state);

    // If we have seen an unexpected exception, jump to it so it gets raised.
    if (state) {
        trilogy_sock_shutdown(ctx->conn.socket);
        rb_jump_tag(state);
    }

    // Handle errors we can gracefully recover from here that were due to
    // errors signaled at the protocol level, not unexpected exceptions.
    if (result == Qundef) {
        handle_trilogy_error(ctx, args.rc, args.msg);
    }

    if (!(ctx->conn.server_status & TRILOGY_SERVER_STATUS_MORE_RESULTS_EXISTS)) {
        rb_trilogy_release_buffer(ctx);
    }

    return result;
}

static VALUE rb_trilogy_next_result(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    if (!(ctx->conn.server_status & TRILOGY_SERVER_STATUS_MORE_RESULTS_EXISTS)) {
        return Qnil;
    }

    return execute_read_query_response(ctx);
}

static VALUE rb_trilogy_more_results_exist(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    if (ctx->conn.server_status & TRILOGY_SERVER_STATUS_MORE_RESULTS_EXISTS) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}

static VALUE rb_trilogy_abandon_results(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    long count = 0;
    while (ctx->conn.server_status & TRILOGY_SERVER_STATUS_MORE_RESULTS_EXISTS) {
        count++;
        int rc = trilogy_drain_results(&ctx->conn);
        while (rc == TRILOGY_AGAIN) {
            rc = trilogy_sock_wait_read(ctx->conn.socket);
            if (rc != TRILOGY_OK) {
                handle_trilogy_error(ctx, rc, "trilogy_sock_wait_read");
            }

            rc = trilogy_drain_results(&ctx->conn);
        }

        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_drain_results");
        }
    }

    return LONG2NUM(count);
}

static VALUE rb_trilogy_query(VALUE self, VALUE query)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    StringValue(query);
    query = rb_str_export_to_enc(query, ctx->encoding);

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_query_send(&ctx->conn, RSTRING_PTR(query), RSTRING_LEN(query));

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc < 0) {
        handle_trilogy_error(ctx, rc, "trilogy_query_send");
    }

    return execute_read_query_response(ctx);
}

static VALUE rb_trilogy_ping(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_ping_send(&ctx->conn);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc < 0) {
        handle_trilogy_error(ctx, rc, "trilogy_ping_send");
    }

    while (1) {
        rc = trilogy_ping_recv(&ctx->conn);

        if (rc == TRILOGY_OK) {
            break;
        }

        if (rc != TRILOGY_AGAIN) {
            handle_trilogy_error(ctx, rc, "trilogy_ping_recv");
        }

        rc = trilogy_sock_wait_read(ctx->conn.socket);
        if (rc != TRILOGY_OK) {
            handle_trilogy_error(ctx, rc, "trilogy_ping_recv");
        }
    }

    rb_trilogy_release_buffer(ctx);
    return Qtrue;
}

static VALUE rb_trilogy_escape(VALUE self, VALUE str)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);
    rb_encoding *str_enc = rb_enc_get(str);

    StringValue(str);

    if (!rb_enc_asciicompat(str_enc)) {
        rb_raise(rb_eEncCompatError, "input string must be ASCII-compatible");
    }

    const char *escaped_str;
    size_t escaped_len;

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_escape(&ctx->conn, RSTRING_PTR(str), RSTRING_LEN(str), &escaped_str, &escaped_len);

    if (rc < 0) {
        handle_trilogy_error(ctx, rc, "trilogy_escape");
    }

    VALUE escaped_string = rb_enc_str_new(escaped_str, escaped_len, str_enc);

    rb_trilogy_release_buffer(ctx);

    return escaped_string;
}

static VALUE rb_trilogy_close(VALUE self)
{
    struct trilogy_ctx *ctx = get_ctx(self);

    if (ctx->conn.socket == NULL) {
        return Qnil;
    }

    rb_trilogy_acquire_buffer(ctx);

    int rc = trilogy_close_send(&ctx->conn);

    if (rc == TRILOGY_AGAIN) {
        rc = flush_writes(ctx);
    }

    if (rc == TRILOGY_OK) {
        while (1) {
            rc = trilogy_close_recv(&ctx->conn);

            if (rc != TRILOGY_AGAIN) {
                break;
            }

            if (trilogy_sock_wait_read(ctx->conn.socket) < 0) {
                // timed out
                break;
            }
        }
    }

    // We aren't checking or raising errors here (we need close to always close the socket and free the connection), so
    // we must clear any SSL errors left in the queue from a read/write.
    ERR_clear_error();

    rb_trilogy_release_buffer(ctx);

    trilogy_free(&ctx->conn);

    return Qnil;
}

static VALUE rb_trilogy_closed(VALUE self)
{
    struct trilogy_ctx *ctx = get_ctx(self);

    if (ctx->conn.socket == NULL) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}

static VALUE rb_trilogy_check(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);

    int rc = trilogy_sock_check(ctx->conn.socket);
    if (rc != TRILOGY_OK && rc != TRILOGY_AGAIN) {
        handle_trilogy_error(ctx, rc, "trilogy_sock_check");
    }
    return Qtrue;
}

static VALUE rb_trilogy_discard(VALUE self)
{
    struct trilogy_ctx *ctx = get_ctx(self);

    if (ctx->conn.socket == NULL) {
        return Qtrue;
    }

    int rc = trilogy_discard(&ctx->conn);
    switch (rc) {
        case TRILOGY_OK:
            return Qtrue;
        case TRILOGY_SYSERR:
            trilogy_syserr_fail_str(errno, rb_str_new_cstr("Failed to discard connection"));
            UNREACHABLE_RETURN(Qfalse);
    }
    return Qfalse;
}

static VALUE rb_trilogy_last_insert_id(VALUE self) { return ULL2NUM(get_open_ctx(self)->conn.last_insert_id); }

static VALUE rb_trilogy_affected_rows(VALUE self) { return ULL2NUM(get_open_ctx(self)->conn.affected_rows); }

static VALUE rb_trilogy_warning_count(VALUE self) { return UINT2NUM(get_open_ctx(self)->conn.warning_count); }

static VALUE rb_trilogy_last_gtid(VALUE self)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);
    if (ctx->conn.last_gtid_len > 0) {
        return rb_str_new(ctx->conn.last_gtid, ctx->conn.last_gtid_len);
    } else {
        return Qnil;
    }
}

static VALUE rb_trilogy_query_flags(VALUE self) { return UINT2NUM(get_ctx(self)->query_flags); }

static VALUE rb_trilogy_query_flags_set(VALUE self, VALUE query_flags)
{
    return get_ctx(self)->query_flags = NUM2UINT(query_flags);
}

static VALUE rb_trilogy_read_timeout(VALUE self) {
    struct trilogy_ctx *ctx = get_open_ctx(self);
    return DBL2NUM(timeval_to_double(ctx->conn.socket->opts.read_timeout));
}

static VALUE rb_trilogy_read_timeout_set(VALUE self, VALUE read_timeout)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);
    if (read_timeout == Qnil) {
        ctx->conn.socket->opts.read_timeout = double_to_timeval(0.0);
    } else {
        ctx->conn.socket->opts.read_timeout = double_to_timeval(NUM2DBL(read_timeout));
    }
    return read_timeout;
}

static VALUE rb_trilogy_write_timeout(VALUE self) {
    struct trilogy_ctx *ctx = get_open_ctx(self);
    return DBL2NUM(timeval_to_double(ctx->conn.socket->opts.write_timeout));
}

static VALUE rb_trilogy_write_timeout_set(VALUE self, VALUE write_timeout)
{
    struct trilogy_ctx *ctx = get_open_ctx(self);
    if (write_timeout == Qnil) {
        ctx->conn.socket->opts.write_timeout = double_to_timeval(0.0);
    } else {
        ctx->conn.socket->opts.write_timeout = double_to_timeval(NUM2DBL(write_timeout));
    }
    return write_timeout;
}

static VALUE rb_trilogy_server_status(VALUE self) { return LONG2FIX(get_open_ctx(self)->conn.server_status); }

static VALUE rb_trilogy_server_version(VALUE self) { return rb_str_new_cstr(get_open_ctx(self)->server_version); }

RUBY_FUNC_EXPORTED void Init_cext(void)
{
    #ifdef HAVE_RB_RACTOR_LOCAL_STORAGE_VALUE_NEWKEY
        rb_ext_ractor_safe(true);
        buffer_pool_key = rb_ractor_local_storage_value_newkey();
    #endif

    VALUE Trilogy = rb_const_get(rb_cObject, rb_intern("Trilogy"));
    rb_define_alloc_func(Trilogy, allocate_trilogy);

    rb_define_private_method(Trilogy, "_connect", rb_trilogy_connect, 4);
    rb_define_method(Trilogy, "change_db", rb_trilogy_change_db, 1);
    rb_define_alias(Trilogy, "select_db", "change_db");
    rb_define_method(Trilogy, "query", rb_trilogy_query, 1);
    rb_define_method(Trilogy, "ping", rb_trilogy_ping, 0);
    rb_define_method(Trilogy, "escape", rb_trilogy_escape, 1);
    rb_define_method(Trilogy, "close", rb_trilogy_close, 0);
    rb_define_method(Trilogy, "closed?", rb_trilogy_closed, 0);
    rb_define_method(Trilogy, "check", rb_trilogy_check, 0);
    rb_define_method(Trilogy, "discard!", rb_trilogy_discard, 0);
    rb_define_method(Trilogy, "last_insert_id", rb_trilogy_last_insert_id, 0);
    rb_define_method(Trilogy, "affected_rows", rb_trilogy_affected_rows, 0);
    rb_define_method(Trilogy, "warning_count", rb_trilogy_warning_count, 0);
    rb_define_method(Trilogy, "last_gtid", rb_trilogy_last_gtid, 0);
    rb_define_method(Trilogy, "query_flags", rb_trilogy_query_flags, 0);
    rb_define_method(Trilogy, "query_flags=", rb_trilogy_query_flags_set, 1);
    rb_define_method(Trilogy, "read_timeout", rb_trilogy_read_timeout, 0);
    rb_define_method(Trilogy, "read_timeout=", rb_trilogy_read_timeout_set, 1);
    rb_define_method(Trilogy, "write_timeout", rb_trilogy_write_timeout, 0);
    rb_define_method(Trilogy, "write_timeout=", rb_trilogy_write_timeout_set, 1);
    rb_define_method(Trilogy, "server_status", rb_trilogy_server_status, 0);
    rb_define_method(Trilogy, "server_version", rb_trilogy_server_version, 0);
    rb_define_method(Trilogy, "more_results_exist?", rb_trilogy_more_results_exist, 0);
    rb_define_method(Trilogy, "next_result", rb_trilogy_next_result, 0);
    rb_define_method(Trilogy, "abandon_results!", rb_trilogy_abandon_results, 0);
    rb_define_method(Trilogy, "set_server_option", rb_trilogy_set_server_option, 1);
    rb_define_const(Trilogy, "TLS_VERSION_10", INT2NUM(TRILOGY_TLS_VERSION_10));
    rb_define_const(Trilogy, "TLS_VERSION_11", INT2NUM(TRILOGY_TLS_VERSION_11));
    rb_define_const(Trilogy, "TLS_VERSION_12", INT2NUM(TRILOGY_TLS_VERSION_12));
    rb_define_const(Trilogy, "TLS_VERSION_13", INT2NUM(TRILOGY_TLS_VERSION_13));

    rb_define_const(Trilogy, "SSL_DISABLED", INT2NUM(TRILOGY_SSL_DISABLED));
    rb_define_const(Trilogy, "SSL_VERIFY_IDENTITY", INT2NUM(TRILOGY_SSL_VERIFY_IDENTITY));
    rb_define_const(Trilogy, "SSL_VERIFY_CA", INT2NUM(TRILOGY_SSL_VERIFY_CA));
    rb_define_const(Trilogy, "SSL_REQUIRED_NOVERIFY", INT2NUM(TRILOGY_SSL_REQUIRED_NOVERIFY));
    rb_define_const(Trilogy, "SSL_PREFERRED_NOVERIFY", INT2NUM(TRILOGY_SSL_PREFERRED_NOVERIFY));

    rb_define_const(Trilogy, "QUERY_FLAGS_NONE", INT2NUM(0));
    rb_define_const(Trilogy, "QUERY_FLAGS_CAST", INT2NUM(TRILOGY_FLAGS_CAST));
    rb_define_const(Trilogy, "QUERY_FLAGS_CAST_BOOLEANS", INT2NUM(TRILOGY_FLAGS_CAST_BOOLEANS));
    rb_define_const(Trilogy, "QUERY_FLAGS_CAST_ALL_DECIMALS_TO_BIGDECIMALS", INT2NUM(TRILOGY_FLAGS_CAST_ALL_DECIMALS_TO_BIGDECIMALS));
    rb_define_const(Trilogy, "QUERY_FLAGS_LOCAL_TIMEZONE", INT2NUM(TRILOGY_FLAGS_LOCAL_TIMEZONE));
    rb_define_const(Trilogy, "QUERY_FLAGS_FLATTEN_ROWS", INT2NUM(TRILOGY_FLAGS_FLATTEN_ROWS));
    rb_define_const(Trilogy, "QUERY_FLAGS_DEFAULT", INT2NUM(TRILOGY_FLAGS_DEFAULT));

    Trilogy_ProtocolError = rb_const_get(Trilogy, rb_intern("ProtocolError"));
    rb_global_variable(&Trilogy_ProtocolError);

    Trilogy_SSLError = rb_const_get(Trilogy, rb_intern("SSLError"));
    rb_global_variable(&Trilogy_SSLError);

    Trilogy_QueryError = rb_const_get(Trilogy, rb_intern("QueryError"));
    rb_global_variable(&Trilogy_QueryError);

    Trilogy_TimeoutError = rb_const_get(Trilogy, rb_intern("TimeoutError"));
    rb_global_variable(&Trilogy_TimeoutError);

    Trilogy_BaseConnectionError = rb_const_get(Trilogy, rb_intern("BaseConnectionError"));
    rb_global_variable(&Trilogy_BaseConnectionError);

    Trilogy_ConnectionClosedError = rb_const_get(Trilogy, rb_intern("ConnectionClosed"));
    rb_global_variable(&Trilogy_ConnectionClosedError);

    Trilogy_Result = rb_const_get(Trilogy, rb_intern("Result"));
    rb_global_variable(&Trilogy_Result);

    Trilogy_SyscallError = rb_const_get(Trilogy, rb_intern("SyscallError"));
    rb_global_variable(&Trilogy_SyscallError);

    Trilogy_CastError = rb_const_get(Trilogy, rb_intern("CastError"));
    rb_global_variable(&Trilogy_CastError);

    Trilogy_EOFError = rb_const_get(Trilogy, rb_intern("EOFError"));
    rb_global_variable(&Trilogy_EOFError);

    rb_global_variable(&Trilogy_AuthPluginError);
    Trilogy_AuthPluginError = rb_const_get(Trilogy, rb_intern("AuthPluginError"));

    id_socket = rb_intern("socket");
    id_host = rb_intern("host");
    id_port = rb_intern("port");
    id_username = rb_intern("username");
    id_password = rb_intern("password");
    id_found_rows = rb_intern("found_rows");
    id_connect_timeout = rb_intern("connect_timeout");
    id_read_timeout = rb_intern("read_timeout");
    id_write_timeout = rb_intern("write_timeout");
    id_max_allowed_packet = rb_intern("max_allowed_packet");
    id_keepalive_enabled = rb_intern("keepalive_enabled");
    id_keepalive_idle = rb_intern("keepalive_idle");
    id_keepalive_count = rb_intern("keepalive_count");
    id_keepalive_interval = rb_intern("keepalive_interval");
    id_database = rb_intern("database");
    id_enable_cleartext_plugin = rb_intern("enable_cleartext_plugin");
    id_ssl_ca = rb_intern("ssl_ca");
    id_ssl_capath = rb_intern("ssl_capath");
    id_ssl_cert = rb_intern("ssl_cert");
    id_ssl_cipher = rb_intern("ssl_cipher");
    id_ssl_crl = rb_intern("ssl_crl");
    id_ssl_crlpath = rb_intern("ssl_crlpath");
    id_ssl_key = rb_intern("ssl_key");
    id_ssl_mode = rb_intern("ssl_mode");
    id_tls_ciphersuites = rb_intern("tls_ciphersuites");
    id_tls_min_version = rb_intern("tls_min_version");
    id_tls_max_version = rb_intern("tls_max_version");
    id_multi_statement = rb_intern("multi_statement");
    id_multi_result = rb_intern("multi_result");
    id_from_code = rb_intern("from_code");
    id_from_errno = rb_intern("from_errno");

    rb_trilogy_cast_init();

// server_status flags
#define XX(name, code) rb_const_set(Trilogy, rb_intern((char *)#name + strlen("TRILOGY_")), LONG2NUM(name));
    TRILOGY_SERVER_STATUS(XX)
#undef XX

// set_server_option options
#define XX(name, code) rb_const_set(Trilogy, rb_intern((char *)#name + strlen("TRILOGY_")), LONG2NUM(name));
    TRILOGY_SET_SERVER_OPTION(XX)
#undef XX

// charsets
#define XX(name, code) rb_const_set(Trilogy, rb_intern((char *)#name + strlen("TRILOGY_")), LONG2NUM(name));
    TRILOGY_CHARSETS(XX)
#undef XX
}
