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

  MAX_SIZE = 32_767

  FPDF_ANNOT = 0x01
  FPDF_LCD_TEXT = 0x02
  FPDF_NO_NATIVETEXT = 0x04
  FPDF_GRAYSCALE = 0x08
  FPDF_REVERSE_BYTE_ORDER = 0x10
  FPDF_RENDER_LIMITEDIMAGECACHE = 0x200
  FPDF_RENDER_FORCEHALFTONE = 0x400
  FPDF_PRINTING = 0x800

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
  attach_function :FPDFBitmap_FillRect, %i[FPDF_BITMAP int int int int ulong], :void

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

  # Page object functions for extracting paths/lines
  attach_function :FPDFPage_CountObjects, [:FPDF_PAGE], :int
  attach_function :FPDFPage_GetObject, %i[FPDF_PAGE int], :FPDF_PAGEOBJECT
  attach_function :FPDFPageObj_GetType, [:FPDF_PAGEOBJECT], :int
  attach_function :FPDFPageObj_GetBounds, %i[FPDF_PAGEOBJECT pointer pointer pointer pointer], :int
  attach_function :FPDFPath_CountSegments, [:FPDF_PAGEOBJECT], :int
  attach_function :FPDFPath_GetPathSegment, %i[FPDF_PAGEOBJECT int], :FPDF_PATHSEGMENT
  attach_function :FPDFPathSegment_GetType, [:FPDF_PATHSEGMENT], :int
  attach_function :FPDFPathSegment_GetPoint, %i[FPDF_PATHSEGMENT pointer pointer], :int

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

      left_ptr = FFI::MemoryPointer.new(:double)
      right_ptr = FFI::MemoryPointer.new(:double)
      bottom_ptr = FFI::MemoryPointer.new(:double)
      top_ptr = FFI::MemoryPointer.new(:double)
      origin_x_ptr = FFI::MemoryPointer.new(:double)
      origin_y_ptr = FFI::MemoryPointer.new(:double)

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

        result = Pdfium.FPDFText_GetCharBox(text_page, box_index, left_ptr, right_ptr, bottom_ptr, top_ptr)

        next if result.zero?

        left = left_ptr.read_double
        right = right_ptr.read_double

        Pdfium.FPDFText_GetCharOrigin(text_page, box_index, origin_x_ptr, origin_y_ptr)

        origin_y = origin_y_ptr.read_double
        origin_x = origin_x_ptr.read_double

        font_size = Pdfium.FPDFText_GetFontSize(text_page, box_index)
        font_size = 8 if font_size == 1

        abs_x = left
        abs_y = height - origin_y - (font_size * 0.8)
        abs_width = right - left
        abs_height = font_size

        x = origin_x / width
        y = abs_y / height
        node_width = (abs_width + ((abs_x - origin_x).abs * 2)) / width
        node_height = abs_height / height

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
