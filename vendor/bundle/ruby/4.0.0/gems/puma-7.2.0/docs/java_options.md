# Java Options

`System Properties` or `Environment Variables` can be used to change Puma's
default configuration for its Java extension. The provided values are evaluated
during initialization, and changes while running the app have no effect.
Moreover, default values may be used in case of invalid inputs.

## Supported Options

| ENV Name                     | Default Value |        Validation        |
|------------------------------|:-------------:|:------------------------:|
| PUMA_QUERY_STRING_MAX_LENGTH |   1024 * 10   | Positive natural number  |
| PUMA_REQUEST_PATH_MAX_LENGTH |     8192      | Positive natural number  |
| PUMA_REQUEST_URI_MAX_LENGTH  |   1024 * 12   | Positive natural number  |
| PUMA_SKIP_SIGUSR2            |   nil         | n/a                      |

## Examples

### Invalid inputs

An empty string will be handled as missing, and the default value will be used instead.
Puma will print an error message for other invalid values.

```
foo@bar:~/puma$ PUMA_QUERY_STRING_MAX_LENGTH=abc PUMA_REQUEST_PATH_MAX_LENGTH='' PUMA_REQUEST_URI_MAX_LENGTH=0 bundle exec bin/puma test/rackup/hello.ru

The value 0 for PUMA_REQUEST_URI_MAX_LENGTH is invalid. Using default value 12288 instead.
The value abc for PUMA_QUERY_STRING_MAX_LENGTH is invalid. Using default value 10240 instead.
Puma starting in single mode...
```

### Valid inputs

```
foo@bar:~/puma$ PUMA_REQUEST_PATH_MAX_LENGTH=9 bundle exec bin/puma test/rackup/hello.ru

Puma starting in single mode...
```
```
foo@bar:~ export path=/123456789 # 10 chars
foo@bar:~ curl "http://localhost:9292${path}"

Puma caught this error: HTTP element REQUEST_PATH is longer than the 9 allowed length. (Puma::HttpParserError)

foo@bar:~ export path=/12345678 # 9 chars
foo@bar:~ curl "http://localhost:9292${path}"
Hello World
```

### Java Flight Recorder Compatibility

Unfortunately Java Flight Recorder uses `SIGUSR2` internally. If you wish to 
use JFR, turn off Puma's trapping of `SIGUSR2` by setting the environment variable
`PUMA_SKIP_SIGUSR2` to any value.
