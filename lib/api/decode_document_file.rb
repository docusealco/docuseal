# frozen_string_literal: true

module Api
  module DecodeDocumentFile
    module_function

    def call(file_param, name: nil)
      if url?(file_param)
        download_from_url(file_param, name)
      else
        decode_base64(file_param, name)
      end
    end

    def url?(str)
      str.to_s.match?(%r{\Ahttps?://})
    end

    def download_from_url(url, name)
      response = DownloadUtils.call(url, validate: true)

      tempfile = Tempfile.new(['document', File.extname(URI.parse(url).path).presence || '.pdf'])
      tempfile.binmode
      tempfile.write(response.body)
      tempfile.rewind

      filename = name.presence || File.basename(URI.decode_www_form_component(URI.parse(url).path))

      ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename:,
        type: Marcel::MimeType.for(tempfile, name: filename)
      )
    end

    def decode_base64(data, name)
      decoded = Base64.decode64(data)

      tempfile = Tempfile.new(['document', '.pdf'])
      tempfile.binmode
      tempfile.write(decoded)
      tempfile.rewind

      filename = name.presence || 'document.pdf'

      ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename:,
        type: Marcel::MimeType.for(tempfile, name: filename)
      )
    end
  end
end
