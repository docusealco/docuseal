# frozen_string_literal: true

require 'pathname'
require 'securerandom'
require 'set'

module Aws
  module S3
    # @api private
    class FileDownloader
      MIN_CHUNK_SIZE = 5 * 1024 * 1024
      MAX_PARTS = 10_000
      HEAD_OPTIONS = Set.new(Client.api.operation(:head_object).input.shape.member_names)
      GET_OPTIONS = Set.new(Client.api.operation(:get_object).input.shape.member_names)

      def initialize(options = {})
        @client = options[:client] || Client.new
        @executor = options[:executor]
      end

      # @return [Client]
      attr_reader :client

      def download(destination, options = {})
        validate_destination!(destination)
        opts = build_download_opts(destination, options)
        validate_opts!(opts)

        Aws::Plugins::UserAgent.metric('S3_TRANSFER') do
          case opts[:mode]
          when 'auto' then multipart_download(opts)
          when 'single_request' then single_request(opts)
          when 'get_range' then range_request(opts)
          end
        end
        File.rename(opts[:temp_path], destination) if opts[:temp_path]
      ensure
        cleanup_temp_file(opts)
      end

      private

      def build_download_opts(destination, opts)
        {
          destination: destination,
          mode: opts.delete(:mode) || 'auto',
          chunk_size: opts.delete(:chunk_size),
          on_checksum_validated: opts.delete(:on_checksum_validated),
          progress_callback: opts.delete(:progress_callback),
          params: opts,
          temp_path: nil
        }
      end

      def cleanup_temp_file(opts)
        return unless opts

        temp_file = opts[:temp_path]
        File.delete(temp_file) if temp_file && File.exist?(temp_file)
      end

      def download_with_executor(part_list, total_size, opts)
        download_attempts = 0
        completion_queue = Queue.new
        abort_download = false
        error = nil
        progress = MultipartProgress.new(part_list, total_size, opts[:progress_callback])

        while (part = part_list.shift)
          break if abort_download

          download_attempts += 1
          @executor.post(part) do |p|
            update_progress(progress, p)
            resp = @client.get_object(p.params)
            range = extract_range(resp.content_range)
            validate_range(range, p.params[:range]) if p.params[:range]
            write(resp.body, range, opts)

            execute_checksum_callback(resp, opts)
          rescue StandardError => e
            abort_download = true
            error = e
          ensure
            completion_queue << :done
          end
        end

        download_attempts.times { completion_queue.pop }
        raise error unless error.nil?
      end

      def handle_checksum_mode_option(option_key, opts)
        return false unless option_key == :checksum_mode && opts[:checksum_mode] == 'DISABLED'

        msg = ':checksum_mode option is deprecated. Checksums will be validated by default. ' \
          'To disable checksum validation, set :response_checksum_validation to "when_required" on your S3 client.'
        warn(msg)
        true
      end

      def get_opts(opts)
        GET_OPTIONS.each_with_object({}) do |k, h|
          next if k == :checksum_mode

          h[k] = opts[k] if opts.key?(k)
        end
      end

      def head_opts(opts)
        HEAD_OPTIONS.each_with_object({}) do |k, h|
          next if handle_checksum_mode_option(k, opts)

          h[k] = opts[k] if opts.key?(k)
        end
      end

      def compute_chunk(chunk_size, file_size)
        raise ArgumentError, ":chunk_size shouldn't exceed total file size." if chunk_size && chunk_size > file_size

        chunk_size || [(file_size.to_f / MAX_PARTS).ceil, MIN_CHUNK_SIZE].max.to_i
      end

      def compute_mode(file_size, total_parts, etag, opts)
        chunk_size = compute_chunk(opts[:chunk_size], file_size)
        part_size = (file_size.to_f / total_parts).ceil

        resolve_temp_path(opts)
        if chunk_size < part_size
          multithreaded_get_by_ranges(file_size, etag, opts)
        else
          multithreaded_get_by_parts(total_parts, file_size, etag, opts)
        end
      end

      def extract_range(value)
        value.match(%r{bytes (?<range>\d+-\d+)/\d+})[:range]
      end

      def multipart_download(opts)
        resp = @client.head_object(head_opts(opts[:params].merge(part_number: 1)))
        count = resp.parts_count

        if count.nil? || count <= 1
          if resp.content_length <= MIN_CHUNK_SIZE
            single_request(opts)
          else
            resolve_temp_path(opts)
            multithreaded_get_by_ranges(resp.content_length, resp.etag, opts)
          end
        else
          # covers cases when given object is not uploaded via UploadPart API
          resp = @client.head_object(head_opts(opts[:params])) # partNumber is an option
          if resp.content_length <= MIN_CHUNK_SIZE
            single_request(opts)
          else
            compute_mode(resp.content_length, count, resp.etag, opts)
          end
        end
      end

      def multithreaded_get_by_parts(total_parts, file_size, etag, opts)
        parts = (1..total_parts).map do |part|
          params = get_opts(opts[:params].merge(part_number: part, if_match: etag))
          Part.new(part_number: part, params: params)
        end
        download_with_executor(PartList.new(parts), file_size, opts)
      end

      def multithreaded_get_by_ranges(file_size, etag, opts)
        offset = 0
        default_chunk_size = compute_chunk(opts[:chunk_size], file_size)
        chunks = []
        part_number = 1 # parts start at 1
        while offset < file_size
          progress = offset + default_chunk_size
          progress = file_size if progress > file_size
          params = get_opts(opts[:params].merge(range: "bytes=#{offset}-#{progress - 1}", if_match: etag))
          chunks << Part.new(part_number: part_number, size: (progress - offset), params: params)
          part_number += 1
          offset = progress
        end
        download_with_executor(PartList.new(chunks), file_size, opts)
      end

      def range_request(opts)
        resp = @client.head_object(head_opts(opts[:params]))
        resolve_temp_path(opts)
        multithreaded_get_by_ranges(resp.content_length, resp.etag, opts)
      end

      def resolve_temp_path(opts)
        return if [File, Tempfile].include?(opts[:destination].class)

        opts[:temp_path] ||= "#{opts[:destination]}.s3tmp.#{SecureRandom.alphanumeric(8)}"
      end

      def single_request(opts)
        params = get_opts(opts[:params]).merge(response_target: opts[:destination])
        params[:on_chunk_received] = single_part_progress(opts) if opts[:progress_callback]
        resp = @client.get_object(params)
        return resp unless opts[:on_checksum_validated]

        opts[:on_checksum_validated].call(resp.checksum_validated, resp) if resp.checksum_validated
        resp
      end

      def single_part_progress(opts)
        proc do |_chunk, bytes_read, total_size|
          opts[:progress_callback].call([bytes_read], [total_size], total_size)
        end
      end

      def update_progress(progress, part)
        return unless progress.progress_callback

        part.params[:on_chunk_received] =
          proc do |_chunk, bytes, total|
            progress.call(part.part_number, bytes, total)
          end
      end

      def execute_checksum_callback(resp, opts)
        return unless opts[:on_checksum_validated] && resp.checksum_validated

        opts[:on_checksum_validated].call(resp.checksum_validated, resp)
      end

      def validate_destination!(destination)
        valid_types = [String, Pathname, File, Tempfile]
        return if valid_types.include?(destination.class)

        raise ArgumentError, "Invalid destination, expected #{valid_types.join(', ')} but got: #{destination.class}"
      end

      def validate_opts!(opts)
        if opts[:on_checksum_validated] && !opts[:on_checksum_validated].respond_to?(:call)
          raise ArgumentError, ':on_checksum_validated must be callable'
        end

        valid_modes = %w[auto get_range single_request]
        unless valid_modes.include?(opts[:mode])
          msg = "Invalid mode #{opts[:mode]} provided, :mode should be single_request, get_range or auto"
          raise ArgumentError, msg
        end

        if opts[:mode] == 'get_range' && opts[:chunk_size].nil?
          raise ArgumentError, 'In get_range mode, :chunk_size must be provided'
        end

        if opts[:chunk_size] && opts[:chunk_size] <= 0
          raise ArgumentError, ':chunk_size must be positive'
        end
      end

      def validate_range(actual, expected)
        return if actual == expected.match(/bytes=(?<range>\d+-\d+)/)[:range]

        raise MultipartDownloadError, "multipart download failed: expected range of #{expected} but got #{actual}"
      end

      def write(body, range, opts)
        path = opts[:temp_path] || opts[:destination]
        File.write(path, body.read, range.split('-').first.to_i)
      end

      # @api private
      class Part < Struct.new(:part_number, :size, :params)
        include Aws::Structure
      end

      # @api private
      class PartList
        include Enumerable
        def initialize(parts = [])
          @parts = parts
          @mutex = Mutex.new
        end

        def shift
          @mutex.synchronize { @parts.shift }
        end

        def size
          @mutex.synchronize { @parts.size }
        end

        def clear!
          @mutex.synchronize { @parts.clear }
        end

        def each(&block)
          @mutex.synchronize { @parts.each(&block) }
        end
      end

      # @api private
      class MultipartProgress
        def initialize(parts, total_size, progress_callback)
          @bytes_received = Array.new(parts.size, 0)
          @part_sizes = parts.map(&:size)
          @total_size = total_size
          @progress_callback = progress_callback
        end

        attr_reader :progress_callback

        def call(part_number, bytes_received, total)
          # part numbers start at 1
          @bytes_received[part_number - 1] = bytes_received
          # part size may not be known until we get the first response
          @part_sizes[part_number - 1] ||= total
          @progress_callback.call(@bytes_received, @part_sizes, @total_size)
        end
      end
    end
  end
end
