#include <sqlite3_ruby.h>

#define REQUIRE_OPEN_STMT(_ctxt) \
  if (!_ctxt->st) \
    rb_raise(rb_path2class("SQLite3::Exception"), "cannot use a closed statement");

#define REQUIRE_LIVE_DB(_ctxt) \
  if (_ctxt->db->flags & SQLITE3_RB_DATABASE_DISCARDED) \
    rb_raise(rb_path2class("SQLite3::Exception"), "cannot use a statement associated with a discarded database");

VALUE cSqlite3Statement;

static void
statement_deallocate(void *data)
{
    sqlite3StmtRubyPtr s = (sqlite3StmtRubyPtr)data;

    if (s->st) {
        sqlite3_finalize(s->st);
    }

    xfree(data);
}

static size_t
statement_memsize(const void *data)
{
    const sqlite3StmtRubyPtr s = (const sqlite3StmtRubyPtr)data;
    // NB: can't account for s->st because the type is incomplete.
    return sizeof(*s);
}

static const rb_data_type_t statement_type = {
    "SQLite3::Backup",
    {
        NULL,
        statement_deallocate,
        statement_memsize,
    },
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
allocate(VALUE klass)
{
    sqlite3StmtRubyPtr ctx;
    return TypedData_Make_Struct(klass, sqlite3StmtRuby, &statement_type, ctx);
}

static VALUE
prepare(VALUE self, VALUE db, VALUE sql)
{
    sqlite3RubyPtr db_ctx = sqlite3_database_unwrap(db);
    sqlite3StmtRubyPtr ctx;
    const char *tail = NULL;
    int status;

    StringValue(sql);

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    /* Dereferencing a pointer to the database struct will be faster than accessing it through the
     * instance variable @connection. The struct pointer is guaranteed to be live because instance
     * variable will keep it from being GCed. */
    ctx->db = db_ctx;

#ifdef HAVE_SQLITE3_PREPARE_V2
    status = sqlite3_prepare_v2(
#else
    status = sqlite3_prepare(
#endif
                 db_ctx->db,
                 (const char *)StringValuePtr(sql),
                 (int)RSTRING_LEN(sql),
                 &ctx->st,
                 &tail
             );

    CHECK_PREPARE(db_ctx->db, status, StringValuePtr(sql));
    timespecclear(&db_ctx->stmt_deadline);

    return rb_utf8_str_new_cstr(tail);
}

/* call-seq: stmt.close
 *
 * Closes the statement by finalizing the underlying statement
 * handle. The statement must not be used after being closed.
 */
static VALUE
sqlite3_rb_close(VALUE self)
{
    sqlite3StmtRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_OPEN_STMT(ctx);

    sqlite3_finalize(ctx->st);
    ctx->st = NULL;

    return self;
}

/* call-seq: stmt.closed?
 *
 * Returns true if the statement has been closed.
 */
static VALUE
closed_p(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    if (!ctx->st) { return Qtrue; }

    return Qfalse;
}

static VALUE
step(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    sqlite3_stmt *stmt;
    int value, length;
    VALUE list;
    rb_encoding *internal_encoding;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    if (ctx->done_p) { return Qnil; }

    internal_encoding = rb_default_internal_encoding();

    stmt = ctx->st;

    value = sqlite3_step(stmt);
    if (rb_errinfo() != Qnil) {
        /* some user defined function was invoked as a callback during step and
         * it raised an exception that has been suppressed until step returns.
         * Now re-raise it. */
        VALUE exception = rb_errinfo();
        rb_set_errinfo(Qnil);
        rb_exc_raise(exception);
    }

    length = sqlite3_column_count(stmt);
    list = rb_ary_new2((long)length);

    switch (value) {
        case SQLITE_ROW: {
            int i;
            for (i = 0; i < length; i++) {
                VALUE val;

                switch (sqlite3_column_type(stmt, i)) {
                    case SQLITE_INTEGER:
                        val = LL2NUM(sqlite3_column_int64(stmt, i));
                        break;
                    case SQLITE_FLOAT:
                        val = rb_float_new(sqlite3_column_double(stmt, i));
                        break;
                    case SQLITE_TEXT: {
                        val = rb_utf8_str_new(
                                  (const char *)sqlite3_column_text(stmt, i),
                                  (long)sqlite3_column_bytes(stmt, i)
                              );
                        if (internal_encoding) {
                            val = rb_str_export_to_enc(val, internal_encoding);
                        }
                        rb_obj_freeze(val);
                    }
                    break;
                    case SQLITE_BLOB: {
                        val = rb_str_new(
                                  (const char *)sqlite3_column_blob(stmt, i),
                                  (long)sqlite3_column_bytes(stmt, i)
                              );
                        rb_obj_freeze(val);
                    }
                    break;
                    case SQLITE_NULL:
                        val = Qnil;
                        break;
                    default:
                        rb_raise(rb_eRuntimeError, "bad type");
                }

                rb_ary_store(list, (long)i, val);
            }
        }
        break;
        case SQLITE_DONE:
            ctx->done_p = 1;
            return Qnil;
            break;
        default:
            sqlite3_reset(stmt);
            ctx->done_p = 0;
            CHECK(sqlite3_db_handle(ctx->st), value);
    }

    rb_obj_freeze(list);

    return list;
}

/* call-seq: stmt.bind_param(key, value)
 *
 * Binds value to the named (or positional) placeholder. If +param+ is a
 * Fixnum, it is treated as an index for a positional placeholder.
 * Otherwise it is used as the name of the placeholder to bind to.
 *
 * See also #bind_params.
 */
static VALUE
bind_param(VALUE self, VALUE key, VALUE value)
{
    sqlite3StmtRubyPtr ctx;
    int status;
    int index;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    switch (TYPE(key)) {
        case T_SYMBOL:
            key = rb_funcall(key, rb_intern("to_s"), 0);
        case T_STRING:
            if (RSTRING_PTR(key)[0] != ':') { key = rb_str_plus(rb_str_new2(":"), key); }
            index = sqlite3_bind_parameter_index(ctx->st, StringValuePtr(key));
            break;
        default:
            index = (int)NUM2INT(key);
    }

    if (index == 0) {
        rb_raise(rb_path2class("SQLite3::Exception"), "no such bind parameter");
    }

    switch (TYPE(value)) {
        case T_STRING:
            if (CLASS_OF(value) == cSqlite3Blob
                    || rb_enc_get_index(value) == rb_ascii8bit_encindex()
               ) {
                status = sqlite3_bind_blob(
                             ctx->st,
                             index,
                             (const char *)StringValuePtr(value),
                             (int)RSTRING_LEN(value),
                             SQLITE_TRANSIENT
                         );
            } else {


                if (UTF16_LE_P(value) || UTF16_BE_P(value)) {
                    status = sqlite3_bind_text16(
                                 ctx->st,
                                 index,
                                 (const char *)StringValuePtr(value),
                                 (int)RSTRING_LEN(value),
                                 SQLITE_TRANSIENT
                             );
                } else {
                    if (!UTF8_P(value) || !USASCII_P(value)) {
                        value = rb_str_encode(value, rb_enc_from_encoding(rb_utf8_encoding()), 0, Qnil);
                    }
                    status = sqlite3_bind_text(
                                 ctx->st,
                                 index,
                                 (const char *)StringValuePtr(value),
                                 (int)RSTRING_LEN(value),
                                 SQLITE_TRANSIENT
                             );
                }
            }
            break;
        case T_BIGNUM: {
            sqlite3_int64 num64;
            if (bignum_to_int64(value, &num64)) {
                status = sqlite3_bind_int64(ctx->st, index, num64);
                break;
            }
        }
        case T_FLOAT:
            status = sqlite3_bind_double(ctx->st, index, NUM2DBL(value));
            break;
        case T_FIXNUM:
            status = sqlite3_bind_int64(ctx->st, index, (sqlite3_int64)FIX2LONG(value));
            break;
        case T_NIL:
            status = sqlite3_bind_null(ctx->st, index);
            break;
        default:
            rb_raise(rb_eRuntimeError, "can't prepare %s",
                     rb_class2name(CLASS_OF(value)));
            break;
    }

    CHECK(sqlite3_db_handle(ctx->st), status);

    return self;
}

/* call-seq: stmt.reset!
 *
 * Resets the statement. This is typically done internally, though it might
 * occasionally be necessary to manually reset the statement.
 */
static VALUE
reset_bang(VALUE self)
{
    sqlite3StmtRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    sqlite3_reset(ctx->st);

    ctx->done_p = 0;

    return self;
}

/* call-seq: stmt.clear_bindings!
 *
 * Resets the statement. This is typically done internally, though it might
 * occasionally be necessary to manually reset the statement.
 */
static VALUE
clear_bindings_bang(VALUE self)
{
    sqlite3StmtRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    sqlite3_clear_bindings(ctx->st);

    ctx->done_p = 0;

    return self;
}

/* call-seq: stmt.done?
 *
 * returns true if all rows have been returned.
 */
static VALUE
done_p(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    if (ctx->done_p) { return Qtrue; }
    return Qfalse;
}

/* call-seq: stmt.column_count
 *
 * Returns the number of columns to be returned for this statement
 */
static VALUE
column_count(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    return INT2NUM(sqlite3_column_count(ctx->st));
}

#if HAVE_RB_ENC_INTERNED_STR_CSTR
static VALUE
interned_utf8_cstr(const char *str)
{
    return rb_enc_interned_str_cstr(str, rb_utf8_encoding());
}
#else
static VALUE
interned_utf8_cstr(const char *str)
{
    VALUE rb_str = rb_utf8_str_new_cstr(str);
    return rb_funcall(rb_str, rb_intern("-@"), 0);
}
#endif

/* call-seq: stmt.column_name(index)
 *
 * Get the column name at +index+.  0 based.
 */
static VALUE
column_name(VALUE self, VALUE index)
{
    sqlite3StmtRubyPtr ctx;
    const char *name;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    name = sqlite3_column_name(ctx->st, (int)NUM2INT(index));

    VALUE ret = Qnil;

    if (name) {
        ret = interned_utf8_cstr(name);
    }
    return ret;
}

/* call-seq: stmt.column_decltype(index)
 *
 * Get the column type at +index+.  0 based.
 */
static VALUE
column_decltype(VALUE self, VALUE index)
{
    sqlite3StmtRubyPtr ctx;
    const char *name;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    name = sqlite3_column_decltype(ctx->st, (int)NUM2INT(index));

    if (name) { return rb_str_new2(name); }
    return Qnil;
}

/* call-seq: stmt.bind_parameter_count
 *
 * Return the number of bind parameters
 */
static VALUE
bind_parameter_count(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    return INT2NUM(sqlite3_bind_parameter_count(ctx->st));
}

/** call-seq: stmt.named_params
 *
 * Return the list of named parameters in the statement.
 * This returns a frozen array of strings (without the leading prefix character).
 * The values of this list can be used to bind parameters
 * to the statement using bind_param. Positional (?NNN) and anonymous (?)
 * parameters are excluded.
 *
 */
static VALUE
named_params(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    int param_count = sqlite3_bind_parameter_count(ctx->st);
    VALUE params = rb_ary_new2(param_count);

    // The first host parameter has an index of 1, not 0.
    for (int i = 1; i <= param_count; i++) {
        const char *name = sqlite3_bind_parameter_name(ctx->st, i);
        // We ignore positional and anonymous parameters, and also null values, since there can be
        // gaps in the list.
        if (name && *name != '?') {
            VALUE param = interned_utf8_cstr(name + 1);
            rb_ary_push(params, param);
        }
    }
    return rb_obj_freeze(params);
}

enum stmt_stat_sym {
    stmt_stat_sym_fullscan_steps,
    stmt_stat_sym_sorts,
    stmt_stat_sym_autoindexes,
    stmt_stat_sym_vm_steps,
#ifdef SQLITE_STMTSTATUS_REPREPARE
    stmt_stat_sym_reprepares,
#endif
#ifdef SQLITE_STMTSTATUS_RUN
    stmt_stat_sym_runs,
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_MISS
    stmt_stat_sym_filter_misses,
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_HIT
    stmt_stat_sym_filter_hits,
#endif
    stmt_stat_sym_last
};

static VALUE stmt_stat_symbols[stmt_stat_sym_last];

static void
setup_stmt_stat_symbols(void)
{
    if (stmt_stat_symbols[0] == 0) {
#define S(s) stmt_stat_symbols[stmt_stat_sym_##s] = ID2SYM(rb_intern_const(#s))
        S(fullscan_steps);
        S(sorts);
        S(autoindexes);
        S(vm_steps);
#ifdef SQLITE_STMTSTATUS_REPREPARE
        S(reprepares);
#endif
#ifdef SQLITE_STMTSTATUS_RUN
        S(runs);
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_MISS
        S(filter_misses);
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_HIT
        S(filter_hits);
#endif
#undef S
    }
}

static size_t
stmt_stat_internal(VALUE hash_or_sym, sqlite3_stmt *stmt)
{
    VALUE hash = Qnil, key = Qnil;

    setup_stmt_stat_symbols();

    if (RB_TYPE_P(hash_or_sym, T_HASH)) {
        hash = hash_or_sym;
    } else if (SYMBOL_P(hash_or_sym)) {
        key = hash_or_sym;
    } else {
        rb_raise(rb_eTypeError, "non-hash or symbol argument");
    }

#define SET(name, stat_type) \
    if (key == stmt_stat_symbols[stmt_stat_sym_##name]) \
        return sqlite3_stmt_status(stmt, stat_type, 0); \
    else if (hash != Qnil) \
        rb_hash_aset(hash, stmt_stat_symbols[stmt_stat_sym_##name], SIZET2NUM(sqlite3_stmt_status(stmt, stat_type, 0)));

    SET(fullscan_steps, SQLITE_STMTSTATUS_FULLSCAN_STEP);
    SET(sorts, SQLITE_STMTSTATUS_SORT);
    SET(autoindexes, SQLITE_STMTSTATUS_AUTOINDEX);
    SET(vm_steps, SQLITE_STMTSTATUS_VM_STEP);
#ifdef SQLITE_STMTSTATUS_REPREPARE
    SET(reprepares, SQLITE_STMTSTATUS_REPREPARE);
#endif
#ifdef SQLITE_STMTSTATUS_RUN
    SET(runs, SQLITE_STMTSTATUS_RUN);
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_MISS
    SET(filter_misses, SQLITE_STMTSTATUS_FILTER_MISS);
#endif
#ifdef SQLITE_STMTSTATUS_FILTER_HIT
    SET(filter_hits, SQLITE_STMTSTATUS_FILTER_HIT);
#endif
#undef SET

    if (!NIL_P(key)) { /* matched key should return above */
        rb_raise(rb_eArgError, "unknown key: %"PRIsVALUE, rb_sym2str(key));
    }

    return 0;
}

/* call-seq: stmt.stats_as_hash(hash)
 *
 * Returns a Hash containing information about the statement.
 */
static VALUE
stats_as_hash(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    VALUE arg = rb_hash_new();

    stmt_stat_internal(arg, ctx->st);
    return arg;
}

/* call-seq: stmt.stmt_stat(hash_or_key)
 *
 * Returns a Hash containing information about the statement.
 */
static VALUE
stat_for(VALUE self, VALUE key)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    if (SYMBOL_P(key)) {
        size_t value = stmt_stat_internal(key, ctx->st);
        return SIZET2NUM(value);
    } else {
        rb_raise(rb_eTypeError, "non-symbol given");
    }
}

#ifdef SQLITE_STMTSTATUS_MEMUSED
/* call-seq: stmt.memused
 *
 * Return the approximate number of bytes of heap memory used to store the prepared statement
 */
static VALUE
memused(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    return INT2NUM(sqlite3_stmt_status(ctx->st, SQLITE_STMTSTATUS_MEMUSED, 0));
}
#endif

#ifdef HAVE_SQLITE3_COLUMN_DATABASE_NAME

/* call-seq: stmt.database_name(column_index)
 *
 * Return the database name for the column at +column_index+
 */
static VALUE
database_name(VALUE self, VALUE index)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    return SQLITE3_UTF8_STR_NEW2(
               sqlite3_column_database_name(ctx->st, NUM2INT(index)));
}

#endif

/* call-seq: stmt.sql
 *
 * Returns the SQL statement used to create this prepared statement
 */
static VALUE
get_sql(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    return rb_obj_freeze(SQLITE3_UTF8_STR_NEW2(sqlite3_sql(ctx->st)));
}

/* call-seq: stmt.expanded_sql
 *
 * Returns the SQL statement used to create this prepared statement, but
 * with bind parameters substituted in to the statement.
 */
static VALUE
get_expanded_sql(VALUE self)
{
    sqlite3StmtRubyPtr ctx;
    char *expanded_sql;
    VALUE rb_expanded_sql;

    TypedData_Get_Struct(self, sqlite3StmtRuby, &statement_type, ctx);

    REQUIRE_LIVE_DB(ctx);
    REQUIRE_OPEN_STMT(ctx);

    expanded_sql = sqlite3_expanded_sql(ctx->st);
    rb_expanded_sql = rb_obj_freeze(SQLITE3_UTF8_STR_NEW2(expanded_sql));
    sqlite3_free(expanded_sql);

    return rb_expanded_sql;
}

void
init_sqlite3_statement(void)
{
    cSqlite3Statement = rb_define_class_under(mSqlite3, "Statement", rb_cObject);

    rb_define_alloc_func(cSqlite3Statement, allocate);
    rb_define_method(cSqlite3Statement, "close", sqlite3_rb_close, 0);
    rb_define_method(cSqlite3Statement, "closed?", closed_p, 0);
    rb_define_method(cSqlite3Statement, "bind_param", bind_param, 2);
    rb_define_method(cSqlite3Statement, "reset!", reset_bang, 0);
    rb_define_method(cSqlite3Statement, "clear_bindings!", clear_bindings_bang, 0);
    rb_define_method(cSqlite3Statement, "step", step, 0);
    rb_define_method(cSqlite3Statement, "done?", done_p, 0);
    rb_define_method(cSqlite3Statement, "column_count", column_count, 0);
    rb_define_method(cSqlite3Statement, "column_name", column_name, 1);
    rb_define_method(cSqlite3Statement, "column_decltype", column_decltype, 1);
    rb_define_method(cSqlite3Statement, "bind_parameter_count", bind_parameter_count, 0);
    rb_define_method(cSqlite3Statement, "named_params", named_params, 0);
    rb_define_method(cSqlite3Statement, "sql", get_sql, 0);
    rb_define_method(cSqlite3Statement, "expanded_sql", get_expanded_sql, 0);
#ifdef HAVE_SQLITE3_COLUMN_DATABASE_NAME
    rb_define_method(cSqlite3Statement, "database_name", database_name, 1);
#endif
#ifdef SQLITE_STMTSTATUS_MEMUSED
    rb_define_method(cSqlite3Statement, "memused", memused, 0);
#endif

    rb_define_private_method(cSqlite3Statement, "prepare", prepare, 2);
    rb_define_private_method(cSqlite3Statement, "stats_as_hash", stats_as_hash, 0);
    rb_define_private_method(cSqlite3Statement, "stat_for", stat_for, 1);
}
