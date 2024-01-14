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
end
