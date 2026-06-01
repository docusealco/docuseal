## 1.7.0 - 2026-04-13

### Added

* Smart text extraction for retrieving layouted text from pages
* Support for digitally signing with ECDSA keys
* Support for digitally signing with DSA keys
* Support for BrotliDecode filter
* [HexaPDF::Type::DocumentSecurityStore] and
  [HexaPDF::Type::ValidationRelatedInformation]

### Changed

* **Breaking change**: [HexaPDF::Document#unwrap] to not unwrap streams
* Automatic detection of digital signature size to account for small deviations
* [HexaPDF::Type::AcroForm::Form#fill] to ignore password fields
* [HexaPDF::Type::AcroForm::TextField] validation to convert invalid Symbol
  values to String
* [HexaPDF::Type::Annotations::Widget] validation to also validate a widget as a
  field if necessary
* PDF/A task to include a fix for mismatching glyph widths for Type 2 CID fonts

### Fixed

* Writing of PDF documents with an invalid value for the /Info dictionary
* Subsetting of TrueType fonts in case compound glyphs are themselves compound


## 1.6.0 - 2026-02-10

### Added

* CLI command `hexapdf debug-info` for creating debugging information,
  especially for malformed files

### Changed

* Optimized decoding character codes with a CMap to drastically lower memory
  usage
* CLI command `hexapdf inspect rev` to show whether the cross-reference table
  was reconstructed

### Fixed

* Path generation for image extraction in CLI command `hexapdf images`
* Handling of certain invalid PDFs where the generation number for object
  identifiers don't match their cross-reference section value
* AES 256bit encryption to include unnecessary field /Length in encryption
  dictionary to work around buggy PDF libraries
* Parsing of invalid /Filter and /DecodeParms stream keys in case they resolve
  to a recursive structure
* [HexaPDF::Type::AcroForm::Field#each_widget] to only yield widget objects


## 1.5.0 - 2025-12-08

### Added

* Support for basic authentication to
  [HexaPDF::DigitalSignature::Signing::TimestampHandler]

### Changed

* Dictionary validation to delete field entries that have an invalid type
* CLI command `hexapdf images` to create directories specified in the `--prefix`
* CLI command `hexapdf images` to omit the dash in the file names if `--prefix`
  points to a directory

## Fixed

* [HexaPDF::Type::Annotation#appearance] to work in case /AP contains a value of
  an invalid type
* [HexaPDF::DigitalSignature::CMSHandler] to throw an appropriate error when
  encountering invalid signature contents


## 1.4.1 - 2025-09-23

### Added

* [HexaPDF::Font::Encoding::Base#to_compact_array] for creating a compact array
  representation of the encoding

### Changed

- CLI to handle missing file errors better

### Fixed

* Serialization of strings that need to be UTF-16 encoded when using encryption
* [HexaPDF::Document#write_to_string] to pass on arguments to `#write`
* [HexaPDF::Type::FontType1] validation to handle PDFs with an invalid value of
  /SymbolEncoding for the /Encoding key
* [HexaPDF::Type::FontType1] validation to handle PDFs with an invalid value of
  /StandardEncoding for the /Encoding key
* CLI command `hexapdf form` to ignore widgets that don't belong to any field
* Validation of invalid sorted tree root nodes with odd number of direct entries


## 1.4.0 - 2025-08-03

### Added

* [HexaPDF::Type::Annotations::Polygon] for polygon annotations as well as
  [HexaPDF::Document::Annotations#create_polygon]
* [HexaPDF::Type::Annotations::Polyline] for polyline annotations as well as
  [HexaPDF::Document::Annotations#create_polyline]
* [HexaPDF::Layout::ContainerBox#splitable] for specifying whether the container
  box may be split
* [HexaPDF::Layout::Style::Layers#layers] for retrieving the list of defined
  layers
* [HexaPDF::Document::Layout#resolve_font] for resolving the font style property
* [HexaPDF::Type::Measure] for representing the measure dictionary
* [HexaPDF::Layout::Box::FitResult#failure!] for setting the result status to
  failure

### Changed

* **Breaking change**: Extracted `#line_ending_style` and associated data class
  from [HexaPDF::Type::Annotations::Line] into
  [HexaPDF::Type::Annotations::LineEndingStyling]
* [HexaPDF::Layout::TableBox] implementation to allow setting the minimum height
  of a table cell
* [HexaPDF::Layout::Style::Quad#set] to allow setting a subset of values using a
  hash
* CLI command `hexapdf form` to show the names of radio button widgets
* CLI command `hexapdf form` to show position and size of widgets in easier to
  understand form
* Default signing handler to not set /DigestMethod entry on signature reference
  dictionary anymore

### Fixed

* Parsing and writing the /ModDate and /CreationDate trailer info fields in case
  of string values when using the XMP metadata handler
* [HexaPDF::Layout::Style] to not accidentally set subscript or superscript
  values
* [HexaPDF::DictionaryFields::DateConverter] to handle invalid dates with two
  trailing apostrophes
* [HexaPDF::Document::Layout::CellArgumentCollector#retrieve_arguments_for] to
  not change the stored data
* Encryption when using AES with 256bits and an owner password


## 1.3.0 - 2025-04-23

### Added

* [HexaPDF::Type::Annotations::Square] for rectangle annotations as well as
  [HexaPDF::Document::Annotations#create_rectangle]
* [HexaPDF::Type::Annotations::Circle] for ellipse annotations as well as
  [HexaPDF::Document::Annotations#create_ellipse]
* Basic appearance generation for push button fields
* [HexaPDF::Type::Annotation::BorderEffect] type class
* [HexaPDF::Type::Annotations::BorderEffect] module that provides convenience
  access to the border effect dictionary
* [HexaPDF::Document::Layout#style?] and [HexaPDF::Composer#style?] for checking
  whether a given style (name) exists
* [HexaPDF::Layout::Style#each_property] for iterating over all set properties
* [HexaPDF::Layout::Style#merge] for merging another style instance
* [HexaPDF::Layout::Style#box_options] for specifying box initialization options
* [HexaPDF::Layout::Style#font_bold] and [HexaPDF::Layout::Style#font_italic]
  for setting bold and/or italic variants independently of the font name
* [HexaPDF::PDFArray#map!] for mapping elements in-place
* [HexaPDF::PDFArray#compact!] for removing `nil` elements

### Changed

* **Breaking change**: [HexaPDF::Type::Annotations::Widget::MarkerStyle::new]
  got a new positional argument
* [HexaPDF::Type::Annotations::Widget#marker_style] to allow setting and
  retrieving the font for push buttons
* Extracted `#interior_color` from [HexaPDF::Type::Annotations::Line] into
  [HexaPDF::Type::Annotations::InteriorColor]
* CLI command `hexapdf inspect` to support decoding Form XObject streams
* [HexaPDF::Layout::Style#line_spacing] to accept a `LineSpacing` object when
  setting the value

### Fixed

* Text extraction with macOS Preview due a bug in Preview
* [HexaPDF::PDFArray#reject!] to work according to documented method signature
* [HexaPDF::Type::AcroForm::Field#create_widget] to ensure the proper type
  class is stored in the document in case an embedded widget is extracted
* [HexaPDF::Type::AcroForm::Form] validation to ensure that all field objects in
  the field hierarchy are using a field type class
* [HexaPDF::Type::AcroForm::Form] validation to delete merged fields


## 1.2.0 - 2025-02-10

### Added

* **Breaking change**: Argument `compact` to [HexaPDF::Document#write] to
  automatically run the 'compact' optimization task
* [HexaPDF::Document::Annotations], accessible via
  [HexaPDF::Document#annotations], as convenience interface for working with
  annotations
* [HexaPDF::Type::Annotations::AppearanceGenerator] as central class for
  generating appearance streams
* [HexaPDF::Type::Annotations::Line] for line annotations
* [HexaPDF::Type::Annotation#opacity] for setting the opacity values when
  regenerating the appearance stream
* [HexaPDF::Type::Annotation#contents] for setting the text of the annotation
* Configuration option 'acro_form.text_field.on_max_len_exceeded' to allow
  custom handling of too long values

### Changed

* **Breaking change**: Extracted `#border_style` and associated data class from
  [HexaPDF::Type::Annotations::Widget] into
  [HexaPDF::Type::Annotations::BorderStyling]
* [HexaPDF::Type::Form#canvas] to allow getting the canvas without the initial
  translation

### Fixed

* AcroForm Javascript actions to gracefully handle the special values infinity
  and NaN
* Type1 and TrueType font wrappers to handle the case where fonts are first
  added and later deleted


## 1.1.1 - 2025-01-08

### Fixed

* Missing require statements leading to problems loading type classes


## 1.1.0 - 2025-01-08

### Added

* Basic type classes for logical structure support

### Changed

* Optimized output of simple borders to avoid unnecessary drawing operations

### Fixed

* Type of field /DW for CIDFont which used to be Integer in PDF 1.7 but now is
  Numeric inf 2.0
* Validation of /ProcSet entry in resources dictionary to correctly handle the
  case of /ProcSet having a Symbol value


## 1.0.3 - 2024-12-04

### Fixed

* Offsets and lengths of revisions shown using the `inspect rev` CLI command for
  linearized PDF files
* [HexaPDF::Type::AcroForm::Form#recalculate_fields] to only consider real
  fields


## 1.0.2 - 2024-11-05

### Added

* [HexaPDF::Type::CMap] for representing CMap streams

### Fixed

* Checksum calculation for TrueType tables
* Automatic wrapping of dictionary entry /CIDToGIDMap for CID fonts
* Performance regression when encoding char codes for TrueType fonts
* PDF/A validation regression for PDFs using TrueType fonts


## 1.0.1 - 2024-11-04

### Changed

* Informational output on errors when running CLI commands to provide more
  details

### Fixed

* Parsing of indirect objects the value of which is an indirect reference
* Writing of the initial cross-reference section to ensure a single subsection
* [HexaPDF::Utils::SortedTreeNode] to wrap all /Kids entries with the correct
  type class


## 1.0.0 - 2024-10-26

### Added

* [HexaPDF::Task::MergeAcroForm] for merging AcroForm information for imported
  pages
* [HexaPDF::Document#write_to_string] and [HexaPDF::Composer#write_to_string]
  for easily writing a document to a String
* [HexaPDF::Font::CMap::Writer#create_cid_cmap] for creating a character code to
  CID CMap file

### Changed

* [HexaPDF::Type::AcroForm::Form] text-like field creation methods to always set
  a default appearance string and the quadding
* Convenience methods for accessing resources to not add the deprecated /ProcSet
  entry by default
* [HexaPDF::DigitalSignature::CMSHandler] to add informational output regarding
  the certificate chain on verification
* Validation of [HexaPDF::Type::FontType1] to ensure correct /Encoding value

### Fixed

* [HexaPDF::DigitalSignature::Signature#signed_data] to work for invalid offsets
* [HexaPDF::DigitalSignature::Signing::DefaultHandler] to update the document's
  version to 2.0 when using PAdES
* Parsing of invalid `)` character in PDF objects and content streams
* Handling of files that contain stream length values that are indirect objects
  that do not exist
* [HexaPDF::Font::TrueTypeWrapper] to correctly handle the situation when
  multiple codepoints refer to the same glyph ID
* [HexaPDF::Type::Page#contents] to handle null values in /Contents array


## 0.47.0 - 2024-09-07

### Added

* Configuration option 'acro_form.fallback_default_appearance' to allow setting
  a standard default appearance string for a variable text field if none is
  found
* Support for decrypting files with the proprietary algorithm /R 5

### Changed

* [HexaPDF::Task::Optimize] to not remove optional /Type entries containing
  default values
* Validation of [HexaPDF::Type::AcroForm::Form] to not add a /DA entry

### Fixed

* [HexaPDF::Layout::TableBox] to correctly calculcate and distribute row
  heights when row spans are involved
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to work for files where check
  boxes don't define the name of the on state
* [HexaPDF::Importer#import] to handle null values in all cases
* [HexaPDF::Type::AcroForm::VariableTextField] to handle parsing of invalid PDFs
  with symbolic appearance strings
* [HexaPDF::Type::Annotations::Widget#marker_style] to handle invalid /DA values
  with missing font size or color information
* [HexaPDF::Type::AcroForm::SignatureField#field_value] to always return a
  correctly wrapped object
* [HexaPDF::Writer] to remove /Type entry from trailer
* [HexaPDF::Type::AcroForm::AppearanceGenerator#create_text_appearances] to
  handle invalid appearance streams that are not correct Form XObjects


## 0.46.0 - 2024-08-11

### Added

* [HexaPDF::DigitalSignature::CMSHandler#embedded_tsa_signature] to return the
  embedded timestamp authority signature if any
* [HexaPDF::DigitalSignature::Signing::DefaultHandler#signing_time] for setting
  a custom signing time
* [HexaPDF::Document#duplicate] for making an in-memory copy of a PDF document
* Configuration option 'font.default' for setting the default font for the
  document layout engine

### Changed

* [HexaPDF::Document::Layout::CellArgumentCollector#[]=] to allow stepped ranges
* [HexaPDF::Document::Layout::ChildrenCollector] to also return the box when
  creating and adding one to the list
* [HexaPDF::Layout::InlineBox] to allow usage without predefined width
* [HexaPDF::DigitalSignature::CMSHandler#verify] to recognize non-repudiation
  signatures
* [HexaPDF::DigitalSignature::CMSHandler#signing_time] to use time from an
  embedded timestamp authority signature if possible
* HexaPDF::Layout::Box#fit to return success for boxes with content
  width/height of zero
* [HexaPDF::Importer::copy] to optionally allow copying the catalog and page
  tree nodes

### Fixed

* Setting of correct x-position in fit result for boxes with flow positioning
* HexaPDF::Layout::ListBox#fit to respect the set height
* CLI command `hexapdf inspect` to work in case of missing Unicde mappings
* [HexaPDF::Type::AcroForm::Form#delete_field] to correctly work for fields with
  an embedded widget
* Parsing of "linearized" PDF files where the first cross-reference section
  isn't actually used
* [HexaPDF::Layout::PageStyle#create_page] to return new frame objects on each
  invocation


## 0.45.0 - 2024-06-18

### Added

* [HexaPDF::Document::Layout#styles] and [HexaPDF::Composer#styles] for defining
  multiple styles at once

### Changed

* HexaPDF::Layout::Box#fit to set width/height correctly for boxes with
  position `:flow`

### Fixed

* Regression in [HexaPDF::Layout::ListBox] that leads to missing markers
* [HexaPDF::Content::CanvasComposer#draw_box] to handle truncated boxes
* [HexaPDF::Layout::TableBox::Cell] to handle too-big content in all cases


## 0.44.0 - 2024-06-05

### Added

* Support for specifying the MIME type when embedding files
* Support for adding custom XMP metadata

### Changed

* **Breaking change**: Refactored the box implementation of the document layout
  system

### Fixed

* Parsing of invalid files with garbage bytes at the end


## 0.43.0 - 2024-05-26

### Added

* [HexaPDF::Type::AcroForm::Form#create_namespace_field] for creating a pure
  namespace field
* [HexaPDF::Type::AcroForm::Form#delete_field] for deleting fields

### Changed

* Minimum Ruby version to be 3.0
* **Breaking change**: Renamed `HexaPDF::Layout::BoxFitter#fit_successful?` to
  [HexaPDF::Layout::BoxFitter#success?]
* **Breaking Change**: Removed HexaPDF::Dictionary#to_h
* Form field creation methods of [HexaPDF::Type::AcroForm::Form] to
  automatically create parent fields as namespace fields

### Fixed

* HexaPDF::Layout::TextBox#fit to correctly calculate width in case of flowing
  text around other boxes
* HexaPDF::Layout::TextBox#draw to correctly draw border, background... on
  boxes using position 'flow'
* Comparison of Hash with [HexaPDF::Dictionary] objects by implementing
  `#to_hash`
* Parsing of invalid files having multiple end-of-file markers with the last one
  being invalid


## 0.42.0 - 2024-05-12

### Added

* Support for the `AFPercent_Format` JavaScript method
* Support for the `AFTime_Format` JavaScript method
* [HexaPDF::Type::AcroForm::Form#fill] for easily filling out form fields
* CLI command `hexapdf usage` for showing space usage information
* Support for attaching files via `hexapdf files` CLI command
* Refinement on [HexaPDF::Utils] to support conversion of Numeric values to
  points (e.g. `5.mm`, `5.cm`, `5.inch`)

### Changed

* [HexaPDF::Type::AcroForm::ButtonField#field_value=] to always allow using
  `true` for check boxes
* CLI commands to prompt whether an existing output file should be overwritten

### Fixed

* [HexaPDF::Type::Resources#font] to always return a correctly wrapped font
  object
* [HexaPDF::Type::AcroForm::TextField#field_value=] to actually use the value
  returned by the call to the config option 'acro_form.on_invalid_value'


## 0.41.0 - 2024-05-05

### Added

* Font loader [HexaPDF::FontLoader::VariantFromName] to ease specifying font
  variants
* [HexaPDF::Type::AcroForm::JavaScriptActions] module to contain all JavaScript
  actions that HexaPDF can handle
* Support for the `AFSimple_Calculate` Javascript method
* Support for Simplified Field Notation for defining Javascript calculations
* Configuration option 'encryption.on_decryption_error' to allow custom
  decryption error handling
* CLI option `--fill-read-only-fields` to `hexapdf form` to specify whether
  filling in read only fields is allowed
* [HexaPDF::Type::AcroForm::Field#form_field] to getting the field irrespective
  of whether the object is already a field or a widget
* [HexaPDF::Type::AcroForm::TextField#set_format_action] for setting a
  JavaScript action that formats the field's value
* [HexaPDF::Type::AcroForm::TextField#set_calculate_action] for setting a
  JavaScript action that calculates the field's value
* [HexaPDF::Type::AcroForm::Form#recalculate_fields] for recalculating fields

### Changed

* CLI command `hexapdf form` to show more information in verbose mode
* CLI command 'hexapdf form' to show the field flags "read only" and "required"
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to remove the hidden flag from
  widgets

### Fixed

* [HexaPDF::FontLoader::FromConfiguration] to accept arbitrary keyword arguments
* [HexaPDF::Font::CMap::Parser] to avoid instantiating invalid UTF-16BE chars
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to work for files where check
  boxes don't have appearance subdictionaries
* [HexaPDF::Type::AcroForm::TextField#field_value=] to call the config option
  'acro_form.on_invalid_value' when passing a non-String argument (except `nil`)
* [HexaPDF::Type::AcroForm::JavaScriptActions#apply_af_number_format] to
  correctly convert strings using commas or points into numbers
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to use the field instead of the
  widget object as the source for JavaScript format actions
* CLI command `hexapdf form --generate-template` to output fields without values
* `AFNumber_Format` JavaScript parsing to work without trailing semicolon


## 0.40.0 - 2024-03-23

### Changed

* **Breaking change**: Style property 'text_overflow' is now called 'overflow'

### Fixed

* [HexaPDF::Layout::ListBox] to hide marker in case of splitting list items with
  multiple boxes
* [HexaPDF::Layout::ListBox] to create independent marker boxes for all markers
* [HexaPDF::Layout::ListBox] to correctly respect a set height


## 0.39.1 - 2024-03-20

### Fixed

* [HexaPDF::Layout::TableBox] to correctly split tables when a row span with a
  too high cell is involved


## 0.39.0 - 2024-03-18

### Added

* Hierarchical box information to the document layout engine
* Style property 'text_overflow' for controlling how overflowing text should be
  handled

### Changed

* HexaPDF::Layout::Frame::FitResult#draw to provide better optional content
  group names

### Fixed

* [HexaPDF::Layout::TextBox] to correctly respect a set height


## 0.38.0 - 2024-03-10

### Added

* [HexaPDF::Task::PDFA] for creating PDF/A conforming PDF files
* [HexaPDF::Type::OutputIntent] for defining output intents
* [HexaPDF::Document::Metadata#delete] for deleting metadata properties
* PDF/A metadata properties definitions
* Added a /Name entry to the default optional content configuration dictionary
  (needed by PDF/A)

### Changed

* Default language for XMP metadata from English to 'x-default'
* [HexaPDF::Layout::ListBox] to use the style's font for drawing markers and to
  fall back to Times and ZapfDingbats if necessary
* [HexaPDF::Document::Layout#table_box] to merge the `:cell` keys that define
  the cell style instead of using the last one
* [HexaPDF::Document::Layout] style retrieval to fall back to using the font of
  the `:base` style and only if that doesn't exist to 'Times'
* XMP metadata stream contents to satisfy more PDF/A validators


## 0.37.2 - 2024-02-27

### Fixed

* Type of /TransformParams field in signature reference dictionary
* [HexaPDF::Type::Page#box] to intersect the requested box with the media box
* Validation of [HexaPDF::Type::Annotation] to resolve PDF reference before
  access
* [HexaPDF::Type::Page#flatten_annotations] to work in case of duplicate
  annotations
* [HexaPDF::Type::AcroForm::Form#each_field] to gracefully handle null values
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to take an appearance string
  set on a widget instead of a field into account
* [HexaPDF::Type::AcroForm::ChoiceField] to take PDFs where the /Opt key is set
  on the widgets into account


## 0.37.1 - 2024-02-05

### Fixed

* Validation of annotation dictionaries having an empty appearance dictionary


## 0.37.0 - 2024-01-29

### Added

* [HexaPDF::Document::Metadata] for working with metadata (reading the info
  dictionary and writing it as well as the XMP metadata stream)

### Changed

* Minimum Ruby version to be 2.7

### Fixed

* [HexaPDF::FiberDoubleForString#length] to not assume a binary string


## 0.36.0 - 2024-01-20

### Added

* [HexaPDF::Layout::ContainerBox] for grouping child boxes together

### Changed

* HexaPDF::Layout::Frame::FitResult#draw to allow drawing at an offset
* HexaPDF::Layout::Box#fit to delegate the actual content fitting to the
  `#fit_content` method
* [HexaPDF::Document::Layout#box] to allow using the block as drawing block for
  the base box class

### Fixed

* [HexaPDF::Type::FontSimple#to_utf8] to work in case the font's encoding cannot
  be retrieved


## 0.35.1 - 2024-01-11

### Added

* [HexaPDF::Utils] module functions for float comparisons and using them instead
  of the geom2d ones

### Changed

* Pre-defined paper sizes of the ISO A, B and C series to be more precise

### Fixed

* [HexaPDF::Layout::Box#fit] to use float comparison
* [HexaPDF::Type::IconFit] to use correct superclass


## 0.35.0 - 2024-01-06

### Added

* Command 'psd' for CLI `hexapdf inspect` to show a decoded content stream
* Style property 'mask_mode' for more control over the region that gets removed
  from a frame after placing a box
* Style property 'valign' for vertically centering a box in a frame
* [HexaPDF::Content::Canvas#form] for creating reusable Form XObjects
* Method `#valid?` to all Glyph classes
* [HexaPDF::Font::InvalidGlyph#control_char?] for detecting invalid glyphs that
  represent a control character (like a newline)
* [HexaPDF::Font::Type1Wrapper#decode_codepoint] and
  [HexaPDF::Font::TrueTypeWrapper#decode_codepoint] for decoding a single
  Unicode codepoint into a glyph
* [HexaPDF::Layout::TextFragment::create_with_fallback_glyphs] for creating an
  array of text fragments with support for fallback glyphs
* Configuration option 'font.on_invalid_glyph' for use together with the new
  method for creating text fragments with fallback glyphs
* Configuration option 'font.fallback' which is used by the default
  implementation of 'font.on_invalid_glyph'
* [HexaPDF::Document::Layout#text_fragments] for creating text fragments with
  support for fallback glyphs via 'font.on_invalid_glyph'
* [HexaPDF::Content::CanvasComposer] for using high-level layout functionality
  on a single canvas
* [HexaPDF::Content::Canvas#composer] for easily creating a canvas composer
* [HexaPDF::Font::TrueTypeWrapper#bold?] and [HexaPDF::Font::Type1Wrapper#bold?]
  for determining whether a font is bold
* [HexaPDF::Font::TrueTypeWrapper#italic?] and
  [HexaPDF::Font::Type1Wrapper#italic?] for determining whether a font is italic
* [HexaPDF::Encryption::StandardSecurityHandler#decryption_password_type] for
  information on the type of password used for decryption

### Changed

* **Breaking change**: Style property 'align' is now called 'text_align' and
  'valign' is 'text_valign'
* **Breaking change**: Style property 'position' now takes the absolute position
  directly as value instead of in the 'position_hint' property
* **Breaking change**: Style property 'position_hint' is now called 'align'
* **Breaking change**: Glyph objects now take the font wrapper instead of the
  font on creation
* **Breaking change**: The item marker type of a [HexaPDF::Layout::ListBox] item
  is now set via `#marker_type` instead of `#item_type`
* [HexaPDF::Object#validate] to catch exceptions and provided an appropriate
  validation message

### Fixed

* HexaPDF::Layout::ColumnBox#fit to correctly take initial height into account
* HexaPDF::Layout::ColumnBox#fit to ensure correct results in case the
  requested dimensions are larger than the current region
* [HexaPDF::Document::Layout#formatted_text_box] to correctly handle properties
* [HexaPDF::Layout::Frame#fit] to raise an error if an invalid value for the
  style property 'position' is used
* Validation of PDF arrays and dictionaries by making sure only processed values
  are used


## 0.34.1 - 2023-11-01

### Added

* Setting of /SMask key in graphics state parameters operator

### Fixed

* [HexaPDF::Composer#page_style] to set a page style when no attributes are
  given but a block is
* [HexaPDF::Type::Page#each_annotation] and
  [HexaPDF::Type::Page#flatten_annotations] to process certain invalid /Annot
  keys without errors


## 0.34.0 - 2023-10-22

### Added

* Support for optional content groups (layers)
* Support for reference XObjects
* Basic support for group XObjects
* [HexaPDF::Layout::Style#fill_horizontal] for allowing a text fragment to fill
  the remaining space of line
* [HexaPDF::Layout::TextFragment#text] and [HexaPDF::Layout::TextBox#text] for
  retrieving the text represented by the stored items
* [HexaPDF::Content::Canvas#pos] for retrieving untransformed positions
* [HexaPDF::Type::CIDFont::CIDSystemInfo] type class

### Changed

* [HexaPDF::Composer#draw_box] to return the last drawn box
* [HexaPDF::Layout::Style::LinkLayer] to support arbitrary actions
* [HexaPDF::Layout::Frame::new] (and adapted other layout classes) to accept a
  context argument (a page or Form XObject instance)
* [HexaPDF::Layout::ListBox] to use its 'fill_color' style property for the item
  marker color
* HexaPDF::Layout::Frame::FitResult#draw to use optional content groups for
  debug output

### Fixed

* [HexaPDF::Document::Pages#add_labelling_range] to add a correct entry for the
  default range starting at page 1
* [HexaPDF::Type::Page#flatten_annotations] to correctly handle scaled
  appearances
* Using an unknown style name in [HexaPDF::Document::Layout] method by providing
  a useful error message
* [HexaPDF::Layout::Box::new] to ensure that the properties attribute is always
  a hash
* [HexaPDF::Layout::ListBox] to work correctly if the marker height is larger
  than the item content height
* [HexaPDF::Dictionary] setting default values on wrong classes in certain
  situations
* [HexaPDF::Importer#import] to correctly import stream objects backed by a
  [HexaPDF::FiberDoubleForString]


## 0.33.0 - 2023-08-02

### Added

* [HexaPDF::Layout::TableBox] for rendering tables
* [HexaPDF::Document::Layout#table_box] for easier table box creation
* [HexaPDF::Content::GraphicObject::EndpointArc#max_curves] for setting the
  approximation accuracy
* [HexaPDF::Importer::copy] for completely copying (including referenced
  indirect objects) a single PDF object (which may be from the same document)
* [HexaPDF::Layout::Style::Border#draw_on_bounds] for drawing the border on the
  bounds instead of inside
* [HexaPDF::MissingGlyphError] for better error messages when a font is missing
  a glyph
* [HexaPDF::Font::Type1Wrapper#custom_glyph] and
  [HexaPDF::Font::TrueTypeWrapper#custom_glyph] for custom glyph creation
* [HexaPDF::FiberDoubleForString] to avoid creating real `Fiber` instances when
  not necessary
* Support for drawing `Geom2D::Rectangle` instances via the :geom2d graphic
  object
* Optional argument `apply_first_text_indent` to
  [HexaPDF::Layout::TextLayouter#fit]

### Changed

* [HexaPDF::Layout::Frame] to use more efficient `Geom2D::Rectangle` class
* Internal constant `HexaPDF::Content::ColorSpace::CSS_COLOR_NAMES` changed to
  [HexaPDF::Content::ColorSpace::COLOR_NAMES]
* Constructor of [HexaPDF::Layout::PageStyle] to allow setting `next_style`
  attribute
* The encryption dictionary is now validated before using it for decryption
* Changed encryption permissions to be compatible to PDF 2.0 by always
  activating the "extract content" permission
* Digital signature creation in case of signature widgets containing images to
  work around bug in Adobe Acrobat
* [HexaPDF::Type::Page#each_annotation] and
  [HexaPDF::Type::Page#flatten_annotations] to process certain invalid /Annot
  keys without errors

### Fixed

* **Breaking change**: [HexaPDF::Object::make_direct] now needs the document
  instance as second argument to correctly resolve references
* [HexaPDF::Layout::ColumnBox], [HexaPDF::Layout::ListBox] and
  [HexaPDF::Layout::ImageBox] to correctly respond to `#empty?`
* [HexaPDF::Layout::ColumnBox] and [HexaPDF::Layout::ListBox] to take different
  final box positions into account
* [HexaPDF::Content::Canvas#text] to set the leading only when multiple lines
  are drawn
* HexaPDF::Layout::TextBox#split to use float comparison
* Validation of standard encryption dictionary to auto-correct invalid /U and /O
  fields in case they are padded with zeros
* [HexaPDF::Document#wrap] handling of sub-type mapping in case of missing type
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to also take a text field
  widget's width into account when auto-sizing
* [HexaPDF::Layout::TextBox] to correctly handle text indentation for split
  boxes


## 0.32.2 - 2023-05-06

### Changed

* Cross-reference table reconstruction to be more relaxed concerning the
  `endobj` keyword

### Fixed

* [HexaPDF::Type::ObjectStream] to not compress any encryption dictionary
  instead of only the current one


## 0.32.1 - 2023-04-20

### Added

* [HexaPDF::Type::FontType0#font_descriptor] and
  [HexaPDF::Type::FontSimple#font_descriptor] for easy access to the font
  descriptor

### Changed

* [HexaPDF::Content::Canvas#color_from_specification] to allow strings and color
  objects without a wrapping array

### Fixed

* AES 128bit encryption to include unnecessary field in encryption dictionary to
  work around buggy PDF libraries
* [HexaPDF::Layout::Style::LinkLayer] to correctly process the border color
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to use fallback for font cap
  height value when necessary


## 0.32.0 - 2023-03-08

### Added

* [HexaPDF::Document::Layout#method_missing] for more convenient box creation
* [HexaPDF::Composer#method_missing] for more convenient box drawing
* [HexaPDF::Document::Layout#inline_box] for easy creation of inline boxes
* [HexaPDF::Type::OutlineItem#open?] for getting the open state of an outline
  item

### Changed

* [HexaPDF::Document::Layout#formatted_text_box] to allow using and/or creating
  inline boxes

### Fixed

* Decryption of invalid files having empty strings or streams when using the AES
  algorithm
* [HexaPDF::Type::Page#flatten_annotations] to work for annotations having
  appearances with degenerate bounding boxes
* `HexaPDF::Tokenizer#parse_literal_string` to make sure enough bytes are in the
  buffer for correctly reading escape sequences
* [HexaPDF::Layout::InlineBox] to correctly work for all kinds of wrapped boxes


## 0.31.0 - 2023-02-22

### Added

* [HexaPDF::Layout::PageStyle] for collecting all styling information for pages
* [HexaPDF::Composer#page_style] for configuring different page styles
* Configuration option 'filter.flate.on_error' for handling potentially
  recoverable flate errors

### Changed

* **Breaking change**: [HexaPDF::Composer] uses page styles underneath
* **Breaking change**: Configuration options `filter.flate_compression` and
  `filter.flate_memory` are changed to `filter.flate.compression` and
  `filter.flate.memory`
* **Breaking change**: [HexaPDF::Document#wrap] handles cross-reference and
  object stream specially to avoid problems with invalid PDFs
* [HexaPDF::Composer::new] to allow skipping the initial page creation
* CLI command `hexapdf info --check` to process streams to reveal stream errors
* CLI commands to output the name of created PDF files in verbose mode

### Fixed

* Validation of document outline items in case the first or last item got
  deleted
* `HexaPDF::Type::Page#perform_validation` to set a /MediaBox for invalid pages
  that don't have one
* Parsing of invalid flate encoded streams that can potentially be recovered


## 0.30.0 - 2023-02-13

### Added

* [HexaPDF::Document::Pages#create] for creating a page object without adding it
  to the page tree

### Changed

* `HexaPDF::Type::FontSimple#perform_validation` to correct /Widths fields in
  case it has an invalid number of entries

### Fixed

* [HexaPDF::DictionaryFields::DateConverter] to handle invalid months, day,
  hour, minute and second values


## 0.29.0 - 2023-01-30

### Added

* [HexaPDF::DigitalSignature::Signing::SignedDataCreator] for creating custom
  CMS signed data objects

### Changed

* **Breaking change**: Refactored digital signature support and moved all
  related code under the [HexaPDF::DigitalSignature] module
* **Breaking change**: New external signing mode without the need for creating
  the PKCS#7/CMS signed data object for
  [HexaPDF::DigitalSignature::Signing::DefaultHandler]
* **Breaking change**: Use value :pades instead of :etsi for
  [HexaPDF::DigitalSignature::Signing::DefaultHandler#signature_type]
* [HexaPDF::DigitalSignature::Signing::DefaultHandler] to allow creating PAdES
  level B-B and B-T signatures
* [HexaPDF::DigitalSignature::Signing::DefaultHandler] to allow specifying the
  used digest algorithm
* [HexaPDF::DigitalSignature::Signing::DefaultHandler] to allow specifying a
  timestamp handler for including a timestamp token in the signature
* Moved setting of signature entries /Filter, /SubFilter and /M fields to the
  signing handlers

### Fixed

* [HexaPDF::DictionaryFields::DateConverter] to handle invalid timezone hour and
  minute values


## 0.28.0 - 2022-12-30

### Added

* [HexaPDF::Type::AcroForm::AppearanceGenerator#create_push_button_appearances]
  to allow customizing the behaviour
* [HexaPDF::Parser#linearized?] for determining whether a document is linearized
* Information on linearization to `hexapdf info` output
* Support for `AFNumber_Format` Javascript method to the form field appearance
  generator
* Support for using fully embedded, simple TrueType fonts for drawing operations

### Changed

* **Breaking change**: `HexaPDF::Revision#reset_objects` has been removed
* **Breaking change**: Method signature of [HexaPDF::Importer::for] has been
  changed
* **Breaking change**: [HexaPDF::Type::AcroForm::Field#each_widget] now has the
  default value of the argument `direct_only` set to `true` instead of `false`
* [HexaPDF::Revision#each_modified_object] to allow deleting the modified
  objects from the active objects' container
* [HexaPDF::Revision#each_modified_object] to allow ignoring added object and
  cross-reference stream objects
* [HexaPDF::Revisions::from_io] to merge the two revisions of a linearized PDF
* [HexaPDF::Importer] and [HexaPDF::Document#import] to make working with them
  easier by allowing the import of arbitrary objects
* `HexaPDF::Type::AcroForm::Form#perform_validation` to combine fields with the
  same name

### Fixed

* [HexaPDF::Type::AcroForm::AppearanceGenerator#create_check_box_appearances] to
  correctly handle a field value of `nil`
* Return value of `#type` method for all AcroForm field classes
* [HexaPDF::Type::Page#flatten_annotations] to work correctly in case no
  annotations are on the page
* [HexaPDF::Type::AcroForm::ButtonField#create_appearances] to avoid creating
  appearances in case of as-yet unresolved references to existing appearances
* [HexaPDF::Type::AcroForm::TextField#create_appearances] to avoid creating
  appearances in case of pre-existing ones
* `HexaPDF::Tokenizer#parse_number` to treat invalid indirect object references
  with an object number of 0 as null values
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to handle empty appearance
  characteristics dictionary marker style strings
* Writing of encrypted files containing two or more revisions
* Generation of object streams to never allow storing the catalog object to
  avoid problems with certain viewers
* `HexaPDF::Type::Outline#perform_validation` to not show validation error when
  `/Count` is zero
* Writing of documents with two or more revisions in non-incremental mode when
  `optimize: true` is used and the original document used cross-reference tables
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to take a widget's rotation
  value into account
* [HexaPDF::Type::Page#flatten_annotations] to correctly flatten all
  annotations, including ones with custom rotations
* [HexaPDF::Type::Page#rotate] to also rotate annotations


## 0.27.0 - 2022-11-18

### Added

* Support for timestamp signatures through the
  `HexaPDF::Document::Signatures::TimestampHandler`
* [HexaPDF::Document::Destinations#resolve] for resolving destination values
* [HexaPDF::Document::Destinations::Destination#value] to return the destination
  array
* Support for verifying document timestamp signatures
* `HexaPDF::Document::Signatures::DefaultHandler#signature_size` to support
  setting custom signature sizes
* `HexaPDF::Document::Signatures::DefaultHandler#external_signing` to support
  signing via custom mechanisms
* `HexaPDF::Document::Signatures::embed_signature` to enable asynchronous
  external signing

### Changed

* **Breaking change**: The crop box is now used instead of the media box in most
  cases to be in line with the specification
* `HexaPDF::Document::Signatures::DefaultHandler` to allow setting the used
  signature method
* **Breaking change**: `HexaPDF::Document::Signatures::DefaultHandler#sign`
  needs to accept the IO object and the byte range instead of just the data
* **Breaking change**: Enhanced support for outline items with new methods
  `#level` and `#destination_page` as well as changes to `#add` and `#each_item`
* **Breaking change**: Removed `#filter_name` and `#sub_filter_name` from
  `HexaPDF::Document::Signatures::DefaultHandler`
* `HexaPDF::Type::Resources#perform_validation` to not add a default procedure
  set since this feature is deprecated

### Fixed

* [HexaPDF::Document::Destinations::Destination::new] to also accept a hash
* [HexaPDF::Type::Catalog] auto-conversion of /Outlines to correct class
* [HexaPDF::Type::AcroForm::Form#flatten] to return the unflattened form fields
  instead of the widgets
* [HexaPDF::Writer#write_incremental] to set the /Version in the catalog
  dictionary when necessary
* [HexaPDF::Importer#import] to always return an imported object with the same
  class as the argument
* [HexaPDF::Type::OutlineItem] to always be an indirect object
* `HexaPDF::Tokenizer#parse_number` to handle references correctly in all cases
* [HexaPDF::Type::Page#rotate] to correctly flatten all page boxes
* `HexaPDF::Document::Signatures#add` to raise an error if the reserved space
  for the signature is not enough
* `HexaPDF::Type::AcroForm::Form#perform_validation` to fix broken /Parent
  entries and to remove invalid objects from the field hierarchy
* `HexaPDF::Type::OutlineItem#perform_validation` bug where a missing /Count key
  was deemed invalid
* [HexaPDF::Revisions::from_io] to use the correct /Prev offset when revisions
  have been merged
* Handling of indirect objects with invalid values for more situations


## 0.26.2 - 2022-10-22

### Added

* Support for setting custom properties on [HexaPDF::Layout::Box] and
  [HexaPDF::Layout::TextFragment]

### Changed

* [HexaPDF::Layout::Style::LinkLayer] to use the 'link' custom box property if
  no target is set

### Fixed

* [HexaPDF::Layout::Style::Layers] to allow named layers without options
* [HexaPDF::Revision#each_modified_object] to not yield signature objects
* [HexaPDF::Revision#each_modified_object] to force comparison of direct objects
* [HexaPDF::Type::ObjectStream] to work for encrypted documents again


## 0.26.1 - 2022-10-14

### Changed

* [HexaPDF::Serializer] to provide better error messages when encountering
  unserializable objects

### Fixed

* [HexaPDF::Importer] to correctly expose previously mapped objects


## 0.26.0 - 2022-10-14

### Added

* Support for page labels
* [HexaPDF::Type::MarkInformation]

### Changed

* [HexaPDF::Rectangle] to recover from invalid values by defaulting to
  `[0, 0, 0, 0]`

### Fixed

* [HexaPDF::DictionaryFields::PDFByteStringConverter] to duplicate the string
  before conversion
* [HexaPDF::Type::FileSpecification#path=] to duplicate the given string value
  due to using it for two different fields


## 0.25.0 - 2022-10-02

### Added

* Support for the document outline
* [HexaPDF::Layout::Style#line_height] for setting a custom line height
  independent of the font size
* [HexaPDF::Document::Destinations#use_or_create] as unified interface for using
  or creating destinations
* [HexaPDF::Document::Destinations::Destination#valid?] and class method for
  checking whether a destination array is valid

### Fixed

* Calculation of text related [HexaPDF::Layout::Style] values for Type3 fonts
* [HexaPDF::Encryption::SecurityHandler#encrypt_string] to either return a
  dupped or encrypted string
* [HexaPDF::Layout::TextLayouter#fit] to avoid infinite loop when encountering a
  non-zero width breakpoint penalty
* [HexaPDF::Type::ObjectStream] to parse the initial stream data right after
  initialization to avoid access errors
* [HexaPDF::Revisions::from_io] to merge a completely empty revision with just a
  /XRefStm pointing into the previous one with the latter
* [HexaPDF::Revisions::from_io] to handle the case of the configuration option
  'parser.try_xref_reconstruction' being false


## 0.24.2 - 2022-08-31

### Fixed

* [HexaPDF::Importer] to detect loops in a fully-loaded document
* HexaPDF::Type::PageTreeNode#perform_validation to only do the validation for
  the document's root page tree node
* HexaPDF::Type::Page#perform_validation to only do the validation if the page
  is part of the document's page tree
* Box layouting to take small floating point differences into account


## 0.24.1 - 2022-08-11

### Added

* [HexaPDF::TestUtils] module that contains helper methods useful for testing
  various parts of HexaPDF

### Changed

* All applicable places to only load the current version of PDF objects, to
  avoid possible inconsistencies when working with files containing multiple
  revisions

### Fixed

* Parsing of streams with an invalid length value that led to a parsing error
* [HexaPDF::Object#==] to only allow comparing simple values to non-indirect
  objects and not also other HexaPDF::Object instances


## 0.24.0 - 2022-08-01

### Added

* [HexaPDF::Layout::ListBox] for rendering ordered and unordered lists
* [HexaPDF::Layout::ColumnBox] for rendering content inside columns
* [HexaPDF::Layout::BoxFitter] for placing boxes into multiple frames
* New configuration option 'debug' for enabling debug output
* [HexaPDF::Document::Pages#move] for moving pages around the same document
* [HexaPDF::Composer#box] for drawing arbitrary, registered boxes
* [HexaPDF::Layout::Box#split_box?] for determining whether a box is a split
  box, i.e. the continuation of another box
* [HexaPDF::Document::Layout::ChildrenCollector] to provide an easy method for
  defining children boxes of a container box

### Changed

* **Breaking change**: Refactored [HexaPDF::Layout::Frame] and associated data
  structures so that the complete result of fitting a box is returned
* [HexaPDF::Layout::Frame] to use a better algorithm for trimming the shape
* [HexaPDF::Layout::Frame::new] to allow setting the initial shape
* **Breaking change**: Removed contour line from [HexaPDF::Layout::Frame]
* **Breaking change**: Changed positional arguments of
  [HexaPDF::Layout::TextBox::new] and [HexaPDF::Layout::ImageBox::new] to
  keyword arguments for a consistent box initialization interface
* [HexaPDF::Layout::Box#split] to provide a default implementation that is
  useful for most subclasses
* Layout box implementations to provide a `#supports_position_flow?` method that
  indicates whether the box supports flowing its content around other content.
* `hexapdf info --check` to only check the current version of each object
* [HexaPDF::Writer] to make sure the producer information is written when
  writing the file incrementally

### Fixed

* [HexaPDF::Layout::TextLayouter] to freeze the new items when a text fragment
  needs to be split
* [HexaPDF::Layout::TextLayouter] to avoid the possible splitting of a text
  fragment if there would not be enough height left anyway
* [HexaPDF::Layout::WidthFromPolygon] to work correctly in case of very small
  floating point errors
* HexaPDF::Layout::TextFragment#inspect to work in case of interspersed numbers
* HexaPDF::Layout::TextBox#split to work for position :flow when box is wider
  than the initial available width
* [HexaPDF::Layout::Frame#fit] to create minimally sized mask rectangles
* [HexaPDF::Content::GraphicObject::Geom2D] to close the path when drawing
  polygons
* [HexaPDF::Layout::WidthFromPolygon] to work for all counterclockwise polygons
* [HexaPDF::Type::PageTreeNode#move_page] to work in case the parent node of the
  moved node doesn't change
* [HexaPDF::Type::PageTreeNode#move_page] to use the correct target position
  when the moved node is before the target position
* `HexaPDF::Document::Signatures#add` to work in case the signature object is
  the last object written
* CLI command `hexapdf inspect` to show correct byte range of the last revision
* [HexaPDF::Writer#write_incremental] to only use a cross-reference stream if a
  revision directly used one and not through an `/XRefStm` entry
* [HexaPDF::Encryption::FastARC4] to use RubyARC4 as fallback if OpenSSL has RC4
  disabled
* [HexaPDF::Font::Encoding::GlyphList] to use binary reading to avoid problems
  on Windows
* `HexaPDF::Document::Signatures#add` to use binary writing to avoid problems on
  Windows


## 0.23.0 - 2022-05-26

### Added

- [HexaPDF::Composer#create_stamp] for creating a form Xobject
- `HexaPDF::Revision#reset_objects` for deleting all live loaded and added
  objects
- Support for removing or flattening annotations to the `hexapdf modify` command
- Option to CLI command `hexapdf form` to allow generation of a template file
- Support for centering a floating box in [HexaPDF::Layout::Frame]
- [HexaPDF::Type::Catalog#names] for easier access to the name dictionary
- [HexaPDF::Type::Names#destinations] for easier access to the destinations name
  tree
- [HexaPDF::Document::Destinations], accessible via
  [HexaPDF::Document#destinations], as convenience interface for working with
  destination arrays

### Changed

- **Breaking change**: Refactored the [HexaPDF::Document] interface for working
  with objects and move parts into [HexaPDF::Revisions]
- **Breaking change**: [HexaPDF::Layout::TextBox] to use whole available width
  when aligning to the center or right
- **Breaking change**: [HexaPDF::Layout::TextBox] to use whole available height
  when vertically aligning to the center or bottom
- CLI command `hexapdf inspect` to show the type of revisions, as well as the
  number of objects per revision
- [HexaPDF::Task::Optimize] to allow skipping invalid content stream operations
- [HexaPDF::Composer#image] to allow using a form xobject in place of the image

### Fixed

- [HexaPDF::Writer#write] to write modified objects into the correct revision
- [HexaPDF::Revisions::from_io] to correctly handle hybrid-reference files
- [HexaPDF::Writer] to assign a valid object number to a created cross-reference
  stream in all cases
* [HexaPDF::Type::AcroForm::TextField] to validate the existence of a /MaxLen
  value for comb text fields
* [HexaPDF::Type::AcroForm::TextField#field_value=] to check for the existence
  of /MaxLen when setting a value for a comb text field
* [HexaPDF::Type::AcroForm::TextField#field_value=] to check the value against
  /MaxLen
* [HexaPDF::Layout::TextLayouter#fit] to not use style valign when doing
  variable width layouting
* [HexaPDF::Utils::SortedTreeNode#find_entry] to work in case of a node without
  a container name or kids key
* CLI command `hexapdf form` to allow setting array values when using a template
* CLI command `hexapdf form` to allow setting file select fields


## 0.22.0 - 2022-03-26

### Added

- Support for writing images with an ICCBased color space
- Support for writing images with soft masks

### Changed

- CLI command `hexapdf form` to show a warning when working with a file
  containing an XFA form

### Fixed

- [HexaPDF::Type::AcroForm::Form#field_by_name] to work correctly when field
  name parts are UTF-16BE encoded
- `hexapdf inspect` command 'revision' to correctly detect the end of revisions
- [HexaPDF::DictionaryFields::StringConverter] to use correct method name
  `HexaPDF::Document#config`


## 0.21.1 - 2022-03-12

### Fixed

- Handling of invalid AES encrypted files where the padding is missing


## 0.21.0 - 2022-03-04

### Added

* [HexaPDF::Parser#reconstructed?] which returns true if the cross-reference
  table was reconstructed
- [HexaPDF::Layout::Style::create] for easier creation of style objects
* The ability to view revisions of a PDF document or extract a single revision
  via `hexapdf inspect`

### Changed

* **Breaking change**: Refactored [HexaPDF::Composer] for better and more
  consistent style support
* **Breaking change**: Arguments for configuration option
  'font.on_missing_glyph' have changed to allow access to the document instance

### Fixed

* Setter for [HexaPDF::Layout::Style#line_spacing] to allow usage of numeric
  arguments
* Digital Signature validation for 'adbe.pkcs7.detached' certifiates in case no
  key usage was defined
* Removed caching of configuration 'font.on_missing_glyph' in font wrappers to
  avoid problems


## 0.20.4 - 2022-01-26

### Fixed

* Regression when using Type1 font with different encodings


## 0.20.3 - 2022-01-24

### Changed

* Appearance of signature field values when using the `hexapdf form` command

### Fixed

* Writing of encrypted PDF files in incremental node in case the encryption was
  changed
* [HexaPDF::Type::Annotation#appearance] to return correctly wrapped object in
  case of Form XObjects missing required data
* Decrypting of files with multiple revisions


## 0.20.2 - 2022-01-17

### Fixed

* [HexaPDF::Task::Optimize] so that page resource pruning works for pages
  without XObjects


## 0.20.1 - 2022-01-05

### Changed

* Refactored signature handlers, making `#store_verification_callback` a
  protected method

### Fixed

* [HexaPDF::Task::Dereference] to work for even very deeply nested structures


## 0.20.0 - 2021-12-30

### Added

* Support for signing a PDF using a digital signature
* Support for reading and validating digital signatures
* Output info regarding digital signatures when using the `hexapdf info` command
* [HexaPDF::Type::AcroForm::Form#create_signature_field] for adding signature
  fields
* [HexaPDF::Type::Annotation::AppearanceDictionary#set_appearance] for setting
  the appearance stream
* [HexaPDF::Type::Annotation#create_appearance] for creating an empty appearance
  stream

### Changed

* **Breaking change**: Method signature of
  [HexaPDF::Type::Annotation#appearance] changed
* [HexaPDF::Object#==] to allow comparison to simple value if not indirect
* [HexaPDF::Type::AcroForm::Form] to use an empty array as default for the
  /Fields field
* [HexaPDF::Type::ObjectStream] to not store signature fields in object streams
* [HexaPDF::Writer] to return the last written cross-reference section
* [HexaPDF::Type::AcroForm::Field#create_widget] to automatically set the print
  flag and assign the page

### Fixed

* Incremental writing of files in cases where object streams were deleted (e.g.
  when using the `optimize: true` argument when writing)
* Comparison of non-indirect [HexaPDF::Object] instances with other
  HexaPDF::Object instances
* Deleting of objects via [HexaPDF::Revision#delete] to re-use the
  [HexaPDF::PDFData] object of the deleted object when using
  `mark_as_free: true`
* [HexaPDF::Revision#each_modified_object] to work correctly for dictionary
  objects even if a value is changed only by reading it


## 0.19.3 - 2021-12-14

### Fixed

* Handling of invalid files where the "startxref" keyword and its value are on
  the same line


## 0.19.2 - 2021-12-14

### Fixed

* Set the trailer's ID field to an array of two empty strings when decrypting in
  case it is missing
* Incremental writing when one of the existing revisions contains a
  cross-reference stream


## 0.19.1 - 2021-12-12

### Added

* [HexaPDF::Type::FontType3#bounding_box] to fix content stream processing error

### Fixed

* Calculation of scaled font size for [HexaPDF::Content::GraphicsState] and
  [HexaPDF::Layout::Style] when Type3 fonts are used


## 0.19.0 - 2021-11-24

### Added

* Page resource pruning to the optimization task
* An option for page resources pruning to the optimization options of the
  `hexapdf` command

### Fixed

* Handling of invalid date strings with a minute time zone offset greater than
  59


## 0.18.0 - 2021-11-04

### Added

* [HexaPDF::Content::ColorSpace::serialize_device_color] for serialization of
  device colors in parts other than the canvas
* [HexaPDF::Type::AcroForm::VariableTextField::create_appearance_string] for
  centralized creation of appearance strings
* [HexaPDF::Object::make_direct] for making objects and all parts of them direct
  instead of indirect

### Changed

* [HexaPDF::Type::AcroForm::VariableTextField::parse_appearance_string] to also
  return the font color
* [HexaPDF::Type::AcroForm::VariableTextField#set_default_appearance_string] to
  allow specifying the font color
* [HexaPDF::Type::AcroForm::Form] methods to support new variable text field
  methods
* [HexaPDF::Type::AcroForm::AppearanceGenerator] to support the set font color
  when creating text field appearances

### Fixed

* Writing of existing, encrypted PDF files where parts of the encryption
  dictionary are indirect objects
* [HexaPDF::Content::GraphicObject::EndpointArc] to correctly determine the
  start and end points
* HexaPDF::Dictionary#perform_validation to correctly handle objects that should
  not be indirect objects


## 0.17.3 - 2021-10-31

### Fixed

* Reconstruction of invalid PDF files where the PDF header is not at the start
  of the file
* Reconstruction of invalid PDF files where the first object is invalid


## 0.17.2 - 2021-10-26

### Fixed

* Deployment of HexaPDF's Rubygem


## 0.17.1 - 2021-10-21

### Fixed

* Handling of files containing invalid UTF-16 strings


## 0.17.0 - 2021-10-21

### Added

* CLI command `hexapdf fonts` for listing fonts of a PDF file
* [HexaPDF::Layout::Style#background_alpha] for defining the opacity of the
  background
* [HexaPDF::Type::Page#each_annotation] for iterating over all annotations of a
  page

### Changed

* **Breaking change**: Handling of AcroForm check boxes to allow multiple
  widgets with different values
* CLI command `hexapdf form` to support new check box features
* [HexaPDF::Content::Canvas#text] to use the font size as leading if no leading
  has been set
* [HexaPDF::Content::Canvas#line_with_rounded_corner] to be a public method
* [HexaPDF::Layout::Style::LineSpacing] to allow using integers or floats as
  type argument to mean proportional line spacing
* [HexaPDF::Type::AcroForm::VariableTextField#set_default_appearance_string] to
  allow specifying font options
* AcroForm text field creation methods in [HexaPDF::Type::AcroForm::Form] to
  allow specifying font options

### Fixed

* [HexaPDF::Type::AcroForm::Field#each_widget] to also return widgets of other
  form fields that have the same name
* `hexapdf form` to allow filling in multiline and comb text fields
* `hexapdf form` to correctly work for PDF files containing null values in the
  list of annotations
* Handling of files that contain invalid default appearance strings
* [HexaPDF::Type::AcroForm::TextField#field_value] to allow setting a `nil`
  value for single line text fields
* [HexaPDF::Content::GraphicObject::Arc] to respect the value set by the
  `#max_curves` accessor


## 0.16.0 - 2021-09-28

### Added

* Support for RGB color values of the form "RGB" in addition to "RRGGBB" and for
  CSS color module level 3 color names
* Conversion module for Integer fields to fix certain invalid PDF files


## 0.15.9 - 2021-09-04

### Fixed

* Handling of files that contain stream length values that are indirect objects
  not referring to a number


## 0.15.8 - 2021-08-16

### Fixed

* Regression when using `-v` with the hexapdf command line tool


## 0.15.7 - 2021-07-17

### Fixed

* Infinite loop while parsing PDF array due to missing closing bracket
* Handling of invalid files with missing or corrupted trailer dictionary


## 0.15.6 - 2021-07-16

### Fixed

* Handling of indirect objects with invalid values which are now treated as null
  objects


## 0.15.5 - 2021-07-06

### Changed

* Refactored [HexaPDF::Tokenizer#next_xref_entry] and changed yielded value


### Fixed

* Handling of invalid cross-reference stream entries that ends with the sequence
  `\r\r`


## 0.15.4 - 2021-05-27

### Fixed

* [HexaPDF::Type::Annotation#appearance] to handle cases where there is no valid
  appearance stream


## 0.15.3 - 2021-05-01

### Fixed

* Handling of general (not document-level), unencrypted metadata streams


## 0.15.2 - 2021-05-01

### Fixed

* Handling of unencrypted metadata streams


## 0.15.1 - 2021-04-15

### Fixed

* Potential division by zero when calculating the scaling for XObjects
* Handling of XObjects with a width or height of zero when drawing on canvas


## 0.15.0 - 2021-04-12

### Added

* [HexaPDF::Type::Page#flatten_annotations] for flattening the annotations of a
  page
* [HexaPDF::Type::AcroForm::Form#flatten] for flattening interactive forms
* [HexaPDF::Revision#update] for updating the stored wrapper class of a PDF
  object
* [HexaPDF::Type::AcroForm::SignatureField] for working with AcroForm signature
  fields
* Support for form field flattening to the `hexapdf form` CLI command

### Changed

* **Breaking change**: Overhauled the interface for accessing appearances of
  annotations to make it more convenient
* Validation of [HexaPDF::Type::FontDescriptor] to delete invalid `/FontWeight`
  value
* [HexaPDF::MalformedPDFError#pos] an accessor instead of a reader and update
  the exception message
* Configuration option 'acro_form.fallback_font' to allow a callable object for
  more advanced fallback font handling

### Fixed

* [HexaPDF::Type::Annotations::Widget#background_color] to correctly handle
  empty background color arrays
* [HexaPDF::Type::AcroForm::Field#delete_widget] to update the wrapper object
  stored in the document in case the widget is embedded
* Processing of invalid PDF files containing a space,CR,LF combination after the
  'stream' keyword
* Cross-reference stream reconstruction with respect to detection of linearized
  files
* Detection of existing appearances for AcroForm push button fields when
  creating appearances


## 0.14.4 - 2021-02-27

### Added

* Support for the Crypt filters

### Changed

* [HexaPDF::MalformedPDFError] to make the `pos` argument optional

### Fixed

* Handling of invalid floating point numbers NaN, Inf and -Inf when serializing
* Processing of invalid PDF files containing NaN and Inf instead of numbers
* Bug in Type1 font AFM parser that occured if the file doesn't end with a new
  line character
* Cross-reference table reconstruction to handle the case of an entry specifying
  a non-existent indirect object
* Cross-reference table reconstruction to handle trailers specified by cross-
  reference streams
* Cross-reference table reconstruction to use the set security handle for
  decrypting indirect objects
* Parsing of cross-reference streams where data is missing


## 0.14.3 - 2021-02-16

### Fixed

* Bug in [HexaPDF::Font::TrueType::Subsetter#use_glyph] which lead to corrupt
  text output
* [HexaPDF::Serializer] to handle infinite recursion problem
* Cross-reference table reconstruction to avoid an O(n^2) performance problem
* [HexaPDF::Type::Resources] validation to handle an invalid `/ProcSet` entry
  containing a single value instead of an array
* Processing of invalid PDF files missing a required value in appearance streams
* Processing of invalid empty arrays that should be rectangles by converting
  them to PDF null objects
* Processing of invalid PDF files containing indirect objects with offset 0
* Processing of invalid PDF files containing a space/CR or space/LF combination
  after the 'stream' keyword


## 0.14.2 - 2021-01-22

### Fixed

* [HexaPDF::Font::TrueType::Subsetter#use_glyph] to really avoid using subset
  glyph ID 41 (`)`)


## 0.14.1 - 2021-01-21

### Changed

* Validation message when checking for allowed values to include the invalid
  object
* [HexaPDF::FontLoader::FromFile] to allow (re)using an existing font object
* [HexaPDF::Importer] internals to avoid problems with retained memory

### Fixed

* Parsing of invalid PDF files where whitespace is missing after the integer
  value of an indirect object
* [HexaPDF::Dictionary] so that adding new key-value pairs during validation is
  possible


## 0.14.0 - 2020-12-30

### Added

* Support for creating AcroForm multiline text fields and their appearances
* Support for creating AcroForm comb text fields and their appearances
* Support for creating AcroForm password fields and their appearances
* Support for creating AcroForm file select fields and their appearances
* Support for creating AcroForm list box appearances
* [HexaPDF::Type::AcroForm::ChoiceField#list_box_top_index] and its setter
  method
* [HexaPDF::Type::AcroForm::ChoiceField#update_widgets] to create appearances if
  they don't exist
* Methods for caching data to [HexaPDF::Object]
* Support for splitting by page size to CLI command `hexapdf split`

### Changed

* [HexaPDF::Utils::ObjectHash#oids] to be public instead of private
* Cross-reference table parsing to handle invalidly numbered main sections
* [HexaPDF::Document#cache] and [HexaPDF::Object#cache] to allow updating values
  for existing keys
* Appearance creation methods of AcroForm objects to allow forcing the creation
  of new appearances
* [HexaPDF::Type::AcroForm::AppearanceGenerator#create_text_appearances] to
  re-use existing form objects
* AcroForm field creation methods to allow specifying often used field
  properties

### Fixed

* Missing usage of `:sort` flag for AcroForm choice fields
* Setting the `/I` field for AcroForm list boxes with multiple selection
* [HexaPDF::Layout::TextLayouter::SimpleLineWrapping] to remove glue items
  (whitespace) before a hard line break
* Infinite loop when reconstructing the cross-reference table
* [HexaPDF::Type::AcroForm::ChoiceField] to support export values for option
  items
* AcroForm text field appearance creation to only create a new appearance if the
  field's value has changed
* AcroForm choice field appearance creation to only create a new appearance if
  the involved dictionary fields' values have changed
* [HexaPDF::Type::AcroForm::ChoiceField#list_box_top_index=] to raise an error
  if no option items are set
* [HexaPDF::PDFArray#to_ary] to return an array with preprocessed values
* [HexaPDF::Type::Form#contents=] to clear cached values to avoid returning e.g.
  an invalid canvas object later
* [HexaPDF::Type::AcroForm::ButtonField#update_widgets] to create appearances if
  they don't exist


## 0.13.0 - 2020-11-15

### Added

* Cross-reference table reconstruction for damaged PDFs, controllable via the
  new 'parser.try_xref_reconstruction' option
* Two new `hexapdf inspect` commands for showing page objects and page content
  streams by page number
* Flag `--check` to the CLI command `hexapdf info` for checking a file for parse
  and validation errors
* [HexaPDF::Type::AcroForm::Field#embedded_widget?] for checking if a widget is
  embedded in the field object
* [HexaPDF::Type::AcroForm::Field#delete_widget] for deleting a widget
* [HexaPDF::PDFArray#delete] for deleting an object from a PDF array
* [HexaPDF::Type::Page#ancestor_nodes] for retrieving all ancestor page tree
  nodes of a page
* [HexaPDF::Type::PageTreeNode#move_page] for moving a page to another index

### Changed

* **Breaking change**: Overhauled document/object validation interfaces and
  internals to be more similar and to allow for reporting of multiple validation
  problems
* Validation of TrueType fonts to ignore missing fields if the font name
  suggests that the font is one of the standard 14 PDF fonts
* Option `-p` of CLI command `hexapdf image2pdf` to also allow lowercase page
  size names

### Fixed

* Reporting of cross-reference section entry parsing error
* PDF version used by default for dictionary fields
* Error in CLI command `hexapdf inspect` when parsing an invalid object number
* Output of error messages in CLI command `hexapdf inspect` to go to `$stderr`
* Bug in [HexaPDF::Type::AcroForm::TextField] validation due to missing nil
  handling


## 0.12.3 - 2020-08-22

### Changed

* Allow any object responding to `#to_sym` when setting a radio button value

### Fixed

* Error in the AcroForm appearance generator for text fields when the font is
  not found in the default resources
* Parsing of long numbers when reading a file from IO
* Usage of unsupported method for Ruby 2.4 so that all tests pass again


## 0.12.2 - 2020-08-17

### Fixed

- Wrong origin for page canvases when bottom left corner of media box doesn't
  coincide with origin of coordinate system
- Wrong origin for Form XObject canvas when bottom left corner of bounding box
  doesn't coincide with origin of coordinate system


## 0.12.1 - 2020-08-16

### Added

* [HexaPDF::Font::Encoding::Base#code] for retrieving the code for a given glyph
  name

### Fixed

* [HexaPDF::Font::Type1Wrapper#encode] to correctly resolve the code for a glyph
  name


## 0.12.0 - 2020-08-12

### Added

* Convenience methods for accessing field flags for
  [HexaPDF::Type::AcroForm::Field]
* [HexaPDF::Type::AcroForm::TextField] and
  [HexaPDF::Type::AcroForm::VariableTextField] for basic text field support
* [HexaPDF::Type::AcroForm::ButtonField] for push button, radio button and check
  box support
* [HexaPDF::Type::AcroForm::ChoiceField] for combo box and list box support
* [HexaPDF::Type::AcroForm::AppearanceGenerator] as central class for generating
  appearance streams for form fields
* Various convenience methods for [HexaPDF::Type::AcroForm::Form]
* Various convenience methods for [HexaPDF::Type::AcroForm::Field]
* Various convenience methods for [HexaPDF::Type::Annotations::Widget]
* [HexaPDF::Type::Annotation::AppearanceDictionary]
* [HexaPDF::Document#acro_form] and [HexaPDF::Type::Catalog#acro_form]
  convenience methods
* CLI command `hexapdf form` for listing fields of interactive forms and filling
  them out
* [HexaPDF::Rectangle] methods for setting the left, top, right, bottom, width
  and height
* Method #prenormalized_color to all color space implementations
* [HexaPDF::Type::Font#font_wrapper] for accessing an associated font wrapper
  instance
* [HexaPDF::Type::FontType1#font_wrapper] for providing a font wrapper for the
  standard PDF fonts
* [HexaPDF::Type::Annotation::Border] class
* [HexaPDF::Content::ColorSpace::device_color_from_specification] for easily
  getting a device color object
* [HexaPDF::Content::ColorSpace::prenormalized_device_color] for getting a
  device color object without normalizing values
* [HexaPDF::Type::Annotation#appearance] for returning the associated appearance
  dictionary
* [HexaPDF::Type::Annotation#appearance?] for checking whether an appearance for
  the annotation exists
* Configuration option 'acro_form.create_appearance_streams' for automatically
  creating appearance streams
* [HexaPDF::Type::Resources] methods `#pattern` and `add_pattern`

### Changed

* Deletion of pages to delete them from the document as well
* Refactored [HexaPDF::Font::Type1Wrapper] and [HexaPDF::Font::TrueTypeWrapper]
  and renamed `#dict` to `#pdf_object`
* Fall back to the Type1 font's internal encoding when decoding a string
* All [HexaPDF::Content::ColorSpace] implementations to only normalize values
  when using the ::color method
* [HexaPDF::Content::Parser#parse] to also accept a block in place of a
  processor object
* HexaPDF::Type::AcroForm::Field#full_name to
  [HexaPDF::Type::AcroForm::Field#full_field_name]
* Moved `HexaPDF::Content::Canvas#color_space_for_components` to class method on
  [HexaPDF::Content::ColorSpace]
* Added bit unsetter method to[HexaPDF::Utils::BitField]
* [HexaPDF::Type::AcroForm::Form#find_root_fields] and `#each_field` to take the
  field type into account when wrapping a field dictionary
* Pages specification of CLI commands to allow counting from the end using the
  new `r<N>` notation
* [HexaPDF::Font::Type1Wrapper] to use the internal encoding of a font with a
  'Special' character set instead of a custom encoding
* Configuration 'filter.map' to use the pass-through filter on all unsupported
  filters

### Fixed

* Wrong normalization of color values when invoking a color operator
* Invalid type of `/DR` field of [HexaPDF::Type::AcroForm::Form]
* Invalid ordering of types for the `/V` and `/DV` fields of
  [HexaPDF::Type::AcroForm::Field]
* [HexaPDF::Type::AcroForm::Field#terminal_field?] to work according to the spec
* Handling of empty files by throwing better error messages
* [HexaPDF::Type::Image#info] to correctly identify images with a soft mask as
  currently not supported for writing
* [HexaPDF::Revision#delete] to remove the connection between the object and the
  document
* Missing `#definition` method of `DeviceRGB`, `DeviceCMYK` and `DeviceGray`
  color spaces
* Handling of 'Pattern' color spaces when parsing content streams


## 0.11.9 - 2020-06-15

### Changed

* Encryption dictionaries to always be indirect objects


## 0.11.8 - 2020-06-11

### Fixed

* Serialization of special `/` (zero-length name) object in dictionaries and
  arrays


## 0.11.7 - 2020-06-10

### Fixed

* Deletion of object streams in [HexaPDF::Task::Optimize] to avoid accessing
  then invalid object streams
* [HexaPDF::Task::Optimize] to work correctly when deleting object streams and
  generating xref streams


## 0.11.6 - 2020-05-27

### Fixed

* [HexaPDF::Layout::TextBox] to respect the set width and height when fitting
  and splitting the box


## 0.11.5 - 2020-01-27

### Changed

* [HexaPDF::Font::TrueType::Table::CmapSubtable] to lazily parse the subtable
* [HexaPDF::Font::TrueType::Table::Hmtx] to lazily parse the width data
* CLI command `hexapdf image2pdf` to use the last argument as output file
  instead of the first (same order as `merge`)
* Automatically require the HexaPDF C extension if it is installed

### Fixed

* Wrong line length calculation for variable width layouting when a text box is
  too wide and needs to be broken into parts
* CLI command `hexapdf image2pdf` so that treating a PDF as image works


## 0.11.4 - 2019-12-28

### Fixed

* Memory consumption problem of PNG image loader when using images with alpha
  channel


## 0.11.3 - 2019-11-27

### Fixed

* Restore compatibility with Ruby 2.4


## 0.11.2 - 2019-11-22

### Fixed

* Conversion of [HexaPDF::Rectangle] type when the original is not a plain Array
  but a [HexaPDF::PDFArray]


## 0.11.1 - 2019-11-19

### Fixed

* [HexaPDF::Type::AcroForm::Form#find_root_fields] to work for documents where
  not all pages have form fields


## 0.11.0 - 2019-11-19

### Added

* [HexaPDF::PDFArray] to wrap arrays and allow automatic resolution of
  references like with [HexaPDF::Dictionary] - MAY BREAK THINGS!
* CLI command `hexapdf watermark` to apply a watermark PDF as background or
  stamp onto another PDF file
* CLI command `hexapdf image2pdf` to convert images into a PDF file
* [HexaPDF::DictionaryFields::Field#allowed_values] to allow constraining a
  field to certain allowed values
* [HexaPDF::Document::Fonts#configured_fonts] to return all font variants that
  are configured and available for adding to a document
* [HexaPDF::Type::Annotations::Widget] and associated classes
* [HexaPDF::Type::AcroForm::Form] and [HexaPDF::Type::AcroForm::Field] for basic
  AcroForm support

### Changed

* Use Reline for interactive mode of `hexapdf inspect` if available
* [HexaPDF::DictionaryFields::Field::new] to use keyword arguments
* Update the field information for implemented PDF types to include the allowed
  values where possible
* Interface of font loader objects to allow another method `available_fonts` for
  returning all available fonts
* [HexaPDF::Layout::Style] to check for valid values where possible

### Fixed

* Line spacing of empty lines for [HexaPDF::Layout::TextLayouter]
* Handling of `/DecodeParms` when exporting to PNG images


## 0.10.0 - 2019-10-02

### Added

* [HexaPDF::Reference#to_s] to return the serialized form of the PDF reference
* [HexaPDF::Revision#xref] for getting cross-reference entries
* HexaPDF::XRefSection::Entry#to_s to return a description of the
  cross-reference entry

### Changed

* Enhanced the `hexapdf images` command to also show information on PPI (pixels
  per inch) and size
* Completely revamped the `hexapdf inspect` command with an interactive mode,
  structure output, cross-reference entry output and object search
* Output of validation problem messages for `hexapdf` command to include more
  information
* The Validation feature to automatically correct String-for-Symbol and
  Symbol-for-String problems

### Fixed

* [HexaPDF::Document#wrap] to better handle subtype mappings in case of unknown
  type information
* [HexaPDF::DictionaryFields::DictionaryConverter] to not allow conversion to a
  [HexaPDF::Stream] subclass from objects without stream data
* Import of JPEG images with YCCK color encoding
* Export of images without `/FlateDecode` filter or `/DecodeParms` to PNG files
* Mistyped name of field type for field `/Popup` of
  [HexaPDF::Type::Annotations::MarkupAnnotation]
* Loading and saving of encrypted and signed PDFs
* CLI commands that optimize font data structures won't crash when encountering
  invalid font objects


## 0.9.3 - 2019-06-13

### Changed

* Behaviour of how object streams are generated to work around a bug (?) in
  Adobe Acrobat

### Fixed

* Fix problem with [HexaPDF::Encryption::StandardSecurityHandler] due to
  behaviour change of Ruby 2.6.0 in `String#setbyte`

## 0.9.2 - 2019-05-22

### Changed

* [HexaPDF::Encryption::AES] to handle invalid padding
* [HexaPDF::Filter::FlateDecode] to correctly handle invalid empty streams

## 0.9.1 - 2019-03-26

### Fixed

* [HexaPDF::Serializer] to avoid infinite loops for self-referencing streams
* Bug due to frozen string in [HexaPDF::Font::CMap::Writer]


## 0.9.0 - 2018-12-31

### Added

* [HexaPDF::Composer] for composing PDF documents in a high-level way
* Incremental writing support (i.e. appending a single revision with all the
  changes to an existing document) to [HexaPDF::Writer] and [HexaPDF::Document]
* CLI command `hexapdf split` to split a PDF file into individual pages
* [HexaPDF::Revisions#parser] for accessing the parser object that is created
  when a document is read from an IO stream
* [HexaPDF::Document#each] argument `only_loaded` for iteration over loaded
  objects only
* [HexaPDF::Document#validate] argument `only_loaded` for validating only loaded
  objects
* [HexaPDF::Revision#each_modified_object] for iterating over all modified
  objects of a revision
* [HexaPDF::Layout::Box#split] and HexaPDF::Layout::TextBox#split for
  splitting a box into two parts
* [HexaPDF::Layout::Frame#full?] for testing whether the frame has any space
  left
* [HexaPDF::Layout::Style] property `last_line_gap` for controlling the spacing
  after the last line of text
* HexaPDF::Layout::Box#draw_content for use by subclasses
* [HexaPDF::Type::Form#width] and [HexaPDF::Type::Form#height] for compatibility
  with [HexaPDF::Type::Image]
* [HexaPDF::Layout::ImageBox] for displaying an image inside a frame

### Changed

* [HexaPDF::Revision#each] to allow iteration over loaded objects only
* [HexaPDF::Document#each] method argument from `current` to `only_current`
* [HexaPDF::Object#==] and [HexaPDF::Reference#==] so that Object and Reference
  objects can be compared
* Refactored [HexaPDF::Layout::Frame] to allow separate fitting, splitting and
  drawing of boxes
* [HexaPDF::Layout::Style::LineSpacing::new] to allow setting of line spacing
  via a single hash argument
* Made [HexaPDF::Layout::Style] copyable

### Fixed

* Configuration so that annotation objects are correctly mapped to classes
* Fix problem with [HexaPDF::Filter::Predictor] due to behaviour change of Ruby
  2.6.0 in `String#setbyte`
* Fitting of [HexaPDF::Layout::TextBox] when the box has padding and/or borders
* Fitting of [HexaPDF::Layout::TextBox] when width and/or height has been set
* Fitting of absolutely positioned boxes in [HexaPDF::Layout::Frame]
* Fix bug in variable width line wrapping due to not considering line spacing
  correctly ([HexaPDF::Layout::Line::HeightCalculator#simulate_height] return
  value needed to be changed for this fix)

## 0.8.0 - 2018-10-26

### Added

* [HexaPDF::Layout::Frame] for box positioning and easier text layouting inside
  an arbitrary polygon
* [HexaPDF::Layout::TextBox] for displaying text in a rectangular and for
  flowing text inside a frame
* [HexaPDF::Layout::WidthFromPolygon] for getting a width specification from a
  polygon for use with the text layouting engine
* [HexaPDF::Type::Image#width] and [HexaPDF::Type::Image#height] convenience
  methods
* [HexaPDF::Type::FontType3] for Type 3 font support
* [HexaPDF::Content::GraphicObject::Geom2D] for [Geom2D] object drawing support
* [HexaPDF::Type::Page#orientation] for easy determination of page orientation
* [HexaPDF::Type::Page#rotate] for rotating a page
* [HexaPDF::Layout::Style::Quad#set] for setting all values at once

### Changed

* [HexaPDF::Document#validate] to also yield the object that failed validation
* [HexaPDF::Type::Page#box] to allow setting the value for a box
* [HexaPDF::Layout::TextLayouter#fit] to allow fitting text into arbitrarily
  shaped areas
* [HexaPDF::Layout::TextLayouter] to return a new
  [HexaPDF::Layout::TextLayouter::Result] structure when `#fit` is called that
  includes the `#draw` method
* [HexaPDF::Layout::TextLayouter#fit] to require the height argument
* Refactored [HexaPDF::Layout::Box] to make using it a bit easier

### Fixed

* Validation and conversion of dictionary fields with multiple possible types
* Box border drawing when border width is greater than edge length

[geom2d]: https://github.com/gettalong/geom2d


## 0.7.0 - 2018-06-19

### Changed

* All Ruby source files use frozen string literal pragma
* [HexaPDF::MalformedPDFError::new] method signature
* [HexaPDF::Layout::TextFragment::new] and
  [HexaPDF::Layout::TextFragment::create] method signatures
* [HexaPDF::Encryption::SecurityHandler#set_up_encryption] argument `force_V4`
  to `force_v4`
* HexaPDF::Layout::TextLayouter#draw to return result of #fit if possible

### Removed

* Optional `leading` argument to HexaPDF::Content::Canvas#font_size method

### Fixed

* Misspelt variable name in [HexaPDF::Layout::TextLayouter::SimpleLineWrapping]
* [HexaPDF::Layout::TextLayouter::SimpleTextSegmentation] to work if the last
  character in a text fragment is \r
* [HexaPDF::Layout::TextLayouter] to work if an optional break point (think
  soft-hyphen) is followed by whitespace
* [HexaPDF::Font::TrueType::Builder] to correctly order the entries in the table
  directory
* [HexaPDF::Font::TrueType::Builder] to pad the table data to achieve the
  correct alignment
* [HexaPDF::Filter::FlateDecode] by removing the Zlib pools since they were not
  thread safe
* All color space classes to accept the color space definition as argument to
  `::new`


## 0.6.0 - 2017-10-27

### Added

* [HexaPDF::Layout::Box] as base class for all layout boxes
* More styling properties for [HexaPDF::Layout::Style]
* Methods for checking whether styling properties in [HexaPDF::Layout::Style]
  have been accessed or set
* [HexaPDF::FontLoader::FromFile] to allow specifying a font file directly
* Configuration option 'page.default_media_orientation' for settig the default
  orientation of new pages
* Convenience methods for getting underline and strikeout properties from fonts
* Configuration option 'style.layers_map' for pre-defining overlay and underlay
  callback objects for [HexaPDF::Layout::Style]
* [HexaPDF::Type::Action] as well as specific implementations for the GoTo,
  GoToR, Launch and URI actions
* [HexaPDF::Type::Annotation] as well as specific implementations for the Text
  Link annotations
* [HexaPDF::Layout::Style::LinkLayer] for easy adding of in-document, URI and
  file links

### Changed

* [HexaPDF::Layout::TextFragment] to support more styling properties
* Cross-reference subsection parsing can handle missing whitespace
* Renamed HexaPDF::Layout::LineFragment to [HexaPDF::Layout::Line]
* Renamed HexaPDF::Layout::TextBox to [HexaPDF::Layout::TextLayouter]
* [HexaPDF::Layout::TextFragment::new] and [HexaPDF::Layout::TextLayouter::new]
  to either take a Style object or style options
* [HexaPDF::Layout::TextLayouter#fit] method signature
* [HexaPDF::Layout::InlineBox] to wrap a generic box
* HexaPDF::Document::Fonts#load to [HexaPDF::Document::Fonts#add] for
  consistency
* [HexaPDF::Document::Pages#add] to allow setting the paper orientation when
  creating new pages
* [HexaPDF::Filter::Predictor] to allow correcting some common problems
  depending on the new configuration option 'filter.predictor.strict'
* Moved configuration options 'encryption.aes', 'encryption.arc4',
  'encryption.filter_map', 'encryption.sub_filter.map', 'filter.map',
  'image_loader' and 'task.map' to the document specific configuration object
* [HexaPDF::Configuration#constantize] can now dig into hierarchical values
* [HexaPDF::Document#wrap] class resolution and configuration option structure
  of 'object.subtype_map'

### Removed

* HexaPDF::Dictionary#to_hash method

### Fixed

* [HexaPDF::Layout::TextLayouter#fit] to split text fragment into parts if the
  fragment doesn't fit on an empty line
* Parsing of PDF files containing a loop with respect to cross-reference tables
* [HexaPDF::Layout::InlineBox] to act as placeholder if no drawing block is
  given
* Undefined method error in [HexaPDF::Content::Canvas] by raising a proper error
* Invalid handling of fonts by [HexaPDF::Content::Canvas] when saving and
  restoring the graphics state
* [HexaPDF::Layout::TextLayouter] so that text fragments don't pollute the
  graphics state
* [HexaPDF::Content::Operator::SetTextRenderingMode] to normalize the value
* [HexaPDF::Stream#stream_source] to always return a decrypted stream
* [HexaPDF::Layout::TextLayouter] to correctly indent all paragraphs, not just
  the first one
* One-off error in [HexaPDF::Filter::LZWDecode]
* [HexaPDF::Configuration#merge] to duplicate array values to avoid unwanted
  modifications
* [HexaPDF::Dictionary#key?] to return false if the key is present but nil
* [HexaPDF::DictionaryFields::FileSpecificationConverter] to convert hash and
  dictionaries
* Field /F definition in [HexaPDF::Stream]


## 0.5.0 - 2017-06-24

### Added

* HexaPDF::Layout::TextBox for easy positioning and layouting of text
* HexaPDF::Layout::LineFragment for single text line layout calculations
* [HexaPDF::Layout::TextShaper] for text shaping functionality
* [HexaPDF::Layout::TextFragment] for basic text metrics calculations
* [HexaPDF::Layout::InlineBox] for fixed size inline graphics
* [HexaPDF::Layout::Style] as container for text and graphics styling properties
* Support for kerning of TrueType fonts via the 'kern' table
* Support for determining the features provided by a font

### Changed

* Handling of invalid glyphs is done using the special
  [HexaPDF::Font::InvalidGlyph] class
* Configuration option 'font.on_missing_glyph'; returns an invalid glyph instead
  of raising an error
* Bounding box of TrueType glyphs without contours is set to `[0, 0, 0, 0]`
* Ligature pairs for AFM fonts are stored like kerning pairs
* Use TrueType configuration option 'font.true_type.unknown_format' in all
  places where applicable
* Allow passing a font object to [HexaPDF::Content::Canvas#font]
* Handle invalid entry in TrueType format 4 cmap subtable encountered in the
  wild gracefully
* Invalid positive descent values in font descriptors are now changed into
  negative ones by the validation feature
* Allow specifying the page media box or a page format when adding a new page
  through [HexaPDF::Document::Pages#add]

### Fixed

* [HexaPDF::Task::Dereference] to work correctly when encountering invalid
  references
* [HexaPDF::Tokenizer] and HexaPDF::Content::Tokenizer to parse a solitary plus
  sign
* Usage of Strings instead of Symbols for AFM font kerning and ligature pairs
* Processing the contents of form XObjects in case they don't have a resources
  dictionary
* Deletion of valid page node when optimizing page trees with the `hexapdf
  optimize` command
* [HexaPDF::Type::FontType0] to always wrap the descendant font even if it is a
  direct object


## 0.4.0 - 2017-03-19

### Added

* [HexaPDF::Type::FontType0] and [HexaPDF::Type::CIDFont] for composite font
  support
* Complete support for CMaps for use with composite fonts; the interface for
  [HexaPDF::Font::CMap] changed to accomodate this
* CLI command `hexapdf batch` for batch execution of a single command for
  multiple input files
* CLI option `--verbose` for more verbose output; also changed the default
  verbosity level to only display warnings and not informational messages
* CLI option `--quiet` for suppressing additional and diagnostic output
* CLI option `--strict` for enabling strict parsing and validation; also changed
  the default from strict to non-strict parsing/validation
* CLI optimization option `--optimize-fonts` for optimizing embedded fonts
* Method `#word_spacing_applicable?` to font types
* Support for marked-content points and sequences in [HexaPDF::Content::Canvas]
* Support for property lists in a page's resource dictionary
* Show file name and size in `hexapdf info` output
* [HexaPDF::Type::Font#font_file] for getting the embedded font file
* [HexaPDF::Font::TrueType::Optimizer] for optimizing TrueType fonts
* Configuration option 'filter.flate_memory' for configuring memory use of the
  [HexaPDF::Filter::FlateDecode] filter
* Method [HexaPDF::Content::Canvas#show_glyphs_only] for faster glyph showing
  without text matrix calculations
* Methods for caching expensive computations of PDF objects
  ([HexaPDF::Document#cache] and others)

### Changed

* Enabled in-place processing of PDF files for all CLI commands
* Show warning instead of exiting when extracting images with `hexapdf images`
  and an image format is not supported
* Handling of character code to Unicode mapping:
  - [HexaPDF::Font::CMap#to_unicode], [HexaPDF::Font::Encoding::Base#unicode]
    and [HexaPDF::Font::Encoding::GlyphList#name_to_unicode] return `nil`
    instead of an empty string
  - Font dictionaries use the new configuration option
    'font.on_missing_unicode_mapping' in their `#to_utf8` method
* [HexaPDF::Configuration#constantize] to raise error if constant is not found
* Extracted TrueType font file building code into new module
  [HexaPDF::Font::TrueType::Builder]
* [HexaPDF::Filter::FlateDecode] filter to use pools of Zlib inflaters and
  deflaters to conserve memory

### Fixed

* Use of wrong glyph IDs for glyph width entries and unicode mapping for subset
  TrueType fonts
* Invalid document reference when importing wrapped direct objects with
  [HexaPDF::Importer]
* Invalid type of /DW key in CIDFont dictionary when embedding TrueType fonts
* Caching problem in [HexaPDF::Document::Fonts] which lead to multiple instances
  of the same font
* Bug in handling of word spacing with respect to offset calculations when
  showing or extracting text
* Incorrect handling of page rotation values in `hexapdf merge`
* Missing handling of certain rotation values in `hexapdf modify`
* Removal of unused pages in `hexapdf modify`
* Handling of invalid page numbers in CLI commands
* Useless multiple extraction of the same image in `hexapdf images`
* Type of /VP entry of [HexaPDF::Type::Page]
* Parsing of inline images that contain the end-of-image marker
* High memory usage due to not closing `Zlib::Stream` objects in
  [HexaPDF::Filter::FlateDecode]


## 0.3.0 - 2017-01-25

### Added

* TrueType font subsetting support
* Image extraction ability to CLI via `hexapdf images` command
* [HexaPDF::Type::Image#write] for writing an image XObject to an IO stream or
  file
* [HexaPDF::Type::Image#info] for getting image properties of an image XObject
* CLI option `--[no-]force` to force overwriting existing files

### Changed

* Refactor `hexapdf modify` command into three individual commands `modify`,
  `merge` and `optimize`
* Rename `hexapdf extract` to `hexapdf files` and the option `--indices` to
  `--extract`
* Show PDF trailer by default with `hexapdf inspect`
* Refactor CLI command classes to use specialized superclass
  [HexaPDF::CLI::Command]
* Optimize parsing of PDF files for better performance and memory efficiency

### Fixed

* Writing of hybrid-reference PDF files - they are written as standard PDF files
  since all current applications should be able to handle PDF 1.5
* Serialization of self-referential, indirect PDF objects
* Performance problem for `hexapdf inspect --pages` when inspecting huge files
* TrueType compound glyph component offset calculation
* Parsing of TrueType data type 'fixed'
* Updating a PDF trailer's ID field when it isn't an array

## 0.2.0 - 2016-11-28

### Added

* PDF file merge ability to `hexapdf modify`, i.e. adding pages from other PDFs
* Page interleaving support to 'hexapdf modify'
* Step values in pages definitions for CLI commands
* Convenience class for working with pages through [HexaPDF::Document#pages]
  with a more Ruby-like interface
* Method [HexaPDF::Type::Form#canvas]
* Method [HexaPDF::Type::Page#index]
* Validation for [HexaPDF::Rectangle] objects
* [HexaPDF::Font::Type1::FontMetrics#weight_class] for returning the numeric
  weight

### Changed

* Refactor document utilities into own classes with a more Ruby-like interface;
  concern fonts, images and files, now accessible through
  [HexaPDF::Document#fonts], [HexaPDF::Document#images] and
  [HexaPDF::Document#files]
* Validate nested collection values in [HexaPDF::Object]
* Allow [HexaPDF::Dictionary#[]] to always unwrap nil values
* Update [HexaPDF::Task::Optimize] to delete unused objects on `:compact`
* Allow [HexaPDF::Type::PageTreeNode#delete_page] to take a page object or a
  page index
* Don't set /EFF key in encryption dictionary
* Better error handling for hexapdf CLI commands
* Show help output when no command is given for `hexapdf` CLI
* Set /FontWeight in [HexaPDF::Font::Type1Wrapper]
* Use kramdown's man page support for the `hexapdf` man page instead of ronn

### Removed

* Remove unneeded parts of TrueType implementation

### Fixed

* Problem with unnamed classes/modules on serialization
* Handle potentially indirect objects correctly in [HexaPDF::Object::deep_copy]
* [HexaPDF::Revisions#merge] for objects that appear in multiple revisions
* Output of `--pages` option of 'hexapdf inspect' command
* Infinite recursion problem in [HexaPDF::Task::Dereference]
* Problem with iteration over images in certain cases
* [HexaPDF::Type::Page#[]] with respect to inherited fields
* Problems with access permissions on encryption
* Encryption routine of standard security handler with respect to owner password
* Invalid check in validation of standard encryption dictionary
* 'hexapdf modify' command to support files with many pages
* Validation of encryption key for encryption revision 6
* Various parts of the API documentation


## 0.1.0 - 2016-10-26

* Initial release
