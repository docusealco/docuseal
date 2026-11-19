# frozen_string_literal: true

Rack::Request.forwarded_priority = %i[x_forwarded]

module RackMultipartCharsetGuard
  private

  def find_encoding(enc)
    encoding = super

    if encoding != Encoding::UTF_8 && encoding != Encoding::US_ASCII
      raise Rack::Utils::InvalidParameterError, 'Unsupported multipart charset'
    end

    encoding
  end
end

Rack::Multipart::Parser.prepend(RackMultipartCharsetGuard)
