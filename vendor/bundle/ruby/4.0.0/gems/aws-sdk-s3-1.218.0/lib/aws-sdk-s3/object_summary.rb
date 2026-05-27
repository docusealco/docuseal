# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  class ObjectSummary

    extend Aws::Deprecations

    # @overload def initialize(bucket_name, key, options = {})
    #   @param [String] bucket_name
    #   @param [String] key
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :bucket_name
    #   @option options [required, String] :key
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @bucket_name = extract_bucket_name(args, options)
      @key = extract_key(args, options)
      @data = options.delete(:data)
      @client = options.delete(:client) || Client.new(options)
      @waiter_block_warned = false
    end

    # @!group Read-Only Attributes

    # @return [String]
    def bucket_name
      @bucket_name
    end

    # @return [String]
    def key
      @key
    end

    # Creation date of the object.
    # @return [Time]
    def last_modified
      data[:last_modified]
    end

    # The entity tag is a hash of the object. The ETag reflects changes only
    # to the contents of an object, not its metadata. The ETag may or may
    # not be an MD5 digest of the object data. Whether or not it is depends
    # on how the object was created and how it is encrypted as described
    # below:
    #
    # * Objects created by the PUT Object, POST Object, or Copy operation,
    #   or through the Amazon Web Services Management Console, and are
    #   encrypted by SSE-S3 or plaintext, have ETags that are an MD5 digest
    #   of their object data.
    #
    # * Objects created by the PUT Object, POST Object, or Copy operation,
    #   or through the Amazon Web Services Management Console, and are
    #   encrypted by SSE-C or SSE-KMS, have ETags that are not an MD5 digest
    #   of their object data.
    #
    # * If an object is created by either the Multipart Upload or Part Copy
    #   operation, the ETag is not an MD5 digest, regardless of the method
    #   of encryption. If an object is larger than 16 MB, the Amazon Web
    #   Services Management Console will upload or copy that object as a
    #   Multipart Upload, and therefore the ETag will not be an MD5 digest.
    #
    # <note markdown="1"> **Directory buckets** - MD5 is not supported by directory buckets.
    #
    #  </note>
    # @return [String]
    def etag
      data[:etag]
    end

    # The algorithm that was used to create a checksum of the object.
    # @return [Array<String>]
    def checksum_algorithm
      data[:checksum_algorithm]
    end

    # The checksum type that is used to calculate the object’s checksum
    # value. For more information, see [Checking object integrity][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @return [String]
    def checksum_type
      data[:checksum_type]
    end

    # Size in bytes of the object
    # @return [Integer]
    def size
      data[:size]
    end

    # The class of storage used to store the object.
    #
    # <note markdown="1"> **Directory buckets** - Directory buckets only support
    # `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    # Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent Access
    # storage class) in Dedicated Local Zones.
    #
    #  </note>
    # @return [String]
    def storage_class
      data[:storage_class]
    end

    # The owner of the object
    #
    # <note markdown="1"> **Directory buckets** - The bucket owner is returned as the object
    # owner.
    #
    #  </note>
    # @return [Types::Owner]
    def owner
      data[:owner]
    end

    # Specifies the restoration status of an object. Objects in certain
    # storage classes must be restored before they can be retrieved. For
    # more information about these storage classes and how to work with
    # archived objects, see [ Working with archived objects][1] in the
    # *Amazon S3 User Guide*.
    #
    # <note markdown="1"> This functionality is not supported for directory buckets. Directory
    # buckets only support `EXPRESS_ONEZONE` (the S3 Express One Zone
    # storage class) in Availability Zones and `ONEZONE_IA` (the S3 One
    # Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/archived-objects.html
    # @return [Types::RestoreStatus]
    def restore_status
      data[:restore_status]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # @raise [NotImplementedError]
    # @api private
    def load
      msg = "#load is not implemented, data only available via enumeration"
      raise NotImplementedError, msg
    end
    alias :reload :load

    # @raise [NotImplementedError] Raises when {#data_loaded?} is `false`.
    # @return [Types::Object]
    #   Returns the data for this {ObjectSummary}.
    def data
      load unless @data
      @data
    end

    # @return [Boolean]
    #   Returns `true` if this resource is loaded.  Accessing attributes or
    #   {#data} on an unloaded resource will trigger a call to {#load}.
    def data_loaded?
      !!@data
    end

    # @param [Hash] options ({})
    # @return [Boolean]
    #   Returns `true` if the ObjectSummary exists.
    def exists?(options = {})
      begin
        wait_until_exists(options.merge(max_attempts: 1))
        true
      rescue Aws::Waiters::Errors::UnexpectedError => e
        raise e.error
      rescue Aws::Waiters::Errors::WaiterFailed
        false
      end
    end

    # @param [Hash] options ({})
    # @option options [Integer] :max_attempts (20)
    # @option options [Float] :delay (5)
    # @option options [Proc] :before_attempt
    # @option options [Proc] :before_wait
    # @return [ObjectSummary]
    def wait_until_exists(options = {}, &block)
      options, params = separate_params_and_options(options)
      waiter = Waiters::ObjectExists.new(options)
      yield_waiter_and_warn(waiter, &block) if block_given?
      Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        waiter.wait(params.merge(bucket: @bucket_name,
        key: @key))
      end
      ObjectSummary.new({
        bucket_name: @bucket_name,
        key: @key,
        client: @client
      })
    end

    # @param [Hash] options ({})
    # @option options [Integer] :max_attempts (20)
    # @option options [Float] :delay (5)
    # @option options [Proc] :before_attempt
    # @option options [Proc] :before_wait
    # @return [ObjectSummary]
    def wait_until_not_exists(options = {}, &block)
      options, params = separate_params_and_options(options)
      waiter = Waiters::ObjectNotExists.new(options)
      yield_waiter_and_warn(waiter, &block) if block_given?
      Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        waiter.wait(params.merge(bucket: @bucket_name,
        key: @key))
      end
      ObjectSummary.new({
        bucket_name: @bucket_name,
        key: @key,
        client: @client
      })
    end

    # @deprecated Use [Aws::S3::Client] #wait_until instead
    #
    # Waiter polls an API operation until a resource enters a desired
    # state.
    #
    # @note The waiting operation is performed on a copy. The original resource
    #   remains unchanged.
    #
    # ## Basic Usage
    #
    # Waiter will polls until it is successful, it fails by
    # entering a terminal state, or until a maximum number of attempts
    # are made.
    #
    #     # polls in a loop until condition is true
    #     resource.wait_until(options) {|resource| condition}
    #
    # ## Example
    #
    #     instance.wait_until(max_attempts:10, delay:5) do |instance|
    #       instance.state.name == 'running'
    #     end
    #
    # ## Configuration
    #
    # You can configure the maximum number of polling attempts, and the
    # delay (in seconds) between each polling attempt. The waiting condition is
    # set by passing a block to {#wait_until}:
    #
    #     # poll for ~25 seconds
    #     resource.wait_until(max_attempts:5,delay:5) {|resource|...}
    #
    # ## Callbacks
    #
    # You can be notified before each polling attempt and before each
    # delay. If you throw `:success` or `:failure` from these callbacks,
    # it will terminate the waiter.
    #
    #     started_at = Time.now
    #     # poll for 1 hour, instead of a number of attempts
    #     proc = Proc.new do |attempts, response|
    #       throw :failure if Time.now - started_at > 3600
    #     end
    #
    #       # disable max attempts
    #     instance.wait_until(before_wait:proc, max_attempts:nil) {...}
    #
    # ## Handling Errors
    #
    # When a waiter is successful, it returns the Resource. When a waiter
    # fails, it raises an error.
    #
    #     begin
    #       resource.wait_until(...)
    #     rescue Aws::Waiters::Errors::WaiterFailed
    #       # resource did not enter the desired state in time
    #     end
    #
    # @yieldparam [Resource] resource to be used in the waiting condition.
    #
    # @raise [Aws::Waiters::Errors::FailureStateError] Raised when the waiter
    #   terminates because the waiter has entered a state that it will not
    #   transition out of, preventing success.
    #
    #   yet successful.
    #
    # @raise [Aws::Waiters::Errors::UnexpectedError] Raised when an error is
    #   encountered while polling for a resource that is not expected.
    #
    # @raise [NotImplementedError] Raised when the resource does not
    #
    # @option options [Integer] :max_attempts (10) Maximum number of
    # attempts
    # @option options [Integer] :delay (10) Delay between each
    # attempt in seconds
    # @option options [Proc] :before_attempt (nil) Callback
    # invoked before each attempt
    # @option options [Proc] :before_wait (nil) Callback
    # invoked before each wait
    # @return [Resource] if the waiter was successful
    def wait_until(options = {}, &block)
      self_copy = self.dup
      attempts = 0
      options[:max_attempts] = 10 unless options.key?(:max_attempts)
      options[:delay] ||= 10
      options[:poller] = Proc.new do
        attempts += 1
        if block.call(self_copy)
          [:success, self_copy]
        else
          self_copy.reload unless attempts == options[:max_attempts]
          :retry
        end
      end
      Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        Aws::Waiters::Waiter.new(options).wait({})
      end
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   object_summary.copy_from({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     cache_control: "CacheControl",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_type: "ContentType",
    #     copy_source: "CopySource", # required
    #     copy_source_if_match: "CopySourceIfMatch",
    #     copy_source_if_modified_since: Time.now,
    #     copy_source_if_none_match: "CopySourceIfNoneMatch",
    #     copy_source_if_unmodified_since: Time.now,
    #     expires: Time.now,
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     if_match: "IfMatch",
    #     if_none_match: "IfNoneMatch",
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     metadata_directive: "COPY", # accepts COPY, REPLACE
    #     tagging_directive: "COPY", # accepts COPY, REPLACE
    #     server_side_encryption: "AES256", # accepts AES256, aws:fsx, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW, EXPRESS_ONEZONE, FSX_OPENZFS, FSX_ONTAP
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     copy_source_sse_customer_algorithm: "CopySourceSSECustomerAlgorithm",
    #     copy_source_sse_customer_key: "CopySourceSSECustomerKey",
    #     copy_source_sse_customer_key_md5: "CopySourceSSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #     expected_source_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :acl
    #   The canned access control list (ACL) to apply to the object.
    #
    #   When you copy an object, the ACL metadata is not preserved and is set
    #   to `private` by default. Only the owner has full access control. To
    #   override the default ACL setting, specify a new ACL when you generate
    #   a copy request. For more information, see [Using ACLs][1].
    #
    #   If the destination bucket that you're copying objects to uses the
    #   bucket owner enforced setting for S3 Object Ownership, ACLs are
    #   disabled and no longer affect permissions. Buckets that use this
    #   setting only accept `PUT` requests that don't specify an ACL or `PUT`
    #   requests that specify bucket owner full control ACLs, such as the
    #   `bucket-owner-full-control` canned ACL or an equivalent form of this
    #   ACL expressed in the XML format. For more information, see
    #   [Controlling ownership of objects and disabling ACLs][2] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> * If your destination bucket uses the bucket owner enforced setting
    #     for Object Ownership, all objects written to the bucket by any
    #     account will be owned by the bucket owner.
    #
    #   * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # @option options [String] :cache_control
    #   Specifies the caching behavior along the request/reply chain.
    # @option options [String] :checksum_algorithm
    #   Indicates the algorithm that you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   When you copy an object, if the source object has a checksum, that
    #   checksum value will be copied to the new object by default. If the
    #   `CopyObject` request does not include this `x-amz-checksum-algorithm`
    #   header, the checksum algorithm will be copied from the source object
    #   to the destination object (if it's present on the source object). You
    #   can optionally specify a different checksum algorithm to use with the
    #   `x-amz-checksum-algorithm` header. Unrecognized or unsupported values
    #   will respond with the HTTP status code `400 Bad Request`.
    #
    #   <note markdown="1"> For directory buckets, when you use Amazon Web Services SDKs, `CRC32`
    #   is the default checksum algorithm that's used for performance.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :content_disposition
    #   Specifies presentational information for the object. Indicates whether
    #   an object should be displayed in a web browser or downloaded as a
    #   file. It allows specifying the desired filename for the downloaded
    #   file.
    # @option options [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field.
    #
    #   <note markdown="1"> For directory buckets, only the `aws-chunked` value is supported in
    #   this header field.
    #
    #    </note>
    # @option options [String] :content_language
    #   The language the content is in.
    # @option options [String] :content_type
    #   A standard MIME type that describes the format of the object data.
    # @option options [required, String] :copy_source
    #   Specifies the source object for the copy operation. The source object
    #   can be up to 5 GB. If the source object is an object that was uploaded
    #   by using a multipart upload, the object copy will be a single part
    #   object after the source object is copied to the destination bucket.
    #
    #   You specify the value of the copy source in one of two formats,
    #   depending on whether you want to access the source object through an
    #   [access point][1]:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and the key of the source object, separated by
    #     a slash (/). For example, to copy the object `reports/january.pdf`
    #     from the general purpose bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be
    #     URL-encoded. To copy the object `reports/january.pdf` from the
    #     directory bucket `awsexamplebucket--use1-az5--x-s3`, use
    #     `awsexamplebucket--use1-az5--x-s3/reports/january.pdf`. The value
    #     must be URL-encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through access
    #     point `my-access-point` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf`.
    #     The value must be URL encoded.
    #
    #     <note markdown="1"> * Amazon S3 supports copy operations using Access points only when
    #       the source and destination buckets are in the same Amazon Web
    #       Services Region.
    #
    #     * Access points are not supported by directory buckets.
    #
    #      </note>
    #
    #     Alternatively, for objects accessed through Amazon S3 on Outposts,
    #     specify the ARN of the object as accessed in the format
    #     `arn:aws:s3-outposts:<Region>:<account-id>:outpost/<outpost-id>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     outpost `my-outpost` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/object/reports/january.pdf`.
    #     The value must be URL-encoded.
    #
    #   If your source bucket versioning is enabled, the `x-amz-copy-source`
    #   header by default identifies the current version of an object to copy.
    #   If the current version is a delete marker, Amazon S3 behaves as if the
    #   object was deleted. To copy a different version, use the `versionId`
    #   query parameter. Specifically, append `?versionId=<version-id>` to the
    #   value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #   If you enable versioning on the destination bucket, Amazon S3
    #   generates a unique version ID for the copied object. This version ID
    #   is different from the version ID of the source object. Amazon S3
    #   returns the version ID of the copied object in the `x-amz-version-id`
    #   response header in the response.
    #
    #   If you do not enable versioning or suspend it on the destination
    #   bucket, the version ID that Amazon S3 generates in the
    #   `x-amz-version-id` response header is always null.
    #
    #   <note markdown="1"> **Directory buckets** - S3 Versioning isn't enabled and supported for
    #   directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
    # @option options [String] :copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified tag.
    #
    #   If both the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns `200 OK` and copies
    #   the data:
    #
    #   * `x-amz-copy-source-if-match` condition evaluates to true
    #
    #   * `x-amz-copy-source-if-unmodified-since` condition evaluates to false
    # @option options [Time,DateTime,Date,Integer,String] :copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #
    #   If both the `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns the `412
    #   Precondition Failed` response code:
    #
    #   * `x-amz-copy-source-if-none-match` condition evaluates to false
    #
    #   * `x-amz-copy-source-if-modified-since` condition evaluates to true
    # @option options [String] :copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #
    #   If both the `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns the `412
    #   Precondition Failed` response code:
    #
    #   * `x-amz-copy-source-if-none-match` condition evaluates to false
    #
    #   * `x-amz-copy-source-if-modified-since` condition evaluates to true
    # @option options [Time,DateTime,Date,Integer,String] :copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #
    #   If both the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns `200 OK` and copies
    #   the data:
    #
    #   * `x-amz-copy-source-if-match` condition evaluates to true
    #
    #   * `x-amz-copy-source-if-unmodified-since` condition evaluates to false
    # @option options [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable.
    # @option options [String] :grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :if_match
    #   Copies the object if the entity tag (ETag) of the destination object
    #   matches the specified tag. If the ETag values do not match, the
    #   operation returns a `412 Precondition Failed` error. If a concurrent
    #   operation occurs during the upload S3 returns a `409
    #   ConditionalRequestConflict` response. On a 409 failure you should
    #   fetch the object's ETag and retry the upload.
    #
    #   Expects the ETag value as a string.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [String] :if_none_match
    #   Copies the object only if the object key name at the destination does
    #   not already exist in the bucket specified. Otherwise, Amazon S3
    #   returns a `412 Precondition Failed` error. If a concurrent operation
    #   occurs during the upload S3 returns a `409 ConditionalRequestConflict`
    #   response. On a 409 failure you should retry the upload.
    #
    #   Expects the '*' (asterisk) character.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    # @option options [String] :metadata_directive
    #   Specifies whether the metadata is copied from the source object or
    #   replaced with metadata that's provided in the request. When copying
    #   an object, you can preserve all metadata (the default) or specify new
    #   metadata. If this header isn’t specified, `COPY` is the default
    #   behavior.
    #
    #   **General purpose bucket** - For general purpose buckets, when you
    #   grant permissions, you can use the `s3:x-amz-metadata-directive`
    #   condition key to enforce certain metadata behavior when objects are
    #   uploaded. For more information, see [Amazon S3 condition key
    #   examples][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> `x-amz-website-redirect-location` is unique to each object and is not
    #   copied when using the `x-amz-metadata-directive` header. To copy the
    #   value, you must specify `x-amz-website-redirect-location` in the
    #   request header.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/amazon-s3-policy-keys.html
    # @option options [String] :tagging_directive
    #   Specifies whether the object tag-set is copied from the source object
    #   or replaced with the tag-set that's provided in the request.
    #
    #   The default value is `COPY`.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets in a `CopyObject`
    #   operation, only the empty tag-set is supported. Any requests that
    #   attempt to write non-empty tags into directory buckets will receive a
    #   `501 Not Implemented` status code. When the destination bucket is a
    #   directory bucket, you will receive a `501 Not Implemented` response in
    #   any of the following situations:
    #
    #    * When you attempt to `COPY` the tag-set from an S3 source object that
    #     has non-empty tags.
    #
    #   * When you attempt to `REPLACE` the tag-set of a source object and set
    #     a non-empty value to `x-amz-tagging`.
    #
    #   * When you don't set the `x-amz-tagging-directive` header and the
    #     source object has non-empty tags. This is because the default value
    #     of `x-amz-tagging-directive` is `COPY`.
    #
    #    Because only the empty tag-set is supported for directory buckets in a
    #   `CopyObject` operation, the following situations are allowed:
    #
    #    * When you attempt to `COPY` the tag-set from a directory bucket
    #     source object that has no tags to a general purpose bucket. It
    #     copies an empty tag-set to the destination object.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and set the `x-amz-tagging` value of the directory
    #     bucket destination object to empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a general purpose
    #     bucket source object that has non-empty tags and set the
    #     `x-amz-tagging` value of the directory bucket destination object to
    #     empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and don't set the `x-amz-tagging` value of the
    #     directory bucket destination object. This is because the default
    #     value of `x-amz-tagging` is the empty value.
    #
    #    </note>
    # @option options [String] :server_side_encryption
    #   The server-side encryption algorithm used when storing this object in
    #   Amazon S3. Unrecognized or unsupported values won’t write a
    #   destination object and will receive a `400 Bad Request` response.
    #
    #   Amazon S3 automatically encrypts all new objects that are copied to an
    #   S3 bucket. When copying an object, if you don't specify encryption
    #   information in your copy request, the encryption setting of the target
    #   object is set to the default encryption configuration of the
    #   destination bucket. By default, all buckets have a base level of
    #   encryption configuration that uses server-side encryption with Amazon
    #   S3 managed keys (SSE-S3). If the destination bucket has a different
    #   default encryption configuration, Amazon S3 uses the corresponding
    #   encryption key to encrypt the target object copy.
    #
    #   With server-side encryption, Amazon S3 encrypts your data as it writes
    #   your data to disks in its data centers and decrypts the data when you
    #   access it. For more information about server-side encryption, see
    #   [Using Server-Side Encryption][1] in the *Amazon S3 User Guide*.
    #
    #   <b>General purpose buckets </b>
    #
    #   * For general purpose buckets, there are the following supported
    #     options for server-side encryption: server-side encryption with Key
    #     Management Service (KMS) keys (SSE-KMS), dual-layer server-side
    #     encryption with Amazon Web Services KMS keys (DSSE-KMS), and
    #     server-side encryption with customer-provided encryption keys
    #     (SSE-C). Amazon S3 uses the corresponding KMS key, or a
    #     customer-provided key to encrypt the target object copy.
    #
    #   * When you perform a `CopyObject` operation, if you want to use a
    #     different type of encryption setting for the target object, you can
    #     specify appropriate encryption-related headers to encrypt the target
    #     object with an Amazon S3 managed key, a KMS key, or a
    #     customer-provided key. If the encryption setting in your request is
    #     different from the default encryption configuration of the
    #     destination bucket, the encryption setting in your request takes
    #     precedence.
    #
    #   <b>Directory buckets </b>
    #
    #   * For directory buckets, there are only two supported options for
    #     server-side encryption: server-side encryption with Amazon S3
    #     managed keys (SSE-S3) (`AES256`) and server-side encryption with KMS
    #     keys (SSE-KMS) (`aws:kms`). We recommend that the bucket's default
    #     encryption uses the desired encryption configuration and you don't
    #     override the bucket default encryption in your `CreateSession`
    #     requests or `PUT` object requests. Then, new objects are
    #     automatically encrypted with the desired encryption settings. For
    #     more information, see [Protecting data with server-side
    #     encryption][2] in the *Amazon S3 User Guide*. For more information
    #     about the encryption overriding behaviors in directory buckets, see
    #     [Specifying server-side encryption with KMS for new object
    #     uploads][3].
    #
    #   * To encrypt new object copies to a directory bucket with SSE-KMS, we
    #     recommend you specify SSE-KMS as the directory bucket's default
    #     encryption configuration with a KMS key (specifically, a [customer
    #     managed key][4]). The [Amazon Web Services managed key][5]
    #     (`aws/s3`) isn't supported. Your SSE-KMS configuration can only
    #     support 1 [customer managed key][4] per directory bucket for the
    #     lifetime of the bucket. After you specify a customer managed key for
    #     SSE-KMS, you can't override the customer managed key for the
    #     bucket's SSE-KMS configuration. Then, when you perform a
    #     `CopyObject` operation and want to specify server-side encryption
    #     settings for new object copies with SSE-KMS in the
    #     encryption-related request headers, you must ensure the encryption
    #     key is the same customer managed key that you specified for the
    #     directory bucket's default encryption configuration.
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data stored
    #     in Amazon FSx file systems using S3 access points, the only valid
    #     server side encryption option is `aws:fsx`. All Amazon FSx file
    #     systems have encryption configured by default and are encrypted at
    #     rest. Data is automatically encrypted before being written to the
    #     file system, and automatically decrypted as it is read. These
    #     processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # @option options [String] :storage_class
    #   If the `x-amz-storage-class` header is not used, the copied object
    #   will be stored in the `STANDARD` Storage Class by default. The
    #   `STANDARD` storage class provides high durability and high
    #   availability. Depending on performance needs, you can specify a
    #   different Storage Class.
    #
    #   <note markdown="1"> * <b>Directory buckets </b> - Directory buckets only support
    #     `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #     Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #     Access storage class) in Dedicated Local Zones. Unsupported storage
    #     class values won't write a destination object and will respond with
    #     the HTTP status code `400 Bad Request`.
    #
    #   * <b>Amazon S3 on Outposts </b> - S3 on Outposts only uses the
    #     `OUTPOSTS` Storage Class.
    #
    #    </note>
    #
    #   You can use the `CopyObject` action to change the storage class of an
    #   object that is already stored in Amazon S3 by using the
    #   `x-amz-storage-class` header. For more information, see [Storage
    #   Classes][1] in the *Amazon S3 User Guide*.
    #
    #   Before using an object as a source object for the copy operation, you
    #   must restore a copy of it if it meets any of the following conditions:
    #
    #   * The storage class of the source object is `GLACIER` or
    #     `DEEP_ARCHIVE`.
    #
    #   * The storage class of the source object is `INTELLIGENT_TIERING` and
    #     it's [S3 Intelligent-Tiering access tier][2] is `Archive Access` or
    #     `Deep Archive Access`.
    #
    #   For more information, see [RestoreObject][3] and [Copying Objects][4]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/intelligent-tiering-overview.html#intel-tiering-tier-definition
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjectsExamples.html
    # @option options [String] :website_redirect_location
    #   If the destination bucket is configured as a website, redirects
    #   requests for this object copy to another object in the same bucket or
    #   to an external URL. Amazon S3 stores the value of this header in the
    #   object metadata. This value is unique to each object and is not copied
    #   when using the `x-amz-metadata-directive` header. Instead, you may opt
    #   to provide this header in combination with the
    #   `x-amz-metadata-directive` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, `AES256`).
    #
    #   When you perform a `CopyObject` operation, if you want to use a
    #   different type of encryption setting for the target object, you can
    #   specify appropriate encryption-related headers to encrypt the target
    #   object with an Amazon S3 managed key, a KMS key, or a
    #   customer-provided key. If the encryption setting in your request is
    #   different from the default encryption configuration of the destination
    #   bucket, the encryption setting in your request takes precedence.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded. Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. All GET and PUT requests for an object protected by
    #   KMS will fail if they're not made via SSL or using SigV4. For
    #   information about configuring any of the officially supported Amazon
    #   Web Services SDKs and Amazon Web Services CLI, see [Specifying the
    #   Signature Version in Request Authentication][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed key
    #   ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match the
    #   bucket's default customer managed key (using key ID or ARN, not
    #   alias). Your SSE-KMS configuration can only support 1 [customer
    #   managed key][2] per directory bucket's lifetime. The [Amazon Web
    #   Services managed key][3] (`aws/s3`) isn't supported. Incorrect key
    #   specification results in an HTTP `400 Bad Request` error.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # @option options [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context as an
    #   additional encryption context to use for the destination object
    #   encryption. The value of this header is a base64-encoded UTF-8 string
    #   holding JSON with the encryption context key-value pairs.
    #
    #   **General purpose buckets** - This value must be explicitly added to
    #   specify encryption context for `CopyObject` requests if you want an
    #   additional encryption context for your destination object. The
    #   additional encryption context of the source object won't be copied to
    #   the destination object. For more information, see [Encryption
    #   context][1] in the *Amazon S3 User Guide*.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default encryption
    #   context - the bucket Amazon Resource Name (ARN). An additional
    #   encryption context value is not supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html#encryption-context
    # @option options [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). If a target object uses SSE-KMS, you can enable
    #   an S3 Bucket Key for the object.
    #
    #   Setting this header to `true` causes Amazon S3 to use an S3 Bucket Key
    #   for object encryption with SSE-KMS. Specifying this header with a COPY
    #   action doesn’t affect bucket-level settings for S3 Bucket Key.
    #
    #   For more information, see [Amazon S3 Bucket Keys][1] in the *Amazon S3
    #   User Guide*.
    #
    #   <note markdown="1"> **Directory buckets** - S3 Bucket Keys aren't supported, when you
    #   copy SSE-KMS encrypted objects from general purpose buckets to
    #   directory buckets, from directory buckets to general purpose buckets,
    #   or between directory buckets, through [CopyObject][2]. In this case,
    #   Amazon S3 makes a call to KMS every time a copy request is made for a
    #   KMS-encrypted object.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    # @option options [String] :copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object (for
    #   example, `AES256`).
    #
    #   If the source object for the copy is stored in Amazon S3 using SSE-C,
    #   you must provide the necessary encryption information in your request
    #   so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use to
    #   decrypt the source object. The encryption key provided in this header
    #   must be the same one that was used when the source object was created.
    #
    #   If the source object for the copy is stored in Amazon S3 using SSE-C,
    #   you must provide the necessary encryption information in your request
    #   so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    #   If the source object for the copy is stored in Amazon S3 using SSE-C,
    #   you must provide the necessary encryption information in your request
    #   so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :tagging
    #   The tag-set for the object copy in the destination bucket. This value
    #   must be used in conjunction with the `x-amz-tagging-directive` if you
    #   choose `REPLACE` for the `x-amz-tagging-directive`. If you choose
    #   `COPY` for the `x-amz-tagging-directive`, you don't need to set the
    #   `x-amz-tagging` header, because the tag-set will be copied from the
    #   source object directly. The tag-set must be encoded as URL Query
    #   parameters.
    #
    #   The default value is the empty value.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets in a `CopyObject`
    #   operation, only the empty tag-set is supported. Any requests that
    #   attempt to write non-empty tags into directory buckets will receive a
    #   `501 Not Implemented` status code. When the destination bucket is a
    #   directory bucket, you will receive a `501 Not Implemented` response in
    #   any of the following situations:
    #
    #    * When you attempt to `COPY` the tag-set from an S3 source object that
    #     has non-empty tags.
    #
    #   * When you attempt to `REPLACE` the tag-set of a source object and set
    #     a non-empty value to `x-amz-tagging`.
    #
    #   * When you don't set the `x-amz-tagging-directive` header and the
    #     source object has non-empty tags. This is because the default value
    #     of `x-amz-tagging-directive` is `COPY`.
    #
    #    Because only the empty tag-set is supported for directory buckets in a
    #   `CopyObject` operation, the following situations are allowed:
    #
    #    * When you attempt to `COPY` the tag-set from a directory bucket
    #     source object that has no tags to a general purpose bucket. It
    #     copies an empty tag-set to the destination object.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and set the `x-amz-tagging` value of the directory
    #     bucket destination object to empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a general purpose
    #     bucket source object that has non-empty tags and set the
    #     `x-amz-tagging` value of the directory bucket destination object to
    #     empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and don't set the `x-amz-tagging` value of the
    #     directory bucket destination object. This is because the default
    #     value of `x-amz-tagging` is the empty value.
    #
    #    </note>
    # @option options [String] :object_lock_mode
    #   The Object Lock mode that you want to apply to the object copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   The date and time when you want the Object Lock of the object copy to
    #   expire.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the object copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected destination bucket owner. If the
    #   account ID that you provide does not match the actual owner of the
    #   destination bucket, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    # @option options [String] :expected_source_bucket_owner
    #   The account ID of the expected source bucket owner. If the account ID
    #   that you provide does not match the actual owner of the source bucket,
    #   the request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    # @return [Types::CopyObjectOutput]
    def copy_from(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.copy_object(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object_summary.delete({
    #     mfa: "MFA",
    #     version_id: "ObjectVersionId",
    #     request_payer: "requester", # accepts requester
    #     bypass_governance_retention: false,
    #     expected_bucket_owner: "AccountId",
    #     if_match: "IfMatch",
    #     if_match_last_modified_time: Time.now,
    #     if_match_size: 1,
    #   })
    # @param [Hash] options ({})
    # @option options [String] :mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication device.
    #   Required to permanently delete a versioned object if versioning is
    #   configured with MFA delete enabled.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> For directory buckets in this API operation, only the `null` value of
    #   the version ID is supported.
    #
    #    </note>
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [Boolean] :bypass_governance_retention
    #   Indicates whether S3 Object Lock should bypass Governance-mode
    #   restrictions to process this operation. To use this header, you must
    #   have the `s3:BypassGovernanceRetention` permission.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @option options [String] :if_match
    #   Deletes the object if the ETag (entity tag) value provided during the
    #   delete operation matches the ETag of the object in S3. If the ETag
    #   values do not match, the operation returns a `412 Precondition Failed`
    #   error.
    #
    #   Expects the ETag value as a string. `If-Match` does accept a string
    #   value of an '*' (asterisk) character to denote a match of any ETag.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Time,DateTime,Date,Integer,String] :if_match_last_modified_time
    #   If present, the object is deleted only if its modification times
    #   matches the provided `Timestamp`. If the `Timestamp` values do not
    #   match, the operation returns a `412 Precondition Failed` error. If the
    #   `Timestamp` matches or if the object doesn’t exist, the operation
    #   returns a `204 Success (No Content)` response.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    # @option options [Integer] :if_match_size
    #   If present, the object is deleted only if its size matches the
    #   provided size in bytes. If the `Size` value does not match, the
    #   operation returns a `412 Precondition Failed` error. If the `Size`
    #   matches or if the object doesn’t exist, the operation returns a `204
    #   Success (No Content)` response.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    #
    #   You can use the `If-Match`, `x-amz-if-match-last-modified-time` and
    #   `x-amz-if-match-size` conditional headers in conjunction with
    #   each-other or individually.
    # @return [Types::DeleteObjectOutput]
    def delete(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.delete_object(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object_summary.get({
    #     if_match: "IfMatch",
    #     if_modified_since: Time.now,
    #     if_none_match: "IfNoneMatch",
    #     if_unmodified_since: Time.now,
    #     range: "Range",
    #     response_cache_control: "ResponseCacheControl",
    #     response_content_disposition: "ResponseContentDisposition",
    #     response_content_encoding: "ResponseContentEncoding",
    #     response_content_language: "ResponseContentLanguage",
    #     response_content_type: "ResponseContentType",
    #     response_expires: Time.now,
    #     version_id: "ObjectVersionId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     part_number: 1,
    #     expected_bucket_owner: "AccountId",
    #     checksum_mode: "ENABLED", # accepts ENABLED
    #   })
    # @param [Hash] options ({})
    # @option options [String] :if_match
    #   Return the object only if its entity tag (ETag) is the same as the one
    #   specified in this header; otherwise, return a `412 Precondition
    #   Failed` error.
    #
    #   If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows: `If-Match` condition evaluates to
    #   `true`, and; `If-Unmodified-Since` condition evaluates to `false`;
    #   then, S3 returns `200 OK` and the data requested.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Time,DateTime,Date,Integer,String] :if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time; otherwise, return a `304 Not Modified` error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:` If-None-Match` condition evaluates
    #   to `false`, and; `If-Modified-Since` condition evaluates to `true`;
    #   then, S3 returns `304 Not Modified` status code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [String] :if_none_match
    #   Return the object only if its entity tag (ETag) is different from the
    #   one specified in this header; otherwise, return a `304 Not Modified`
    #   error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:` If-None-Match` condition evaluates
    #   to `false`, and; `If-Modified-Since` condition evaluates to `true`;
    #   then, S3 returns `304 Not Modified` HTTP status code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Time,DateTime,Date,Integer,String] :if_unmodified_since
    #   Return the object only if it has not been modified since the specified
    #   time; otherwise, return a `412 Precondition Failed` error.
    #
    #   If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows: `If-Match` condition evaluates to
    #   `true`, and; `If-Unmodified-Since` condition evaluates to `false`;
    #   then, S3 returns `200 OK` and the data requested.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [String] :range
    #   Downloads the specified byte range of an object. For more information
    #   about the HTTP Range header, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-range][1].
    #
    #   <note markdown="1"> Amazon S3 doesn't support retrieving multiple ranges of data per
    #   `GET` request.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-range
    # @option options [String] :response_cache_control
    #   Sets the `Cache-Control` header of the response.
    # @option options [String] :response_content_disposition
    #   Sets the `Content-Disposition` header of the response.
    # @option options [String] :response_content_encoding
    #   Sets the `Content-Encoding` header of the response.
    # @option options [String] :response_content_language
    #   Sets the `Content-Language` header of the response.
    # @option options [String] :response_content_type
    #   Sets the `Content-Type` header of the response.
    # @option options [Time,DateTime,Date,Integer,String] :response_expires
    #   Sets the `Expires` header of the response.
    # @option options [String] :version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   By default, the `GetObject` operation returns the current version of
    #   an object. To return a different version, use the `versionId`
    #   subresource.
    #
    #   <note markdown="1"> * If you include a `versionId` in your request header, you must have
    #     the `s3:GetObjectVersion` permission to access a specific version of
    #     an object. The `s3:GetObject` permission is not required in this
    #     scenario.
    #
    #   * If you request the current version of an object without a specific
    #     `versionId` in the request header, only the `s3:GetObject`
    #     permission is required. The `s3:GetObjectVersion` permission is not
    #     required in this scenario.
    #
    #   * **Directory buckets** - S3 Versioning isn't enabled and supported
    #     for directory buckets. For this API operation, only the `null` value
    #     of the version ID is supported by directory buckets. You can only
    #     specify `null` to the `versionId` query parameter in the request.
    #
    #    </note>
    #
    #   For more information about versioning, see [PutBucketVersioning][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html
    # @option options [String] :sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the object (for
    #   example, `AES256`).
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object in
    #   Amazon S3, then when you GET the object, you must use the following
    #   headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key
    #   Specifies the customer-provided encryption key that you originally
    #   provided for Amazon S3 to encrypt the data before storing it. This
    #   value is used to decrypt the object when recovering it and must match
    #   the one used when storing the data. The key must be appropriate for
    #   use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object in
    #   Amazon S3, then when you GET the object, you must use the following
    #   headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the customer-provided encryption
    #   key according to RFC 1321. Amazon S3 uses this header for a message
    #   integrity check to ensure that the encryption key was transmitted
    #   without error.
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object in
    #   Amazon S3, then when you GET the object, you must use the following
    #   headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [Integer] :part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' GET request
    #   for the part specified. Useful for downloading just a part of an
    #   object.
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @option options [String] :checksum_mode
    #   To retrieve the checksum, this mode must be enabled.
    # @return [Types::GetObjectOutput]
    def get(options = {}, &block)
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.get_object(options, &block)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   multipartupload = object_summary.initiate_multipart_upload({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     cache_control: "CacheControl",
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_type: "ContentType",
    #     expires: Time.now,
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     server_side_encryption: "AES256", # accepts AES256, aws:fsx, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW, EXPRESS_ONEZONE, FSX_OPENZFS, FSX_ONTAP
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
    #     checksum_type: "COMPOSITE", # accepts COMPOSITE, FULL_OBJECT
    #   })
    # @param [Hash] options ({})
    # @option options [String] :acl
    #   The canned ACL to apply to the object. Amazon S3 supports a set of
    #   predefined ACLs, known as *canned ACLs*. Each canned ACL has a
    #   predefined set of grantees and permissions. For more information, see
    #   [Canned ACL][1] in the *Amazon S3 User Guide*.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can grant access permissions to
    #   individual Amazon Web Services accounts or to predefined groups
    #   defined by Amazon S3. These permissions are then added to the access
    #   control list (ACL) on the new object. For more information, see [Using
    #   ACLs][2]. One way to grant the permissions using the request headers
    #   is to specify a canned ACL with the `x-amz-acl` request header.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    # @option options [String] :cache_control
    #   Specifies caching behavior along the request/reply chain.
    # @option options [String] :content_disposition
    #   Specifies presentational information for the object.
    # @option options [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field.
    #
    #   <note markdown="1"> For directory buckets, only the `aws-chunked` value is supported in
    #   this header field.
    #
    #    </note>
    # @option options [String] :content_language
    #   The language that the content is in.
    # @option options [String] :content_type
    #   A standard MIME type describing the format of the object data.
    # @option options [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable.
    # @option options [String] :grant_full_control
    #   Specify access permissions explicitly to give the grantee READ,
    #   READ\_ACP, and WRITE\_ACP permissions on the object.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can use this header to
    #   explicitly grant access permissions to specific Amazon Web Services
    #   accounts or groups. This header maps to specific permissions that
    #   Amazon S3 supports in an ACL. For more information, see [Access
    #   Control List (ACL) Overview][1] in the *Amazon S3 User Guide*.
    #
    #   You specify each grantee as a type=value pair, where the type is one
    #   of the following:
    #
    #   * `id` – if the value specified is the canonical user ID of an Amazon
    #     Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in the
    #     following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints, see
    #     [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the Amazon
    #   Web Services accounts identified by account IDs permissions to read
    #   object data and its metadata:
    #
    #   `x-amz-grant-read: id="11112222333", id="444455556666" `
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # @option options [String] :grant_read
    #   Specify access permissions explicitly to allow grantee to read the
    #   object data and its metadata.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can use this header to
    #   explicitly grant access permissions to specific Amazon Web Services
    #   accounts or groups. This header maps to specific permissions that
    #   Amazon S3 supports in an ACL. For more information, see [Access
    #   Control List (ACL) Overview][1] in the *Amazon S3 User Guide*.
    #
    #   You specify each grantee as a type=value pair, where the type is one
    #   of the following:
    #
    #   * `id` – if the value specified is the canonical user ID of an Amazon
    #     Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in the
    #     following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints, see
    #     [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the Amazon
    #   Web Services accounts identified by account IDs permissions to read
    #   object data and its metadata:
    #
    #   `x-amz-grant-read: id="11112222333", id="444455556666" `
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # @option options [String] :grant_read_acp
    #   Specify access permissions explicitly to allows grantee to read the
    #   object ACL.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can use this header to
    #   explicitly grant access permissions to specific Amazon Web Services
    #   accounts or groups. This header maps to specific permissions that
    #   Amazon S3 supports in an ACL. For more information, see [Access
    #   Control List (ACL) Overview][1] in the *Amazon S3 User Guide*.
    #
    #   You specify each grantee as a type=value pair, where the type is one
    #   of the following:
    #
    #   * `id` – if the value specified is the canonical user ID of an Amazon
    #     Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in the
    #     following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints, see
    #     [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the Amazon
    #   Web Services accounts identified by account IDs permissions to read
    #   object data and its metadata:
    #
    #   `x-amz-grant-read: id="11112222333", id="444455556666" `
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # @option options [String] :grant_write_acp
    #   Specify access permissions explicitly to allows grantee to allow
    #   grantee to write the ACL for the applicable object.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can use this header to
    #   explicitly grant access permissions to specific Amazon Web Services
    #   accounts or groups. This header maps to specific permissions that
    #   Amazon S3 supports in an ACL. For more information, see [Access
    #   Control List (ACL) Overview][1] in the *Amazon S3 User Guide*.
    #
    #   You specify each grantee as a type=value pair, where the type is one
    #   of the following:
    #
    #   * `id` – if the value specified is the canonical user ID of an Amazon
    #     Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in the
    #     following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints, see
    #     [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the Amazon
    #   Web Services accounts identified by account IDs permissions to read
    #   object data and its metadata:
    #
    #   `x-amz-grant-read: id="11112222333", id="444455556666" `
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # @option options [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    # @option options [String] :server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   * <b>Directory buckets </b> - For directory buckets, there are only
    #     two supported options for server-side encryption: server-side
    #     encryption with Amazon S3 managed keys (SSE-S3) (`AES256`) and
    #     server-side encryption with KMS keys (SSE-KMS) (`aws:kms`). We
    #     recommend that the bucket's default encryption uses the desired
    #     encryption configuration and you don't override the bucket default
    #     encryption in your `CreateSession` requests or `PUT` object
    #     requests. Then, new objects are automatically encrypted with the
    #     desired encryption settings. For more information, see [Protecting
    #     data with server-side encryption][1] in the *Amazon S3 User Guide*.
    #     For more information about the encryption overriding behaviors in
    #     directory buckets, see [Specifying server-side encryption with KMS
    #     for new object uploads][2].
    #
    #     In the Zonal endpoint API calls (except [CopyObject][3] and
    #     [UploadPartCopy][4]) using the REST API, the encryption request
    #     headers must match the encryption settings that are specified in the
    #     `CreateSession` request. You can't override the values of the
    #     encryption settings (`x-amz-server-side-encryption`,
    #     `x-amz-server-side-encryption-aws-kms-key-id`,
    #     `x-amz-server-side-encryption-context`, and
    #     `x-amz-server-side-encryption-bucket-key-enabled`) that are
    #     specified in the `CreateSession` request. You don't need to
    #     explicitly specify these encryption settings values in Zonal
    #     endpoint API calls, and Amazon S3 will use the encryption settings
    #     values from the `CreateSession` request to protect new objects in
    #     the directory bucket.
    #
    #     <note markdown="1"> When you use the CLI or the Amazon Web Services SDKs, for
    #     `CreateSession`, the session token refreshes automatically to avoid
    #     service interruptions when a session expires. The CLI or the Amazon
    #     Web Services SDKs use the bucket's default encryption configuration
    #     for the `CreateSession` request. It's not supported to override the
    #     encryption settings values in the `CreateSession` request. So in the
    #     Zonal endpoint API calls (except [CopyObject][3] and
    #     [UploadPartCopy][4]), the encryption request headers must match the
    #     default encryption configuration of the directory bucket.
    #
    #      </note>
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data stored
    #     in Amazon FSx file systems using S3 access points, the only valid
    #     server side encryption option is `aws:fsx`. All Amazon FSx file
    #     systems have encryption configured by default and are encrypted at
    #     rest. Data is automatically encrypted before being written to the
    #     file system, and automatically decrypted as it is read. These
    #     processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    # @option options [String] :storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can specify
    #   a different Storage Class. For more information, see [Storage
    #   Classes][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> * Directory buckets only support `EXPRESS_ONEZONE` (the S3 Express One
    #     Zone storage class) in Availability Zones and `ONEZONE_IA` (the S3
    #     One Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #   * Amazon S3 on Outposts only uses the OUTPOSTS Storage Class.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    # @option options [String] :website_redirect_location
    #   If the bucket is configured as a website, redirects requests for this
    #   object to another object in the same bucket or to an external URL.
    #   Amazon S3 stores the value of this header in the object metadata.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the customer-provided encryption
    #   key according to RFC 1321. Amazon S3 uses this header for a message
    #   integrity check to ensure that the encryption key was transmitted
    #   without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. If the KMS key doesn't exist in the same account
    #   that's issuing the command, you must use the full Key ARN not the Key
    #   ID.
    #
    #   **General purpose buckets** - If you specify
    #   `x-amz-server-side-encryption` with `aws:kms` or `aws:kms:dsse`, this
    #   header specifies the ID (Key ID, Key ARN, or Key Alias) of the KMS key
    #   to use. If you specify `x-amz-server-side-encryption:aws:kms` or
    #   `x-amz-server-side-encryption:aws:kms:dsse`, but do not provide
    #   `x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the
    #   Amazon Web Services managed key (`aws/s3`) to protect the data.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed key
    #   ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match the
    #   bucket's default customer managed key (using key ID or ARN, not
    #   alias). Your SSE-KMS configuration can only support 1 [customer
    #   managed key][1] per directory bucket's lifetime. The [Amazon Web
    #   Services managed key][2] (`aws/s3`) isn't supported. Incorrect key
    #   specification results in an HTTP `400 Bad Request` error.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # @option options [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context to use for
    #   object encryption. The value of this header is a Base64 encoded string
    #   of a UTF-8 encoded JSON, which contains the encryption context as
    #   key-value pairs.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default encryption
    #   context - the bucket Amazon Resource Name (ARN). An additional
    #   encryption context value is not supported.
    # @option options [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS).
    #
    #   **General purpose buckets** - Setting this header to `true` causes
    #   Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS.
    #   Also, specifying this header with a PUT action doesn't affect
    #   bucket-level settings for S3 Bucket Key.
    #
    #   **Directory buckets** - S3 Bucket Keys are always enabled for `GET`
    #   and `PUT` operations in a directory bucket and can’t be disabled. S3
    #   Bucket Keys aren't supported, when you copy SSE-KMS encrypted objects
    #   from general purpose buckets to directory buckets, from directory
    #   buckets to general purpose buckets, or between directory buckets,
    #   through [CopyObject][1], [UploadPartCopy][2], [the Copy operation in
    #   Batch Operations][3], or [the import jobs][4]. In this case, Amazon S3
    #   makes a call to KMS every time a copy request is made for a
    #   KMS-encrypted object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_lock_mode
    #   Specifies the Object Lock mode that you want to apply to the uploaded
    #   object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   Specifies the date and time when you want the Object Lock to expire.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the uploaded
    #   object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @option options [String] :checksum_algorithm
    #   Indicates the algorithm that you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_type
    #   Indicates the checksum type that you want Amazon S3 to use to
    #   calculate the object’s checksum value. For more information, see
    #   [Checking object integrity in the Amazon S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @return [MultipartUpload]
    def initiate_multipart_upload(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.create_multipart_upload(options)
      end
      MultipartUpload.new(
        bucket_name: @bucket_name,
        object_key: @key,
        id: resp.data.upload_id,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   object_summary.put({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     body: source_file,
    #     cache_control: "CacheControl",
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_length: 1,
    #     content_md5: "ContentMD5",
    #     content_type: "ContentType",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_crc64nvme: "ChecksumCRC64NVME",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     expires: Time.now,
    #     if_match: "IfMatch",
    #     if_none_match: "IfNoneMatch",
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     write_offset_bytes: 1,
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     server_side_encryption: "AES256", # accepts AES256, aws:fsx, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW, EXPRESS_ONEZONE, FSX_OPENZFS, FSX_ONTAP
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1] in the *Amazon S3 User Guide*.
    #
    #   When adding a new object, you can use headers to grant ACL-based
    #   permissions to individual Amazon Web Services accounts or to
    #   predefined groups defined by Amazon S3. These permissions are then
    #   added to the ACL on the object. By default, all objects are private.
    #   Only the owner has full access control. For more information, see
    #   [Access Control List (ACL) Overview][2] and [Managing ACLs Using the
    #   REST API][3] in the *Amazon S3 User Guide*.
    #
    #   If the bucket that you're uploading objects to uses the bucket owner
    #   enforced setting for S3 Object Ownership, ACLs are disabled and no
    #   longer affect permissions. Buckets that use this setting only accept
    #   PUT requests that don't specify an ACL or PUT requests that specify
    #   bucket owner full control ACLs, such as the
    #   `bucket-owner-full-control` canned ACL or an equivalent form of this
    #   ACL expressed in the XML format. PUT requests that contain other ACLs
    #   (for example, custom grants to certain Amazon Web Services accounts)
    #   fail and return a `400` error with the error code
    #   `AccessControlListNotSupported`. For more information, see [
    #   Controlling ownership of objects and disabling ACLs][4] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-rest-api.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # @option options [String, StringIO, File] :body
    #   Object data.
    # @option options [String] :cache_control
    #   Can be used to specify caching behavior along the request/reply chain.
    #   For more information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
    # @option options [String] :content_disposition
    #   Specifies presentational information for the object. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc6266#section-4][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc6266#section-4
    # @option options [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field. For more information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding
    # @option options [String] :content_language
    #   The language the content is in.
    # @option options [Integer] :content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically. For more information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length
    # @option options [String] :content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the message (without the
    #   headers) according to RFC 1864. This header can be used as a message
    #   integrity check to verify that the data is the same data that was
    #   originally sent. Although it is optional, we recommend using the
    #   Content-MD5 mechanism as an end-to-end integrity check. For more
    #   information about REST request authentication, see [REST
    #   Authentication][1].
    #
    #   <note markdown="1"> The `Content-MD5` or `x-amz-sdk-checksum-algorithm` header is required
    #   for any request to upload an object with a retention period configured
    #   using Amazon S3 Object Lock. For more information, see [Uploading
    #   objects to an Object Lock enabled bucket ][2] in the *Amazon S3 User
    #   Guide*.
    #
    #    </note>
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-managing.html#object-lock-put-object
    # @option options [String] :content_type
    #   A standard MIME type describing the format of the contents. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type
    # @option options [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum-algorithm ` or
    #   `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the request
    #   with the HTTP status code `400 Bad Request`.
    #
    #   For the `x-amz-checksum-algorithm ` header, replace ` algorithm ` with
    #   the supported algorithm from the following list:
    #
    #   * `CRC32`
    #
    #   * `CRC32C`
    #
    #   * `CRC64NVME`
    #
    #   * `SHA1`
    #
    #   * `SHA256`
    #
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   If the individual checksum value you provide through
    #   `x-amz-checksum-algorithm ` doesn't match the checksum algorithm you
    #   set through `x-amz-sdk-checksum-algorithm`, Amazon S3 fails the
    #   request with a `BadDigest` error.
    #
    #   <note markdown="1"> The `Content-MD5` or `x-amz-sdk-checksum-algorithm` header is required
    #   for any request to upload an object with a retention period configured
    #   using Amazon S3 Object Lock. For more information, see [Uploading
    #   objects to an Object Lock enabled bucket ][2] in the *Amazon S3 User
    #   Guide*.
    #
    #    </note>
    #
    #   For directory buckets, when you use Amazon Web Services SDKs, `CRC32`
    #   is the default checksum algorithm that's used for performance.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-managing.html#object-lock-put-object
    # @option options [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   object. The `CRC64NVME` checksum is always a full object checksum. For
    #   more information, see [Checking object integrity in the Amazon S3 User
    #   Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 160-bit `SHA1` digest of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 256-bit `SHA256` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc7234#section-5.3][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc7234#section-5.3
    # @option options [String] :if_match
    #   Uploads the object only if the ETag (entity tag) value provided during
    #   the WRITE operation matches the ETag of the object in S3. If the ETag
    #   values do not match, the operation returns a `412 Precondition Failed`
    #   error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a `409
    #   ConditionalRequestConflict` response. On a 409 failure you should
    #   fetch the object's ETag and retry the upload.
    #
    #   Expects the ETag value as a string.
    #
    #   For more information about conditional requests, see [RFC 7232][1], or
    #   [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    # @option options [String] :if_none_match
    #   Uploads the object only if the object key name does not already exist
    #   in the bucket specified. Otherwise, Amazon S3 returns a `412
    #   Precondition Failed` error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a `409
    #   ConditionalRequestConflict` response. On a 409 failure you should
    #   retry the upload.
    #
    #   Expects the '*' (asterisk) character.
    #
    #   For more information about conditional requests, see [RFC 7232][1], or
    #   [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    # @option options [String] :grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    # @option options [Integer] :write_offset_bytes
    #   Specifies the offset for appending data to existing objects in bytes.
    #   The offset must be equal to the size of the existing object being
    #   appended to. If no object exists, setting this header to 0 will create
    #   a new object.
    #
    #   <note markdown="1"> This functionality is only supported for objects in the Amazon S3
    #   Express One Zone storage class in directory buckets.
    #
    #    </note>
    # @option options [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    # @option options [String] :server_side_encryption
    #   The server-side encryption algorithm that was used when you store this
    #   object in Amazon S3 or Amazon FSx.
    #
    #   * <b>General purpose buckets </b> - You have four mutually exclusive
    #     options to protect data using server-side encryption in Amazon S3,
    #     depending on how you choose to manage the encryption keys.
    #     Specifically, the encryption key options are Amazon S3 managed keys
    #     (SSE-S3), Amazon Web Services KMS keys (SSE-KMS or DSSE-KMS), and
    #     customer-provided keys (SSE-C). Amazon S3 encrypts data with
    #     server-side encryption by using Amazon S3 managed keys (SSE-S3) by
    #     default. You can optionally tell Amazon S3 to encrypt data at rest
    #     by using server-side encryption with other key options. For more
    #     information, see [Using Server-Side Encryption][1] in the *Amazon S3
    #     User Guide*.
    #
    #   * <b>Directory buckets </b> - For directory buckets, there are only
    #     two supported options for server-side encryption: server-side
    #     encryption with Amazon S3 managed keys (SSE-S3) (`AES256`) and
    #     server-side encryption with KMS keys (SSE-KMS) (`aws:kms`). We
    #     recommend that the bucket's default encryption uses the desired
    #     encryption configuration and you don't override the bucket default
    #     encryption in your `CreateSession` requests or `PUT` object
    #     requests. Then, new objects are automatically encrypted with the
    #     desired encryption settings. For more information, see [Protecting
    #     data with server-side encryption][2] in the *Amazon S3 User Guide*.
    #     For more information about the encryption overriding behaviors in
    #     directory buckets, see [Specifying server-side encryption with KMS
    #     for new object uploads][3].
    #
    #     In the Zonal endpoint API calls (except [CopyObject][4] and
    #     [UploadPartCopy][5]) using the REST API, the encryption request
    #     headers must match the encryption settings that are specified in the
    #     `CreateSession` request. You can't override the values of the
    #     encryption settings (`x-amz-server-side-encryption`,
    #     `x-amz-server-side-encryption-aws-kms-key-id`,
    #     `x-amz-server-side-encryption-context`, and
    #     `x-amz-server-side-encryption-bucket-key-enabled`) that are
    #     specified in the `CreateSession` request. You don't need to
    #     explicitly specify these encryption settings values in Zonal
    #     endpoint API calls, and Amazon S3 will use the encryption settings
    #     values from the `CreateSession` request to protect new objects in
    #     the directory bucket.
    #
    #     <note markdown="1"> When you use the CLI or the Amazon Web Services SDKs, for
    #     `CreateSession`, the session token refreshes automatically to avoid
    #     service interruptions when a session expires. The CLI or the Amazon
    #     Web Services SDKs use the bucket's default encryption configuration
    #     for the `CreateSession` request. It's not supported to override the
    #     encryption settings values in the `CreateSession` request. So in the
    #     Zonal endpoint API calls (except [CopyObject][4] and
    #     [UploadPartCopy][5]), the encryption request headers must match the
    #     default encryption configuration of the directory bucket.
    #
    #      </note>
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data stored
    #     in Amazon FSx file systems using S3 access points, the only valid
    #     server side encryption option is `aws:fsx`. All Amazon FSx file
    #     systems have encryption configured by default and are encrypted at
    #     rest. Data is automatically encrypted before being written to the
    #     file system, and automatically decrypted as it is read. These
    #     processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    # @option options [String] :storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can specify
    #   a different Storage Class. For more information, see [Storage
    #   Classes][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> * Directory buckets only support `EXPRESS_ONEZONE` (the S3 Express One
    #     Zone storage class) in Availability Zones and `ONEZONE_IA` (the S3
    #     One Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #   * Amazon S3 on Outposts only uses the OUTPOSTS Storage Class.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    # @option options [String] :website_redirect_location
    #   If the bucket is configured as a website, redirects requests for this
    #   object to another object in the same bucket or to an external URL.
    #   Amazon S3 stores the value of this header in the object metadata. For
    #   information about object metadata, see [Object Key and Metadata][1] in
    #   the *Amazon S3 User Guide*.
    #
    #   In the following example, the request header sets the redirect to an
    #   object (anotherPage.html) in the same bucket:
    #
    #   `x-amz-website-redirect-location: /anotherPage.html`
    #
    #   In the following example, the request header sets the object redirect
    #   to another website:
    #
    #   `x-amz-website-redirect-location: http://www.example.com/`
    #
    #   For more information about website hosting in Amazon S3, see [Hosting
    #   Websites on Amazon S3][2] and [How to Configure Website Page
    #   Redirects][3] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html
    # @option options [String] :sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, `AES256`).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. If the KMS key doesn't exist in the same account
    #   that's issuing the command, you must use the full Key ARN not the Key
    #   ID.
    #
    #   **General purpose buckets** - If you specify
    #   `x-amz-server-side-encryption` with `aws:kms` or `aws:kms:dsse`, this
    #   header specifies the ID (Key ID, Key ARN, or Key Alias) of the KMS key
    #   to use. If you specify `x-amz-server-side-encryption:aws:kms` or
    #   `x-amz-server-side-encryption:aws:kms:dsse`, but do not provide
    #   `x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the
    #   Amazon Web Services managed key (`aws/s3`) to protect the data.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed key
    #   ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match the
    #   bucket's default customer managed key (using key ID or ARN, not
    #   alias). Your SSE-KMS configuration can only support 1 [customer
    #   managed key][1] per directory bucket's lifetime. The [Amazon Web
    #   Services managed key][2] (`aws/s3`) isn't supported. Incorrect key
    #   specification results in an HTTP `400 Bad Request` error.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # @option options [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context as an
    #   additional encryption context to use for object encryption. The value
    #   of this header is a Base64 encoded string of a UTF-8 encoded JSON,
    #   which contains the encryption context as key-value pairs. This value
    #   is stored as object metadata and automatically gets passed on to
    #   Amazon Web Services KMS for future `GetObject` operations on this
    #   object.
    #
    #   **General purpose buckets** - This value must be explicitly added
    #   during `CopyObject` operations if you want an additional encryption
    #   context for your object. For more information, see [Encryption
    #   context][1] in the *Amazon S3 User Guide*.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default encryption
    #   context - the bucket Amazon Resource Name (ARN). An additional
    #   encryption context value is not supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html#encryption-context
    # @option options [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS).
    #
    #   **General purpose buckets** - Setting this header to `true` causes
    #   Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS.
    #   Also, specifying this header with a PUT action doesn't affect
    #   bucket-level settings for S3 Bucket Key.
    #
    #   **Directory buckets** - S3 Bucket Keys are always enabled for `GET`
    #   and `PUT` operations in a directory bucket and can’t be disabled. S3
    #   Bucket Keys aren't supported, when you copy SSE-KMS encrypted objects
    #   from general purpose buckets to directory buckets, from directory
    #   buckets to general purpose buckets, or between directory buckets,
    #   through [CopyObject][1], [UploadPartCopy][2], [the Copy operation in
    #   Batch Operations][3], or [the import jobs][4]. In this case, Amazon S3
    #   makes a call to KMS every time a copy request is made for a
    #   KMS-encrypted object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters. (For example, "Key1=Value1")
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_lock_mode
    #   The Object Lock mode that you want to apply to this object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   The date and time when you want this object's Object Lock to expire.
    #   Must be formatted as a timestamp parameter.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_lock_legal_hold_status
    #   Specifies whether a legal hold will be applied to this object. For
    #   more information about S3 Object Lock, see [Object Lock][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @return [Types::PutObjectOutput]
    def put(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.put_object(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object_summary.restore_object({
    #     version_id: "ObjectVersionId",
    #     restore_request: {
    #       days: 1,
    #       glacier_job_parameters: {
    #         tier: "Standard", # required, accepts Standard, Bulk, Expedited
    #       },
    #       type: "SELECT", # accepts SELECT
    #       tier: "Standard", # accepts Standard, Bulk, Expedited
    #       description: "Description",
    #       select_parameters: {
    #         input_serialization: { # required
    #           csv: {
    #             file_header_info: "USE", # accepts USE, IGNORE, NONE
    #             comments: "Comments",
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #             allow_quoted_record_delimiter: false,
    #           },
    #           compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #           json: {
    #             type: "DOCUMENT", # accepts DOCUMENT, LINES
    #           },
    #           parquet: {
    #           },
    #         },
    #         expression_type: "SQL", # required, accepts SQL
    #         expression: "Expression", # required
    #         output_serialization: { # required
    #           csv: {
    #             quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #           },
    #           json: {
    #             record_delimiter: "RecordDelimiter",
    #           },
    #         },
    #       },
    #       output_location: {
    #         s3: {
    #           bucket_name: "BucketName", # required
    #           prefix: "LocationPrefix", # required
    #           encryption: {
    #             encryption_type: "AES256", # required, accepts AES256, aws:fsx, aws:kms, aws:kms:dsse
    #             kms_key_id: "SSEKMSKeyId",
    #             kms_context: "KMSContext",
    #           },
    #           canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #           access_control_list: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #             },
    #           ],
    #           tagging: {
    #             tag_set: [ # required
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #           user_metadata: [
    #             {
    #               name: "MetadataKey",
    #               value: "MetadataValue",
    #             },
    #           ],
    #           storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW, EXPRESS_ONEZONE, FSX_OPENZFS, FSX_ONTAP
    #         },
    #       },
    #     },
    #     request_payer: "requester", # accepts requester
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
    #     expected_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :version_id
    #   VersionId used to reference a specific version of the object.
    # @option options [Types::RestoreRequest] :restore_request
    #   Container for restore job parameters.
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has Requester
    #   Pays enabled, the requester will pay for the corresponding charges.
    #   For information about downloading objects from Requester Pays buckets,
    #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @return [Types::RestoreObjectOutput]
    def restore_object(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @key
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.restore_object(options)
      end
      resp.data
    end

    # @!group Associations

    # @return [ObjectAcl]
    def acl
      ObjectAcl.new(
        bucket_name: @bucket_name,
        object_key: @key,
        client: @client
      )
    end

    # @return [Bucket]
    def bucket
      Bucket.new(
        name: @bucket_name,
        client: @client
      )
    end

    # @param [String] id
    # @return [MultipartUpload]
    def multipart_upload(id)
      MultipartUpload.new(
        bucket_name: @bucket_name,
        object_key: @key,
        id: id,
        client: @client
      )
    end

    # @return [Object]
    def object
      Object.new(
        bucket_name: @bucket_name,
        key: @key,
        client: @client
      )
    end

    # @param [String] id
    # @return [ObjectVersion]
    def version(id)
      ObjectVersion.new(
        bucket_name: @bucket_name,
        object_key: @key,
        id: id,
        client: @client
      )
    end

    # @deprecated
    # @api private
    def identifiers
      {
        bucket_name: @bucket_name,
        key: @key
      }
    end
    deprecated(:identifiers)

    private

    def extract_bucket_name(args, options)
      value = args[0] || options.delete(:bucket_name)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :bucket_name"
      else
        msg = "expected :bucket_name to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    def extract_key(args, options)
      value = args[1] || options.delete(:key)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :key"
      else
        msg = "expected :key to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    def yield_waiter_and_warn(waiter, &block)
      if !@waiter_block_warned
        msg = "pass options to configure the waiter; "\
              "yielding the waiter is deprecated"
        warn(msg)
        @waiter_block_warned = true
      end
      yield(waiter.waiter)
    end

    def separate_params_and_options(options)
      opts = Set.new(
        [:client, :max_attempts, :delay, :before_attempt, :before_wait]
      )
      waiter_opts = {}
      waiter_params = {}
      options.each_pair do |key, value|
        if opts.include?(key)
          waiter_opts[key] = value
        else
          waiter_params[key] = value
        end
      end
      waiter_opts[:client] ||= @client
      [waiter_opts, waiter_params]
    end

    class Collection < Aws::Resources::Collection

      # @!group Batch Actions

      # @example Request syntax with placeholder values
      #
      #   object_summary.batch_delete!({
      #     mfa: "MFA",
      #     request_payer: "requester", # accepts requester
      #     bypass_governance_retention: false,
      #     expected_bucket_owner: "AccountId",
      #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
      #   })
      # @param options ({})
      # @option options [String] :mfa
      #   The concatenation of the authentication device's serial number, a
      #   space, and the value that is displayed on your authentication device.
      #   Required to permanently delete a versioned object if versioning is
      #   configured with MFA delete enabled.
      #
      #   When performing the `DeleteObjects` operation on an MFA delete enabled
      #   bucket, which attempts to delete the specified versioned objects, you
      #   must include an MFA token. If you don't provide an MFA token, the
      #   entire request will fail, even if there are non-versioned objects that
      #   you are trying to delete. If you provide an invalid token, whether
      #   there are versioned object keys in the request or not, the entire
      #   Multi-Object Delete request will fail. For information about MFA
      #   Delete, see [ MFA Delete][1] in the *Amazon S3 User Guide*.
      #
      #   <note markdown="1"> This functionality is not supported for directory buckets.
      #
      #    </note>
      #
      #
      #
      #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html#MultiFactorAuthenticationDelete
      # @option options [String] :request_payer
      #   Confirms that the requester knows that they will be charged for the
      #   request. Bucket owners need not specify this parameter in their
      #   requests. If either the source or destination S3 bucket has Requester
      #   Pays enabled, the requester will pay for the corresponding charges.
      #   For information about downloading objects from Requester Pays buckets,
      #   see [Downloading Objects in Requester Pays Buckets][1] in the *Amazon
      #   S3 User Guide*.
      #
      #   <note markdown="1"> This functionality is not supported for directory buckets.
      #
      #    </note>
      #
      #
      #
      #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
      # @option options [Boolean] :bypass_governance_retention
      #   Specifies whether you want to delete this object even if it has a
      #   Governance-type Object Lock in place. To use this header, you must
      #   have the `s3:BypassGovernanceRetention` permission.
      #
      #   <note markdown="1"> This functionality is not supported for directory buckets.
      #
      #    </note>
      # @option options [String] :expected_bucket_owner
      #   The account ID of the expected bucket owner. If the account ID that
      #   you provide does not match the actual owner of the bucket, the request
      #   fails with the HTTP status code `403 Forbidden` (access denied).
      # @option options [String] :checksum_algorithm
      #   Indicates the algorithm used to create the checksum for the object
      #   when you use the SDK. This header will not provide any additional
      #   functionality if you don't use the SDK. When you send this header,
      #   there must be a corresponding `x-amz-checksum-algorithm ` or
      #   `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the request
      #   with the HTTP status code `400 Bad Request`.
      #
      #   For the `x-amz-checksum-algorithm ` header, replace ` algorithm ` with
      #   the supported algorithm from the following list:
      #
      #   * `CRC32`
      #
      #   * `CRC32C`
      #
      #   * `CRC64NVME`
      #
      #   * `SHA1`
      #
      #   * `SHA256`
      #
      #   For more information, see [Checking object integrity][1] in the
      #   *Amazon S3 User Guide*.
      #
      #   If the individual checksum value you provide through
      #   `x-amz-checksum-algorithm ` doesn't match the checksum algorithm you
      #   set through `x-amz-sdk-checksum-algorithm`, Amazon S3 fails the
      #   request with a `BadDigest` error.
      #
      #   If you provide an individual checksum, Amazon S3 ignores any provided
      #   `ChecksumAlgorithm` parameter.
      #
      #
      #
      #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
      # @return [void]
      def batch_delete!(options = {})
        batch_enum.each do |batch|
          params = Aws::Util.copy_hash(options)
          params[:bucket] = batch[0].bucket_name
          params[:delete] ||= {}
          params[:delete][:objects] ||= []
          batch.each do |item|
            params[:delete][:objects] << {
              key: item.key
            }
          end
          Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
            batch[0].client.delete_objects(params)
          end
        end
        nil
      end

      # @!endgroup

    end
  end
end

# Load customizations if they exist
require 'aws-sdk-s3/customizations/object_summary'
