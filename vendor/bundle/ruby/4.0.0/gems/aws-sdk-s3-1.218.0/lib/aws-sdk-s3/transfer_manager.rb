# frozen_string_literal: true

module Aws
  module S3
    # A high-level S3 transfer utility that provides enhanced upload and download capabilities with automatic
    # multipart handling, progress tracking, and handling of large files. The following features are supported:
    #
    # * upload a file with multipart upload
    # * upload a stream with multipart upload
    # * upload all files in a directory to an S3 bucket recursively or non-recursively
    # * download an S3 object with multipart download
    # * download all objects in an S3 bucket with same prefix to a local directory
    # * track transfer progress by using progress listener
    #
    # ## Executor Management
    # TransferManager uses executors to handle concurrent operations during multipart transfers. You can control
    # concurrency behavior by providing a custom executor or relying on the default executor management.
    #
    # ### Default Behavior
    # When no `:executor` is provided, TransferManager creates a new DefaultExecutor for each individual
    # operation (`download_file`, `upload_file`, etc.) and automatically shuts it down when that operation completes.
    # Each operation gets its own isolated thread pool with the specified `:thread_count` (default 10 threads).
    #
    # ### Custom Executor
    # You can provide your own executor (e.g., `Concurrent::ThreadPoolExecutor`) for fine-grained control over thread
    # pools and resource management. When using a custom executor, you are responsible for shutting it down
    # when finished. The executor may be reused across multiple TransferManager operations.
    #
    # Custom executors must implement the same interface as DefaultExecutor.
    #
    # **Required methods:**
    #
    #   * `post(*args, &block)` - Execute a task with given arguments and block
    #   * `kill` - Immediately terminate all running tasks
    #
    # **Optional methods:**
    #
    #   * `shutdown(timeout = nil)` - Gracefully shutdown the executor with optional timeout
    #
    # @example Using default executor (automatic creation and shutdown)
    #     tm = TransferManager.new # No executor provided
    #     # DefaultExecutor created, used, and shutdown automatically
    #     tm.download_file('/path/to/file', bucket: 'bucket', key: 'key')
    #
    # @example Using custom executor (manual shutdown required)
    #     require 'concurrent-ruby'
    #
    #     executor = Concurrent::ThreadPoolExecutor.new(max_threads: 5)
    #     tm = TransferManager.new(executor: executor)
    #     tm.download_file('/path/to/file1', bucket: 'bucket', key: 'key1')
    #     executor.shutdown # You must shutdown custom executors
    #
    class TransferManager
      # @param [Hash] options
      # @option options [S3::Client] :client (S3::Client.new)
      #   The S3 client to use for {TransferManager} operations. If not provided, a new default client
      #   will be created automatically.
      # @option options [Object] :executor (nil)
      #   The executor to use for multipart operations. Must implement the same interface as {DefaultExecutor}.
      #   If not provided, a new {DefaultExecutor} will be created automatically for each operation and
      #   shutdown after completion. When provided a custom executor, it will be reused across operations, and
      #   you are responsible for shutting it down when finished.
      # @option options [Logger] :logger (nil)
      #   The Logger instance for logging transfer operations. If not set, logging is disabled.
      def initialize(options = {})
        @client = options[:client] || Client.new
        @executor = options[:executor]
        @logger = options[:logger]
      end

      # @return [S3::Client]
      attr_reader :client

      # @return [Object]
      attr_reader :executor

      # @return [Logger]
      attr_reader :logger

      # Downloads objects in a S3 bucket to a local directory.
      #
      # The downloaded directory structure will match the provided S3 virtual bucket. For example,
      # assume that you have the following keys in your bucket:
      #
      # * sample.jpg
      # * photos/2022/January/sample.jpg
      # * photos/2022/February/sample1.jpg
      # * photos/2022/February/sample2.jpg
      # * photos/2022/February/sample3.jpg
      #
      # Given a request to download bucket to a destination with path of `/test`, the downloaded
      # directory would look like this:
      #
      # ```
      # |- test
      #   |- sample.jpg
      #   |- photos
      #      |- 2022
      #          |- January
      #             |- sample.jpg
      #          |- February
      #             |- sample1.jpg
      #             |- sample2.jpg
      #             |- sample3.jpg
      # ```
      #
      # Directory markers (zero-byte objects ending with `/`) are skipped during download.
      # Existing files with same name as downloaded objects will be overwritten.
      #
      # Object keys containing path traversal sequences (`..` or `.`) will raise an error.
      #
      # @example Downloading buckets to a local directory
      #     tm = TransferManager.new
      #     tm.download_directory('/local/path', bucket: 'my-bucket')
      #     # => {completed_downloads: 7, failed_downloads: 0, errors: 0}
      #
      # @param [String] destination
      #  The location directory path to download objects to. Created if it doesn't exist.
      #  If files with the same names already exist in the destination, they will be overwritten.
      #
      # @param [String] bucket
      #   The name of the bucket to download from.
      #
      # @param [Hash] options
      #
      # @option options [String] :s3_prefix (nil)
      #   Limit the download to objects that begin with the specified prefix. The prefix is
      #   passed directly to the S3 ListObjectsV2 API for filtering. To match only objects
      #   within a specific "folder", include a trailing `/` (e.g., `"photos/"` instead of
      #   `"photos"`). The full object key is preserved in the local file path.
      #
      # @option options [Boolean] :ignore_failure (false)
      #   How to handle individual file download failures:
      #   * `false` (default) - Cancel all ongoing requests, terminate the ongoing downloads and raise an exception
      #   * `true` - Continue downloading remaining objects, report failures in result.
      #
      # @option options [Proc] :filter_callback (nil)
      #   A Proc to filter which objects to download. Called with `(object)` for each object.
      #   Return `true` to download the object, `false` to skip it.
      #
      # @option options [Proc] :request_callback (nil)
      #   A Proc to modify download parameters for each object. Called with `(key, params)`.
      #   Must return the modified parameters.
      #
      # @option options [Integer] :thread_count (10)
      #   The number of threads to use for multipart downloads of individual large files.
      #   Only used when no custom executor is provided to the {TransferManager}.
      #
      # @note On case-insensitive filesystems (e.g., Windows, macOS default), S3 object keys that
      #   differ only by case (e.g., "File.txt" and "file.txt") may overwrite each other when
      #   downloaded. This condition is not automatically detected. Use the `:filter_callback`
      #   option to handle such conflicts if needed.
      #
      # @raise [DirectoryDownloadError] Raised when download fails with `ignore_failure: false` (default)
      #
      # @return [Hash] Returns a hash with download statistics:
      #
      #   * `:completed_downloads` - Number of objects successfully downloaded
      #   * `:failed_downloads` - Number of objects that failed to download
      #   * `:errors` - Array of errors for failed downloads (only present when failures occur)
      def download_directory(destination, bucket:, **options)
        Aws::Plugins::UserAgent.metric('S3_TRANSFER', 'S3_TRANSFER_DOWNLOAD_DIRECTORY') do
          executor = @executor || DefaultExecutor.new(max_threads: options.delete(:thread_count))
          downloader = DirectoryDownloader.new(client: @client, executor: executor, logger: @logger)
          result = downloader.download(destination, bucket: bucket, **options)
          executor.shutdown unless @executor
          result
        end
      end

      # Downloads a file in S3 to a path on disk.
      #
      #     # small files (< 5MB) are downloaded in a single API call
      #     tm = TransferManager.new
      #     tm.download_file('/path/to/file', bucket: 'bucket', key: 'key')
      #
      # Files larger than 5MB are downloaded using multipart method:
      #
      #     # large files are split into parts and the parts are downloaded in parallel
      #     tm.download_file('/path/to/large_file', bucket: 'bucket', key: 'key')
      #
      # You can provide a callback to monitor progress of the download:
      #
      #     # bytes and part_sizes are each an array with 1 entry per part
      #     # part_sizes may not be known until the first bytes are retrieved
      #     progress = proc do |bytes, part_sizes, file_size|
      #       bytes.map.with_index do |b, i|
      #         puts "Part #{i + 1}: #{b} / #{part_sizes[i]}".join(' ') + "Total: #{100.0 * bytes.sum / file_size}%"
      #       end
      #     end
      #     tm.download_file('/path/to/file', bucket: 'bucket', key: 'key', progress_callback: progress)
      #
      # @param [String, Pathname, File, Tempfile] destination
      #   Where to download the file to. This can either be a String or Pathname to the file, an open File object,
      #   or an open Tempfile object. If you pass an open File or Tempfile object, then you are responsible for
      #   closing it after the download completes. Download behavior varies by destination type:
      #
      #   * **String/Pathname paths**: Downloads to a temporary file first, then atomically moves to the final
      #    destination. This prevents corruption of any existing file if the download fails.
      #   * **File/Tempfile objects**: Downloads directly to the file object without using temporary files.
      #    You are responsible for managing the file object's state and closing it after the download completes.
      #    If the download fails, the file object may contain partial data.
      #
      # @param [String] bucket
      #   The name of the S3 bucket to upload to.
      #
      # @param [String] key
      #   The object key name in S3 bucket.
      #
      # @param [Hash] options
      #   Additional options for {Client#get_object} and #{Client#head_object} may be provided.
      #
      # @option options [String] :mode ("auto") `"auto"`, `"single_request"` or `"get_range"`
      #
      #  * `"auto"` mode is enabled by default, which performs `multipart_download`
      #  * `"single_request`" mode forces only 1 GET request is made in download
      #  * `"get_range"` mode requires `:chunk_size` parameter to configured in customizing each range size
      #
      # @option options [Integer] :chunk_size required in `"get_range"` mode.
      #
      # @option options [Integer] :thread_count (10)
      #   The number of threads to use for multipart downloads.
      #   Only used when no custom executor is provided to the {TransferManager}.
      #
      # @option options [String] :checksum_mode ("ENABLED")
      #   This option is deprecated. Use `:response_checksum_validation` on your S3 client instead.
      #   To disable checksum validation, set `response_checksum_validation: 'when_required'`
      #   when creating your S3 client.
      #
      # @option options [Callable] :on_checksum_validated
      #   Called each time a request's checksum is validated with the checksum algorithm and the
      #   response.  For multipart downloads, this will be called for each part that is downloaded and validated.
      #
      # @option options [Proc] :progress_callback
      #   A Proc that will be called when each chunk of the download is received. It will be invoked with
      #   `bytes_read`, `part_sizes`, `file_size`. When the object is downloaded as parts (rather than by ranges),
      #   the `part_sizes` will not be known ahead of time and will be `nil` in the callback until the first bytes
      #   in the part are received.
      #
      # @raise [MultipartDownloadError] Raised when an object validation fails outside of service errors.
      #
      # @return [Boolean] Returns `true` when the file is downloaded without any errors.
      #
      # @see Client#get_object
      # @see Client#head_object
      def download_file(destination, bucket:, key:, **options)
        download_opts = options.merge(bucket: bucket, key: key)
        executor = @executor || DefaultExecutor.new(max_threads: download_opts.delete(:thread_count))
        downloader = FileDownloader.new(client: @client, executor: executor)
        downloader.download(destination, download_opts)
        executor.shutdown unless @executor
        true
      end

      # Uploads all files under the given directory to the provided S3 bucket.
      # The key name transformation depends on the optional prefix.
      #
      # By default, all subdirectories will be uploaded non-recursively and symbolic links are not
      # followed automatically. Assume you have a local directory `/test` with the following structure:
      #
      # ```
      # |- test
      #   |- sample.jpg
      #   |- photos
      #      |- 2022
      #          |- January
      #             |- sample.jpg
      #          |- February
      #             |- sample1.jpg
      #             |- sample2.jpg
      #             |- sample3.jpg
      # ```
      #
      # Give a request to upload directory `/test` to an S3 bucket on default setting, the target bucket will have the
      # following S3 objects:
      #
      # * sample.jpg
      #
      # If `:recursive` set to `true`, the target bucket will have the following S3 buckets:
      #
      # * sample.jpg
      # * photos/2022/January/sample.jpg
      # * photos/2022/February/sample1.jpg
      # * photos/2022/February/sample2.jpg
      # * photos/2022/February/sample3.jpg
      #
      # Only regular files are uploaded; special files (sockets, pipes, devices) are skipped.
      # Symlink cycles are detected and skipped when following symlinks.
      # Empty directories are not represented in S3. Existing S3 objects with the same key are
      # overwritten.
      #
      # @example Uploading a directory
      #     tm = TransferManager.new
      #     tm.upload_directory('/path/to/directory', bucket: 'bucket')
      #     # => {completed_uploads: 7, failed_uploads: 0}
      #
      # @example Using filter callback to upload only text files
      #     tm = TransferManager.new
      #     filter = proc do |file_path, file_name|
      #       File.extname(file_name) == '.txt'  # Only upload .txt files
      #     end
      #     tm.upload_directory('/path/to/directory', bucket: 'bucket', filter_callback: filter)
      #
      # @param [String, Pathname, File, Tempfile] source
      #  The source directory to upload.
      #
      # @param [String] bucket
      #   The name of the bucket to upload objects to.
      #
      # @param [Hash] options
      #
      # @option options [String] :s3_prefix (nil)
      #   The S3 key prefix to use for each object. If not provided, files will be uploaded to the root of the bucket.
      #
      # @option options [Boolean] :recursive (false)
      #   Whether to upload directories recursively:
      #
      #   * `false` (default) - only files in the top-level directory are uploaded, subdirectories are ignored.
      #   * `true` - all files and subdirectories are uploaded recursively.
      #
      # @option options [Boolean] :follow_symlinks (false)
      #   Whether to follow symbolic links when traversing the file tree:
      #
      #   * `false` (default) - symbolic links are ignored and not uploaded.
      #   * `true` - symbolic links are followed and their target files/directories are uploaded. Symlink cycles
      #     are detected and skipped.
      #
      # @option options [Boolean] :ignore_failure (false)
      #   How to handle individual file upload failures:
      #
      #   * `false` (default) - Cancel all ongoing requests, terminate the directory upload, and raise an exception
      #   * `true` - Ignore the failure and continue the transfer for other files
      #
      # @option options [Proc] :filter_callback (nil)
      #   A Proc to filter which files to upload. Called with `(file_path, file_name)` for each file.
      #   Return `true` to upload the file, `false` to skip it.
      #
      # @option options [Proc] :request_callback (nil)
      #   A Proc to modify upload parameters for each file. Called with `(file_path, params)`.
      #   Must return the modified parameters.
      #
      # @option options [Integer] :http_chunk_size (16384) Size in bytes for each chunk when streaming request bodies
      #   over HTTP. Controls the buffer size used when sending data to S3. Larger values may improve throughput by
      #   reducing the number of network writes, but use more memory. Custom values must be at least 16KB.
      #   Only Ruby MRI is supported.
      #
      # @option options [Integer] :thread_count (10)
      #   The number of threads to use for multipart uploads of individual large files.
      #   Only used when no custom executor is provided to the {TransferManager}.
      #
      # @raise [DirectoryUploadError] Raised when:
      #
      #   * Upload failure with `ignore_failure: false` (default)
      #   * Directory traversal failure (permission denied, broken symlink, etc.)
      #
      # @return [Hash] Returns a hash with upload statistics:
      #
      #   * `:completed_uploads` - Number of files successfully uploaded
      #   * `:failed_uploads` - Number of files that failed to upload
      #   * `:errors` - Array of error objects for failed uploads (only present when failures occur)
      def upload_directory(source, bucket:, **options)
        Aws::Plugins::UserAgent.metric('S3_TRANSFER', 'S3_TRANSFER_UPLOAD_DIRECTORY') do
          executor = @executor || DefaultExecutor.new(max_threads: options.delete(:thread_count))
          uploader = DirectoryUploader.new(client: @client, executor: executor, logger: @logger)
          result = uploader.upload(source, bucket, **options.merge(http_chunk_size: resolve_http_chunk_size(options)))
          executor.shutdown unless @executor
          result
        end
      end

      # Uploads a file from disk to S3.
      #
      #     # a small file are uploaded with PutObject API
      #     tm = TransferManager.new
      #     tm.upload_file('/path/to/small_file', bucket: 'bucket', key: 'key')
      #
      # Files larger than or equal to `:multipart_threshold` are uploaded using multipart upload APIs.
      #
      #     # large files are automatically split into parts and the parts are uploaded in parallel
      #     tm.upload_file('/path/to/large_file', bucket: 'bucket', key: 'key')
      #
      # The response of the S3 upload API is yielded if a block given.
      #
      #     # API response will have etag value of the file
      #     tm.upload_file('/path/to/file', bucket: 'bucket', key: 'key') do |response|
      #       etag = response.etag
      #     end
      #
      # You can provide a callback to monitor progress of the upload:
      #
      #     # bytes and totals are each an array with 1 entry per part
      #     progress = proc do |bytes, totals|
      #       bytes.map.with_index do |b, i|
      #           puts "Part #{i + 1}: #{b} / #{totals[i]} " + "Total: #{100.0 * bytes.sum / totals.sum}%"
      #       end
      #     end
      #     tm.upload_file('/path/to/file', bucket: 'bucket', key: 'key', progress_callback: progress)
      #
      # @param [String, Pathname, File, Tempfile] source
      #   A file on the local file system that will be uploaded. This can either be a `String` or `Pathname` to the
      #   file, an open `File` object, or an open `Tempfile` object. If you pass an open `File` or `Tempfile` object,
      #   then you are responsible for closing it after the upload completes. When using an open Tempfile, rewind it
      #   before uploading or else the object will be empty.
      #
      # @param [String] bucket
      #   The name of the S3 bucket to upload to.
      #
      # @param [String] key
      #   The object key name for the uploaded file.
      #
      # @param [Hash] options
      #   Additional options for {Client#put_object} when file sizes below the multipart threshold.
      #   For files larger than the multipart threshold, options for {Client#create_multipart_upload},
      #   {Client#complete_multipart_upload}, and {Client#upload_part} can be provided.
      #
      # @option options [Integer] :multipart_threshold (104857600)
      #   Files larger han or equal to `:multipart_threshold` are uploaded using the S3 multipart upload APIs.
      #   Default threshold is `100MB`.
      #
      # @option options [Integer] :thread_count (10)
      #   The number of threads to use for multipart uploads.
      #   Only used when no custom executor is provided to the {TransferManager}.
      #
      # @option option [Integer] :http_chunk_size (16384) Size in bytes for each chunk when streaming request bodies
      #   over HTTP. Controls the buffer size used when sending data to S3. Larger values may improve throughput by
      #   reducing the number of network writes, but use more memory. Custom values must be at least 16KB.
      #   Only Ruby MRI is supported.
      #
      # @option options [Proc] :progress_callback (nil)
      #   A Proc that will be called when each chunk of the upload is sent.
      #   It will be invoked with `[bytes_read]` and  `[total_sizes]`.
      #
      # @raise [MultipartUploadError] If a file is being uploaded in parts, and the upload can not be completed,
      #   then the upload is aborted and this error is raised.  The raised error has a `#errors` method that
      #   returns the failures that caused the upload to be aborted.
      #
      # @return [Boolean] Returns `true` when the file is uploaded without any errors.
      #
      # @see Client#put_object
      # @see Client#create_multipart_upload
      # @see Client#complete_multipart_upload
      # @see Client#upload_part
      def upload_file(source, bucket:, key:, **options)
        upload_opts = options.merge(bucket: bucket, key: key)
        http_chunk_size = resolve_http_chunk_size(upload_opts)

        executor = @executor || DefaultExecutor.new(max_threads: upload_opts.delete(:thread_count))
        uploader = FileUploader.new(
          multipart_threshold: upload_opts.delete(:multipart_threshold),
          http_chunk_size: http_chunk_size,
          client: @client,
          executor: executor
        )
        response = uploader.upload(source, upload_opts)
        yield response if block_given?
        executor.shutdown unless @executor
        true
      end

      # Uploads a stream in a streaming fashion to S3.
      #
      # Passed chunks automatically split into multipart upload parts and the parts are uploaded in parallel.
      # This allows for streaming uploads that never touch the disk.
      #
      # **Note**: There are known issues in JRuby until jruby-9.1.15.0, so avoid using this with older JRuby versions.
      #
      # @example Streaming chunks of data
      #     tm = TransferManager.new
      #     tm.upload_stream(bucket: 'bucket', key: 'key') do |write_stream|
      #       10.times { write_stream << 'foo' }
      #     end
      # @example Streaming chunks of data
      #     tm.upload_stream(bucket: 'bucket', key: 'key') do |write_stream|
      #       IO.copy_stream(IO.popen('ls'), write_stream)
      #     end
      # @example Streaming chunks of data
      #     tm.upload_stream(bucket: 'bucket', key: 'key') do |write_stream|
      #       IO.copy_stream(STDIN, write_stream)
      #     end
      #
      # @param [String] bucket
      #   The name of the S3 bucket to upload to.
      #
      # @param [String] key
      #   The object key name for the uploaded file.
      #
      # @param [Hash] options
      #   Additional options for {Client#create_multipart_upload}, {Client#complete_multipart_upload}, and
      #   {Client#upload_part} can be provided.
      #
      # @option options [Integer] :thread_count (10)
      #   The number of parallel multipart uploads. Only used when no custom executor is provided (creates
      #   {DefaultExecutor} with the given thread count). An additional thread is used internally for task coordination.
      #
      # @option options [Boolean] :tempfile (false)
      #   Normally read data is stored in memory when building the parts in order to complete the underlying
      #   multipart upload. By passing `:tempfile => true`, the data read will be temporarily stored on disk reducing
      #   the memory footprint vastly.
      #
      # @option options [Integer] :part_size (5242880)
      #   Define how big each part size but the last should be. Default `:part_size` is `5 * 1024 * 1024`.
      #
      # @raise [MultipartUploadError] If an object is being uploaded in parts, and the upload can not be completed,
      #   then the upload is aborted and this error is raised. The raised error has a `#errors` method that returns
      #   the failures that caused the upload to be aborted.
      #
      # @return [Boolean] Returns `true` when the object is uploaded without any errors.
      #
      # @see Client#create_multipart_upload
      # @see Client#complete_multipart_upload
      # @see Client#upload_part
      def upload_stream(bucket:, key:, **options, &block)
        upload_opts = options.merge(bucket: bucket, key: key)
        executor = @executor || DefaultExecutor.new(max_threads: upload_opts.delete(:thread_count))
        uploader = MultipartStreamUploader.new(
          client: @client,
          executor: executor,
          tempfile: upload_opts.delete(:tempfile),
          part_size: upload_opts.delete(:part_size)
        )
        uploader.upload(upload_opts, &block)
        executor.shutdown unless @executor
        true
      end

      private

      def resolve_http_chunk_size(opts)
        return if defined?(JRUBY_VERSION)

        chunk = opts.delete(:http_chunk_size)
        if chunk && chunk < Aws::Plugins::ChecksumAlgorithm::DEFAULT_TRAILER_CHUNK_SIZE
          raise ArgumentError, ':http_chunk_size must be at least 16384 bytes (16KB)'
        end

        chunk
      end
    end
  end
end
