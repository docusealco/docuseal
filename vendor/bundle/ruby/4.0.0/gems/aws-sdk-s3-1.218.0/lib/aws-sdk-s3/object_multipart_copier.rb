# frozen_string_literal: true

require 'thread'
require "cgi/escape"
require "cgi/util" if RUBY_VERSION < "3.5"

module Aws
  module S3
    # @api private
    class ObjectMultipartCopier

      FIVE_MB = 5 * 1024 * 1024 # 5MB

      FILE_TOO_SMALL = "unable to multipart copy files smaller than 5MB"

      MAX_PARTS = 10_000

      # @option options [Client] :client
      # @option options [Integer] :min_part_size (52428800)
      #   Size of copied parts. Defaults to 50MB.
      # @option options [Integer] :thread_count (10) Number of concurrent
      #   threads to use for copying parts.
      # @option options [Boolean] :use_source_parts (false) Use part sizes
      #   defined on the source object if any exist. If copying or moving an
      #   object that is already multipart, this does not re-part the object,
      #   instead re-using the part definitions on the original. That means
      #   the etag and any checksums will not change. This is especially
      #   useful if the source object has parts with varied sizes.
      def initialize(options = {})
        @use_source_parts = options.delete(:use_source_parts) || false
        @thread_count = options.delete(:thread_count) || 10
        @min_part_size = options.delete(:min_part_size) || (FIVE_MB * 10)
        @client = options[:client] || Client.new
      end

      # @return [Client]
      attr_reader :client

      # @option (see S3::Client#copy_object)
      def copy(options = {})
        metadata = source_metadata(options)
        size = metadata[:content_length]
        options[:upload_id] = initiate_upload(metadata.merge(options))
        begin
          parts = copy_parts(size, default_part_size(size), options)
          complete_upload(parts, options)
        rescue => error
          abort_upload(options)
          raise error
        end
      end

      private

      def initiate_upload(options)
        options = options_for(:create_multipart_upload, options)
        @client.create_multipart_upload(options).upload_id
      end

      def copy_parts(size, default_part_size, options)
        queue = PartQueue.new(compute_parts(size, default_part_size, options))
        threads = []
        @thread_count.times do
          threads << copy_part_thread(queue)
        end
        threads.map(&:value).flatten.sort_by{ |part| part[:part_number] }
      end

      def copy_part_thread(queue)
        Thread.new do
          begin
            completed = []
            while part = queue.shift
              completed << copy_part(part)
            end
            completed
          rescue => error
            queue.clear!
            raise error
          end
        end
      end

      def copy_part(part)
        @client.upload_part_copy(part).copy_part_result.to_h.merge({
          part_number: part[:part_number]
        }).tap { |result| result.delete(:last_modified) }
      end

      def complete_upload(parts, options)
        options = options_for(:complete_multipart_upload, options)
        options[:multipart_upload] = { parts: parts }
        @client.complete_multipart_upload(options)
      end

      def abort_upload(options)
        @client.abort_multipart_upload({
          bucket: options[:bucket],
          key: options[:key],
          upload_id: options[:upload_id],
        })
      end

      def compute_parts(size, default_part_size, options)
        part_number = 1
        offset = 0
        parts = []
        options = options_for(:upload_part_copy, options)
        while offset < size
          part_size = calculate_part_size(part_number, default_part_size, options)
          parts << options.merge({
            part_number: part_number,
            copy_source_range: byte_range(offset, part_size, size),
          })
          part_number += 1
          offset += part_size
        end
        parts
      end

      def byte_range(offset, part_size, size)
        if offset + part_size < size
          "bytes=#{offset}-#{offset + part_size - 1}"
        else
          "bytes=#{offset}-#{size - 1}"
        end
      end

      def calculate_part_size(part_number, default_part_size, options)
        if @use_source_parts && source_has_parts(options)
          source_metadata(options.merge({ part_number: part_number }))[:content_length]
        else
          default_part_size
        end
      end

      def source_has_parts(options)
        @source_has_parts ||= source_metadata(options.merge({ part_number: 1 }))[:parts_count]
      end

      def source_metadata(options)
        return options.slice(:content_length) if options[:content_length]

        client = options[:copy_source_client] || @client

        if vid_match = options[:copy_source].match(/([^\/]+?)\/(.+)\?versionId=(.+)/)
          bucket, key, version_id = vid_match[1,3]
        else
          bucket, key = options[:copy_source].match(/([^\/]+?)\/(.+)/)[1,2]
        end

        head_opts = { bucket: bucket, key: CGI.unescape(key) }.tap { |opts|
          opts[:version_id]  = version_id if version_id
          opts[:part_number] = options[:part_number] if options[:part_number]
        }

        client.head_object(head_opts).to_h.tap { |head|
          head.delete(:server_side_encryption)
          head.delete(:ssekms_key_id)
        }
      end

      def default_part_size(source_size)
        if source_size < FIVE_MB
          raise ArgumentError, FILE_TOO_SMALL
        else
          [(source_size.to_f / MAX_PARTS).ceil, @min_part_size].max.to_i
        end
      end

      def options_for(operation_name, options)
        API_OPTIONS[operation_name].inject({}) do |hash, opt_name|
          hash[opt_name] = options[opt_name] if options.key?(opt_name)
          hash
        end
      end

      # @api private
      def self.options_for(shape_name)
        Client.api.metadata['shapes'][shape_name].member_names
      end

      API_OPTIONS = {
        create_multipart_upload: Types::CreateMultipartUploadRequest.members,
        upload_part_copy: Types::UploadPartCopyRequest.members,
        complete_multipart_upload: Types::CompleteMultipartUploadRequest.members,
      }

      class PartQueue

        def initialize(parts = [])
          @parts = parts
          @mutex = Mutex.new
        end

        def shift
          @mutex.synchronize { @parts.shift }
        end

        def clear!
          @mutex.synchronize { @parts.clear }
        end

      end
    end
  end
end
