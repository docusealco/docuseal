# frozen_string_literal: true

require 'thread'
require 'set'
require 'tempfile'
require 'stringio'

module Aws
  module S3
    # @api private
    class MultipartStreamUploader

      DEFAULT_PART_SIZE = 5 * 1024 * 1024 # 5MB
      CREATE_OPTIONS = Set.new(Client.api.operation(:create_multipart_upload).input.shape.member_names)
      UPLOAD_PART_OPTIONS = Set.new(Client.api.operation(:upload_part).input.shape.member_names)
      COMPLETE_UPLOAD_OPTIONS = Set.new(Client.api.operation(:complete_multipart_upload).input.shape.member_names)

      # @option options [Client] :client
      def initialize(options = {})
        @client = options[:client] || Client.new
        @executor = options[:executor]
        @tempfile = options[:tempfile]
        @part_size = options[:part_size] || DEFAULT_PART_SIZE
      end

      # @return [Client]
      attr_reader :client

      # @option options [required,String] :bucket
      # @option options [required,String] :key
      # @return [Seahorse::Client::Response] - the CompleteMultipartUploadResponse
      def upload(options = {}, &block)
        Aws::Plugins::UserAgent.metric('S3_TRANSFER') do
          upload_id = initiate_upload(options)
          parts = upload_parts(upload_id, options, &block)
          complete_upload(upload_id, parts, options)
        end
      end

      private

      def initiate_upload(options)
        @client.create_multipart_upload(create_opts(options)).upload_id
      end

      def complete_upload(upload_id, parts, options)
        @client.complete_multipart_upload(
          **complete_opts(options).merge(upload_id: upload_id, multipart_upload: { parts: parts })
        )
      rescue StandardError => e
        abort_upload(upload_id, options, [e])
      end

      def upload_parts(upload_id, options, &block)
        completed_parts = Queue.new
        errors = []

        begin
          IO.pipe do |read_pipe, write_pipe|
            upload_thread = Thread.new do
              upload_with_executor(
                read_pipe,
                completed_parts,
                errors,
                upload_part_opts(options).merge(upload_id: upload_id)
              )
            end

            block.call(write_pipe)
          ensure
            # Ensure the pipe is closed to avoid https://github.com/jruby/jruby/issues/6111
            write_pipe.close
            upload_thread.join
          end
        rescue StandardError => e
          errors << e
        end
        return ordered_parts(completed_parts) if errors.empty?

        abort_upload(upload_id, options, errors)
      end

      def abort_upload(upload_id, options, errors)
        @client.abort_multipart_upload(bucket: options[:bucket], key: options[:key], upload_id: upload_id)
        msg = "multipart upload failed: #{errors.map(&:message).join('; ')}"
        raise MultipartUploadError.new(msg, errors)
      rescue MultipartUploadError => e
        raise e
      rescue StandardError => e
        msg = "failed to abort multipart upload: #{e.message}. "\
          "Multipart upload failed: #{errors.map(&:message).join('; ')}"
        raise MultipartUploadError.new(msg, errors + [e])
      end

      def create_opts(options)
        CREATE_OPTIONS.each_with_object({}) do |key, hash|
          hash[key] = options[key] if options.key?(key)
        end
      end

      def upload_part_opts(options)
        UPLOAD_PART_OPTIONS.each_with_object({}) do |key, hash|
          hash[key] = options[key] if options.key?(key)
        end
      end

      def complete_opts(options)
        COMPLETE_UPLOAD_OPTIONS.each_with_object({}) do |key, hash|
          hash[key] = options[key] if options.key?(key)
        end
      end

      def read_to_part_body(read_pipe)
        return if read_pipe.closed?

        temp_io = @tempfile ? Tempfile.new('aws-sdk-s3-upload_stream') : StringIO.new(String.new)
        temp_io.binmode
        bytes_copied = IO.copy_stream(read_pipe, temp_io, @part_size)
        temp_io.rewind
        if bytes_copied.zero?
          if temp_io.is_a?(Tempfile)
            temp_io.close
            temp_io.unlink
          end
          nil
        else
          temp_io
        end
      end

      def upload_with_executor(read_pipe, completed, errors, options)
        completion_queue = Queue.new
        queued_parts = 0
        part_number = 0
        mutex = Mutex.new
        loop do
          part_body, current_part_num = mutex.synchronize do
            [read_to_part_body(read_pipe), part_number += 1]
          end
          break unless part_body || current_part_num == 1

          queued_parts += 1
          @executor.post(part_body, current_part_num, options) do |body, num, opts|
            part = opts.merge(body: body, part_number: num)
            resp = @client.upload_part(part)
            completed_part = create_completed_part(resp, part)
            completed.push(completed_part)
          rescue StandardError => e
            mutex.synchronize do
              errors.push(e)
              read_pipe.close_read unless read_pipe.closed?
            end
          ensure
            clear_body(body)
            completion_queue << :done
          end
        end
        queued_parts.times { completion_queue.pop }
      end

      def create_completed_part(resp, part)
        completed_part = { etag: resp.etag, part_number: part[:part_number] }
        return completed_part unless part[:checksum_algorithm]

        # get the requested checksum from the response
        k = "checksum_#{part[:checksum_algorithm].downcase}".to_sym
        completed_part[k] = resp[k]
        completed_part
      end

      def ordered_parts(parts)
        sorted = []
        until parts.empty?
          part = parts.pop
          index = sorted.bsearch_index { |p| p[:part_number] >= part[:part_number] } || sorted.size
          sorted.insert(index, part)
        end
        sorted
      end

      def clear_body(body)
        if body.is_a?(Tempfile)
          body.close
          body.unlink
        elsif body.is_a?(StringIO)
          body.string.clear
        end
      end
    end
  end
end
