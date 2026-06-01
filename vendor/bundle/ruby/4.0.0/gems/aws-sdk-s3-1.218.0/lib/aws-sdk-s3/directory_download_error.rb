# frozen_string_literal: true

module Aws
  module S3
    # Raised when DirectoryDownloader fails to download objects from S3 bucket
    class DirectoryDownloadError < StandardError
      def initialize(message, errors = [])
        @errors = errors
        super(message)
      end

      # @return [Array<StandardError>] The list of errors encountered when downloading objects
      attr_reader :errors
    end
  end
end
