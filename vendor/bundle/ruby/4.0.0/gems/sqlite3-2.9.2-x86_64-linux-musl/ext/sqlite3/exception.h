#ifndef SQLITE3_EXCEPTION_RUBY
#define SQLITE3_EXCEPTION_RUBY

#define CHECK(_db, _status) rb_sqlite3_raise(_db, _status);
#define CHECK_MSG(_db, _status, _msg) rb_sqlite3_raise_msg(_db, _status, _msg);
#define CHECK_PREPARE(_db, _status, _sql) rb_sqlite3_raise_with_sql(_db, _status, _sql)

void rb_sqlite3_raise(sqlite3 *db, int status);
void rb_sqlite3_raise_msg(sqlite3 *db, int status, const char *msg);
void rb_sqlite3_raise_with_sql(sqlite3 *db, int status, const char *sql);

#endif
