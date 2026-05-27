module MultiXML
  # Mixin that provides file-like metadata to StringIO objects
  #
  # Used when parsing base64-encoded file content from XML.
  # Adds original_filename and content_type attributes to StringIO.
  #
  # @api public
  # @example Extending a StringIO
  #   io = StringIO.new("file content")
  #   io.extend(MultiXML::FileLike)
  #   io.original_filename = "document.pdf"
  #   io.content_type = "application/pdf"
  module FileLike
    # Default filename when none is specified
    # @api public
    # @return [String] the default filename "untitled"
    DEFAULT_FILENAME = "untitled".freeze

    # Default content type when none is specified
    # @api public
    # @return [String] the default MIME type "application/octet-stream"
    DEFAULT_CONTENT_TYPE = "application/octet-stream".freeze

    # Set the original filename
    #
    # @api public
    # @param value [String] The filename to set
    # @return [String] the filename that was set
    # @example Set filename
    #   io.original_filename = "report.pdf"
    attr_writer :original_filename

    # Set the content type
    #
    # @api public
    # @param value [String] The MIME type to set
    # @return [String] the content type that was set
    # @example Set content type
    #   io.content_type = "application/pdf"
    attr_writer :content_type

    # Get the original filename
    #
    # @api public
    # @return [String] the original filename or "untitled" if not set
    # @example Get filename
    #   io.original_filename #=> "document.pdf"
    def original_filename
      @original_filename || DEFAULT_FILENAME
    end

    # Get the content type
    #
    # @api public
    # @return [String] the content type or "application/octet-stream" if not set
    # @example Get content type
    #   io.content_type #=> "application/pdf"
    def content_type
      @content_type || DEFAULT_CONTENT_TYPE
    end
  end
end
