#include "pg.h"

/********************************************************************
 *
 * Document-class: PG::CancelConnection
 *
 * The class to represent a connection to cancel a query.
 *
 * On PostgreSQL-17+ client libaray this class is used to implement PG::Connection#cancel .
 * It works on older PostgreSQL server versions too.
 *
 * Available since PostgreSQL-17
 *
 */

#ifdef HAVE_PQSETCHUNKEDROWSMODE

static VALUE rb_cPG_Cancon;
static ID s_id_autoclose_set;

typedef struct {
	PGcancelConn *pg_cancon;

	/* Cached IO object for the socket descriptor */
	VALUE socket_io;

	/* File descriptor to be used for rb_w32_unwrap_io_handle() */
	int ruby_sd;
} t_pg_cancon;


static void
pg_cancon_gc_mark( void *_this )
{
	t_pg_cancon *this = (t_pg_cancon *)_this;
	rb_gc_mark_movable( this->socket_io );
}

static void
pg_cancon_gc_compact( void *_this )
{
	t_pg_connection *this = (t_pg_connection *)_this;
	pg_gc_location( this->socket_io );
}

static void
pg_cancon_gc_free( void *_this )
{
	t_pg_cancon *this = (t_pg_cancon *)_this;
#if defined(_WIN32)
	if ( RTEST(this->socket_io) ) {
		if( rb_w32_unwrap_io_handle(this->ruby_sd) ){
			rb_warn("pg: Could not unwrap win32 socket handle by garbage collector");
		}
	}
#endif
	if (this->pg_cancon)
		PQcancelFinish(this->pg_cancon);
	xfree(this);
}

static size_t
pg_cancon_memsize( const void *_this )
{
	const t_pg_cancon *this = (const t_pg_cancon *)_this;
	return sizeof(*this);
}

