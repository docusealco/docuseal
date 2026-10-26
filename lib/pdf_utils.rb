# frozen_string_literal: true

module PdfUtils
  DEFAULT_DPI = 72
  US_LETTER_W = DEFAULT_DPI * 8.5

  module_function

  def merge(io_files)
    merged_content = StringIO.new

    Pdfium.with_instance do
      Pdfium::Document.create do |merged_pdf|
        io_files.each do |io|
          Pdfium::Document.open_io(io) { |pdf| merged_pdf.import_pages(pdf) }
        end

        merged_pdf.save(merged_content)
      end
    end

    merged_content.tap(&:rewind)
  end
end
