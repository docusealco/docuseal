# frozen_string_literal: true

require 'set'

module Aws
  module S3
    # @api private
    # This is a one-shot class that uploads files from a local directory to a bucket.
    # This works as follows:
    # * FileProducer runs in a background thread, scanning the directory and
    #   pushing entries into a SizedQueue (max: 100).
    # * An internal executor pulls from that queue and posts work. Each task uses
    #   FileUploader to upload files then signals completion via `completion_queue`.
    #
    # We track how many tasks we posted, then pop that many times from `completion_queue`
    # to wait for everything to finish.
    #
    # Errors are collected in a mutex-protected array. On failure (unless ignore_failure is set),
    # we call abort which closes the queue - the producer catches ClosedQueueError and exits cleanly.
    class DirectoryUploader
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

      def upload(source_directory, bucket, **opts)
        raise ArgumentError, 'Invalid directory' unless Dir.exist?(source_directory)

        uploader = FileUploader.new(
          multipart_threshold: opts.delete(:multipart_threshold),
          http_chunk_size: opts.delete(:http_chunk_size),
          client: @client,
          executor: @executor
        )
        upload_opts = build_upload_opts(opts)
        @producer = FileProducer.new(build_producer_opts(source_directory, bucket, opts))
        uploads, errors = process_upload_queue(uploader, upload_opts)
        build_result(uploads, errors)
      end

      private

      def build_upload_opts(opts)
        { ignore_failure: opts[:ignore_failure] || false }
      end

      def build_producer_opts(source_directory, bucket, opts)
        {
          directory_uploader: self,
          source_dir: source_directory,
          bucket: bucket,
          s3_prefix: opts[:s3_prefix],
          recursive: opts[:recursive] || false,
          follow_symlinks: opts[:follow_symlinks] || false,
          filter_callback: opts[:filter_callback],
          request_callback: opts[:request_callback]
        }
      end

      def build_result(upload_count, errors)
        if @producer&.closed?
          msg = "directory upload failed: #{errors.map(&:message).join('; ')}"
          raise DirectoryUploadError.new(msg, errors)
        else
          {
            completed_uploads: [upload_count - errors.count, 0].max,
            failed_uploads: errors.count,
            errors: errors.any? ? errors : nil
          }.compact
        end
      end

      def process_upload_queue(uploader, opts)
        queue_executor = DefaultExecutor.new(max_threads: 2)
        completion_queue = Queue.new
        posted_count = 0
        errors = []
        begin
          @producer.each do |file|
            queue_executor.post(file) do |f|
              upload_file(f, uploader, errors, opts)
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

      def upload_file(entry, uploader, errors, opts)
        uploader.upload(entry.path, entry.params)
        @logger&.debug("Uploaded #{entry.path} to #{entry.params[:bucket]} as #{entry.params[:key]}")
      rescue StandardError => e
        @logger&.warn("Failed to upload #{entry.path} to #{entry.params[:bucket]}: #{e.message}")
        @mutex.synchronize { errors << e }
        abort unless opts[:ignore_failure]
      end

      # @api private
      class FileProducer
        include Enumerable

        DEFAULT_QUEUE_SIZE = 100
        DONE_MARKER = :done

        def initialize(opts = {})
          @directory_uploader = opts[:directory_uploader]
          @source_dir = opts[:source_dir]
          @bucket = opts[:bucket]
          @s3_prefix = opts[:s3_prefix]
          @recursive = opts[:recursive]
          @follow_symlinks = opts[:follow_symlinks]
          @filter_callback = opts[:filter_callback]
          @request_callback = opts[:request_callback]
          @file_queue = SizedQueue.new(DEFAULT_QUEUE_SIZE)
        end

        def closed?
          @file_queue.closed?
        end

        def close
          @file_queue.close
          @file_queue.clear
        end

        def each
          producer_thread = Thread.new do
            if @recursive
              find_recursively
            else
              find_directly
            end
            @file_queue << DONE_MARKER
          rescue ClosedQueueError
            # abort requested
          rescue StandardError => e
            # encountered a traversal error, we must abort immediately
            close
            raise DirectoryUploadError, "Directory traversal failed for '#{@source_dir}': #{e.message}"
          end

          while (file = @file_queue.shift) && file != DONE_MARKER
            yield file
          end
        ensure
          producer_thread.value
        end

        private

        def apply_request_callback(file_path, params)
          callback_params = @request_callback.call(file_path, params.dup)
          return params unless callback_params.is_a?(Hash) && callback_params.any?

          params.merge(callback_params)
        end

        def build_upload_entry(file_path, key)
          params = { bucket: @bucket, key: @s3_prefix ? File.join(@s3_prefix, key) : key }
          params = apply_request_callback(file_path, params) if @request_callback
          UploadEntry.new(path: file_path, params: params)
        end

        def find_directly
          Dir.each_child(@source_dir) do |entry|
            entry_path = File.join(@source_dir, entry)
            stat = nil

            if @follow_symlinks
              stat = File.stat(entry_path)
              next if stat.directory?
            else
              stat = File.lstat(entry_path)
              next if stat.symlink? || stat.directory?
            end

            next unless stat.file?
            next unless include_file?(entry_path, entry)

            @file_queue << build_upload_entry(entry_path, entry)
          end
        end

        def find_recursively
          if @follow_symlinks
            ancestors = Set.new
            ancestors << File.stat(@source_dir).ino
            scan_directory(@source_dir, ancestors: ancestors)
          else
            scan_directory(@source_dir)
          end
        end

        def include_file?(file_path, file_name)
          return true unless @filter_callback

          @filter_callback.call(file_path, file_name)
        end

        def scan_directory(dir_path, key_prefix: '', ancestors: nil)
          Dir.each_child(dir_path) do |entry|
            full_path = File.join(dir_path, entry)
            next unless include_file?(full_path, entry)

            stat = get_file_stat(full_path)
            next unless stat

            if stat.directory?
              handle_directory(full_path, entry, key_prefix, ancestors)
            elsif stat.file? # skip non-file types
              key = key_prefix.empty? ? entry : File.join(key_prefix, entry)
              @file_queue << build_upload_entry(full_path, key)
            end
          end
        end

        def get_file_stat(full_path)
          return File.stat(full_path) if @follow_symlinks

          lstat = File.lstat(full_path)
          return if lstat.symlink?

          lstat
        end

        def handle_directory(dir_path, dir_name, key_prefix, ancestors)
          ino = nil
          if @follow_symlinks && ancestors
            ino = File.stat(dir_path).ino
            return if ancestors.include?(ino) # cycle detected - skip

            ancestors.add(ino)
          end
          new_prefix = key_prefix.empty? ? dir_name : File.join(key_prefix, dir_name)
          scan_directory(dir_path, key_prefix: new_prefix, ancestors: ancestors)
          ancestors.delete(ino) if @follow_symlinks && ancestors
        end

        # @api private
        class UploadEntry
          def initialize(opts = {})
            @path = opts[:path]
            @params = opts[:params]
          end

          attr_reader :path, :params
        end
      end
    end
  end
end