static const rb_data_type_t pg_cancon_type = {
	"PG::CancelConnection",
	{
		pg_cancon_gc_mark,
		pg_cancon_gc_free,
		pg_cancon_memsize,
		pg_cancon_gc_compact,
	},
	0, 0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

/*
 * Document-method: allocate
 *
 * call-seq:
 *   PG::CancelConnection.allocate -> obj
 */
static VALUE
pg_cancon_s_allocate( VALUE klass )
{
	t_pg_cancon *this;
	return TypedData_Make_Struct( klass, t_pg_cancon, &pg_cancon_type, this );
}

static inline t_pg_cancon *
pg_cancon_get_this( VALUE self )
{
	t_pg_cancon *this;
	TypedData_Get_Struct(self, t_pg_cancon, &pg_cancon_type, this);

	return this;
}

static inline PGcancelConn *
pg_cancon_get_conn( VALUE self )
{
	t_pg_cancon *this = pg_cancon_get_this(self);
	if (this->pg_cancon == NULL)
		pg_raise_conn_error( rb_eConnectionBad, self, "PG::CancelConnection is closed");

	return this->pg_cancon;
}

/*
 * Close the associated socket IO object if there is one.
 */
static void
pg_cancon_close_socket_io( VALUE self )
{
	t_pg_cancon *this = pg_cancon_get_this( self );
	pg_unwrap_socket_io( self, &this->socket_io, this->ruby_sd);
}

/*
 * call-seq:
 *    PG::CancelConnection.new(conn) -> obj
 *
 * Prepares a connection over which a cancel request can be sent.
 *
 * Creates a PG::CancelConnection from a PG::Connection object, but it won't instantly start sending a cancel request over this connection.
 * A cancel request can be sent over this connection in a blocking manner using #cancel and in a non-blocking manner using #start.
 * #status can be used to check if the PG::CancelConnection object was connected successfully.
 * This PG::CancelConnection object can be used to cancel the query that's running on the original connection in a thread-safe way.
 *
 * Many connection parameters of the original client will be reused when setting up the connection for the cancel request.
 * Importantly, if the original connection requires encryption of the connection and/or verification of the target host (using sslmode or gssencmode), then the connection for the cancel request is made with these same requirements.
 * Any connection options that are only used during authentication or after authentication of the client are ignored though, because cancellation requests do not require authentication and the connection is closed right after the cancellation request is submitted.
 *
 */
VALUE
pg_cancon_initialize(VALUE self, VALUE rb_conn)
{
	t_pg_cancon *this = pg_cancon_get_this(self);
	PGconn *conn = pg_get_pgconn(rb_conn);

	this->pg_cancon = PQcancelCreate(conn);
	if (this->pg_cancon == NULL)
		pg_raise_conn_error( rb_eConnectionBad, self, "PQcancelCreate failed");

	return self;
}

/*
 * call-seq:
 *    conn.sync_cancel -> nil
 *
 * Requests that the server abandons processing of the current command in a blocking manner.
 *
 * This method directly calls +PQcancelBlocking+ of libpq, so that it doesn't respond to ruby interrupts and doesn't trigger the +Thread.scheduler+ .
 * It is threrfore recommended to call #cancel instead.
 *
 */
static VALUE
pg_cancon_sync_cancel(VALUE self)
{
	PGcancelConn *conn = pg_cancon_get_conn(self);

	pg_cancon_close_socket_io( self );
	if(gvl_PQcancelBlocking(conn) == 0)
		pg_raise_conn_error( rb_eConnectionBad, self, "PQcancelBlocking %s", PQcancelErrorMessage(conn));
	return Qnil;
}

/*
 * call-seq:
 *    conn.start -> nil
 *
 * Requests that the server abandons processing of the current command in a non-blocking manner.
 *
 * The behavior is the same like PG::Connection.connect_start .
 *
 * Use #poll to poll the status of the connection.
 *
 */
static VALUE
pg_cancon_start(VALUE self)
{
	PGcancelConn *conn = pg_cancon_get_conn(self);

	pg_cancon_close_socket_io( self );
	if(gvl_PQcancelStart(conn) == 0)
		pg_raise_conn_error( rb_eConnectionBad, self, "PQcancelStart %s", PQcancelErrorMessage(conn));
	return Qnil;
}

/*
 * call-seq:
 *    conn.error_message -> String
 *
 * Returns the error message most recently generated by an operation on the cancel connection.
 *
 * Nearly all PG::CancelConnection functions will set a message if they fail.
 * Note that by libpq convention, a nonempty error_message result can consist of multiple lines, and will include a trailing newline.
 */
static VALUE
pg_cancon_error_message(VALUE self)
{
	PGcancelConn *conn = pg_cancon_get_conn(self);
	char *p_err;

	p_err = PQcancelErrorMessage(conn);

	return p_err ? rb_str_new_cstr(p_err) : Qnil;
}

/*
 * call-seq:
 *    conn.poll -> Integer
 *
 * This is to poll libpq so that it can proceed with the cancel connection sequence.
 *
 * The behavior is the same like PG::Connection#connect_poll .
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-cancel.html#LIBPQ-PQCANCELSTART]
 *
 */
static VALUE
pg_cancon_poll(VALUE self)
{
	PostgresPollingStatusType status;
	PGcancelConn *conn = pg_cancon_get_conn(self);

	pg_cancon_close_socket_io( self );
	status = gvl_PQcancelPoll(conn);

	return INT2FIX((int)status);
}

/*
 * call-seq:
 *    conn.status -> Integer
 *
 * Returns the status of the cancel connection.
 *
 * The status can be one of a number of values.
 * However, only three of these are seen outside of an asynchronous cancel procedure:
 * +CONNECTION_ALLOCATED+, +CONNECTION_OK+ and +CONNECTION_BAD+.
 * The initial state of a PG::CancelConnection that's successfully created is +CONNECTION_ALLOCATED+.
 * A cancel request that was successfully dispatched has the status +CONNECTION_OK+.
 * A failed cancel attempt is signaled by status +CONNECTION_BAD+.
 * An OK status will remain so until #finish or #reset is called.
 *
 * See #poll with regards to other status codes that might be returned.
 *
 * Successful dispatch of the cancellation is no guarantee that the request will have any effect, however.
 * If the cancellation is effective, the command being canceled will terminate early and return an error result.
 * If the cancellation fails (say, because the server was already done processing the command), then there will be no visible result at all.
 *
 */
static VALUE
pg_cancon_status(VALUE self)
{
	ConnStatusType status;
	PGcancelConn *conn = pg_cancon_get_conn(self);

	status = PQcancelStatus(conn);

	return INT2NUM(status);
}

/*
 * call-seq:
 *    conn.socket_io() -> IO
 *
 * Fetch an IO object created from the CancelConnection's underlying socket.
 * This object can be used per <tt>socket_io.wait_readable</tt>, <tt>socket_io.wait_writable</tt> or for <tt>IO.select</tt> to wait for events while running asynchronous API calls.
 * <tt>IO#wait_*able</tt> is <tt>Fiber.scheduler</tt> compatible in contrast to <tt>IO.select</tt>.
 *
 * The IO object can change while the connection is established.
 * So be sure not to cache the IO object, but repeat calling <tt>conn.socket_io</tt> instead.
 */
static VALUE
pg_cancon_socket_io(VALUE self)
{
	t_pg_cancon *this = pg_cancon_get_this( self );

	if ( !RTEST(this->socket_io) ) {
		int sd;
		if( (sd = PQcancelSocket(this->pg_cancon)) < 0){
			pg_raise_conn_error( rb_eConnectionBad, self, "PQcancelSocket() can't get socket descriptor");
		}
		return pg_wrap_socket_io( sd, self, &this->socket_io, &this->ruby_sd);
	}

	return this->socket_io;
}

/*
 * call-seq:
 *    conn.reset -> nil
 *
 * Resets the PG::CancelConnection so it can be reused for a new cancel connection.
 *
 * If the PG::CancelConnection is currently used to send a cancel request, then this connection is closed.
 * It will then prepare the PG::CancelConnection object such that it can be used to send a new cancel request.
 *
 * This can be used to create one PG::CancelConnection for a PG::Connection and reuse it multiple times throughout the lifetime of the original PG::Connection.
 */
static VALUE
pg_cancon_reset(VALUE self)
{
	PGcancelConn *conn = pg_cancon_get_conn(self);

	pg_cancon_close_socket_io( self );
	PQcancelReset(conn);

	return Qnil;
}

/*
 * call-seq:
 *    conn.finish -> nil
 *
 * Closes the cancel connection (if it did not finish sending the cancel request yet). Also frees memory used by the PG::CancelConnection object.
 *
 */
static VALUE
pg_cancon_finish(VALUE self)
{
	t_pg_cancon *this = pg_cancon_get_this( self );

	pg_cancon_close_socket_io( self );
	if( this->pg_cancon )
		PQcancelFinish(this->pg_cancon);
	this->pg_cancon = NULL;

	return Qnil;
}
#endif

void
init_pg_cancon(void)
{
#ifdef HAVE_PQSETCHUNKEDROWSMODE
	s_id_autoclose_set = rb_intern("autoclose=");

	rb_cPG_Cancon = rb_define_class_under( rb_mPG, "CancelConnection", rb_cObject );
	rb_define_alloc_func( rb_cPG_Cancon, pg_cancon_s_allocate );
	rb_include_module(rb_cPG_Cancon, rb_mEnumerable);

	rb_define_method(rb_cPG_Cancon, "initialize", pg_cancon_initialize, 1);
	rb_define_method(rb_cPG_Cancon, "sync_cancel", pg_cancon_sync_cancel, 0);
	rb_define_method(rb_cPG_Cancon, "start", pg_cancon_start, 0);
	rb_define_method(rb_cPG_Cancon, "poll", pg_cancon_poll, 0);
	rb_define_method(rb_cPG_Cancon, "status", pg_cancon_status, 0);
	rb_define_method(rb_cPG_Cancon, "socket_io", pg_cancon_socket_io, 0);
	rb_define_method(rb_cPG_Cancon, "error_message", pg_cancon_error_message, 0);
	rb_define_method(rb_cPG_Cancon, "reset", pg_cancon_reset, 0);
	rb_define_method(rb_cPG_Cancon, "finish", pg_cancon_finish, 0);
#endif
}
