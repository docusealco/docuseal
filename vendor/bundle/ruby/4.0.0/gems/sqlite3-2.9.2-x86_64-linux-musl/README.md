# Ruby Interface for SQLite3

## Overview

This library allows Ruby programs to use the SQLite3 database engine (http://www.sqlite.org).

Note that this module is only compatible with SQLite 3.6.16 or newer.

* Source code: https://github.com/sparklemotion/sqlite3-ruby
* Mailing list: http://groups.google.com/group/sqlite3-ruby
* Download: http://rubygems.org/gems/sqlite3
* Documentation: https://sparklemotion.github.io/sqlite3-ruby/

[![Test suite](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/ci.yml)


## Quick start

For help understanding the SQLite3 Ruby API, please read the [FAQ](./FAQ.md) and the [full API documentation](https://sparklemotion.github.io/sqlite3-ruby/).

A few key classes whose APIs are often-used are:

- SQLite3::Database ([rdoc](https://sparklemotion.github.io/sqlite3-ruby/SQLite3/Database.html))
- SQLite3::Statement ([rdoc](https://sparklemotion.github.io/sqlite3-ruby/SQLite3/Statement.html))
- SQLite3::ResultSet ([rdoc](https://sparklemotion.github.io/sqlite3-ruby/SQLite3/ResultSet.html))

If you have any questions that you feel should be addressed in the FAQ, please send them to [the mailing list](http://groups.google.com/group/sqlite3-ruby) or open a [discussion thread](https://github.com/sparklemotion/sqlite3-ruby/discussions/categories/q-a).


``` ruby
require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.db"

# Create a table
rows = db.execute <<-SQL
  create table numbers (
    name varchar(30),
    val int
  );
SQL

# Execute a few inserts
{
  "one" => 1,
  "two" => 2,
}.each do |pair|
  db.execute "insert into numbers values ( ?, ? )", pair
end

# Find a few rows
db.execute( "select * from numbers" ) do |row|
  p row
end
# => ["one", 1]
#    ["two", 2]

# Create another table with multiple columns
db.execute <<-SQL
  create table students (
    name varchar(50),
    email varchar(50),
    grade varchar(5),
    blog varchar(50)
  );
SQL

# Execute inserts with parameter markers
db.execute("INSERT INTO students (name, email, grade, blog)
            VALUES (?, ?, ?, ?)", ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"])

db.execute( "select * from students" ) do |row|
  p row
end
# => ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"]
```

## Thread Safety

When `SQLite3.threadsafe?` returns `true`, then SQLite3 has been compiled to
support running in a multithreaded environment.  However, this doesn't mean
that all classes in the SQLite3 gem can be considered "thread safe".

When `SQLite3.threadsafe?` returns `true`, it is safe to share only
`SQLite3::Database` instances among threads without providing your own locking
mechanism.  For example, the following code is fine because only the database
instance is shared among threads:

```ruby
require 'sqlite3'

db = SQLite3::Database.new ":memory:"

latch = Queue.new

ts = 10.times.map {
  Thread.new {
    latch.pop
    db.execute "SELECT '#{Thread.current.inspect}'"
  }
}
10.times { latch << nil }

p ts.map(&:value)
```

Other instances can be shared among threads, but they require that you provide
your own locking for thread safety.  For example, `SQLite3::Statement` objects
(prepared statements) are mutable, so applications must take care to add
appropriate locks to avoid data race conditions when sharing these objects
among threads.

Lets rewrite the above example but use a prepared statement and safely share
the prepared statement among threads:

```ruby
db = SQLite3::Database.new ":memory:"

# Prepare a statement
stmt = db.prepare "SELECT :inspect"
stmt_lock = Mutex.new

latch = Queue.new

ts = 10.times.map {
  Thread.new {
    latch.pop

    # Add a lock when using the prepared statement.
    # Binding values, and walking over results will mutate the statement, so
    # in order to prevent other threads from "seeing" this thread's data, we
    # must lock when using the statement object
    stmt_lock.synchronize do
      stmt.execute(Thread.current.inspect).to_a
    end
  }
}

10.times { latch << nil }

p ts.map(&:value)

stmt.close
```

It is generally recommended that if applications want to share a database among
threads, they _only_ share the database instance object.  Other objects are
fine to share, but may require manual locking for thread safety.


## Fork Safety

[Sqlite is not fork
safe](https://www.sqlite.org/howtocorrupt.html#_carrying_an_open_database_connection_across_a_fork_)
and instructs users to not carry an open writable database connection across a `fork()`. Using an inherited
connection in the child may corrupt your database, leak memory, or cause other undefined behavior.

To help protect users of this gem from accidental corruption due to this lack of fork safety, the gem will immediately close any open writable databases in the child after a fork. Discarding writable
connections in the child will incur a small one-time memory leak per connection, but that's
preferable to potentially corrupting your database.

Whenever possible, close writable connections in the parent before forking. If absolutely necessary (and you know what you're doing), you may suppress the fork safety warnings by calling `SQLite3::ForkSafety.suppress_warnings!`.

See [./adr/2024-09-fork-safety.md](./adr/2024-09-fork-safety.md) for more information and context.


## Support

### Installation or database extensions

If you're having trouble with installation, please first read [`INSTALLATION.md`](./INSTALLATION.md).

### General help requests

You can ask for help or support:

* by emailing the [sqlite3-ruby mailing list](http://groups.google.com/group/sqlite3-ruby)
* by opening a [discussion thread](https://github.com/sparklemotion/sqlite3-ruby/discussions/categories/q-a) on Github

### Bug reports

You can file the bug at the [github issues page](https://github.com/sparklemotion/sqlite3-ruby/issues).


## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md).


## License

This library is licensed under `BSD-3-Clause`, see [`LICENSE`](./LICENSE).

### Dependencies

The source code of `sqlite` is distributed in the "ruby platform" gem. This code is public domain,
see https://www.sqlite.org/copyright.html for details.
