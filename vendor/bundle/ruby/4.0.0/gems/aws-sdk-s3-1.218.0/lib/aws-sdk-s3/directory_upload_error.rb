# frozen_string_literal: true

module Aws
  module S3
    # Raised when DirectoryUploader fails to upload files to S3 bucket
    class DirectoryUploadError < StandardError
      def initialize(message, errors = [])
        @errors = errors
        super(message)
      end

      # @return [Array<StandardError>] The list of errors encountered when uploading files
      attr_reader :errors
    end
  end
end
