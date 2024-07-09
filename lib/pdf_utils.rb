# frozen_string_literal: true

module PdfUtils
  module_function

  def encrypted?(data, password: nil)
    HexaPDF::Document.new(io: StringIO.new(data), decryption_opts: { password: })

    false
  rescue HexaPDF::EncryptionError
    true
  end

  def decrypt(data, password)
    encrypted_doc = HexaPDF::Document.new(io: StringIO.new(data), decryption_opts: { password: })

    decrypted_doc = HexaPDF::Document.new

    encrypted_doc.pages.each do |page|
      decrypted_doc.pages << decrypted_doc.import(page)
    end

    decrypted_io = StringIO.new

    decrypted_doc.write(decrypted_io, validate: false)

    decrypted_io.tap(&:rewind).read
  end

  def merge(files)
    merged_pdf = HexaPDF::Document.new

    files.each do |file|
      pdf = HexaPDF::Document.new(io: file)
      pdf.pages.each { |page| merged_pdf.pages << merged_pdf.import(page) }
    end

    merged_content = StringIO.new
    merged_pdf.write(merged_content)
    merged_content.rewind

    merged_content
  end
end
