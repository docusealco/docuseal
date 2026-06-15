# frozen_string_literal: true

class Pdfium
  extend FFI::Library

  LIB_NAME = 'pdfium'

  begin
    ffi_lib case FFI::Platform::OS
            when 'darwin'
              [
                "lib#{LIB_NAME}.dylib",
                '/Applications/LibreOffice.app/Contents/Frameworks/libpdfiumlo.dylib'
              ]
            else
              "lib#{LIB_NAME}.so"
            end
  rescue LoadError => e
    raise "Could not load libpdfium library. Make sure it's installed and in your library path. Error: #{e.message}"
  end

  typedef :pointer, :FPDF_STRING
  typedef :pointer, :FPDF_DOCUMENT
  typedef :pointer, :FPDF_PAGE
  typedef :pointer, :FPDF_BITMAP
  typedef :pointer, :FPDF_FORMHANDLE
  typedef :pointer, :FPDF_TEXTPAGE
  typedef :pointer, :FPDF_PAGEOBJECT
  typedef :pointer, :FPDF_PATHSEGMENT
  typedef :pointer, :FPDF_FONT

  MAX_SIZE = 32_767

  BLANK_TEXT_CODEPOINTS = [0x00, 0x09, 0x0A, 0x0D, 0x20, 0xA0].freeze

  FPDF_ANNOT = 0x01
  FPDF_LCD_TEXT = 0x02
  FPDF_NO_NATIVETEXT = 0x04
  FPDF_GRAYSCALE = 0x08
  FPDF_REVERSE_BYTE_ORDER = 0x10
  FPDF_RENDER_LIMITEDIMAGECACHE = 0x200
  FPDF_RENDER_FORCEHALFTONE = 0x400
  FPDF_PRINTING = 0x800

  TextObject = Struct.new(:content, :x, :y, :w, :h, :font_size) do
    def endx
      @endx ||= x + w
    end

    def endy
      @endy ||= y + h
    end
  end

  TextNode = Struct.new(:content, :x, :y, :w, :h) do
    def endx
      @endx ||= x + w
    end

    def endy
      @endy ||= y + h
    end
  end

  LineNode = Struct.new(:x, :y, :w, :h, :tilt) do
    def endy
      @endy ||= y + h
    end

    def endx
      @endx ||= x + w
    end
  end

  ImageNode = Struct.new(:x, :y, :w, :h) do
    def endx
      @endx ||= x + w
    end

    def endy
      @endy ||= y + h
    end
  end

  # rubocop:disable Naming/ClassAndModuleCamelCase
  class FPDF_LIBRARY_CONFIG < FFI::Struct
    layout :version, :int,
           :m_pUserFontPaths, :pointer,
           :m_pIsolate, :pointer,
           :m_v8EmbedderSlot, :uint,
           :m_pPlatform, :pointer,
           :m_RendererType, :int
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  attach_function :FPDF_InitLibraryWithConfig, [:pointer], :void
  attach_function :FPDF_DestroyLibrary, [], :void

  attach_function :FPDF_LoadDocument, %i[string FPDF_STRING], :FPDF_DOCUMENT
  attach_function :FPDF_LoadMemDocument, %i[pointer int FPDF_STRING], :FPDF_DOCUMENT
  attach_function :FPDF_CloseDocument, [:FPDF_DOCUMENT], :void
  attach_function :FPDF_GetPageCount, [:FPDF_DOCUMENT], :int
  attach_function :FPDF_GetLastError, [], :ulong

  attach_function :FPDF_LoadPage, %i[FPDF_DOCUMENT int], :FPDF_PAGE
  attach_function :FPDF_ClosePage, [:FPDF_PAGE], :void
  attach_function :FPDF_GetPageWidthF, [:FPDF_PAGE], :float
  attach_function :FPDF_GetPageHeightF, [:FPDF_PAGE], :float

  attach_function :FPDFBitmap_Create, %i[int int int], :FPDF_BITMAP
  attach_function :FPDFBitmap_CreateEx, %i[int int int pointer int], :FPDF_BITMAP
  attach_function :FPDFBitmap_Destroy, [:FPDF_BITMAP], :void
  attach_function :FPDFBitmap_GetBuffer, [:FPDF_BITMAP], :pointer
  attach_function :FPDFBitmap_GetWidth, [:FPDF_BITMAP], :int
  attach_function :FPDFBitmap_GetHeight, [:FPDF_BITMAP], :int
  attach_function :FPDFBitmap_GetStride, [:FPDF_BITMAP], :int
  attach_function :FPDFBitmap_GetFormat, [:FPDF_BITMAP], :int
  attach_function :FPDFBitmap_FillRect, %i[FPDF_BITMAP int int int int ulong], :void

  FPDF_BITMAP_GRAY = 1
  FPDF_BITMAP_BGR = 2
  FPDF_BITMAP_BGRX = 3
  FPDF_BITMAP_BGRA = 4

  BITMAP_FORMAT_BANDS = {
    FPDF_BITMAP_GRAY => [:gray, 1],
    FPDF_BITMAP_BGR => [:bgr, 3],
    FPDF_BITMAP_BGRX => [:bgrx, 4],
    FPDF_BITMAP_BGRA => [:bgra, 4]
  }.freeze

  attach_function :FPDF_RenderPageBitmap, %i[FPDF_BITMAP FPDF_PAGE int int int int int int], :void

  attach_function :FPDFText_LoadPage, [:FPDF_PAGE], :FPDF_TEXTPAGE
  attach_function :FPDFText_ClosePage, [:FPDF_TEXTPAGE], :void
  attach_function :FPDFText_CountChars, [:FPDF_TEXTPAGE], :int
  attach_function :FPDFText_GetText, %i[FPDF_TEXTPAGE int int pointer], :int
  attach_function :FPDFText_GetUnicode, %i[FPDF_TEXTPAGE int], :uint
  attach_function :FPDFText_GetCharBox, %i[FPDF_TEXTPAGE int pointer pointer pointer pointer], :int
  attach_function :FPDFText_GetCharOrigin, %i[FPDF_TEXTPAGE int pointer pointer], :int
  attach_function :FPDFText_GetCharIndexAtPos, %i[FPDF_TEXTPAGE double double double double], :int
  attach_function :FPDFText_CountRects, %i[FPDF_TEXTPAGE int int], :int
  attach_function :FPDFText_GetRect, %i[FPDF_TEXTPAGE int pointer pointer pointer pointer], :int
  attach_function :FPDFText_GetFontSize, %i[FPDF_TEXTPAGE int], :double
  attach_function :FPDFText_GetLooseCharBox, %i[FPDF_TEXTPAGE int pointer], :int

  # Page object functions for extracting paths/lines
  attach_function :FPDFPage_CountObjects, [:FPDF_PAGE], :int
  attach_function :FPDFPage_GetObject, %i[FPDF_PAGE int], :FPDF_PAGEOBJECT
  attach_function :FPDFPageObj_GetType, [:FPDF_PAGEOBJECT], :int
  attach_function :FPDFPageObj_GetBounds, %i[FPDF_PAGEOBJECT pointer pointer pointer pointer], :int
  attach_function :FPDFPath_CountSegments, [:FPDF_PAGEOBJECT], :int
  attach_function :FPDFPath_GetPathSegment, %i[FPDF_PAGEOBJECT int], :FPDF_PATHSEGMENT
  attach_function :FPDFPathSegment_GetType, [:FPDF_PATHSEGMENT], :int
  attach_function :FPDFPathSegment_GetPoint, %i[FPDF_PATHSEGMENT pointer pointer], :int

  # Text page object functions (per-run Tj/TJ extraction)
  attach_function :FPDFTextObj_GetText, %i[FPDF_PAGEOBJECT FPDF_TEXTPAGE pointer ulong], :ulong
  attach_function :FPDFTextObj_GetFontSize, %i[FPDF_PAGEOBJECT pointer], :int

  attach_function :FPDFPage_InsertObject, %i[FPDF_PAGE FPDF_PAGEOBJECT], :void
  attach_function :FPDFPage_RemoveObject, %i[FPDF_PAGE FPDF_PAGEOBJECT], :int
  attach_function :FPDFPage_GenerateContent, [:FPDF_PAGE], :int
  attach_function :FPDFPageObj_Destroy, [:FPDF_PAGEOBJECT], :void
  attach_function :FPDFText_GetTextObject, %i[FPDF_TEXTPAGE int], :FPDF_PAGEOBJECT
  attach_function :FPDFTextObj_GetFont, [:FPDF_PAGEOBJECT], :FPDF_FONT
  attach_function :FPDFText_LoadStandardFont, %i[FPDF_DOCUMENT string], :FPDF_FONT
  attach_function :FPDFPageObj_CreateTextObj, %i[FPDF_DOCUMENT FPDF_FONT float], :FPDF_PAGEOBJECT
  attach_function :FPDFText_SetText, %i[FPDF_PAGEOBJECT pointer], :int
  attach_function :FPDFPageObj_GetMatrix, %i[FPDF_PAGEOBJECT pointer], :int
  attach_function :FPDFPageObj_SetMatrix, %i[FPDF_PAGEOBJECT pointer], :int
  attach_function :FPDFPageObj_CreateNewRect, %i[float float float float], :FPDF_PAGEOBJECT
  attach_function :FPDFPageObj_SetFillColor, %i[FPDF_PAGEOBJECT uint uint uint uint], :int
  attach_function :FPDFPath_SetDrawMode, %i[FPDF_PAGEOBJECT int int], :int

  attach_function :FPDFFormObj_CountObjects, [:FPDF_PAGEOBJECT], :int
  attach_function :FPDFFormObj_GetObject, %i[FPDF_PAGEOBJECT ulong], :FPDF_PAGEOBJECT
  attach_function :FPDFFormObj_RemoveObject, %i[FPDF_PAGEOBJECT FPDF_PAGEOBJECT], :int
  attach_function :FPDFPageObj_Transform, %i[FPDF_PAGEOBJECT double double double double double double], :void

  attach_function :FPDFImageObj_GetBitmap, [:FPDF_PAGEOBJECT], :FPDF_BITMAP
  attach_function :FPDFImageObj_LoadJpegFileInline, %i[pointer int FPDF_PAGEOBJECT pointer], :int

  # Page object types
  FPDF_PAGEOBJ_UNKNOWN = 0
  FPDF_PAGEOBJ_TEXT = 1
  FPDF_PAGEOBJ_PATH = 2
  FPDF_PAGEOBJ_IMAGE = 3
  FPDF_PAGEOBJ_SHADING = 4
  FPDF_PAGEOBJ_FORM = 5

  # Path segment types
  FPDF_SEGMENT_UNKNOWN = -1
  FPDF_SEGMENT_LINETO = 0
  FPDF_SEGMENT_BEZIERTO = 1
  FPDF_SEGMENT_MOVETO = 2

  typedef :int, :FPDF_BOOL
  typedef :pointer, :IPDF_JSPLATFORM

  # rubocop:disable Naming/ClassAndModuleCamelCase
  class FPDF_FORMFILLINFO_V2 < FFI::Struct
    layout :version, :int,
           :Release, :pointer,
           :FFI_Invalidate, :pointer,
           :FFI_OutputSelectedRect, :pointer,
           :FFI_SetCursor, :pointer,
           :FFI_SetTimer, :pointer,
           :FFI_KillTimer, :pointer,
           :FFI_GetLocalTime, :pointer,
           :FFI_OnChange, :pointer,
           :FFI_GetPage, :pointer,
           :FFI_GetCurrentPage, :pointer,
           :FFI_GetRotation, :pointer,
           :FFI_ExecuteNamedAction, :pointer,
           :FFI_SetTextFieldFocus, :pointer,
           :FFI_DoURIAction, :pointer,
           :FFI_DoGoToAction, :pointer,
           :m_pJsPlatform, :IPDF_JSPLATFORM,
           :xfa_disabled, :FPDF_BOOL,
           :FFI_DisplayCaret, :pointer,
           :FFI_GetCurrentPageIndex, :pointer,
           :FFI_SetCurrentPage, :pointer,
           :FFI_GotoURL, :pointer,
           :FFI_GetPageViewRect, :pointer,
           :FFI_PageEvent, :pointer,
           :FFI_PopupMenu, :pointer,
           :FFI_OpenFile, :pointer,
           :FFI_EmailTo, :pointer,
           :FFI_UploadTo, :pointer,
           :FFI_GetPlatform, :pointer,
           :FFI_GetLanguage, :pointer,
           :FFI_DownloadFromURL, :pointer,
           :FFI_PostRequestURL, :pointer,
           :FFI_PutRequestURL, :pointer,
           :FFI_OnFocusChange, :pointer,
           :FFI_DoURIActionWithKeyboardModifier, :pointer
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  attach_function :FPDFDOC_InitFormFillEnvironment, %i[FPDF_DOCUMENT pointer], :FPDF_FORMHANDLE
  attach_function :FPDFDOC_ExitFormFillEnvironment, [:FPDF_FORMHANDLE], :void
  attach_function :FPDF_FFLDraw, %i[FPDF_FORMHANDLE FPDF_BITMAP FPDF_PAGE int int int int int int], :void

  attach_function :FPDFPage_Flatten, %i[FPDF_PAGE int], :int

  FLAT_NORMALDISPLAY = 0
  FLAT_PRINT = 1

  FLATTEN_FAIL = 0
  FLATTEN_SUCCESS = 1
  FLATTEN_NOTHINGTODO = 2

  # rubocop:disable Naming/ClassAndModuleCamelCase
  class FS_MATRIX < FFI::Struct
    layout :a, :float,
           :b, :float,
           :c, :float,
           :d, :float,
           :e, :float,
           :f, :float
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  attach_function :FPDFPage_GetRotation, [:FPDF_PAGE], :int
  attach_function :FPDFPage_SetRotation, %i[FPDF_PAGE int], :void
  attach_function :FPDFPage_TransFormWithClip, %i[FPDF_PAGE pointer pointer], :int
  attach_function :FPDFPage_TransformAnnots, %i[FPDF_PAGE double double double double double double], :void
  attach_function :FPDFPage_GetMediaBox, %i[FPDF_PAGE pointer pointer pointer pointer], :int
  attach_function :FPDFPage_SetMediaBox, %i[FPDF_PAGE float float float float], :void
  attach_function :FPDFPage_GetCropBox, %i[FPDF_PAGE pointer pointer pointer pointer], :int
  attach_function :FPDFPage_SetCropBox, %i[FPDF_PAGE float float float float], :void
  attach_function :FPDFPage_GetBleedBox, %i[FPDF_PAGE pointer pointer pointer pointer], :int
  attach_function :FPDFPage_SetBleedBox, %i[FPDF_PAGE float float float float], :void
  attach_function :FPDFPage_GetTrimBox, %i[FPDF_PAGE pointer pointer pointer pointer], :int
  attach_function :FPDFPage_SetTrimBox, %i[FPDF_PAGE float float float float], :void
  attach_function :FPDFPage_GetArtBox, %i[FPDF_PAGE pointer pointer pointer pointer], :int
  attach_function :FPDFPage_SetArtBox, %i[FPDF_PAGE float float float float], :void

  PAGE_BOX_ACCESSORS = [
    %i[FPDFPage_GetMediaBox FPDFPage_SetMediaBox],
    %i[FPDFPage_GetCropBox FPDFPage_SetCropBox],
    %i[FPDFPage_GetBleedBox FPDFPage_SetBleedBox],
    %i[FPDFPage_GetTrimBox FPDFPage_SetTrimBox],
    %i[FPDFPage_GetArtBox FPDFPage_SetArtBox]
  ].freeze

  # rubocop:disable Naming/ClassAndModuleCamelCase
  class FPDF_FILEWRITE < FFI::Struct
    layout :version, :int,
           :WriteBlock, :pointer
  end

  class FPDF_FILEACCESS < FFI::Struct
    layout :m_FileLen, :ulong,
           :m_GetBlock, :pointer,
           :m_Param, :pointer
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  attach_function :FPDF_SaveAsCopy, %i[FPDF_DOCUMENT pointer ulong], :int

  FPDF_INCREMENTAL = 1
  FPDF_NO_INCREMENTAL = 2
  FPDF_REMOVE_SECURITY = 3

  attach_function :FPDF_CreateNewDocument, [], :FPDF_DOCUMENT

  begin
    attach_function :FPDF_ImportPages, %i[FPDF_DOCUMENT FPDF_DOCUMENT string int], :int
  rescue FFI::NotFoundError
    define_singleton_method(:FPDF_ImportPages) { |*| raise PdfiumError, 'FPDF_ImportPages is not available' } # rubocop:disable Naming/MethodName
  end

  begin
    attach_function :FPDF_RemoveOrphanObjects, [:FPDF_DOCUMENT], :int
  rescue FFI::NotFoundError
    define_singleton_method(:FPDF_RemoveOrphanObjects) { |*| -1 } # rubocop:disable Naming/MethodName
  end

  FPDF_ERR_SUCCESS = 0
  FPDF_ERR_UNKNOWN = 1
  FPDF_ERR_FILE = 2
  FPDF_ERR_FORMAT = 3
  FPDF_ERR_PASSWORD = 4
  FPDF_ERR_SECURITY = 5
  FPDF_ERR_PAGE = 6

  PDFIUM_ERRORS = {
    FPDF_ERR_SUCCESS => 'Success',
    FPDF_ERR_UNKNOWN => 'Unknown error',
    FPDF_ERR_FILE => 'Error open file',
    FPDF_ERR_FORMAT => 'Invalid format',
    FPDF_ERR_PASSWORD => 'Incorrect password',
    FPDF_ERR_SECURITY => 'Security scheme error',
    FPDF_ERR_PAGE => 'Page not found'
  }.freeze

  class PdfiumError < StandardError; end

  def self.error_message(code)
    PDFIUM_ERRORS[code] || "Unknown error code: #{code}"
  end

  def self.with_instance(instance = nil)
    yield instance
  end

  def self.check_last_error(context_message = 'PDFium operation failed')
    error_code = FPDF_GetLastError()

    return if error_code == FPDF_ERR_SUCCESS

    raise PdfiumError, "#{context_message}: #{error_message(error_code)} (Code: #{error_code})"
  end

  # rubocop:disable Metrics
  class Document
    attr_reader :document_ptr, :form_handle

    def initialize(document_ptr, source_buffer = nil)
      raise ArgumentError, 'document_ptr cannot be nil' if document_ptr.nil? || document_ptr.null?

      @document_ptr = document_ptr

      @pages = {}
      @closed = false
      @source_buffer = source_buffer
      @form_handle = FFI::Pointer::NULL
      @form_fill_info_mem = FFI::Pointer::NULL
      @presave_hooks = {}

      init_form_fill_environment
    end

    def init_form_fill_environment
      return if @document_ptr.null?

      @form_fill_info_mem = FFI::MemoryPointer.new(FPDF_FORMFILLINFO_V2.size)

      form_fill_info_struct = FPDF_FORMFILLINFO_V2.new(@form_fill_info_mem)
      form_fill_info_struct[:version] = 2

      @form_handle = Pdfium.FPDFDOC_InitFormFillEnvironment(@document_ptr, @form_fill_info_mem)
    end

    def page_count
      @page_count ||= Pdfium.FPDF_GetPageCount(@document_ptr)
    end

    def import_pages(src_doc, pages: nil, index: nil)
      ensure_not_closed!

      result = Pdfium.FPDF_ImportPages(@document_ptr, src_doc.document_ptr, pages, index || page_count)

      raise PdfiumError, 'Failed to import pages' if result.zero?

      @page_count = nil

      result
    end

    def self.create
      doc_ptr = Pdfium.FPDF_CreateNewDocument()

      if doc_ptr.null?
        Pdfium.check_last_error('Failed to create new document')

        raise PdfiumError, 'Failed to create new document'
      end

      doc = new(doc_ptr)

      return doc unless block_given?

      begin
        yield doc
      ensure
        doc.close
      end
    end

    def self.open_file(file_path, password = nil)
      doc_ptr = Pdfium.FPDF_LoadDocument(file_path, password)

      if doc_ptr.null?
        Pdfium.check_last_error("Failed to load document from file '#{file_path}'")

        raise PdfiumError, "Failed to load document from file '#{file_path}', pointer is NULL."
      end

      doc = new(doc_ptr)

      return doc unless block_given?

      begin
        yield doc
      ensure
        doc.close
      end
    end

    def self.open_bytes(bytes, password = nil)
      buffer = FFI::MemoryPointer.new(:char, bytes.bytesize)
      buffer.put_bytes(0, bytes)

      doc_ptr = Pdfium.FPDF_LoadMemDocument(buffer, bytes.bytesize, password)

      if doc_ptr.null?
        Pdfium.check_last_error('Failed to load document from memory')

        raise PdfiumError, 'Failed to load document from memory, pointer is NULL.'
      end

      doc = new(doc_ptr, buffer)

      return doc unless block_given?

      begin
        yield doc
      ensure
        doc.close
      end
    end

    def closed?
      @closed
    end

    def ensure_not_closed!
      raise PdfiumError, 'Document is closed.' if closed?
    end

    def get_page(page_index)
      ensure_not_closed!

      unless page_index.is_a?(Integer) && page_index >= 0 && page_index < page_count
        raise PdfiumError, "Page index #{page_index} out of range (0..#{page_count - 1})"
      end

      @pages[page_index] ||= Page.new(self, page_index)
    end

    def save(io, flags: Pdfium::FPDF_NO_INCREMENTAL)
      ensure_not_closed!

      run_presave_hooks

      file_write_mem = FFI::MemoryPointer.new(FPDF_FILEWRITE.size)

      file_write_struct = FPDF_FILEWRITE.new(file_write_mem)
      file_write_struct[:version] = 1
      file_write_struct[:WriteBlock] = FFI::Function.new(:int, %i[pointer pointer ulong]) do |_, data, size|
        io.write(data.read_bytes(size))

        1
      end

      result = Pdfium.FPDF_SaveAsCopy(@document_ptr, file_write_mem, flags)

      if result.zero?
        Pdfium.check_last_error('Failed to save document')

        raise PdfiumError, 'Failed to save document'
      end

      io
    end

    def cleanup
      ensure_not_closed!

      Pdfium.FPDF_RemoveOrphanObjects(@document_ptr)
    end

    def standard_font
      @standard_font ||= Pdfium.FPDFText_LoadStandardFont(@document_ptr, 'Helvetica')
    end

    def add_presave_hook(key, &block)
      @presave_hooks[key] ||= block
    end

    def run_presave_hooks
      @presave_hooks.each_value(&:call)
    end

    def close
      return if closed?

      @pages.each_value { |page| page.close unless page.closed? }
      @pages.clear

      unless @form_handle.null?
        Pdfium.FPDFDOC_ExitFormFillEnvironment(@form_handle)

        @form_handle = FFI::Pointer::NULL
      end

      if @form_fill_info_mem && !@form_fill_info_mem.null?
        @form_fill_info_mem.free
        @form_fill_info_mem = FFI::Pointer::NULL
      end

      Pdfium.FPDF_CloseDocument(@document_ptr) unless @document_ptr.null?

      @document_ptr = FFI::Pointer::NULL
      @source_buffer = nil

      @closed = true
    end
  end

  class Page
    attr_reader :document, :page_index, :page_ptr

    def initialize(document, page_index)
      raise ArgumentError, 'Document object is required' unless document.is_a?(Pdfium::Document)

      @document = document
      @document.ensure_not_closed!

      @page_index = page_index

      @page_ptr = Pdfium.FPDF_LoadPage(document.document_ptr, page_index)

      if @page_ptr.null?
        Pdfium.check_last_error("Failed to load page #{page_index}")

        raise PdfiumError, "Failed to load page #{page_index}, pointer is NULL."
      end

      @closed = false
    end

    def width
      @width ||= Pdfium.FPDF_GetPageWidthF(@page_ptr)
    end

    def height
      @height ||= Pdfium.FPDF_GetPageHeightF(@page_ptr)
    end

    def rotation
      @rotation ||= Pdfium.FPDFPage_GetRotation(@page_ptr)
    end

    def rotation=(value)
      Pdfium.FPDFPage_SetRotation(@page_ptr, value)

      @rotation = value
    end

    def closed?
      @closed
    end

    delegate :form_handle, to: :@document

    def ensure_not_closed!
      raise PdfiumError, 'Page is closed.' if closed?

      @document.ensure_not_closed!
    end

    def render_to_bitmap(width: nil, height: nil, scale: nil, background_color: 0xFFFFFFFF,
                         flags: FPDF_ANNOT | FPDF_LCD_TEXT | FPDF_NO_NATIVETEXT | FPDF_REVERSE_BYTE_ORDER)
      ensure_not_closed!

      render_width, render_height = calculate_render_dimensions(width, height, scale)

      bitmap_ptr = Pdfium.FPDFBitmap_Create(render_width, render_height, 1)

      if bitmap_ptr.null?
        Pdfium.check_last_error('Failed to create bitmap (potential pre-existing error)')

        raise PdfiumError, 'Failed to create bitmap (FPDFBitmap_Create returned NULL)'
      end

      Pdfium.FPDFBitmap_FillRect(bitmap_ptr, 0, 0, render_width, render_height, background_color)

      Pdfium.FPDF_RenderPageBitmap(bitmap_ptr, page_ptr, 0, 0, render_width, render_height, 0, flags)

      unless form_handle.null?
        Pdfium.FPDF_FFLDraw(form_handle, bitmap_ptr, page_ptr, 0, 0, render_width, render_height, 0, flags)
      end

      buffer_ptr = Pdfium.FPDFBitmap_GetBuffer(bitmap_ptr)
      stride = Pdfium.FPDFBitmap_GetStride(bitmap_ptr)

      bitmap_data = buffer_ptr.read_bytes(stride * render_height)

      [bitmap_data, render_width, render_height]
    ensure
      Pdfium.FPDFBitmap_Destroy(bitmap_ptr) if bitmap_ptr && !bitmap_ptr.null?
    end

    def text
      return @text if @text

      ensure_not_closed!

      text_page = Pdfium.FPDFText_LoadPage(page_ptr)

      if text_page.null?
        Pdfium.check_last_error("Failed to load text page #{page_index}")

        raise PdfiumError, "Failed to load text page #{page_index}, pointer is NULL."
      end

      char_count = Pdfium.FPDFText_CountChars(text_page)

      return @text = '' if char_count.zero?

      buffer_char_capacity = char_count + 1

      buffer = FFI::MemoryPointer.new(:uint16, buffer_char_capacity)

      chars_written = Pdfium.FPDFText_GetText(text_page, 0, buffer_char_capacity, buffer)

      if chars_written <= 0
        Pdfium.check_last_error("Failed to extract text from page #{page_index}")

        return @text = ''
      end

      @text = buffer.read_bytes((chars_written * 2) - 2).force_encoding('UTF-16LE').encode('UTF-8')
    ensure
      Pdfium.FPDFText_ClosePage(text_page) if text_page && !text_page.null?
    end

    def text_nodes
      return @text_nodes if @text_nodes

      text_page = Pdfium.FPDFText_LoadPage(page_ptr)
      char_count = Pdfium.FPDFText_CountChars(text_page)

      @text_nodes = []

      return @text_nodes if char_count.zero?

      loose_rect_ptr = FFI::MemoryPointer.new(:float, 4)

      i = 0

      loop do
        break unless i < char_count

        box_index = i

        codepoint = Pdfium.FPDFText_GetUnicode(text_page, i)

        if codepoint.between?(0xD800, 0xDBFF) && (i + 1 < char_count)
          codepoint2 = Pdfium.FPDFText_GetUnicode(text_page, i + 1)

          if codepoint2.between?(0xDC00, 0xDFFF)
            codepoint = 0x10000 + ((codepoint - 0xD800) << 10) + (codepoint2 - 0xDC00)

            i += 1
          end
        end

        char = codepoint.chr(Encoding::UTF_8)

        next if Pdfium.FPDFText_GetLooseCharBox(text_page, box_index, loose_rect_ptr).zero?

        loose_left, loose_top, loose_right, loose_bottom = loose_rect_ptr.read_array_of_float(4)

        next if loose_right <= loose_left || loose_top <= loose_bottom

        x = loose_left / width
        y = (height - loose_top) / height
        node_width = (loose_right - loose_left) / width
        node_height = (loose_top - loose_bottom) / height

        @text_nodes << TextNode.new(char, x, y, node_width, node_height)
      ensure
        i += 1
      end

      y_threshold = 4.0 / width

      @text_nodes = @text_nodes.sort do |a, b|
        (a.endy - b.endy).abs < y_threshold ? a.x <=> b.x : a.endy <=> b.endy
      end
    ensure
      Pdfium.FPDFText_ClosePage(text_page) if text_page && !text_page.null?
    end

    def redact(rects, &image_processor)
      ensure_not_closed!

      flatten
      rotate

      rect_bounds = rects.map do |rect|
        left = rect['x'].to_f * width
        top = height - (rect['y'].to_f * height)

        [left, top - (rect['h'].to_f * height), left + (rect['w'].to_f * width), top, rect['color']]
      end

      unwrap_form_objects(rect_bounds)

      remove_redacted_chars(rect_bounds)
      redact_image_objects(rect_bounds, &image_processor) if image_processor
      draw_redaction_rects(rect_bounds)

      raise PdfiumError, 'Failed to generate page content' if Pdfium.FPDFPage_GenerateContent(@page_ptr).zero?

      remove_blank_text_objects

      @document.add_presave_hook(:cleanup) { @document.cleanup }

      reset_text_memoization

      nil
    end

    def remove_blank_text_objects
      text_page = Pdfium.FPDFText_LoadPage(@page_ptr)

      return if text_page.null?

      blanks = []

      begin
        Pdfium.FPDFPage_CountObjects(@page_ptr).times do |index|
          object_ptr = Pdfium.FPDFPage_GetObject(@page_ptr, index)

          next if object_ptr.null?
          next unless Pdfium.FPDFPageObj_GetType(object_ptr) == Pdfium::FPDF_PAGEOBJ_TEXT

          needed_bytes = Pdfium.FPDFTextObj_GetText(object_ptr, text_page, FFI::Pointer::NULL, 0)

          next if needed_bytes < 2

          buffer = FFI::MemoryPointer.new(:uint8, needed_bytes)
          written = Pdfium.FPDFTextObj_GetText(object_ptr, text_page, buffer, needed_bytes)

          next if written < 2

          content = buffer.read_bytes(written - 2).force_encoding('UTF-16LE').encode('UTF-8')

          blanks << object_ptr if content.codepoints.all? { |code| BLANK_TEXT_CODEPOINTS.include?(code) }
        end
      ensure
        Pdfium.FPDFText_ClosePage(text_page)
      end

      return if blanks.empty?

      blanks.each { |object_ptr| remove_page_object(object_ptr) }

      Pdfium.FPDFPage_GenerateContent(@page_ptr)
    end

    def remove_redacted_chars(rect_bounds)
      text_page = Pdfium.FPDFText_LoadPage(@page_ptr)

      raise PdfiumError, 'Failed to load text page' if text_page.null?

      begin
        text_objects_chars = collect_text_objects_chars(text_page, rect_bounds)
      ensure
        Pdfium.FPDFText_ClosePage(text_page)
      end

      text_objects_chars.each_value do |entry|
        next if entry[:chars].none? { |char| char[:redacted] }

        rebuild_text_object_survivors(entry) unless entry[:chars].all? { |char| char[:redacted] }

        remove_page_object(entry[:ptr])
      end
    end

    def unwrap_form_objects(rect_bounds = nil)
      unwrapped = false
      matrix_ptr = FFI::MemoryPointer.new(:float, 6)

      loop do
        form_ptr = find_form_object(rect_bounds)

        break if form_ptr.nil?

        unwrapped = true

        matrix =
          if Pdfium.FPDFPageObj_GetMatrix(form_ptr, matrix_ptr).zero?
            [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]
          else
            matrix_ptr.read_array_of_float(6)
          end

        (Pdfium.FPDFFormObj_CountObjects(form_ptr) - 1).downto(0) do |index|
          child_ptr = Pdfium.FPDFFormObj_GetObject(form_ptr, index)

          next if child_ptr.null?

          raise PdfiumError, 'Failed to unwrap form object' if Pdfium.FPDFFormObj_RemoveObject(form_ptr,
                                                                                               child_ptr).zero?

          Pdfium.FPDFPageObj_Transform(child_ptr, *matrix)
          Pdfium.FPDFPage_InsertObject(@page_ptr, child_ptr)
        end

        remove_page_object(form_ptr)
      end

      Pdfium.FPDFPage_GenerateContent(@page_ptr) if unwrapped

      reset_text_memoization if unwrapped
    end

    def find_form_object(rect_bounds = nil)
      bounds_ptrs = Array.new(4) { FFI::MemoryPointer.new(:float) }

      Pdfium.FPDFPage_CountObjects(@page_ptr).times do |index|
        object_ptr = Pdfium.FPDFPage_GetObject(@page_ptr, index)

        next if object_ptr.null?
        next unless Pdfium.FPDFPageObj_GetType(object_ptr) == FPDF_PAGEOBJ_FORM

        return object_ptr if rect_bounds.nil?

        next if Pdfium.FPDFPageObj_GetBounds(object_ptr, *bounds_ptrs).zero?

        left, bottom, right, top = bounds_ptrs.map(&:read_float)

        intersects = rect_bounds.any? do |rl, rb, rr, rt|
          left < rr && right > rl && bottom < rt && top > rb
        end

        return object_ptr if intersects
      end

      nil
    end

    def collect_text_objects_chars(text_page, rect_bounds)
      char_count = Pdfium.FPDFText_CountChars(text_page)

      left_ptr, right_ptr, bottom_ptr, top_ptr, origin_x_ptr, origin_y_ptr =
        Array.new(6) { FFI::MemoryPointer.new(:double) }

      text_objects_chars = {}

      index = 0

      while index < char_count
        object_ptr = Pdfium.FPDFText_GetTextObject(text_page, index)
        codepoint = Pdfium.FPDFText_GetUnicode(text_page, index)
        box_index = index

        if codepoint.between?(0xD800, 0xDBFF) && (index + 1 < char_count)
          codepoint2 = Pdfium.FPDFText_GetUnicode(text_page, index + 1)

          if codepoint2.between?(0xDC00, 0xDFFF)
            codepoint = 0x10000 + ((codepoint - 0xD800) << 10) + (codepoint2 - 0xDC00)

            index += 1
          end
        end

        index += 1

        next if object_ptr.null?
        next if Pdfium.FPDFText_GetCharBox(text_page, box_index, left_ptr, right_ptr, bottom_ptr, top_ptr).zero?

        center_x = (left_ptr.read_double + right_ptr.read_double) / 2.0
        center_y = (bottom_ptr.read_double + top_ptr.read_double) / 2.0

        Pdfium.FPDFText_GetCharOrigin(text_page, box_index, origin_x_ptr, origin_y_ptr)

        entry = text_objects_chars[object_ptr.address] ||= { ptr: object_ptr, chars: [] }

        entry[:chars] << {
          codepoint:,
          origin_x: origin_x_ptr.read_double,
          origin_y: origin_y_ptr.read_double,
          redacted: rect_bounds.any? do |left, bottom, right, top|
            center_x.between?(left, right) && center_y.between?(bottom, top)
          end
        }
      end

      text_objects_chars
    end

    def rebuild_text_object_survivors(entry)
      font_ptr = @document.standard_font

      font_size_ptr = FFI::MemoryPointer.new(:float)
      font_size = Pdfium.FPDFTextObj_GetFontSize(entry[:ptr], font_size_ptr).zero? ? 12.0 : font_size_ptr.read_float

      matrix_ptr = FFI::MemoryPointer.new(:float, 6)

      matrix =
        if Pdfium.FPDFPageObj_GetMatrix(entry[:ptr], matrix_ptr).zero?
          [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]
        else
          matrix_ptr.read_array_of_float(6)
        end

      entry[:chars].reject { |char| char[:redacted] }.each do |char|
        new_object = Pdfium.FPDFPageObj_CreateTextObj(@document.document_ptr, font_ptr, font_size)

        next if new_object.null?

        text_data = [char[:codepoint]].pack('U').encode(Encoding::UTF_16LE).b + "\x00\x00".b

        text_buffer = FFI::MemoryPointer.new(:char, text_data.bytesize)
        text_buffer.put_bytes(0, text_data)

        if Pdfium.FPDFText_SetText(new_object, text_buffer).zero?
          Pdfium.FPDFPageObj_Destroy(new_object)

          next
        end

        matrix_ptr.write_array_of_float([matrix[0], matrix[1], matrix[2], matrix[3],
                                         char[:origin_x], char[:origin_y]])

        Pdfium.FPDFPageObj_SetMatrix(new_object, matrix_ptr)
        Pdfium.FPDFPage_InsertObject(@page_ptr, new_object)
      end
    end

    def reset_text_memoization
      remove_instance_variable(:@text) if defined?(@text)

      @text_nodes = nil
      @text_objects = nil
      @line_nodes = nil
    end

    def remove_page_object(object_ptr)
      raise PdfiumError, 'Failed to remove page object' if Pdfium.FPDFPage_RemoveObject(@page_ptr, object_ptr).zero?

      Pdfium.FPDFPageObj_Destroy(object_ptr)
    end

    def draw_redaction_rects(rect_bounds)
      rect_bounds.each do |left, bottom, right, top, color|
        next if color == 'white'

        rect_object = Pdfium.FPDFPageObj_CreateNewRect(left, bottom, right - left, top - bottom)

        raise PdfiumError, 'Failed to create redaction rect' if rect_object.null?

        Pdfium.FPDFPageObj_SetFillColor(rect_object, 0, 0, 0, 255)
        Pdfium.FPDFPath_SetDrawMode(rect_object, 1, 0)
        Pdfium.FPDFPage_InsertObject(@page_ptr, rect_object)
      end
    end

    def redact_image_objects(rect_bounds)
      bounds_ptrs = Array.new(4) { FFI::MemoryPointer.new(:float) }
      matrix_ptr = FFI::MemoryPointer.new(:float, 6)

      Pdfium.FPDFPage_CountObjects(@page_ptr).times do |index|
        object_ptr = Pdfium.FPDFPage_GetObject(@page_ptr, index)

        next if object_ptr.null?
        next unless Pdfium.FPDFPageObj_GetType(object_ptr) == FPDF_PAGEOBJ_IMAGE
        next if Pdfium.FPDFPageObj_GetBounds(object_ptr, *bounds_ptrs).zero?

        obj_left, obj_bottom, obj_right, obj_top = bounds_ptrs.map(&:read_float)

        overlapping = rect_bounds.select do |left, bottom, right, top|
          obj_left < right && obj_right > left && obj_bottom < top && obj_top > bottom
        end

        next if overlapping.empty?

        raise PdfiumError, 'Failed to get image matrix' if Pdfium.FPDFPageObj_GetMatrix(object_ptr, matrix_ptr).zero?

        matrix = matrix_ptr.read_array_of_float(6)

        next if ((matrix[0] * matrix[3]) - (matrix[1] * matrix[2])).abs < 1e-9

        bitmap = extract_image_bitmap(object_ptr)
        pixel_rects = image_pixel_rects(matrix, bitmap[:width], bitmap[:height], overlapping)

        next if pixel_rects.empty?

        jpeg = yield(bitmap, pixel_rects)

        load_image_jpeg(object_ptr, jpeg) if jpeg
      end
    end

    def extract_image_bitmap(object_ptr)
      bitmap_ptr = Pdfium.FPDFImageObj_GetBitmap(object_ptr)

      raise PdfiumError, 'Failed to get image bitmap' if bitmap_ptr.nil? || bitmap_ptr.null?

      format, bands = BITMAP_FORMAT_BANDS[Pdfium.FPDFBitmap_GetFormat(bitmap_ptr)]

      raise PdfiumError, 'Unsupported image bitmap format' if format.nil?

      image_width = Pdfium.FPDFBitmap_GetWidth(bitmap_ptr)
      image_height = Pdfium.FPDFBitmap_GetHeight(bitmap_ptr)
      stride = Pdfium.FPDFBitmap_GetStride(bitmap_ptr)

      data = Pdfium.FPDFBitmap_GetBuffer(bitmap_ptr).read_bytes(stride * image_height)

      row_size = image_width * bands

      data = Array.new(image_height) { |row| data.byteslice(row * stride, row_size) }.join if stride != row_size

      { data:, width: image_width, height: image_height, bands:, format: }
    ensure
      Pdfium.FPDFBitmap_Destroy(bitmap_ptr) if bitmap_ptr && !bitmap_ptr.null?
    end

    def image_pixel_rects(matrix, image_width, image_height, rect_bounds)
      a, b, c, d, e, f = matrix
      det = (a * d) - (b * c)

      rect_bounds.filter_map do |left, bottom, right, top, color|
        corners = [[left, bottom], [right, bottom], [left, top], [right, top]].map do |x, y|
          u = ((d * (x - e)) - (c * (y - f))) / det
          v = ((a * (y - f)) - (b * (x - e))) / det

          [u * image_width, (1 - v) * image_height]
        end

        xs = corners.map(&:first)
        ys = corners.map(&:last)

        next if xs.max <= 0 || xs.min >= image_width || ys.max <= 0 || ys.min >= image_height

        px_left = xs.min.floor.clamp(0, image_width - 1)
        px_top = ys.min.floor.clamp(0, image_height - 1)

        [px_left, px_top,
         (xs.max.ceil - px_left).clamp(1, image_width - px_left),
         (ys.max.ceil - px_top).clamp(1, image_height - px_top),
         color]
      end
    end

    def load_image_jpeg(object_ptr, jpeg)
      get_block = FFI::Function.new(:int, %i[pointer ulong pointer ulong]) do |_param, position, out, size|
        out.put_bytes(0, jpeg.byteslice(position, size) || ''.b)

        1
      end

      file_access = Pdfium::FPDF_FILEACCESS.new
      file_access[:m_FileLen] = jpeg.bytesize
      file_access[:m_GetBlock] = get_block
      file_access[:m_Param] = FFI::Pointer::NULL

      pages_ptr = FFI::MemoryPointer.new(:pointer, 1)
      pages_ptr.write_pointer(@page_ptr)

      result = Pdfium.FPDFImageObj_LoadJpegFileInline(pages_ptr, 1, object_ptr, file_access)

      raise PdfiumError, 'Failed to load redacted image' if result.zero?
    end

    def text_objects
      return @text_objects if @text_objects

      ensure_not_closed!

      @text_objects = []

      object_count = Pdfium.FPDFPage_CountObjects(page_ptr)

      return @text_objects if object_count.zero?

      text_page = Pdfium.FPDFText_LoadPage(page_ptr)

      if text_page.null?
        Pdfium.check_last_error("Failed to load text page #{page_index}")

        raise PdfiumError, "Failed to load text page #{page_index}, pointer is NULL."
      end

      left_ptr = FFI::MemoryPointer.new(:float)
      bottom_ptr = FFI::MemoryPointer.new(:float)
      right_ptr = FFI::MemoryPointer.new(:float)
      top_ptr = FFI::MemoryPointer.new(:float)
      font_size_ptr = FFI::MemoryPointer.new(:float)

      object_count.times do |i|
        page_object = Pdfium.FPDFPage_GetObject(page_ptr, i)

        next if page_object.null?

        next unless Pdfium.FPDFPageObj_GetType(page_object) == Pdfium::FPDF_PAGEOBJ_TEXT

        needed_bytes = Pdfium.FPDFTextObj_GetText(page_object, text_page, FFI::Pointer::NULL, 0)

        next if needed_bytes < 4

        buffer = FFI::MemoryPointer.new(:uint8, needed_bytes)

        written = Pdfium.FPDFTextObj_GetText(page_object, text_page, buffer, needed_bytes)

        next if written < 4

        content = buffer.read_bytes(written - 2).force_encoding('UTF-16LE').encode('UTF-8')

        next if content.empty?

        next if Pdfium.FPDFPageObj_GetBounds(page_object, left_ptr, bottom_ptr, right_ptr, top_ptr).zero?

        obj_left = left_ptr.read_float
        obj_bottom = bottom_ptr.read_float
        obj_right = right_ptr.read_float
        obj_top = top_ptr.read_float

        obj_width = obj_right - obj_left
        obj_height = obj_top - obj_bottom

        next if obj_width <= 0 || obj_height <= 0

        font_size =
          if Pdfium.FPDFTextObj_GetFontSize(page_object, font_size_ptr) == 0
            obj_height
          else
            font_size_ptr.read_float
          end

        font_size = 8 if font_size == 1

        norm_x = obj_left / width
        norm_y = (height - obj_top) / height
        norm_w = obj_width / width
        norm_h = obj_height / height

        @text_objects << TextObject.new(content, norm_x, norm_y, norm_w, norm_h, font_size)
      end

      y_threshold = 4.0 / width

      @text_objects = @text_objects.sort do |a, b|
        (a.endy - b.endy).abs < y_threshold ? a.x <=> b.x : a.endy <=> b.endy
      end
    ensure
      Pdfium.FPDFText_ClosePage(text_page) if text_page && !text_page.null?
    end

    def line_nodes
      return @line_nodes if @line_nodes

      ensure_not_closed!

      @line_nodes = []

      object_count = Pdfium.FPDFPage_CountObjects(page_ptr)

      return @line_nodes if object_count.zero?

      object_count.times do |i|
        page_object = Pdfium.FPDFPage_GetObject(page_ptr, i)

        next if page_object.null?

        obj_type = Pdfium.FPDFPageObj_GetType(page_object)

        next unless obj_type == Pdfium::FPDF_PAGEOBJ_PATH

        left_ptr = FFI::MemoryPointer.new(:float)
        bottom_ptr = FFI::MemoryPointer.new(:float)
        right_ptr = FFI::MemoryPointer.new(:float)
        top_ptr = FFI::MemoryPointer.new(:float)

        Pdfium.FPDFPageObj_GetBounds(page_object, left_ptr, bottom_ptr, right_ptr, top_ptr)

        obj_left = left_ptr.read_float
        obj_bottom = bottom_ptr.read_float
        obj_right = right_ptr.read_float
        obj_top = top_ptr.read_float

        obj_width = obj_right - obj_left
        obj_height = obj_top - obj_bottom

        next if obj_width < 1 && obj_height < 1

        segment_count = Pdfium.FPDFPath_CountSegments(page_object)

        next if segment_count < 2

        next unless segment_count <= 10 && (obj_height < 10 || obj_width < 10)

        if obj_width > obj_height && obj_height < 10
          tilt = 0
        elsif obj_height > obj_width && obj_width < 10
          tilt = 90
        else
          next
        end

        x = obj_left
        y = obj_bottom
        w = obj_width
        h = obj_height

        norm_x = x / width
        norm_y = (height - y - h) / height
        norm_w = w / width
        norm_h = h / height

        @line_nodes << LineNode.new(norm_x, norm_y, norm_w, norm_h, tilt)
      end

      @line_nodes = @line_nodes.sort { |a, b| a.endy == b.endy ? a.x <=> b.x : a.endy <=> b.endy }
    end

    def image_nodes
      ensure_not_closed!

      nodes = []

      bounds_ptrs = Array.new(4) { FFI::MemoryPointer.new(:float) }

      Pdfium.FPDFPage_CountObjects(@page_ptr).times do |index|
        object_ptr = Pdfium.FPDFPage_GetObject(@page_ptr, index)

        next if object_ptr.null?
        next unless Pdfium.FPDFPageObj_GetType(object_ptr) == FPDF_PAGEOBJ_IMAGE
        next if Pdfium.FPDFPageObj_GetBounds(object_ptr, *bounds_ptrs).zero?

        obj_left, obj_bottom, obj_right, obj_top = bounds_ptrs.map(&:read_float)

        left = (obj_left / width).clamp(0, 1)
        top = ((height - obj_top) / height).clamp(0, 1)
        right = (obj_right / width).clamp(0, 1)
        bottom = ((height - obj_bottom) / height).clamp(0, 1)

        next if right - left <= 0 || bottom - top <= 0

        nodes << ImageNode.new(left, top, right - left, bottom - top)
      end

      nodes
    end

    def rotate
      ensure_not_closed!

      rotation = Pdfium.FPDFPage_GetRotation(page_ptr)

      return false if rotation.zero?

      l_ptr = FFI::MemoryPointer.new(:float)
      b_ptr = FFI::MemoryPointer.new(:float)
      r_ptr = FFI::MemoryPointer.new(:float)
      t_ptr = FFI::MemoryPointer.new(:float)

      has_crop = !Pdfium.FPDFPage_GetCropBox(page_ptr, l_ptr, b_ptr, r_ptr, t_ptr).zero?
      Pdfium.FPDFPage_GetMediaBox(page_ptr, l_ptr, b_ptr, r_ptr, t_ptr) unless has_crop

      pl = l_ptr.read_float
      pb = b_ptr.read_float
      pr = r_ptr.read_float
      pt = t_ptr.read_float

      a, b, c, d, e, f =
        case rotation
        when 1 then [0, -1, 1, 0, -pb, pr]
        when 2 then [-1, 0, 0, -1, pr, pt]
        when 3 then [0, 1, -1, 0, pt, -pl]
        end

      Pdfium::PAGE_BOX_ACCESSORS.each do |getter, setter|
        next if Pdfium.public_send(getter, page_ptr, l_ptr, b_ptr, r_ptr, t_ptr).zero?

        bl = l_ptr.read_float
        bb = b_ptr.read_float
        br = r_ptr.read_float
        bt = t_ptr.read_float

        c1x, c1y, c2x, c2y =
          case rotation
          when 1 then [br, bb, bl, bt]
          when 2 then [br, bt, bl, bb]
          when 3 then [bl, bt, br, bb]
          end

        new_llx = (a * c1x) + (c * c1y) + e
        new_lly = (b * c1x) + (d * c1y) + f
        new_urx = (a * c2x) + (c * c2y) + e
        new_ury = (b * c2x) + (d * c2y) + f

        Pdfium.public_send(setter, page_ptr, new_llx, new_lly, new_urx, new_ury)
      end

      Pdfium.FPDFPage_TransformAnnots(page_ptr, a, b, c, d, e, f)

      matrix_ptr = FFI::MemoryPointer.new(FS_MATRIX.size)
      matrix_struct = FS_MATRIX.new(matrix_ptr)
      matrix_struct[:a] = a
      matrix_struct[:b] = b
      matrix_struct[:c] = c
      matrix_struct[:d] = d
      matrix_struct[:e] = e
      matrix_struct[:f] = f

      Pdfium.FPDFPage_TransFormWithClip(page_ptr, matrix_ptr, FFI::Pointer::NULL)
      Pdfium.FPDFPage_SetRotation(page_ptr, 0)

      reload

      true
    end

    def flatten(flag = Pdfium::FLAT_NORMALDISPLAY)
      ensure_not_closed!

      result = Pdfium.FPDFPage_Flatten(page_ptr, flag)

      if result == Pdfium::FLATTEN_FAIL
        Pdfium.check_last_error("Failed to flatten page #{page_index}")

        raise PdfiumError, "Failed to flatten page #{page_index}"
      end

      reload if result == Pdfium::FLATTEN_SUCCESS

      result
    end

    def reload
      Pdfium.FPDF_ClosePage(@page_ptr)

      @page_ptr = Pdfium.FPDF_LoadPage(@document.document_ptr, @page_index)

      raise PdfiumError, "Failed to reload page #{page_index}" if @page_ptr.null?

      @rotation = nil
      @width = nil
      @height = nil

      reset_text_memoization
    end

    def close
      return if closed?

      Pdfium.FPDF_ClosePage(@page_ptr) unless @page_ptr.null?

      @page_ptr = FFI::Pointer::NULL

      @closed = true
    end

    private

    def calculate_render_dimensions(width_param, height_param, scale_param)
      if scale_param
        render_width = (width * scale_param).round
        render_height = (height * scale_param).round
      elsif width_param || height_param
        if width_param && height_param
          render_width = width_param
          render_height = height_param
        elsif width_param
          scale_factor = width_param.to_f / width
          render_width = width_param
          render_height = (height * scale_factor).round
        else
          scale_factor = height_param.to_f / height
          render_width = (width * scale_factor).round
          render_height = height_param
        end
      else
        render_width = width.to_i
        render_height = height.to_i
      end

      [render_width.clamp(1, MAX_SIZE), render_height.clamp(1, MAX_SIZE)]
    end
  end

  def self.initialize_library
    config_mem = FFI::MemoryPointer.new(FPDF_LIBRARY_CONFIG.size)

    config_struct = FPDF_LIBRARY_CONFIG.new(config_mem)
    config_struct[:version] = 2
    config_struct[:m_pUserFontPaths] = FFI::Pointer::NULL
    config_struct[:m_pIsolate] = FFI::Pointer::NULL
    config_struct[:m_v8EmbedderSlot] = 0

    FPDF_InitLibraryWithConfig(config_mem)
  end

  def self.cleanup_library
    FPDF_DestroyLibrary()
  end

  initialize_library

  at_exit do
    cleanup_library
  end
  # rubocop:enable Metrics
end
