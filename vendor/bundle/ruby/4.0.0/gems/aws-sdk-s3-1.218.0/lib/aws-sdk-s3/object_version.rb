# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  class ObjectVersion

    extend Aws::Deprecations

    # @overload def initialize(bucket_name, object_key, id, options = {})
    #   @param [String] bucket_name
    #   @param [String] object_key
    #   @param [String] id
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :bucket_name
    #   @option options [required, String] :object_key
    #   @option options [required, String] :id
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @bucket_name = extract_bucket_name(args, options)
      @object_key = extract_object_key(args, options)
      @id = extract_id(args, options)
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
    def object_key
      @object_key
    end

    # @return [String]
    def id
      @id
    end

    # The entity tag is an MD5 hash of that version of the object.
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

    # Size in bytes of the object.
    # @return [Integer]
    def size
      data[:size]
    end

    # The class of storage used to store the object.
    # @return [String]
    def storage_class
      data[:storage_class]
    end

    # The object key.
    # @return [String]
    def key
      data[:key]
    end

    # Version ID of an object.
    # @return [String]
    def version_id
      data[:version_id]
    end

    # Specifies whether the object is (true) or is not (false) the latest
    # version of an object.
    # @return [Boolean]
    def is_latest
      data[:is_latest]
    end

    # Date and time when the object was last modified.
    # @return [Time]
    def last_modified
      data[:last_modified]
    end

    # Specifies the owner of the object.
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
    # @return [Types::ObjectVersion]
    #   Returns the data for this {ObjectVersion}.
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
    #   object_version.delete({
    #     mfa: "MFA",
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
        key: @object_key,
        version_id: @id
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.delete_object(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object_version.get({
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
        key: @object_key,
        version_id: @id
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.get_object(options, &block)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object_version.head({
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
    #   specified; otherwise, return a 412 (precondition failed) error.
    #
    #   If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows:
    #
    #   * `If-Match` condition evaluates to `true`, and;
    #
    #   * `If-Unmodified-Since` condition evaluates to `false`;
    #
    #   Then Amazon S3 returns `200 OK` and the data requested.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Time,DateTime,Date,Integer,String] :if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time; otherwise, return a 304 (not modified) error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:
    #
    #   * `If-None-Match` condition evaluates to `false`, and;
    #
    #   * `If-Modified-Since` condition evaluates to `true`;
    #
    #   Then Amazon S3 returns the `304 Not Modified` response code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [String] :if_none_match
    #   Return the object only if its entity tag (ETag) is different from the
    #   one specified; otherwise, return a 304 (not modified) error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:
    #
    #   * `If-None-Match` condition evaluates to `false`, and;
    #
    #   * `If-Modified-Since` condition evaluates to `true`;
    #
    #   Then Amazon S3 returns the `304 Not Modified` response code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [Time,DateTime,Date,Integer,String] :if_unmodified_since
    #   Return the object only if it has not been modified since the specified
    #   time; otherwise, return a 412 (precondition failed) error.
    #
    #   If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows:
    #
    #   * `If-Match` condition evaluates to `true`, and;
    #
    #   * `If-Unmodified-Since` condition evaluates to `false`;
    #
    #   Then Amazon S3 returns `200 OK` and the data requested.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    # @option options [String] :range
    #   HeadObject returns only the metadata for an object. If the Range is
    #   satisfiable, only the `ContentLength` is affected in the response. If
    #   the Range is not satisfiable, S3 returns a `416 - Requested Range Not
    #   Satisfiable` error.
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
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
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
    # @option options [Integer] :part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' HEAD request
    #   for the part specified. Useful querying about the size of the part and
    #   the number of parts in this object.
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @option options [String] :checksum_mode
    #   To retrieve the checksum, this parameter must be enabled.
    #
    #   **General purpose buckets** - If you enable checksum mode and the
    #   object is uploaded with a [checksum][1] and encrypted with an Key
    #   Management Service (KMS) key, you must have permission to use the
    #   `kms:Decrypt` action to retrieve the checksum.
    #
    #   **Directory buckets** - If you enable `ChecksumMode` and the object is
    #   encrypted with Amazon Web Services Key Management Service (Amazon Web
    #   Services KMS), you must also have the `kms:GenerateDataKey` and
    #   `kms:Decrypt` permissions in IAM identity-based policies and KMS key
    #   policies for the KMS key to retrieve the checksum of the object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_Checksum.html
    # @return [Types::HeadObjectOutput]
    def head(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @object_key,
        version_id: @id
      )
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.head_object(options)
      end
      resp.data
    end

    # @!group Associations

    # @return [Object]
    def object
      Object.new(
        bucket_name: @bucket_name,
        key: @object_key,
        client: @client
      )
    end

    # @deprecated
    # @api private
    def identifiers
      {
        bucket_name: @bucket_name,
        object_key: @object_key,
        id: @id
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

    def extract_object_key(args, options)
      value = args[1] || options.delete(:object_key)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :object_key"
      else
        msg = "expected :object_key to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    def extract_id(args, options)
      value = args[2] || options.delete(:id)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :id"
      else
        msg = "expected :id to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    class Collection < Aws::Resources::Collection

      # @!group Batch Actions

      # @example Request syntax with placeholder values
      #
      #   object_version.batch_delete!({
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
              key: item.object_key,
              version_id: item.id
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
require 'aws-sdk-s3/customizations/object_version'
