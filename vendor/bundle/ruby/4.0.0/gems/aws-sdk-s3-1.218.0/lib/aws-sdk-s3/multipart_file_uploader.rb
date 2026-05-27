# frozen_string_literal: true

require 'pathname'
require 'set'

module Aws
  module S3
    # @api private
    class MultipartFileUploader
      MIN_PART_SIZE = 5 * 1024 * 1024 # 5MB
      MAX_PARTS = 10_000
      CREATE_OPTIONS = Set.new(Client.api.operation(:create_multipart_upload).input.shape.member_names)
      COMPLETE_OPTIONS = Set.new(Client.api.operation(:complete_multipart_upload).input.shape.member_names)
      UPLOAD_PART_OPTIONS = Set.new(Client.api.operation(:upload_part).input.shape.member_names)
      CHECKSUM_KEYS = Set.new(
        Client.api.operation(:upload_part).input.shape.members.map do |n, s|
          n if s.location == 'header' && s.location_name.start_with?('x-amz-checksum-')
        end.compact
      )

      # @option options [Client] :client
      def initialize(options = {})
        @client = options[:client] || Client.new
        @executor = options[:executor]
        @http_chunk_size = options[:http_chunk_size]
      end

      # @return [Client]
      attr_reader :client

      # @param [String, Pathname, File, Tempfile] source The file to upload.
      # @option options [required, String] :bucket The bucket to upload to.
      # @option options [required, String] :key The key for the object.
      # @option options [Proc] :progress_callback
      #   A Proc that will be called when each chunk of the upload is sent.
      #   It will be invoked with [bytes_read], [total_sizes]
      # @return [Seahorse::Client::Response] - the CompleteMultipartUploadResponse
      def upload(source, options = {})
        file_size = File.size(source)
        raise ArgumentError, 'unable to multipart upload files smaller than 5MB' if file_size < MIN_PART_SIZE

        upload_id = initiate_upload(options)
        parts = upload_parts(upload_id, source, file_size, options)
        complete_upload(upload_id, parts, file_size, options)
      end

      private

      def initiate_upload(options)
        @client.create_multipart_upload(create_opts(options)).upload_id
      end

      def complete_upload(upload_id, parts, file_size, options)
        @client.complete_multipart_upload(
          **complete_opts(options),
          upload_id: upload_id,
          multipart_upload: { parts: parts },
          mpu_object_size: file_size
        )
      rescue StandardError => e
        abort_upload(upload_id, options, [e])
      end

      def upload_parts(upload_id, source, file_size, options)
        completed = PartList.new
        pending = PartList.new(compute_parts(upload_id, source, file_size, options))
        errors = upload_with_executor(pending, completed, options)
        if errors.empty?
          completed.to_a.sort_by { |part| part[:part_number] }
        else
          abort_upload(upload_id, options, errors)
        end
      end

      def abort_upload(upload_id, options, errors)
        @client.abort_multipart_upload(bucket: options[:bucket], key: options[:key], upload_id: upload_id)
        msg = "multipart upload failed: #{errors.map(&:message).join('; ')}"
        raise MultipartUploadError.new(msg, errors)
      rescue MultipartUploadError => e
        raise e
      rescue StandardError => e
        msg = "failed to abort multipart upload: #{e&.message}. " \
              "Multipart upload failed: #{errors.map(&:message).join('; ')}"
        raise MultipartUploadError.new(msg, errors + [e])
      end

      def compute_parts(upload_id, source, file_size, options)
        default_part_size = compute_default_part_size(file_size)
        offset = 0
        part_number = 1
        parts = []
        while offset < file_size
          parts << upload_part_opts(options).merge(
            upload_id: upload_id,
            part_number: part_number,
            body: FilePart.new(
              source: source,
              offset: offset,
              size: part_size(file_size, default_part_size, offset)
            )
          )
          part_number += 1
          offset += default_part_size
        end
        parts
      end

      def checksum_key?(key)
        CHECKSUM_KEYS.include?(key)
      end

      def has_checksum_key?(keys)
        keys.any? { |key| checksum_key?(key) }
      end

      def checksum_not_required?(options)
        @client.config.request_checksum_calculation == 'when_required' && !options[:checksum_algorithm]
      end

      def create_opts(options)
        opts = {}
        unless checksum_not_required?(options)
          opts[:checksum_algorithm] = Aws::Plugins::ChecksumAlgorithm::DEFAULT_CHECKSUM
        end
        opts[:checksum_type] = 'FULL_OBJECT' if has_checksum_key?(options.keys)
        CREATE_OPTIONS.each_with_object(opts) { |k, h| h[k] = options[k] if options.key?(k) }
      end

      def complete_opts(options)
        opts = {}
        opts[:checksum_type] = 'FULL_OBJECT' if has_checksum_key?(options.keys)
        COMPLETE_OPTIONS.each_with_object(opts) { |k, h| h[k] = options[k] if options.key?(k) }
      end

      def upload_part_opts(options)
        UPLOAD_PART_OPTIONS.each_with_object({}) do |key, hash|
          # don't pass through checksum calculations
          hash[key] = options[key] if options.key?(key) && !checksum_key?(key)
        end
      end

      def upload_with_executor(pending, completed, options)
        upload_attempts = 0
        completion_queue = Queue.new
        abort_upload = false
        errors = []
        progress = MultipartProgress.new(pending, options[:progress_callback])

        while (part = pending.shift)
          break if abort_upload

          upload_attempts += 1
          @executor.post(part) do |p|
            Thread.current[:net_http_override_body_stream_chunk] = @http_chunk_size if @http_chunk_size
            update_progress(progress, p)
            resp = @client.upload_part(p)
            p[:body].close
            completed_part = { etag: resp.etag, part_number: p[:part_number] }
            apply_part_checksum(resp, completed_part)
            completed.push(completed_part)
          rescue StandardError => e
            abort_upload = true
            errors << e
          ensure
            Thread.current[:net_http_override_body_stream_chunk] = nil if @http_chunk_size
            completion_queue << :done
          end
        end

        upload_attempts.times { completion_queue.pop }
        errors
      end

      def apply_part_checksum(resp, part)
        return unless (checksum = resp.context.params[:checksum_algorithm])

        k = :"checksum_#{checksum.downcase}"
        part[k] = resp.send(k)
      end

      def compute_default_part_size(file_size)
        [(file_size.to_f / MAX_PARTS).ceil, MIN_PART_SIZE].max.to_i
      end

      def part_size(total_size, part_size, offset)
        if offset + part_size > total_size
          total_size - offset
        else
          part_size
        end
      end

      def update_progress(progress, part)
        return unless progress.progress_callback

        part[:on_chunk_sent] =
          proc do |_chunk, bytes, _total|
            progress.call(part[:part_number], bytes)
          end
      end

      # @api private
      class PartList
        def initialize(parts = [])
          @parts = parts
          @mutex = Mutex.new
        end

        def push(part)
          @mutex.synchronize { @parts.push(part) }
        end

        def shift
          @mutex.synchronize { @parts.shift }
        end

        def clear!
          @mutex.synchronize { @parts.clear }
        end

        def size
          @mutex.synchronize { @parts.size }
        end

        def part_sizes
          @mutex.synchronize { @parts.map { |p| p[:body].size } }
        end

        def to_a
          @mutex.synchronize { @parts.dup }
        end
      end

      # @api private
      class MultipartProgress
        def initialize(parts, progress_callback)
          @bytes_sent = Array.new(parts.size, 0)
          @total_sizes = parts.part_sizes
          @progress_callback = progress_callback
        end

        attr_reader :progress_callback

        def call(part_number, bytes_read)
          # part numbers start at 1
          @bytes_sent[part_number - 1] = bytes_read
          @progress_callback.call(@bytes_sent, @total_sizes)
        end
      end
    end
  end
end
