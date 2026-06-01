# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby

HexaPDF is a pure Ruby library with an accompanying application for working with PDF files. It was
designed with ease of use and performance in mind. It uses lazy loading and lazy computing when
possible and tries to produce small PDF files by default.

In short, it allows

* **creating** new PDF files,
* **manipulating** existing PDF files,
* **merging** multiple PDF files into one,
* **extracting** meta information, text, images and files from PDF files,
* **securing** PDF files by encrypting or signing them and
* **optimizing** PDF files for smaller file size or other criteria.

HexaPDF is available under two licenses, the AGPL and a commercial license, see the [License
section](#License) for details.


## Features

* Pure Ruby
* Minimal dependencies ('cmdparse' for `hexapdf` binary, 'geom2d' for document layout)
* Easy to use, Ruby-esque API
* Fully tested with 100% code coverage
* Low-level API with high-level convenience interface on top
* Complete [canvas API] which directly maps to PDF internal operators
* Path drawing operations like lines, polylines, rectangles, bézier curves, arcs, ...
* Embedding images in JPEG (lossy), PNG (lossless) and PDF (vector) format with support for
  transparency
* UTF-8 text via TrueType fonts and support for font subsetting
* High-level [document composition engine] with automatic content layout
  * [Flowing text] around other content
  * Pre-define [styles] and assign to multiple content boxes
  * Automatic page breaks
  * [(Un)ordered lists]
  * [Multi-column layout]
* [PDF forms] (AcroForm) with Adobe Reader like appearance generation
* Annotations
* [Document outline]
* [Attaching files] to the whole PDF or individual pages, extracting files
* Image extraction
* [Encryption] including PDF 2.0 features (e.g. AES256)
* [Digital signatures]
* [File size optimization]
* PDF object validation
* [`hexapdf` binary][hp] for most common PDF manipulation tasks


[canvas API]: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Content/Canvas.html
[document composition engine]: https://hexapdf.gettalong.org/documentation/document-creation/document-layout.html
[flowing text]: https://hexapdf.gettalong.org/examples/frame_text_flow.html
[styles]: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Layout/Style/index.html
[(un)ordered lists]: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Layout/ListBox.html
[multi-column layout]: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Layout/ColumnBox.html
[PDF forms]: https://hexapdf.gettalong.org/documentation/interactive-forms/index.html
[Document outline]: https://hexapdf.gettalong.org/documentation/outline/index.html
[attaching files]: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Document/Files.html
[Encryption]: https://hexapdf.gettalong.org/documentation/encryption/index.html
[Digital Signatures]: https://hexapdf.gettalong.org/documentation/digital-signatures/index.html
[File size optimization]: https://hexapdf.gettalong.org/documentation/benchmarks/optimization.html
[hp]: https://hexapdf.gettalong.org/documentation/hexapdf.1.html


## Usage

The HexaPDF distribution provides the library as well as the `hexapdf` application. The application
can be used to perform common tasks like merging PDF files, decrypting or encrypting PDF files and
so on.

When HexaPDF is used as a library, it can be used to do all the task that the command line
application does and much more. Here is a "Hello World" example that shows how to create a simple
PDF file:

~~~ ruby
require 'hexapdf'

doc = HexaPDF::Document.new
canvas = doc.pages.add.canvas
canvas.font('Helvetica', size: 100)
canvas.text("Hello World!", at: [20, 400])
doc.write("hello-world.pdf")
~~~

For detailed information have a look at the [HexaPDF website][website] where you will find the API
documentation, example code and more.

It is recommend to use the HTML API documentation provided by the HexaPDF website as it is enhanced
with example graphics and PDF files and tightly integrated into the rest of the website.

[website]: https://hexapdf.gettalong.org


## Requirements and Installation

Since HexaPDF is written in Ruby, a working Ruby installation is needed - see the [official
installation documentation][rbinstall] for details. Note that you need Ruby version 3.0 or higher as
prior versions are not supported!

HexaPDF works on all Ruby implementations that are CRuby compatible and on any platform supported by
Ruby (Linux, macOS, Windows, ...). Implementations like JRuby and TruffleRuby should work but
HexaPDF is not actively tested against them.

Apart from Ruby itself the HexaPDF library has only one external dependency `geom2d` which is
written and provided by the HexaPDF authors. The `hexapdf` application has an additional dependency
on `cmdparse`, a command line parsing library.

HexaPDF itself is distributed via Rubygems and therefore easily installable via `gem install
hexapdf`.

[rbinstall]: https://www.ruby-lang.org/en/documentation/installation/


## Difference to Prawn

The main difference between HexaPDF and [Prawn] is that HexaPDF is a **full PDF library** whereas
Prawn is a **library for generating content**.

To be more specific, it is easily possible to read an existing PDF with HexaPDF and modify parts of
it before writing it out again. The modifications can be to the PDF object structure like removing
superfluous annotations or the content itself.

Prawn has no such functionality. There is basic support for using a PDF as a template using the
`pdf-reader` and `prawn-template` gems but support is very limited. However, Prawn has a very
featureful API when it comes to creating content, for individual pages as well as across pages.

If you want to migrate from Prawn to HexaPDF, there is the [migration guide] with detailed
information and examples, comparing the Prawn API to HexaPDF's equivalents.

[migration guide]: https://hexapdf.gettalong.org/documentation/document-creation/migrating-from-prawn.html

Why use HexaPDF?

* It has many more [features](#features) beside content creation that might come in handy (e.g. PDF
  form creation, encryption, digital signatures, ...).

* The architecture of HexaPDF is based on the object model of the PDF standard. This makes extending
  HexaPDF very easy and allows for **reading PDF files for templating purposes**.

* HexaPDF provides a high level API for **composing a document of individual elements** that are
  automatically layouted. Such elements can be headers, paragraphs, code blocks, ... or links,
  emphasized text and so on. These elements can be customized and additional element types easily
  added.

* In addition to being usable as a library, HexaPDF also comes with a command line tool for
  manipulating PDFs. This tool is intended to be a replacement for tools like `pdftk` and the
  various Poppler-based tools like `pdfinfo`, `pdfimages`, ...

[Prawn]: https://prawnpdf.org
[page canvas API]: https://hexapdf.gettalong.org/api/HexaPDF/Content/Canvas.html


## Development

Clone the repository and then run `rake dev:setup`. This will install the needed Rubygem
dependencies as well as make sure that all applications needed for the tests are available.


## License

AGPL - see the LICENSE file for licensing details. Commercial licenses are available at
<https://gettalong.at/hexapdf/>.

A commercial license is needed as soon as HexaPDF is distributed with your software or remotely
accessed via a network and you don't provide the source code of your application under the AGPL. For
example, if you serve PDFs on the fly in a web application.

Contact <sales@gettalong.at> for more information!

Some included files have a different license:

* For the license of the included AFM files in the `data/hexapdf/afm` directory, see the file
  `data/hexapdf/afm/MustRead.html`.

* The files `test/data/encoding/{glyphlist.txt,zapfdingbats.txt}` are licensed under the Apache
  License V2.0.

* The file `test/data/fonts/Ubuntu-Title.ttf` is licensed under the SIL Open Font License.

* The AES test vector files in `test/data/aes-test-vectors` have been created using the test vector
  file available from <http://csrc.nist.gov/groups/STM/cavp/block-ciphers.html#test-vectors>.

* The license of the file `data/hexapdf/sRGB2014.icc` is available in the
  `data/hexapdf/sRGB2014.icc.LICENSE` file.


## Contributing

See <https://hexapdf.gettalong.org/contributing.html> for more information.


## Author

Thomas Leitner, <https://gettalong.org>
