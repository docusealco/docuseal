# Marcel

Marcel chooses the most appropriate content type for a file by inspecting its contents, the declared MIME type (perhaps passed as a Content-Type header), and the file extension.

Marcel checks, in order:

1. The "magic bytes" sniffed from the file contents.
2. The declared type, typically provided in a Content-Type header on an uploaded file, unless it's the `application/octet-stream` default.
3. The filename extension.
4. Safe fallback to the indeterminate `application/octet-stream` default.

At each step, the most specific MIME subtype is selected. This allows the declared type and file extension to refine the parent type sniffed from the file contents, but not conflict with it. For example, if "file.csv" has declared type `text/plain`, `text/csv` is returned since it's a more specific subtype of `text/plain`. Similarly, Adobe Illustrator files are PDFs internally, so magic byte sniffing indicates `application/pdf` which is refined to `application/illustrator` by the `ai` file extension. But a PDF named "image.png" will still be detected as `application/pdf` since `image/png` is not a subtype.

## Usage

```ruby
# Magic bytes sniffing alone
Marcel::MimeType.for Pathname.new("example.gif")
#  => "image/gif"

File.open "example.gif" do |file|
  Marcel::MimeType.for file
end
#  => "image/gif"

# Magic bytes with filename fallback
Marcel::MimeType.for Pathname.new("unrecognisable-data"), name: "example.pdf"
#  => "application/pdf"

# File extension alone
Marcel::MimeType.for extension: ".pdf"
#  => "application/pdf"

# Magic bytes, declared type, and filename together
Marcel::MimeType.for Pathname.new("unrecognisable-data"), name: "example", declared_type: "image/png"
#  => "image/png"

# Safe fallback to application/octet-stream
Marcel::MimeType.for StringIO.new(File.read "unrecognisable-data")
#  => "application/octet-stream"
```

## Extending

Custom file types may be added with `Marcel::MimeType.extend`:

```ruby
Marcel::MimeType.extend "text/custom", extensions: %w( customtxt )
Marcel::MimeType.for name: "file.customtxt"
#  => "text/custom"
```

## Motivation

Marcel was extracted from Basecamp's file detection heuristics. The aim is provide sensible, safe, "do what I expect" results for typical file handling. Test fixtures have been added for many common file types, including those typically encountered by Basecamp.


## Contributing

Marcel generates MIME lookup tables with `bundle exec rake update`. MIME types are seeded from data found in `data/*.xml`. Custom MIMEs may be added to `data/custom.xml`, while overrides to the standard MIME database may be added to `lib/marcel/mime_type/definitions.rb`.

Marcel follows the same contributing guidelines as [rails/rails](https://github.com/rails/rails#contributing).


## Testing

The main test fixture files are split into two folders, those that can be recognised by magic bytes, and those that can only be recognised by name. Even though strictly unnecessary, the fixtures in both folders should all be valid files of the type they represent.


## License

Marcel itself is released under the terms of the MIT License. See the MIT-LICENSE file for details.

Portions of Marcel are adapted from the [mimemagic] gem, released under the terms of the MIT License.

Marcel's magic signature data is adapted from [Apache Tika](https://tika.apache.org), released under the terms of the Apache License. See the APACHE-LICENSE file for details.

[mimemagic]: https://github.com/mimemagicrb/mimemagic
