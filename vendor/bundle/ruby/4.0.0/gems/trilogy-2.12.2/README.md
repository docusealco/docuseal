# trilogy

Ruby bindings to the Trilogy client library

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'trilogy'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install trilogy
```

## Usage

``` ruby
client = Trilogy.new(host: "127.0.0.1", port: 3306, username: "root", read_timeout: 2)
if client.ping
  client.change_db "mydb"

  result = client.query("SELECT id, created_at FROM users LIMIT 10")
  result.each_hash do |user|
    p user
  end
end
```

### Processing multiple result sets

In order to send and receive multiple result sets, pass the `multi_statement` option when connecting.
`Trilogy#more_results_exist?` will return true if more results exist, false if no more results exist, or raise
an error if the respective query errored. `Trilogy#next_result` will retrieve the next result set, or return nil
if no more results exist.

``` ruby
client = Trilogy.new(host: "127.0.0.1", port: 3306, username: "root", read_timeout: 2, multi_statement: true)

results = []
results << client.query("SELECT name FROM users WHERE id = 1; SELECT name FROM users WHERE id = 2")
results << client.next_result while client.more_results_exist?
```

## Building
You should use the rake commands to build/install/release the gem
For instance:
```shell
bundle exec rake build
```

## Contributing

The official Ruby bindings are inside of the canonical trilogy repository itself.

1. Fork it ( https://github.com/trilogy-libraries/trilogy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## mysql2 gem compatibility

The trilogy API was heavily inspired by the mysql2 gem but has a few notable
differences:

* The `query_flags` don't inherit from the connection options hash.
  This means that options like turning on/of casting will need to be set before
  a query and not passed in at connect time.
* For performance reasons there is no `application_timezone` query option. If
  casting is enabled and your database timezone is different than what the
  application is expecting you'll need to do the conversion yourself later.
* While we still tag strings with the encoding configured on the field they came
  from - for performance reasons no automatic transcoding into
  `Encoding.default_internal` is done. Similarly to not automatically converting
  Time objects from `database_timezone` into `application_timezone`, we leave
  the transcoding step up to the caller.
* There is no `as` query option. Calling `Trilogy::Result#each` will yield an array
  of row values. If you want a hash you should use `Trilogy::Result#each_hash`.
