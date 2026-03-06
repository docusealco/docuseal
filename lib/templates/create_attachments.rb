# frozen_string_literal: true

module Templates
  module CreateAttachments
    PDF_CONTENT_TYPE = 'application/pdf'
    ZIP_CONTENT_TYPE = 'application/zip'
    X_ZIP_CONTENT_TYPE = 'application/x-zip-compressed'
    JSON_CONTENT_TYPE = 'application/json'
    DOCUMENT_EXTENSIONS = %w[.docx .doc .xlsx .xls .odt .rtf].freeze

    DOCUMENT_CONTENT_TYPES = %w[
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/msword
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.ms-excel
      application/vnd.oasis.opendocument.text
      application/rtf
    ].freeze

    ANNOTATIONS_SIZE_LIMIT = 6.megabytes
    MAX_ZIP_SIZE = 100.megabytes
    InvalidFileType = Class.new(StandardError)
    PdfEncrypted = Class.new(StandardError)

    module_function

    def call(template, params, extract_fields: false)
      extract_zip_files(params[:files].presence || params[:file]).flat_map do |file|
        handle_file_types(template, file, params, extract_fields:)
      end
    end

    def handle_pdf_or_image(template, file, document_data = nil, params = {}, extract_fields: false, content_type_override: nil, filename_override: nil)
      document_data ||= file.read
      content_type = content_type_override || file.content_type
      filename = filename_override || file.original_filename

      if content_type == PDF_CONTENT_TYPE
        document_data = maybe_decrypt_pdf_or_raise(document_data, params)

        annotations =
          document_data.size < ANNOTATIONS_SIZE_LIMIT ? Templates::BuildAnnotations.call(document_data) : []
      end

      sha256 = Base64.urlsafe_encode64(Digest::SHA256.digest(document_data))

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(document_data),
        filename: filename,
        metadata: {
          identified: content_type == PDF_CONTENT_TYPE,
          analyzed: content_type == PDF_CONTENT_TYPE,
          pdf: { annotations: }.compact_blank, sha256:
        }.compact_blank,
        content_type: content_type
      )

      document = template.documents.create!(blob:)

      Templates::ProcessDocument.call(document, document_data, extract_fields:)
    end

    def maybe_decrypt_pdf_or_raise(data, params)
      if data.size < ANNOTATIONS_SIZE_LIMIT && PdfUtils.encrypted?(data)
        PdfUtils.decrypt(data, params[:password])
      else
        data
      end
    rescue HexaPDF::EncryptionError
      raise PdfEncrypted
    end

    def extract_zip_files(files)
      extracted_files = []

      Array.wrap(files).each do |file|
        if file.content_type == ZIP_CONTENT_TYPE || file.content_type == X_ZIP_CONTENT_TYPE
          total_size = 0

          Zip::File.open(file.tempfile).each do |entry|
            next if entry.directory?

            total_size += entry.size

            raise InvalidFileType, 'zip_too_large' if total_size > MAX_ZIP_SIZE

            tempfile = Tempfile.new(entry.name)
            tempfile.binmode
            entry.get_input_stream { |in_stream| IO.copy_stream(in_stream, tempfile) }
            tempfile.rewind

            type = Marcel::MimeType.for(tempfile, name: entry.name)

            next if type.exclude?('image') &&
                    type != PDF_CONTENT_TYPE &&
                    type != JSON_CONTENT_TYPE &&
                    DOCUMENT_CONTENT_TYPES.exclude?(type)

            extracted_files << ActionDispatch::Http::UploadedFile.new(
              filename: File.basename(entry.name),
              type:,
              tempfile:
            )
          end
        else
          extracted_files << file
        end
      end

      extracted_files
    end

    def handle_file_types(template, file, params, extract_fields:)
      if file.content_type.include?('image') || file.content_type == PDF_CONTENT_TYPE
        return handle_pdf_or_image(template, file, file.read, params, extract_fields:)
      end

      # Handle document types (DOCX, DOC, XLSX, etc.) by converting to PDF
      if DOCUMENT_CONTENT_TYPES.include?(file.content_type)
        pdf_data = convert_document_to_pdf(file)
        if pdf_data
          # Process the converted PDF with PDF content type and filename
          pdf_filename = File.basename(file.original_filename, '.*') + '.pdf'
          return handle_pdf_or_image(template, file, pdf_data, params, extract_fields: extract_fields, content_type_override: PDF_CONTENT_TYPE, filename_override: pdf_filename)
        else
          raise InvalidFileType, "Unable to convert #{file.content_type} to PDF. Please install LibreOffice (brew install --cask libreoffice on macOS or apt-get install libreoffice on Linux) or convert the document to PDF manually."
        end
      end

      raise InvalidFileType, file.content_type
    end

    def convert_document_to_pdf(file)
      # Try to use LibreOffice to convert document to PDF
      libreoffice_path = find_libreoffice
      return nil unless libreoffice_path

      # Create a temporary file for the input document
      input_temp = Tempfile.new(['input', File.extname(file.original_filename)])
      input_temp.binmode
      file.rewind
      input_temp.write(file.read)
      input_temp.close

      output_dir = Dir.mktmpdir
      output_file = File.join(output_dir, File.basename(file.original_filename, '.*') + '.pdf')

      begin
        # Use LibreOffice headless mode to convert to PDF
        success = system(libreoffice_path, '--headless', '--convert-to', 'pdf', '--outdir', output_dir, input_temp.path, out: File::NULL, err: File::NULL)
        
        if success
          generated_pdf = Dir.glob(File.join(output_dir, '*.pdf')).first
          if generated_pdf && File.exist?(generated_pdf)
            return File.binread(generated_pdf)
          end
        end
      rescue StandardError => e
        Rails.logger.warn("Document conversion failed: #{e.message}")
      ensure
        input_temp.unlink if input_temp
        FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
      end

      nil
    end

    def find_libreoffice
      # Check common LibreOffice installation paths
      paths = [
        '/Applications/LibreOffice.app/Contents/MacOS/soffice', # macOS
        '/usr/bin/libreoffice', # Linux
        '/usr/local/bin/libreoffice', # Linux alternative
        `which libreoffice`.strip, # System PATH
        `which soffice`.strip # Alternative command name
      ].compact.reject(&:empty?)

      paths.find { |path| File.executable?(path) }
    end
  end
end
