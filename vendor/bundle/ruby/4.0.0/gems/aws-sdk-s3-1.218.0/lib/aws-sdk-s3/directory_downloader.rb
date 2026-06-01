# frozen_string_literal: true

module Aws
  module S3
    # @api private
    # This is a one-shot class that downloads objects from a bucket to a local directory.
    # This works as follows:
    # * ObjectProducer runs in a background thread, calling `list_objects_v2` and
    #   pushing entries into a SizedQueue (max: 100).
    # * An internal executor pulls from that queue and posts work. Each task uses
    #   FileDownloader to download objects then signals completion via `completion_queue`.
    #
    # We track how many tasks we posted, then pop that many times from `completion_queue`
    # to wait for everything to finish.
    #
    # Errors are collected in a mutex-protected array. On failure (unless ignore_failure is set),
    # we call abort which closes the queue - the producer catches ClosedQueueError and exits cleanly.
    class DirectoryDownloader
      def initialize(options = {})
        @client = options[:client] || Client.new
        @executor = options[:executor] || DefaultExecutor.new
        @logger = options[:logger]
        @producer = nil
        @mutex = Mutex.new
      end

      attr_reader :client, :executor

      def abort
        @producer&.close
      end

      def download(destination, bucket:, **options)
        if File.exist?(destination)
          raise ArgumentError, 'invalid destination, expected a directory' unless File.directory?(destination)
        else
          FileUtils.mkdir_p(destination)
        end

        download_opts = build_download_opts(destination, options)
        @producer = ObjectProducer.new(build_producer_opts(destination, bucket, options))
        downloader = FileDownloader.new(client: @client, executor: @executor)
        downloads, errors = process_download_queue(downloader, download_opts)
        build_result(downloads, errors)
      end

      private

      def build_download_opts(destination, opts)
        {
          destination: destination,
          ignore_failure: opts[:ignore_failure] || false
        }
      end

      def build_producer_opts(destination, bucket, opts)
        {
          client: @client,
          directory_downloader: self,
          destination: destination,
          bucket: bucket,
          s3_prefix: opts[:s3_prefix],
          filter_callback: opts[:filter_callback],
          request_callback: opts[:request_callback]
        }
      end

      def build_result(download_count, errors)
        if @producer&.closed?
          msg = "directory download failed: #{errors.map(&:message).join('; ')}"
          raise DirectoryDownloadError.new(msg, errors)
        else
          {
            completed_downloads: [download_count - errors.count, 0].max,
            failed_downloads: errors.count,
            errors: errors.any? ? errors : nil
          }.compact
        end
      end

      def download_object(entry, downloader, errors, opts)
        raise entry.error if entry.error

        FileUtils.mkdir_p(File.dirname(entry.path)) unless Dir.exist?(File.dirname(entry.path))
        downloader.download(entry.path, entry.params)
        @logger&.debug("Downloaded #{entry.params[:key]} from #{entry.params[:bucket]} to #{entry.path}")
      rescue StandardError => e
        @logger&.warn("Failed to download #{entry.params[:key]} from #{entry.params[:bucket]}: #{e.message}")
        @mutex.synchronize { errors << e }
        abort unless opts[:ignore_failure]
      end

      def process_download_queue(downloader, opts)
        queue_executor = DefaultExecutor.new(max_threads: 2)
        completion_queue = Queue.new
        posted_count = 0
        errors = []
        begin
          @producer.each do |object|
            queue_executor.post(object) do |o|
              download_object(o, downloader, errors, opts)
            ensure
              completion_queue << :done
            end
            posted_count += 1
          end
        rescue ClosedQueueError
          # abort already requested
        rescue StandardError => e
          @mutex.synchronize { errors << e }
          abort
        end
        posted_count.times { completion_queue.pop }
        [posted_count, errors]
      ensure
        queue_executor&.shutdown
      end

      # @api private
      class ObjectProducer
        include Enumerable

        DEFAULT_QUEUE_SIZE = 100
        DONE_MARKER = :done

        def initialize(opts = {})
          @directory_downloader = opts[:directory_downloader]
          @destination_dir = opts[:destination]
          @bucket = opts[:bucket]
          @client = opts[:client]
          @s3_prefix = opts[:s3_prefix]
          @filter_callback = opts[:filter_callback]
          @request_callback = opts[:request_callback]
          @object_queue = SizedQueue.new(DEFAULT_QUEUE_SIZE)
        end

        def closed?
          @object_queue.closed?
        end

        def close
          @object_queue.close
          @object_queue.clear
        end

        def each
          producer_thread = Thread.new do
            stream_objects
            @object_queue << DONE_MARKER
          rescue ClosedQueueError
            # abort requested
          rescue StandardError => e
            close
            raise e
          end

          while (object = @object_queue.shift) && object != DONE_MARKER
            yield object
          end
        ensure
          producer_thread.value
        end

        private

        def apply_request_callback(key, params)
          callback_params = @request_callback.call(key, params.dup)
          return params unless callback_params.is_a?(Hash) && callback_params.any?

          params.merge(callback_params)
        end

        def build_object_entry(key)
          params = { bucket: @bucket, key: key }
          params = apply_request_callback(key, params) if @request_callback
          error = validate_key(key)
          return DownloadEntry.new(path: '', params: params, error: error) if error

          full_path = normalize_path(File.join(@destination_dir, key))
          DownloadEntry.new(path: full_path, params: params, error: error)
        end

        def include_object?(obj)
          return true unless @filter_callback

          @filter_callback.call(obj)
        end

        def directory_marker?(obj)
          obj.key.end_with?('/') && obj.size.zero?
        end

        def normalize_path(path)
          return path if File::SEPARATOR == '/'

          path.tr('/', File::SEPARATOR)
        end

        def stream_objects(continuation_token: nil)
          resp = @client.list_objects_v2(bucket: @bucket, prefix: @s3_prefix, continuation_token: continuation_token)
          resp.contents&.each do |o|
            next if directory_marker?(o)
            next unless include_object?(o)

            @object_queue << build_object_entry(o.key)
          end
          stream_objects(continuation_token: resp.next_continuation_token) if resp.next_continuation_token
        end

        def validate_key(key)
          segments = key.split('/')
          return unless segments.any? { |s| %w[. ..].include?(s) }

          DirectoryDownloadError.new("invalid key '#{key}': contains '.' or '..' path segments")
        end

        # @api private
        class DownloadEntry
          def initialize(opts = {})
            @path = opts[:path]
            @params = opts[:params]
            @error = opts[:error]
          end

          attr_reader :path, :params, :error
        end
      end
    end
  end
end
