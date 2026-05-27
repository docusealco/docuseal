
## How do I do a database query?
### I just want an array of the rows...

Use the `Database#execute` method. If you don't give it a block, it will
return an array of all the rows:

```ruby
  require 'sqlite3'

  db = SQLite3::Database.new( "test.db" )
  rows = db.execute( "select * from test" )
```

### I'd like to use a block to iterate through the rows...

Use the `Database#execute` method. If you give it a block, each row of the
result will be yielded to the block:


```ruby
  require 'sqlite3'

  db = SQLite3::Database.new( "test.db" )
  db.execute( "select * from test" ) do |row|
    ...
  end
```

### I need to get the column names as well as the rows...

Use the `Database#execute2` method. This works just like `Database#execute`;
if you don't give it a block, it returns an array of rows; otherwise, it
will yield each row to the block. _However_, the first row returned is
always an array of the column names from the query:


```ruby
  require 'sqlite3'

  db = SQLite3::Database.new( "test.db" )
  columns, *rows = db.execute2( "select * from test" )

  # or use a block:

  columns = nil
  db.execute2( "select * from test" ) do |row|
    if columns.nil?
      columns = row
    else
      # process row
    end
  end
```

### I just want the first row of the result set...

Easy. Just call `Database#get_first_row`:


```ruby
  row = db.get_first_row( "select * from table" )
```


This also supports bind variables, just like `Database#execute`
and friends.

### I just want the first value of the first row of the result set...

Also easy. Just call `Database#get_first_value`:


```ruby
  count = db.get_first_value( "select count(*) from table" )
```


This also supports bind variables, just like `Database#execute`
and friends.

## How do I prepare a statement for repeated execution?

If the same statement is going to be executed repeatedly, you can speed
things up a bit by _preparing_ the statement. You do this via the
`Database#prepare` method. It returns a `Statement` object, and you can
then invoke `#execute` on that to get the `ResultSet`:


```ruby
  stmt = db.prepare( "select * from person" )

  1000.times do
    stmt.execute do |result|
      ...
    end
  end

  stmt.close

  # or, use a block

  db.prepare( "select * from person" ) do |stmt|
    1000.times do
      stmt.execute do |result|
        ...
      end
    end
  end
```


This is made more useful by the ability to bind variables to placeholders
via the `Statement#bind_param` and `Statement#bind_params` methods. (See the
next FAQ for details.)

## How do I use placeholders in an SQL statement?
    
Placeholders in an SQL statement take any of the following formats:


* `?`
* `?_nnn_`
* `:_word_`
* `$_word_`
* `@_word_`


Where _n_ is an integer, and _word_ is an alpha-numeric identifier(or number).
When the placeholder is associated with a number (only in case of `?_nnn_`),
that number identifies the index of the bind variable to replace it with.
When it is an identifier, it identifies the name of the corresponding bind
variable. (In the instance of the first format--a single question mark--the
placeholder is assigned a number one greater than the last index used, or 1
if it is the first.)


For example, here is a query using these placeholder formats:


```sql
  select *
    from table
   where ( c = ?2 or c = ? )
     and d = :name
     and e = :1
```


This defines 5 different placeholders: 1, 2, 3, and "name".


You replace these placeholders by _binding_ them to values. This can be
accomplished in a variety of ways.


The `Database#execute`, and `Database#execute2` methods all accept additional
arguments following the SQL statement. These arguments are assumed to be
bind parameters, and they are bound (positionally) to their corresponding
placeholders:


```ruby
  db.execute( "select * from table where a = ? and b = ?",
              "hello",
              "world" )
```


The above would replace the first question mark with 'hello' and the
second with 'world'. If the placeholders have an explicit index given, they
will be replaced with the bind parameter at that index (1-based).


If a Hash is given as a bind parameter, then its key/value pairs are bound
to the placeholders. This is how you bind by name:


```ruby
  db.execute( "select * from table where a = :name and b = :value",
              "name" => "bob",
              "value" => "priceless" )
```


You can also bind explicitly using the `Statement` object itself. Just pass
additional parameters to the `Statement#execute` statement:


```ruby
  db.prepare( "select * from table where a = :name and b = ?" ) do |stmt|
    stmt.execute "value", "name" => "bob"
  end
```


Or do a `Database#prepare` to get the `Statement`, and then use either
`Statement#bind_param` or `Statement#bind_params`:


```ruby
  stmt = db.prepare( "select * from table where a = :name and b = ?" )

  stmt.bind_param( "name", "bob" )
  stmt.bind_param( 1, "value" )

  # or

  stmt.bind_params( "value", "name" => "bob" )
```

