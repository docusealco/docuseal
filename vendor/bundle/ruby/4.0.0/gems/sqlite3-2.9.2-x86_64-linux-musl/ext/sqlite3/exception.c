#include <sqlite3_ruby.h>

static VALUE
status2klass(int status)
{
    /* Consider only lower 8 bits, to work correctly when
       extended result codes are enabled. */
    switch (status & 0xff) {
        case SQLITE_OK:
            return Qnil;
        case SQLITE_ERROR:
            return rb_path2class("SQLite3::SQLException");
        case SQLITE_INTERNAL:
            return rb_path2class("SQLite3::InternalException");
        case SQLITE_PERM:
            return rb_path2class("SQLite3::PermissionException");
        case SQLITE_ABORT:
            return rb_path2class("SQLite3::AbortException");
        case SQLITE_BUSY:
            return rb_path2class("SQLite3::BusyException");
        case SQLITE_LOCKED:
            return rb_path2class("SQLite3::LockedException");
        case SQLITE_NOMEM:
            return rb_path2class("SQLite3::MemoryException");
        case SQLITE_READONLY:
            return rb_path2class("SQLite3::ReadOnlyException");
        case SQLITE_INTERRUPT:
            return rb_path2class("SQLite3::InterruptException");
        case SQLITE_IOERR:
            return rb_path2class("SQLite3::IOException");
        case SQLITE_CORRUPT:
            return rb_path2class("SQLite3::CorruptException");
        case SQLITE_NOTFOUND:
            return rb_path2class("SQLite3::NotFoundException");
        case SQLITE_FULL:
            return rb_path2class("SQLite3::FullException");
        case SQLITE_CANTOPEN:
            return rb_path2class("SQLite3::CantOpenException");
        case SQLITE_PROTOCOL:
            return rb_path2class("SQLite3::ProtocolException");
        case SQLITE_EMPTY:
            return rb_path2class("SQLite3::EmptyException");
        case SQLITE_SCHEMA:
            return rb_path2class("SQLite3::SchemaChangedException");
        case SQLITE_TOOBIG:
            return rb_path2class("SQLite3::TooBigException");
        case SQLITE_CONSTRAINT:
            return rb_path2class("SQLite3::ConstraintException");
        case SQLITE_MISMATCH:
            return rb_path2class("SQLite3::MismatchException");
        case SQLITE_MISUSE:
            return rb_path2class("SQLite3::MisuseException");
        case SQLITE_NOLFS:
            return rb_path2class("SQLite3::UnsupportedException");
        case SQLITE_AUTH:
            return rb_path2class("SQLite3::AuthorizationException");
        case SQLITE_FORMAT:
            return rb_path2class("SQLite3::FormatException");
        case SQLITE_RANGE:
            return rb_path2class("SQLite3::RangeException");
        case SQLITE_NOTADB:
            return rb_path2class("SQLite3::NotADatabaseException");
        default:
            return rb_path2class("SQLite3::Exception");
    }
}

void
rb_sqlite3_raise(sqlite3 *db, int status)
{
    VALUE klass = status2klass(status);
    if (NIL_P(klass)) {
        return;
    }

    VALUE exception = rb_exc_new2(klass, sqlite3_errmsg(db));
    rb_iv_set(exception, "@code", INT2FIX(status));

    rb_exc_raise(exception);
}

/*
 *  accepts a sqlite3 error message as the final argument, which will be `sqlite3_free`d
 */
void
rb_sqlite3_raise_msg(sqlite3 *db, int status, const char *msg)
{
    VALUE klass = status2klass(status);
    if (NIL_P(klass)) {
        return;
    }

    VALUE exception = rb_exc_new2(klass, msg);
    rb_iv_set(exception, "@code", INT2FIX(status));
    sqlite3_free((void *)msg);

    rb_exc_raise(exception);
}

void
rb_sqlite3_raise_with_sql(sqlite3 *db, int status, const char *sql)
{
    VALUE klass = status2klass(status);
    if (NIL_P(klass)) {
        return;
    }

    const char *error_msg = sqlite3_errmsg(db);
    int error_offset = -1;
#ifdef HAVE_SQLITE3_ERROR_OFFSET
    error_offset = sqlite3_error_offset(db);
#endif

    VALUE exception = rb_exc_new2(klass, error_msg);
    rb_iv_set(exception, "@code", INT2FIX(status));
    if (sql) {
        rb_iv_set(exception, "@sql", rb_str_new2(sql));
        rb_iv_set(exception, "@sql_offset", INT2FIX(error_offset));
    }

    rb_exc_raise(exception);
}
