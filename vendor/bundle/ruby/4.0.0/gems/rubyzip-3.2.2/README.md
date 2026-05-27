# rubyzip

[![Gem Version](https://badge.fury.io/rb/rubyzip.svg)](http://badge.fury.io/rb/rubyzip)
[![Tests](https://github.com/rubyzip/rubyzip/actions/workflows/tests.yml/badge.svg)](https://github.com/rubyzip/rubyzip/actions/workflows/tests.yml)
[![Linter](https://github.com/rubyzip/rubyzip/actions/workflows/lint.yml/badge.svg)](https://github.com/rubyzip/rubyzip/actions/workflows/lint.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Maintainability](https://qlty.sh/gh/rubyzip/projects/rubyzip/maintainability.svg)](https://qlty.sh/gh/rubyzip/projects/rubyzip)
[![Coverage Status](https://img.shields.io/coveralls/rubyzip/rubyzip.svg)](https://coveralls.io/r/rubyzip/rubyzip?branch=master)

Rubyzip is a ruby library for reading and writing zip files.

## Important notes

### Updating to version 3.0

The public API of some classes has been modernized to use named parameters for optional arguments. Please check your usage of the following Rubyzip classes:
* `File`
* `Entry`
* `InputStream`
* `OutputStream`

**Please see [Updating to version 3.x](https://github.com/rubyzip/rubyzip/wiki/Updating-to-version-3.x) in the wiki for details.**

## Requirements

Version 3.x requires at least Ruby 3.0.

Version 2.x requires at least Ruby 2.4, and is known to work on Ruby 3.x.

It is not recommended to use any versions of Rubyzip earlier than 2.3 due to security issues.

## Installation

Rubyzip is available on RubyGems:

```
gem install rubyzip
```

Or in your Gemfile:

```ruby
gem 'rubyzip'
```

## Usage

### Basic zip archive creation

```ruby
require 'rubygems'
require 'zip'

folder = "Users/me/Desktop/stuff_to_zip"
input_filenames = ['image.jpg', 'description.txt', 'stats.csv']

zipfile_name = "/Users/me/Desktop/archive.zip"

Zip::File.open(zipfile_name, create: true) do |zipfile|
  input_filenames.each do |filename|
    # Two arguments:
    # - The name of the file as it will appear in the archive
    # - The original file, including the path to find it
    zipfile.add(filename, File.join(folder, filename))
  end
  zipfile.get_output_stream("myFile") { |f| f.write "myFile contains just this" }
end
```

### Creating a Zip file with `Zip::OutputStream`

```ruby
require 'rubygems'
require 'zip'

Zip::OutputStream.open('archive.zip') do |zos|
  # Quick.
  zos.put_next_entry('greeting.txt')
  zos << 'Hello, World!'

  # More control.
  # You MUST NOT make any calls on your `Entry` after calling `put_next_entry`.
  entry = Zip::Entry.new(nil, 'parting.txt')
  entry.atime = Time.now
  zos.put_next_entry(entry)
  zos.write('TTFN')
end
```

You can generate a Zip archive in memory using `Zip::OutputStream.write_buffer`.

### Suppressing extra fields

If you wish to suppress extra fields from being added to your entries, you can do so by passing the `suppress_extra_fields` parameter to any of the archive opening calls within `Zip::File` or `Zip::OutputStream`, e.g.:

```ruby
# Suppress all extra fields.
Zip::File.open('archive.zip', create: true, suppress_extra_fields: true)
Zip::OutputStream.open('archive.zip', suppress_extra_fields: true)

# Suppress an individual extra field.
Zip::File.open('archive.zip', create: true, suppress_extra_fields: :zip64)
Zip::OutputStream.open('archive.zip', suppress_extra_fields: :zip64)

# Suppress multiple extra fields.
Zip::File.open('archive.zip', create: true, suppress_extra_fields: [:ntfs, :zip64])
Zip::OutputStream.open('archive.zip', suppress_extra_fields: [:ntfs, :zip64])
```

Note that there are some extra fields that cannot be suppressed at all (e.g. `:aes`), and some which will only be suppressed if it is safe to do so (e.g. `:zip64`).

### Zipping a directory recursively

Copy from [here](https://github.com/rubyzip/rubyzip/blob/9d891f7353e66052283562d3e252fe380bb4b199/samples/example_recursive.rb)

```ruby
require 'zip'

# This is a simple example which uses rubyzip to
# recursively generate a zip file from the contents of
# a specified directory. The directory itself is not
# included in the archive, rather just its contents.
#
# Usage:
#   directory_to_zip = "/tmp/input"
#   output_file = "/tmp/out.zip"
#   zf = ZipFileGenerator.new(directory_to_zip, output_file)
#   zf.write()
class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  # Zip the input directory.
  def write
    entries = Dir.entries(@input_dir) - %w[. ..]

    ::Zip::File.open(@output_file, create: true) do |zipfile|
      write_entries entries, '', zipfile
    end
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path, zipfile)
    entries.each do |e|
      zipfile_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zipfile_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      else
        put_into_archive(disk_file_path, zipfile, zipfile_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
    zipfile.mkdir zipfile_path
    subdir = Dir.entries(disk_file_path) - %w[. ..]
    write_entries subdir, zipfile_path, zipfile
  end

  def put_into_archive(disk_file_path, zipfile, zipfile_path)
    zipfile.add(zipfile_path, disk_file_path)
  end
end
```

### Save zip archive entries sorted by name

To save zip archives with their entries sorted by name (see below), set `::Zip.sort_entries` to `true`

```
Vegetable/
Vegetable/bean
Vegetable/carrot
Vegetable/celery
fruit/
fruit/apple
fruit/kiwi
fruit/mango
fruit/orange
```

Opening an existing zip file with this option set will not change the order of the entries automatically. Altering the zip file - adding an entry, renaming an entry, adding or changing the archive comment, etc - will cause the ordering to be applied when closing the file.

### Default permissions of zip archives

On Posix file systems the default file permissions applied to a new archive
are (0666 - umask), which mimics the behavior of standard tools such as `touch`.

On Windows the default file permissions are set to 0644 as suggested by the
[Ruby File documentation](http://ruby-doc.org/core-2.2.2/File.html).

When modifying a zip archive the file permissions of the archive are preserved.

### Reading a Zip file

```ruby
MAX_SIZE = 1024**2 # 1MiB (but of course you can increase this)
Zip::File.open('foo.zip') do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    puts "Extracting #{entry.name}"
    raise 'File too large when extracted' if entry.size > MAX_SIZE

    # Extract to file or directory based on name in the archive
    entry.extract

    # Read into memory
    content = entry.get_input_stream.read
  end

  # Find specific entry
  entry = zip_file.glob('*.csv').first
  raise 'File too large when extracted' if entry.size > MAX_SIZE
  puts entry.get_input_stream.read
end
```

### Reading a Zip file with `Zip::InputStream`

`Zip::InputStream` can be used for faster reading of zip file content because it does not read the Central directory up front.

There is one exception where it can not work however, and this is if the file does not contain enough information in the local entry headers to extract an entry. This is indicated in an entry by the General Purpose Flag bit 3 being set.

> If bit 3 (0x08) of the general-purpose flags field is set, then the CRC-32 and file sizes are not known when the header is written. The fields in the local header are filled with zero, and the CRC-32 and size are appended in a 12-byte structure (optionally preceded by a 4-byte signature) immediately after the compressed data.

If `Zip::InputStream` finds such an entry in the zip archive it will raise an exception (`Zip::StreamingError`).

`Zip::InputStream` is not designed to be used for random access in a zip file. When performing any operations on an entry that you are accessing via `Zip::InputStream#get_next_entry` then you should complete any such operations before the next call to `get_next_entry`.

```ruby
Zip::InputStream.open('file.zip') do |zip_stream|
  while entry = zip_stream.get_next_entry
    # All required operations on `entry` go here.
  end
end # The `InputStream` is closed at the end of the block.
```

Any attempt to move about in a zip file opened with `Zip::InputStream` could result in the incorrect entry being accessed and/or Zlib buffer errors. If you need random access in a zip file, use `Zip::File`.

### Password Protection (experimental)

Rubyzip supports reading zip files with AES encryption (version 3.1 and later), and reading and writing zip files with traditional zip encryption (a.k.a. "ZipCrypto"). Encryption is currently only available with the stream API, with either files or buffers, e.g.:

#### Version 2.x (ZipCrypto only)

```ruby
# Writing.
enc = Zip::TraditionalEncrypter.new('password')
buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), enc) do |output|
  output.put_next_entry("my_file.txt")
  output.write my_data
end

# Reading.
dec = Zip::TraditionalDecrypter.new('password')
Zip::InputStream.open(buffer, 0, dec) do |input|
  entry = input.get_next_entry
  puts "Contents of '#{entry.name}':"
  puts input.read
end
```

#### Version 3.x (AES reading and ZipCrypto read/write)

```ruby
# Reading AES, version 3.1 and later.
dec = Zip::AESDecrypter.new('password', Zip::AESEncryption::STRENGTH_256_BIT)
Zip::InputStream.open('aes-encrypted-file.zip', decrypter: dec) do |input|
  entry = input.get_next_entry
  puts "Contents of '#{entry.name}':"
  puts input.read
end

# Writing.
enc = Zip::TraditionalEncrypter.new('password')
buffer = Zip::OutputStream.write_buffer(encrypter: enc) do |output|
  output.put_next_entry("my_file.txt")
  output.write my_data
end

# Reading.
dec = Zip::TraditionalDecrypter.new('password')
Zip::InputStream.open(buffer, decrypter: dec) do |input|
  entry = input.get_next_entry
  puts "Contents of '#{entry.name}':"
  puts input.read
end
```

_This is an evolving feature and the interface for encryption may change in future versions._

## Known issues

### Modify docx file with rubyzip

Use `write_buffer` instead `open`. Thanks to @jondruse

```ruby
buffer = Zip::OutputStream.write_buffer do |out|
  @zip_file.entries.each do |e|
    unless [DOCUMENT_FILE_PATH, RELS_FILE_PATH].include?(e.name)
      out.put_next_entry(e.name)
      out.write e.get_input_stream.read
    end
  end

  out.put_next_entry(DOCUMENT_FILE_PATH)
  out.write xml_doc.to_xml(:indent => 0).gsub("\n","")

  out.put_next_entry(RELS_FILE_PATH)
  out.write rels.to_xml(:indent => 0).gsub("\n","")
end

File.open(new_path, "wb") {|f| f.write(buffer.string) }
```

## Configuration

### Existing Files

By default, rubyzip will not overwrite files if they already exist inside of the extracted path. To change this behavior, you may specify a configuration option like so:

```ruby
Zip.on_exists_proc = true
```

If you're using rubyzip with rails, consider placing this snippet of code in an initializer file such as `config/initializers/rubyzip.rb`

Additionally, if you want to configure rubyzip to overwrite existing files while creating a .zip file, you can do so with the following:

```ruby
Zip.continue_on_exists_proc = true
```

### Non-ASCII Names

If you want to store non-english names and want to open them on Windows(pre 7) you need to set this option:

```ruby
Zip.unicode_names = true
```

Sometimes file names inside zip contain non-ASCII characters. If you can assume which encoding was used for such names and want to be able to find such entries using `find_entry` then you can force assumed encoding like so:

```ruby
Zip.force_entry_names_encoding = 'UTF-8'
```

Allowed encoding names are the same as accepted by `String#force_encoding`

### Date Validation

Some zip files might have an invalid date format, which will raise a warning. You can hide this warning with the following setting:

```ruby
Zip.warn_invalid_date = false
```

### Size Validation

By default (in rubyzip >= 2.0), rubyzip's `extract` method checks that an entry's reported uncompressed size is not (significantly) smaller than its actual size. This is to help you protect your application against [zip bombs](https://en.wikipedia.org/wiki/Zip_bomb). Before `extract`ing an entry, you should check that its size is in the range you expect. For example, if your application supports processing up to 100 files at once, each up to 10MiB, your zip extraction code might look like:

```ruby
MAX_FILE_SIZE = 10 * 1024**2 # 10MiB
MAX_FILES = 100
Zip::File.open('foo.zip') do |zip_file|
  num_files = 0
  zip_file.each do |entry|
    num_files += 1 if entry.file?
    raise 'Too many extracted files' if num_files > MAX_FILES
    raise 'File too large when extracted' if entry.size > MAX_FILE_SIZE
    entry.extract
  end
end
```

If you need to extract zip files that report incorrect uncompressed sizes and you really trust them not too be too large, you can disable this setting with
```ruby
Zip.validate_entry_sizes = false
```

Note that if you use the lower level `Zip::InputStream` interface, `rubyzip` does *not* check the entry `size`s. In this case, the caller is responsible for making sure it does not read more data than expected from the input stream.

### Compression level

When adding entries to a zip archive you can set the compression level to trade-off compressed size against compression speed. By default this is set to the same as the underlying Zlib library's default (`Zlib::DEFAULT_COMPRESSION`), which is somewhere in the middle.

You can configure the default compression level with:

```ruby
Zip.default_compression = X
```

Where X is an integer between 0 and 9, inclusive. If this option is set to 0 (`Zlib::NO_COMPRESSION`) then entries will be stored in the zip archive uncompressed. A value of 1 (`Zlib::BEST_SPEED`) gives the fastest compression and 9 (`Zlib::BEST_COMPRESSION`) gives the smallest compressed file size.

This can also be set for each archive as an option to `Zip::File`:

```ruby
Zip::File.open('foo.zip', create:true, compression_level: 9) do |zip|
  zip.add ...
end
```

### Zip64 Support

Since version 3.0, Zip64 support is enabled for writing by default. To disable it do this:

```ruby
Zip.write_zip64_support = false
```

Prior to version 3.0, Zip64 support is disabled for writing by default.

_NOTE_: If Zip64 write support is enabled then any extractor subsequently used may also require Zip64 support to read from the resultant archive.

### Block Form

You can set multiple settings at the same time by using a block:

```ruby
  Zip.setup do |c|
    c.on_exists_proc = true
    c.continue_on_exists_proc = true
    c.unicode_names = true
    c.default_compression = Zlib::BEST_COMPRESSION
  end
```

## Compatibility

Rubyzip is known to run on a number of platforms and under a number of different Ruby versions.

### Version 2.4.x

Rubyzip 2.4 is known to work on MRI 2.4 to 3.4 on Linux and Mac, and JRuby and Truffleruby on Linux. There are known issues with Windows which have been fixed on the development branch. Please [let us know](https://github.com/rubyzip/rubyzip/pulls) if you know Rubyzip 2.4 works on a platform/Ruby combination not listed here, or [raise an issue](https://github.com/rubyzip/rubyzip/issues) if you see a failure where we think it should work.

### Version 3.x

Please see the table below for what we think the current situation is. Note: an empty cell means "unknown", not "does not work".

| OS/Ruby | 3.0 | 3.1 | 3.2 | 3.3 | 3.4 | Head | JRuby 10.0.1.0 | JRuby Head | Truffleruby 24.2.1 | Truffleruby Head |
|---------|-----|-----|-----|-----|-----|------|---------------|------------|--------------------|------------------|
|Ubuntu 24.04| CI | CI | CI | CI | CI | ci | CI | ci | CI | ci |
|Mac OS 14.7.6| CI | CI | CI | CI | CI | ci | x |  | x |  |
|Windows Server 2022| CI |  |  |  | CI&nbsp;mswin</br>CI&nbsp;ucrt |  |  |  |  |  |

Key: `CI` - tested in CI, should work; `ci` - tested in CI, might fail; `x` - known working; `o` - known failing.

Rubies 3.1+ are also tested separately with YJIT turned on (Ubuntu and Mac OS).

See [the Actions tab](https://github.com/rubyzip/rubyzip/actions) in GitHub for full details.

Please [raise a PR](https://github.com/rubyzip/rubyzip/pulls) if you know Rubyzip works on a platform/Ruby combination not listed here, or [raise an issue](https://github.com/rubyzip/rubyzip/issues) if you see a failure where we think it should work.

## Developing

Install the dependencies:

```shell
bundle install
```

Run the tests with `rake`:

```shell
rake
```

Please also run `rubocop` over your changes.

Our CI runs on [GitHub Actions](https://github.com/rubyzip/rubyzip/actions). Please note that `rubocop` is run as part of the CI configuration and will fail a build if errors are found.

## Website and Project Home

http://github.com/rubyzip/rubyzip

http://rdoc.info/github/rubyzip/rubyzip/master/frames

## Authors

See https://github.com/rubyzip/rubyzip/graphs/contributors for a comprehensive list.

### Current maintainers

* Robert Haines (@hainesr)
* John Lees-Miller (@jdleesmiller)
* Oleksandr Simonov (@simonoff)

### Original author

* Thomas Sondergaard

## License

Rubyzip is distributed under the same license as Ruby. In practice this means you can use it under the terms of the Ruby License or the 2-Clause BSD License. See https://www.ruby-lang.org/en/about/license.txt and LICENSE.md for details.
