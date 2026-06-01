#ifdef HAVE_SQLITE3_BACKUP_INIT

#include <sqlite3_ruby.h>

#define REQUIRE_OPEN_BACKUP(_ctxt) \
  if(!_ctxt->p) \
    rb_raise(rb_path2class("SQLite3::Exception"), "cannot use a closed backup");

VALUE cSqlite3Backup;

static size_t
backup_memsize(const void *data)
{
    sqlite3BackupRubyPtr ctx = (sqlite3BackupRubyPtr)data;
    // NB: can't account for ctx->p because the type is incomplete.
    return sizeof(*ctx);
}

static const rb_data_type_t backup_type = {
    "SQLite3::Backup",
    {
        NULL,
        RUBY_TYPED_DEFAULT_FREE,
        backup_memsize,
    },
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
allocate(VALUE klass)
{
    sqlite3BackupRubyPtr ctx;
    return TypedData_Make_Struct(klass, sqlite3BackupRuby, &backup_type, ctx);
}

/* call-seq: SQLite3::Backup.new(dstdb, dstname, srcdb, srcname)
 *
 * Initialize backup the backup.
 *
 * dstdb:
 *   the destination SQLite3::Database object.
 * dstname:
 *   the destination's database name.
 * srcdb:
 *   the source SQLite3::Database object.
 * srcname:
 *   the source's database name.
 *
 * The database name is "main", "temp", or the name specified in an
 * ATTACH statement.
 *
 * This feature requires SQLite 3.6.11 or later.
 *
 *   require 'sqlite3'
 *   sdb = SQLite3::Database.new('src.sqlite3')
 *
 *   ddb = SQLite3::Database.new(':memory:')
 *   b = SQLite3::Backup.new(ddb, 'main', sdb, 'main')
 *   p [b.remaining, b.pagecount] # invalid value; for example [0, 0]
 *   begin
 *     p b.step(1) #=> OK or DONE
 *     p [b.remaining, b.pagecount]
 *   end while b.remaining > 0
 *   b.finish
 *
 *   ddb = SQLite3::Database.new(':memory:')
 *   b = SQLite3::Backup.new(ddb, 'main', sdb, 'main')
 *   b.step(-1) #=> DONE
 *   b.finish
 *
 */
static VALUE
initialize(VALUE self, VALUE dstdb, VALUE dstname, VALUE srcdb, VALUE srcname)
{
    sqlite3BackupRubyPtr ctx;
    sqlite3RubyPtr ddb_ctx, sdb_ctx;
    sqlite3_backup *pBackup;

    TypedData_Get_Struct(self, sqlite3BackupRuby, &backup_type, ctx);
    ddb_ctx = sqlite3_database_unwrap(dstdb);
    sdb_ctx = sqlite3_database_unwrap(srcdb);

    if (!sdb_ctx->db) {
        rb_raise(rb_eArgError, "cannot backup from a closed database");
    }
    if (!ddb_ctx->db) {
        rb_raise(rb_eArgError, "cannot backup to a closed database");
    }

    pBackup = sqlite3_backup_init(ddb_ctx->db, StringValuePtr(dstname),
                                  sdb_ctx->db, StringValuePtr(srcname));
    if (pBackup) {
        ctx->p = pBackup;
    } else {
        CHECK(ddb_ctx->db, sqlite3_errcode(ddb_ctx->db));
    }

    return self;
}

/* call-seq: SQLite3::Backup#step(nPage)
 *
 * Copy database pages up to +nPage+.
 * If negative, copy all remaining source pages.
 *
 * If all pages are copied, it returns SQLite3::Constants::ErrorCode::DONE.
 * When coping is not done, it returns SQLite3::Constants::ErrorCode::OK.
 * When some errors occur, it returns the error code.
 */
static VALUE
step(VALUE self, VALUE nPage)
{
    sqlite3BackupRubyPtr ctx;
    int status;

    TypedData_Get_Struct(self, sqlite3BackupRuby, &backup_type, ctx);
    REQUIRE_OPEN_BACKUP(ctx);
    status = sqlite3_backup_step(ctx->p, NUM2INT(nPage));
    return INT2NUM(status);
}

/* call-seq: SQLite3::Backup#finish
 *
 * Destroy the backup object.
 */
static VALUE
finish(VALUE self)
{
    sqlite3BackupRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3BackupRuby, &backup_type, ctx);
    REQUIRE_OPEN_BACKUP(ctx);
    (void)sqlite3_backup_finish(ctx->p);
    ctx->p = NULL;
    return Qnil;
}

/* call-seq: SQLite3::Backup#remaining
 *
 * Returns the number of pages still to be backed up.
 *
 * Note that the value is only updated after step() is called,
 * so before calling step() returned value is invalid.
 */
static VALUE
remaining(VALUE self)
{
    sqlite3BackupRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3BackupRuby, &backup_type, ctx);
    REQUIRE_OPEN_BACKUP(ctx);
    return INT2NUM(sqlite3_backup_remaining(ctx->p));
}

/* call-seq: SQLite3::Backup#pagecount
 *
 * Returns the total number of pages in the source database file.
 *
 * Note that the value is only updated after step() is called,
 * so before calling step() returned value is invalid.
 */
static VALUE
pagecount(VALUE self)
{
    sqlite3BackupRubyPtr ctx;

    TypedData_Get_Struct(self, sqlite3BackupRuby, &backup_type, ctx);
    REQUIRE_OPEN_BACKUP(ctx);
    return INT2NUM(sqlite3_backup_pagecount(ctx->p));
}

void
init_sqlite3_backup(void)
{
#if 0
    VALUE mSqlite3 = rb_define_module("SQLite3");
#endif
    cSqlite3Backup = rb_define_class_under(mSqlite3, "Backup", rb_cObject);

    rb_define_alloc_func(cSqlite3Backup, allocate);
    rb_define_method(cSqlite3Backup, "initialize", initialize, 4);
    rb_define_method(cSqlite3Backup, "step", step, 1);
    rb_define_method(cSqlite3Backup, "finish", finish, 0);
    rb_define_method(cSqlite3Backup, "remaining", remaining, 0);
    rb_define_method(cSqlite3Backup, "pagecount", pagecount, 0);
}

#endif