## How do I discover metadata about a query result?
  
IMPORTANT: `Database#execute` returns an Array of Array of Strings
which will have no metadata about the query or the result, such
as column names.


There are 2 main sources of query metadata:

* `Statement`
* `ResultSet`


You can get a `Statement` via `Database#prepare`, and you can get
a `ResultSet` via `Statement#execute` or `Database#query`.


```ruby
sql = 'select * from table'

# No metadata
rows = db.execute(sql)
rows.class # => Array, no metadata
rows.first.class # => Array, no metadata
rows.first.first.class #=> String, no metadata

# Statement has metadata
stmt = db.prepare(sql)
stmt.columns # => [ ... ]
stmt.types # => [ ... ]

# ResultSet has metadata
results = stmt.execute
results.columns # => [ ... ]
results.types # => [ ... ]

# ResultSet has metadata
results = db.query(sql)
results.columns # => [ ... ]
results.types # => [ ... ]
```

## I'd like the rows to be indexible by column name.

By default, each row from a query is returned as an `Array` of values. This
means that you can only obtain values by their index. Sometimes, however,
you would like to obtain values by their column name.


The first way to do this is to set the Database property `results_as_hash`
to true. If you do this, then all rows will be returned as Hash objects,
with the column names as the keys. (In this case, the `fields` property
is unavailable on the row, although the "types" property remains.)


```ruby
  db.results_as_hash = true
  db.execute( "select * from table" ) do |row|
    p row['column1']
    p row['column2']
  end
```


A more granular way to do this is via `ResultSet#next_hash` or
`ResultSet#each_hash`.


```ruby
  results = db.query( "select * from table" )
  row = results.next_hash
  p row['column1']
```


Another way is to use Ara Howard's
[`ArrayFields`](http://rubyforge.org/projects/arrayfields)
module. Just `require "arrayfields"`, and all of your rows will be indexable
by column name, even though they are still arrays!


```ruby
  require 'arrayfields'

  ...
  db.execute( "select * from table" ) do |row|
    p row[0] == row['column1']
    p row[1] == row['column2']
  end
```

## How do I insert binary data into the database?

Use blobs. Blobs are new features of SQLite3. You have to use bind
variables to make it work:


```ruby
  db.execute( "insert into foo ( ?, ? )",
    SQLite3::Blob.new( "\0\1\2\3\4\5" ),
    SQLite3::Blob.new( "a\0b\0c\0d ) )
```


The blob values must be indicated explicitly by binding each parameter to
a value of type `SQLite3::Blob`.

## How do I do a DDL (insert, update, delete) statement?

You can actually do inserts, updates, and deletes in exactly the same way
as selects, but in general the `Database#execute` method will be most
convenient:


```ruby
  db.execute( "insert into table values ( ?, ? )", *bind_vars )
```

## How do I execute multiple statements in a single string?
    
The standard query methods (`Database#execute`, `Database#execute2`,
`Database#query`, and `Statement#execute`) will only execute the first
statement in the string that is given to them. Thus, if you have a
string with multiple SQL statements, each separated by a string,
you can't use those methods to execute them all at once.


Instead, use `Database#execute_batch`:


```ruby
  sql = <<SQL
    create table the_table (
      a varchar2(30),
      b varchar2(30)
    );

    insert into the_table values ( 'one', 'two' );
    insert into the_table values ( 'three', 'four' );
    insert into the_table values ( 'five', 'six' );
  SQL

  db.execute_batch( sql )
```


Unlike the other query methods, `Database#execute_batch` accepts no
block. It will also only ever return `nil`. Thus, it is really only
suitable for batch processing of DDL statements.

## How do I begin/end a transaction
    
Use `Database#transaction` to start a transaction. If you give it a block,
the block will be automatically committed at the end of the block,
unless an exception was raised, in which case the transaction will be
rolled back. (Never explicitly call `Database#commit` or `Database#rollback`
inside of a transaction block--you'll get errors when the block
terminates!)


```ruby
  database.transaction do |db|
    db.execute( "insert into table values ( 'a', 'b', 'c' )" )
    ...
  end
```


Alternatively, if you don't give a block to `Database#transaction`, the
transaction remains open until you explicitly call `Database#commit` or
`Database#rollback`.


```ruby
  db.transaction
  db.execute( "insert into table values ( 'a', 'b', 'c' )" )
  db.commit
```


Note that SQLite does not allow nested transactions, so you'll get errors
if you try to open a new transaction while one is already active. Use
`Database#transaction_active?` to determine whether a transaction is
active or not.

## How do I discover metadata about a table/index?

## How do I do tweak database settings?
