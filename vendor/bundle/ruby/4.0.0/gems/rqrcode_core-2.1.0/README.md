![](https://github.com/whomwah/rqrcode_core/actions/workflows/ruby.yml/badge.svg)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

# RQRCodeCore

`rqrcode_core` is a library for encoding QR Codes in pure Ruby. It has a simple interface with all the standard QR Code options. It was originally adapted in 2008 from a Javascript library by [Kazuhiko Arase](https://github.com/kazuhikoarase).

Features:

- `rqrcode_core` is a Ruby only library. It requires no 3rd party libraries. Just Ruby!
- It is an encoding library. You can't decode QR Codes with it.
- The interface is simple and assumes you just want to encode a string into a QR Code, but also allows for encoding multiple segments.
- QR Code is trade marked by Denso Wave inc.
- Minimum Ruby version is `>= 3.2.0`

`rqrcode_core` is the basis of the popular `rqrcode` gem [https://github.com/whomwah/rqrcode]. This gem allows you to generate different renderings of your QR Code, including `png`, `svg` and `ansi`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rqrcode_core"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rqrcode_core

## Basic Usage

```ruby
$ require "rqrcode_core"
$ qr = RQRCodeCore::QRCode.new("https://kyan.com")
$ puts qr.to_s
```

Output:

```
xxxxxxx x  x x   x x  xx  xxxxxxx
x     x  xxx  xxxxxx xxx  x     x
x xxx x  xxxxx x       xx x xxx x
... etc
```

## Multiple Encoding Support

```ruby
$ require "rqrcode_core"
$ qr = RQRCodeCore::QRCode.new([
  {data: "byteencoded", mode: :byte_8bit},
  {data: "A1" * 100, mode: :alphanumeric},
  {data: "1" * 500, mode: :number}
])
```

This will create a QR Code with byte encoded, alphanumeric and number segments. Any combination of encodings/segments will work provided it fits within size limits.

## Doing your own rendering

```ruby
require "rqrcode_core"

qr = RQRCodeCore::QRCode.new("https://kyan.com")
qr.modules.each do |row|
  row.each do |col|
    print col ? "#" : " "
  end

  print "\n"
end
```

### Options

The library expects a string or array (for multiple encodings) to be parsed in, other args are optional.

```
data - the string or array you wish to encode

size - the size (integer) of the QR Code (defaults to smallest size needed to encode the string)

max_size - the max_size (Integer) of the QR Code (default RQRCodeCore::QRUtil.max_size)

level  - the error correction level, can be:
  * Level :l 7%  of code can be restored
  * Level :m 15% of code can be restored
  * Level :q 25% of code can be restored
  * Level :h 30% of code can be restored (default :h)

mode - the mode of the QR Code (defaults to alphanumeric or byte_8bit, depending on the input data, only used when data is a string):
  * :number
  * :alphanumeric
  * :byte_8bit
```

#### Example

```ruby
RQRCodeCore::QRCode.new("http://kyan.com", size: 2, level: :m, mode: :byte_8bit)
```

## Development

### Tests

You can run the test suite using:

```
$ ./bin/setup
$ rake
```

or try the project from the console with:

```
$ ./bin/console
```

### Linting

The project uses [standardrb](https://github.com/testdouble/standard) and can be run with:

```
$ ./bin/setup
$ rake standard # check
$ rake standard:fix # fix
```

## Performance Optimisation

### Reduce Memory Usage by 70-76%

**If you're running on a 64-bit system, you can dramatically reduce memory consumption by setting:**

```ruby
ENV['RQRCODE_CORE_ARCH_BITS'] = '32'
```

Or from the command line:

```bash
RQRCODE_CORE_ARCH_BITS=32 ruby your_script.rb
```

#### Benchmark Results (64-bit vs 32-bit on 64-bit systems)

**Memory Savings:**
- Single small QR code: 0.38 MB → 0.10 MB (**74% reduction**)
- Single large QR code: 8.53 MB → 2.92 MB (**66% reduction**)
- 100 small QR codes: 37.91 MB → 9.10 MB (**76% reduction**)
- 10 large QR codes: 85.32 MB → 29.19 MB (**66% reduction**)

**Speed Improvement:**
- 2-4% faster across all scenarios (better cache utilization, reduced GC pressure)

**Object Allocation:**
- 85-87% fewer objects allocated
- Integer allocations nearly eliminated (from 70-76% to ~0%)

#### Why This Works

The QR code algorithm doesn't require 64-bit integers for its bit manipulation operations—32-bit is sufficient for all calculations. By default, Ruby on 64-bit systems uses 64-bit integers, which causes unnecessary memory allocation during the internal "right shift zero fill" operations.

**Recommendation:** Use `RQRCODE_CORE_ARCH_BITS=32` for production workloads, especially when:
- Generating QR codes in batch
- Running in memory-constrained environments
- Handling high-concurrency web requests
- Processing large QR codes (version 10+)

See `test/benchmarks/ARCH_BITS_ANALYSIS.md` for detailed benchmark data and analysis.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whomwah/rqrcode_core.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
