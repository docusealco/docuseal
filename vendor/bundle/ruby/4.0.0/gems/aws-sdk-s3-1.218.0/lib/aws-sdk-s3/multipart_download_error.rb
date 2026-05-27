# frozen_string_literal: true

module Aws
  module S3
    # Raised when multipart download fails to complete.
    class MultipartDownloadError < StandardError; end
  end
end
