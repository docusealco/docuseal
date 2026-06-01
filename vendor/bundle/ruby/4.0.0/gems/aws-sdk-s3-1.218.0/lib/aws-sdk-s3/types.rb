# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  module Types

    # The ABAC status of the general purpose bucket. When ABAC is enabled
    # for the general purpose bucket, you can use tags to manage access to
    # the general purpose buckets as well as for cost tracking purposes.
    # When ABAC is disabled for the general purpose buckets, you can only
    # use tags for cost tracking purposes. For more information, see [Using
    # tags with S3 general purpose buckets][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/buckets-tagging.html
    #
    # @!attribute [rw] status
    #   The ABAC status of the general purpose bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbacStatus AWS API Documentation
    #
    class AbacStatus < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the days since the initiation of an incomplete multipart
    # upload that Amazon S3 will wait before permanently removing all parts
    # of the upload. For more information, see [ Aborting Incomplete
    # Multipart Uploads Using a Bucket Lifecycle Configuration][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #
    # @!attribute [rw] days_after_initiation
    #   Specifies the number of days after which Amazon S3 aborts an
    #   incomplete multipart upload.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortIncompleteMultipartUpload AWS API Documentation
    #
    class AbortIncompleteMultipartUpload < Struct.new(
      :days_after_initiation)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortMultipartUploadOutput AWS API Documentation
    #
    class AbortMultipartUploadOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name to which the upload was taking place.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key of the object for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   Upload ID that identifies the multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] if_match_initiated_time
    #   If present, this header aborts an in progress multipart upload only
    #   if it was initiated on the provided timestamp. If the initiated
    #   timestamp of the multipart upload does not match the provided value,
    #   the operation returns a `412 Precondition Failed` error. If the
    #   initiated timestamp matches or if the multipart upload doesn’t
    #   exist, the operation returns a `204 Success (No Content)` response.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortMultipartUploadRequest AWS API Documentation
    #
    class AbortMultipartUploadRequest < Struct.new(
      :bucket,
      :key,
      :upload_id,
      :request_payer,
      :expected_bucket_owner,
      :if_match_initiated_time)
      SENSITIVE = []
      include Aws::Structure
    end

    # Configures the transfer acceleration state for an Amazon S3 bucket.
    # For more information, see [Amazon S3 Transfer Acceleration][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    #
    # @!attribute [rw] status
    #   Specifies the transfer acceleration status of the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccelerateConfiguration AWS API Documentation
    #
    class AccelerateConfiguration < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the elements that set the ACL permissions for an object per
    # grantee.
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] owner
    #   Container for the bucket owner's display name and ID.
    #   @return [Types::Owner]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccessControlPolicy AWS API Documentation
    #
    class AccessControlPolicy < Struct.new(
      :grants,
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for information about access control for replicas.
    #
    # @!attribute [rw] owner
    #   Specifies the replica ownership. For default and valid values, see
    #   [PUT bucket replication][1] in the *Amazon S3 API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTreplication.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccessControlTranslation AWS API Documentation
    #
    class AccessControlTranslation < Struct.new(
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # You might receive this error for several reasons. For details, see the
    # description of this API operation.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccessDenied AWS API Documentation
    #
    class AccessDenied < Aws::EmptyStructure; end

    # A conjunction (logical AND) of predicates, which is used in evaluating
    # a metrics filter. The operator must have at least two predicates in
    # any combination, and an object must match all of the predicates for
    # the filter to apply.
    #
    # @!attribute [rw] prefix
    #   The prefix to use when evaluating an AND predicate: The prefix that
    #   an object must have to be included in the metrics results.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   The list of tags to use when evaluating an AND predicate.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsAndOperator AWS API Documentation
    #
    class AnalyticsAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the configuration and any analyses for the analytics filter
    # of an Amazon S3 bucket.
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   The filter used to describe a set of objects for analyses. A filter
    #   must have exactly one prefix, one tag, or one conjunction
    #   (AnalyticsAndOperator). If no filter is provided, all objects will
    #   be considered in any analysis.
    #   @return [Types::AnalyticsFilter]
    #
    # @!attribute [rw] storage_class_analysis
    #   Contains data related to access patterns to be collected and made
    #   available to analyze the tradeoffs between different storage
    #   classes.
    #   @return [Types::StorageClassAnalysis]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsConfiguration AWS API Documentation
    #
    class AnalyticsConfiguration < Struct.new(
      :id,
      :filter,
      :storage_class_analysis)
      SENSITIVE = []
      include Aws::Structure
    end

    # Where to publish the analytics results.
    #
    # @!attribute [rw] s3_bucket_destination
    #   A destination signifying output to an S3 bucket.
    #   @return [Types::AnalyticsS3BucketDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsExportDestination AWS API Documentation
    #
    class AnalyticsExportDestination < Struct.new(
      :s3_bucket_destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # The filter used to describe a set of objects for analyses. A filter
    # must have exactly one prefix, one tag, or one conjunction
    # (AnalyticsAndOperator). If no filter is provided, all objects will be
    # considered in any analysis.
    #
    # @!attribute [rw] prefix
    #   The prefix to use when evaluating an analytics filter.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   The tag to use when evaluating an analytics filter.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A conjunction (logical AND) of predicates, which is used in
    #   evaluating an analytics filter. The operator must have at least two
    #   predicates.
    #   @return [Types::AnalyticsAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsFilter AWS API Documentation
    #
    class AnalyticsFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains information about where to publish the analytics results.
    #
    # @!attribute [rw] format
    #   Specifies the file format used when exporting data to Amazon S3.
    #   @return [String]
    #
    # @!attribute [rw] bucket_account_id
    #   The account ID that owns the destination S3 bucket. If no account ID
    #   is provided, the owner is not validated before exporting data.
    #
    #   <note markdown="1"> Although this value is optional, we strongly recommend that you set
    #   it to help prevent problems if the destination bucket ownership
    #   changes.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket to which data is
    #   exported.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix to use when exporting data. The prefix is prepended to
    #   all results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsS3BucketDestination AWS API Documentation
    #
    class AnalyticsS3BucketDestination < Struct.new(
      :format,
      :bucket_account_id,
      :bucket,
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # A bucket-level setting for Amazon S3 general purpose buckets used to
    # prevent the upload of new objects encrypted with the specified
    # server-side encryption type. For example, blocking an encryption type
    # will block `PutObject`, `CopyObject`, `PostObject`, multipart upload,
    # and replication requests to the bucket for objects with the specified
    # encryption type. However, you can continue to read and list any
    # pre-existing objects already encrypted with the specified encryption
    # type. For more information, see [Blocking or unblocking SSE-C for a
    # general purpose bucket][1].
    #
    # This data type is used with the following actions:
    #
    # * [PutBucketEncryption][2]
    #
    # * [GetBucketEncryption][3]
    #
    # * [DeleteBucketEncryption][4]
    #
    # Permissions
    #
    # : You must have the `s3:PutEncryptionConfiguration` permission to
    #   block or unblock an encryption type for a bucket.
    #
    #   You must have the `s3:GetEncryptionConfiguration` permission to view
    #   a bucket's encryption type.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/blocking-unblocking-s3-c-encryption-gpb.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html
    #
    # @!attribute [rw] encryption_type
    #   The object encryption type that you want to block or unblock for an
    #   Amazon S3 general purpose bucket.
    #
    #   <note markdown="1"> Currently, this parameter only supports blocking or unblocking
    #   server side encryption with customer-provided keys (SSE-C). For more
    #   information about SSE-C, see [Using server-side encryption with
    #   customer-provided keys (SSE-C)][1].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BlockedEncryptionTypes AWS API Documentation
    #
    class BlockedEncryptionTypes < Struct.new(
      :encryption_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # In terms of implementation, a Bucket is a resource.
    #
    # @!attribute [rw] name
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] creation_date
    #   Date the bucket was created. This date can change when making
    #   changes to your bucket, such as editing its bucket policy.
    #   @return [Time]
    #
    # @!attribute [rw] bucket_region
    #   `BucketRegion` indicates the Amazon Web Services region where the
    #   bucket is located. If the request contains at least one valid
    #   parameter, it is included in the response.
    #   @return [String]
    #
    # @!attribute [rw] bucket_arn
    #   The Amazon Resource Name (ARN) of the S3 bucket. ARNs uniquely
    #   identify Amazon Web Services resources across all of Amazon Web
    #   Services.
    #
    #   <note markdown="1"> This parameter is only supported for S3 directory buckets. For more
    #   information, see [Using tags with directory buckets][1].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-tagging.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Bucket AWS API Documentation
    #
    class Bucket < Struct.new(
      :name,
      :creation_date,
      :bucket_region,
      :bucket_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # The requested bucket name is not available. The bucket namespace is
    # shared by all users of the system. Select a different name and try
    # again.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketAlreadyExists AWS API Documentation
    #
    class BucketAlreadyExists < Aws::EmptyStructure; end

    # The bucket you tried to create already exists, and you own it. Amazon
    # S3 returns this error in all Amazon Web Services Regions except in the
    # North Virginia Region. For legacy compatibility, if you re-create an
    # existing bucket that you already own in the North Virginia Region,
    # Amazon S3 returns 200 OK and resets the bucket access control lists
    # (ACLs).
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketAlreadyOwnedByYou AWS API Documentation
    #
    class BucketAlreadyOwnedByYou < Aws::EmptyStructure; end

    # Specifies the information about the bucket that will be created. For
    # more information about directory buckets, see [Directory buckets][1]
    # in the *Amazon S3 User Guide*.
    #
    # <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html
    #
    # @!attribute [rw] data_redundancy
    #   The number of Zone (Availability Zone or Local Zone) that's used
    #   for redundancy for the bucket.
    #   @return [String]
    #
    # @!attribute [rw] type
    #   The type of bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketInfo AWS API Documentation
    #
    class BucketInfo < Struct.new(
      :data_redundancy,
      :type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the lifecycle configuration for objects in an Amazon S3
    # bucket. For more information, see [Object Lifecycle Management][1] in
    # the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    #
    # @!attribute [rw] rules
    #   A lifecycle rule for individual objects in an Amazon S3 bucket.
    #   @return [Array<Types::LifecycleRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketLifecycleConfiguration AWS API Documentation
    #
    class BucketLifecycleConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for logging status information.
    #
    # @!attribute [rw] logging_enabled
    #   Describes where logs are stored and the prefix that Amazon S3
    #   assigns to all log object keys for a bucket. For more information,
    #   see [PUT Bucket logging][1] in the *Amazon S3 API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #   @return [Types::LoggingEnabled]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketLoggingStatus AWS API Documentation
    #
    class BucketLoggingStatus < Struct.new(
      :logging_enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the cross-origin access configuration for objects in an
    # Amazon S3 bucket. For more information, see [Enabling Cross-Origin
    # Resource Sharing][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    #
    # @!attribute [rw] cors_rules
    #   A set of origins and methods (cross-origin access that you want to
    #   allow). You can add up to 100 rules to the configuration.
    #   @return [Array<Types::CORSRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CORSConfiguration AWS API Documentation
    #
    class CORSConfiguration < Struct.new(
      :cors_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a cross-origin access rule for an Amazon S3 bucket.
    #
    # @!attribute [rw] id
    #   Unique identifier for the rule. The value cannot be longer than 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] allowed_headers
    #   Headers that are specified in the `Access-Control-Request-Headers`
    #   header. These headers are allowed in a preflight OPTIONS request. In
    #   response to any preflight OPTIONS request, Amazon S3 returns any
    #   requested headers that are allowed.
    #   @return [Array<String>]
    #
    # @!attribute [rw] allowed_methods
    #   An HTTP method that you allow the origin to execute. Valid values
    #   are `GET`, `PUT`, `HEAD`, `POST`, and `DELETE`.
    #   @return [Array<String>]
    #
    # @!attribute [rw] allowed_origins
    #   One or more origins you want customers to be able to access the
    #   bucket from.
    #   @return [Array<String>]
    #
    # @!attribute [rw] expose_headers
    #   One or more headers in the response that you want customers to be
    #   able to access from their applications (for example, from a
    #   JavaScript `XMLHttpRequest` object).
    #   @return [Array<String>]
    #
    # @!attribute [rw] max_age_seconds
    #   The time in seconds that your browser is to cache the preflight
    #   response for the specified resource.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CORSRule AWS API Documentation
    #
    class CORSRule < Struct.new(
      :id,
      :allowed_headers,
      :allowed_methods,
      :allowed_origins,
      :expose_headers,
      :max_age_seconds)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how an uncompressed comma-separated values (CSV)-formatted
    # input object is formatted.
    #
    # @!attribute [rw] file_header_info
    #   Describes the first line of input. Valid values are:
    #
    #   * `NONE`: First line is not a header.
    #
    #   * `IGNORE`: First line is a header, but you can't use the header
    #     values to indicate the column in an expression. You can use column
    #     position (such as \_1, \_2, …) to indicate the column (`SELECT
    #     s._1 FROM OBJECT s`).
    #
    #   * `Use`: First line is a header, and you can use the header value to
    #     identify a column in an expression (`SELECT "name" FROM OBJECT`).
    #   @return [String]
    #
    # @!attribute [rw] comments
    #   A single character used to indicate that a row should be ignored
    #   when the character is present at the start of that row. You can
    #   specify any character to indicate a comment line. The default
    #   character is `#`.
    #
    #   Default: `#`
    #   @return [String]
    #
    # @!attribute [rw] quote_escape_character
    #   A single character used for escaping the quotation mark character
    #   inside an already escaped value. For example, the value `""" a , b
    #   """` is parsed as `" a , b "`.
    #   @return [String]
    #
    # @!attribute [rw] record_delimiter
    #   A single character used to separate individual records in the input.
    #   Instead of the default value, you can specify an arbitrary
    #   delimiter.
    #   @return [String]
    #
    # @!attribute [rw] field_delimiter
    #   A single character used to separate individual fields in a record.
    #   You can specify an arbitrary delimiter.
    #   @return [String]
    #
    # @!attribute [rw] quote_character
    #   A single character used for escaping when the field delimiter is
    #   part of the value. For example, if the value is `a, b`, Amazon S3
    #   wraps this field value in quotation marks, as follows: `" a , b "`.
    #
    #   Type: String
    #
    #   Default: `"`
    #
    #   Ancestors: `CSV`
    #   @return [String]
    #
    # @!attribute [rw] allow_quoted_record_delimiter
    #   Specifies that CSV field values may contain quoted record delimiters
    #   and such records should be allowed. Default value is FALSE. Setting
    #   this value to TRUE may lower performance.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CSVInput AWS API Documentation
    #
    class CSVInput < Struct.new(
      :file_header_info,
      :comments,
      :quote_escape_character,
      :record_delimiter,
      :field_delimiter,
      :quote_character,
      :allow_quoted_record_delimiter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how uncompressed comma-separated values (CSV)-formatted
    # results are formatted.
    #
    # @!attribute [rw] quote_fields
    #   Indicates whether to use quotation marks around output fields.
    #
    #   * `ALWAYS`: Always use quotation marks for output fields.
    #
    #   * `ASNEEDED`: Use quotation marks for output fields when needed.
    #   @return [String]
    #
    # @!attribute [rw] quote_escape_character
    #   The single character used for escaping the quote character inside an
    #   already escaped value.
    #   @return [String]
    #
    # @!attribute [rw] record_delimiter
    #   A single character used to separate individual records in the
    #   output. Instead of the default value, you can specify an arbitrary
    #   delimiter.
    #   @return [String]
    #
    # @!attribute [rw] field_delimiter
    #   The value used to separate individual fields in a record. You can
    #   specify an arbitrary delimiter.
    #   @return [String]
    #
    # @!attribute [rw] quote_character
    #   A single character used for escaping when the field delimiter is
    #   part of the value. For example, if the value is `a, b`, Amazon S3
    #   wraps this field value in quotation marks, as follows: `" a , b "`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CSVOutput AWS API Documentation
    #
    class CSVOutput < Struct.new(
      :quote_fields,
      :quote_escape_character,
      :record_delimiter,
      :field_delimiter,
      :quote_character)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains all the possible checksum or digest values for an object.
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32 checksum` of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the object. This
    #   checksum is present if the object was uploaded with the `CRC64NVME`
    #   checksum algorithm, or if the object was uploaded without a checksum
    #   (and Amazon S3 added the default checksum, `CRC64NVME`, to the
    #   uploaded object). For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use the API operation on an object that was
    #   uploaded using multipart uploads, this value may not be a direct
    #   checksum value of the full object. Instead, it's a calculation
    #   based on the checksum values of each individual part. For more
    #   information about how checksums are calculated with multipart
    #   uploads, see [ Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type that is used to calculate the object’s checksum
    #   value. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Checksum AWS API Documentation
    #
    class Checksum < Struct.new(
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for specifying the Lambda notification configuration.
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] event
    #   The bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   Bucket events for which to send notifications.
    #   @return [Array<String>]
    #
    # @!attribute [rw] cloud_function
    #   Lambda cloud function ARN that Amazon S3 can invoke when it detects
    #   events of the specified type.
    #   @return [String]
    #
    # @!attribute [rw] invocation_role
    #   The role supporting the invocation of the Lambda function
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CloudFunctionConfiguration AWS API Documentation
    #
    class CloudFunctionConfiguration < Struct.new(
      :id,
      :event,
      :events,
      :cloud_function,
      :invocation_role)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all (if there are any) keys between Prefix and the next
    # occurrence of the string specified by a delimiter. CommonPrefixes
    # lists keys that act like subdirectories in the directory specified by
    # Prefix. For example, if the prefix is notes/ and the delimiter is a
    # slash (/) as in notes/summer/july, the common prefix is notes/summer/.
    #
    # @!attribute [rw] prefix
    #   Container for the specified common prefix.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CommonPrefix AWS API Documentation
    #
    class CommonPrefix < Struct.new(
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location
    #   The URI that identifies the newly created object.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket that contains the newly created object. Does
    #   not return the access point ARN or access point alias if used.
    #
    #   <note markdown="1"> Access points are not supported by directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key of the newly created object.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured, this will contain the
    #   expiration date (`expiry-date`) and rule ID (`rule-id`). The value
    #   of `rule-id` is URL-encoded.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag that identifies the newly created object's data. Objects
    #   with different object data will have different entity tags. The
    #   entity tag is an opaque string. The entity tag may or may not be an
    #   MD5 digest of the object data. If the entity tag is not an MD5
    #   digest of the object data, it will contain one or more
    #   nonhexadecimal characters and/or will consist of less than 32 or
    #   more than 32 hexadecimal digits. For more information about how the
    #   entity tag is calculated, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32 checksum` of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   object. The `CRC64NVME` checksum is always a full object checksum.
    #   For more information, see [Checking object integrity in the Amazon
    #   S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use the API operation on an object that was
    #   uploaded using multipart uploads, this value may not be a direct
    #   checksum value of the full object. Instead, it's a calculation
    #   based on the checksum values of each individual part. For more
    #   information about how checksums are calculated with multipart
    #   uploads, see [ Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type, which determines how part-level checksums are
    #   combined to create an object-level checksum for multipart objects.
    #   You can use this header as a data integrity check to verify that the
    #   checksum type that is received is the same checksum type that was
    #   specified during the `CreateMultipartUpload` request. For more
    #   information, see [Checking object integrity in the Amazon S3 User
    #   Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of the newly created object, in case the bucket has
    #   versioning turned on.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the multipart upload uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompleteMultipartUploadOutput AWS API Documentation
    #
    class CompleteMultipartUploadOutput < Struct.new(
      :location,
      :bucket,
      :key,
      :expiration,
      :etag,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type,
      :server_side_encryption,
      :version_id,
      :ssekms_key_id,
      :bucket_key_enabled,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] multipart_upload
    #   The container for the multipart upload request information.
    #   @return [Types::CompletedMultipartUpload]
    #
    # @!attribute [rw] upload_id
    #   ID for the initiated multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the
    #   object. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   object. The `CRC64NVME` checksum is always a full object checksum.
    #   For more information, see [Checking object integrity in the Amazon
    #   S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 160-bit `SHA1` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 256-bit `SHA256` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   This header specifies the checksum type of the object, which
    #   determines how part-level checksums are combined to create an
    #   object-level checksum for multipart objects. You can use this header
    #   as a data integrity check to verify that the checksum type that is
    #   received is the same checksum that was specified. If the checksum
    #   type doesn’t match the checksum type that was specified for the
    #   object during the `CreateMultipartUpload` request, it’ll result in a
    #   `BadDigest` error. For more information, see Checking object
    #   integrity in the Amazon S3 User Guide.
    #   @return [String]
    #
    # @!attribute [rw] mpu_object_size
    #   The expected total object size of the multipart upload request. If
    #   there’s a mismatch between the specified object size value and the
    #   actual object size value, it results in an `HTTP 400 InvalidRequest`
    #   error.
    #   @return [Integer]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Uploads the object only if the ETag (entity tag) value provided
    #   during the WRITE operation matches the ETag of the object in S3. If
    #   the ETag values do not match, the operation returns a `412
    #   Precondition Failed` error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a
    #   `409 ConditionalRequestConflict` response. On a 409 failure you
    #   should fetch the object's ETag, re-initiate the multipart upload
    #   with `CreateMultipartUpload`, and re-upload each part.
    #
    #   Expects the ETag value as a string.
    #
    #   For more information about conditional requests, see [RFC 7232][1],
    #   or [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    #   @return [String]
    #
    # @!attribute [rw] if_none_match
    #   Uploads the object only if the object key name does not already
    #   exist in the bucket specified. Otherwise, Amazon S3 returns a `412
    #   Precondition Failed` error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a
    #   `409 ConditionalRequestConflict` response. On a 409 failure you
    #   should re-initiate the multipart upload with `CreateMultipartUpload`
    #   and re-upload each part.
    #
    #   Expects the '*' (asterisk) character.
    #
    #   For more information about conditional requests, see [RFC 7232][1],
    #   or [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the
    #   object. This parameter is required only when the object was created
    #   using a checksum algorithm or if your bucket policy requires the use
    #   of SSE-C. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html#ssec-require-condition-key
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompleteMultipartUploadRequest AWS API Documentation
    #
    class CompleteMultipartUploadRequest < Struct.new(
      :bucket,
      :key,
      :multipart_upload,
      :upload_id,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type,
      :mpu_object_size,
      :request_payer,
      :expected_bucket_owner,
      :if_match,
      :if_none_match,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # The container for the completed multipart upload details.
    #
    # @!attribute [rw] parts
    #   Array of CompletedPart data types.
    #
    #   If you do not supply a valid `Part` with your request, the service
    #   sends back an HTTP 400 response.
    #   @return [Array<Types::CompletedPart>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompletedMultipartUpload AWS API Documentation
    #
    class CompletedMultipartUpload < Struct.new(
      :parts)
      SENSITIVE = []
      include Aws::Structure
    end

    # Details of the parts that were uploaded.
    #
    # @!attribute [rw] etag
    #   Entity tag returned when the part was uploaded.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC32` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC32C` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC64NVME` checksum algorithm to the uploaded object). For more
    #   information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `SHA1` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `SHA256` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number that identifies the part. This is a positive integer
    #   between 1 and 10,000.
    #
    #   <note markdown="1"> * **General purpose buckets** - In `CompleteMultipartUpload`, when a
    #     additional checksum (including `x-amz-checksum-crc32`,
    #     `x-amz-checksum-crc32c`, `x-amz-checksum-sha1`, or
    #     `x-amz-checksum-sha256`) is applied to each part, the `PartNumber`
    #     must start at 1 and the part numbers must be consecutive.
    #     Otherwise, Amazon S3 generates an HTTP `400 Bad Request` status
    #     code and an `InvalidPartOrder` error code.
    #
    #   * **Directory buckets** - In `CompleteMultipartUpload`, the
    #     `PartNumber` must start at 1 and the part numbers must be
    #     consecutive.
    #
    #    </note>
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompletedPart AWS API Documentation
    #
    class CompletedPart < Struct.new(
      :etag,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :part_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for describing a condition that must be met for the
    # specified redirect to apply. For example, 1. If request is for pages
    # in the `/docs` folder, redirect to the `/documents` folder. 2. If
    # request results in HTTP error 4xx, redirect request to another host
    # where you might process the error.
    #
    # @!attribute [rw] http_error_code_returned_equals
    #   The HTTP error code when the redirect is applied. In the event of an
    #   error, if the error code equals this value, then the specified
    #   redirect is applied. Required when parent element `Condition` is
    #   specified and sibling `KeyPrefixEquals` is not specified. If both
    #   are specified, then both must be true for the redirect to be
    #   applied.
    #   @return [String]
    #
    # @!attribute [rw] key_prefix_equals
    #   The object key name prefix when the redirect is applied. For
    #   example, to redirect requests for `ExamplePage.html`, the key prefix
    #   will be `ExamplePage.html`. To redirect request for all pages with
    #   the prefix `docs/`, the key prefix will be `/docs`, which identifies
    #   all objects in the `docs/` folder. Required when the parent element
    #   `Condition` is specified and sibling `HttpErrorCodeReturnedEquals`
    #   is not specified. If both conditions are specified, both must be
    #   true for the redirect to be applied.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Condition AWS API Documentation
    #
    class Condition < Struct.new(
      :http_error_code_returned_equals,
      :key_prefix_equals)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ContinuationEvent AWS API Documentation
    #
    class ContinuationEvent < Struct.new(
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] copy_object_result
    #   Container for all response elements.
    #   @return [Types::CopyObjectResult]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured, the response includes this
    #   header.
    #
    #   <note markdown="1"> Object expiration information is not returned in directory buckets
    #   and this header returns the value "`NotImplemented`" in all
    #   responses for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_version_id
    #   Version ID of the source object that was copied.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of the newly created copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, indicates the Amazon Web Services KMS Encryption Context
    #   to use for object encryption. The value of this header is a Base64
    #   encoded UTF-8 string holding JSON with the encryption context
    #   key-value pairs.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the copied object uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectOutput AWS API Documentation
    #
    class CopyObjectOutput < Struct.new(
      :copy_object_result,
      :expiration,
      :copy_source_version_id,
      :version_id,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :request_charged)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] acl
    #   The canned access control list (ACL) to apply to the object.
    #
    #   When you copy an object, the ACL metadata is not preserved and is
    #   set to `private` by default. Only the owner has full access control.
    #   To override the default ACL setting, specify a new ACL when you
    #   generate a copy request. For more information, see [Using ACLs][1].
    #
    #   If the destination bucket that you're copying objects to uses the
    #   bucket owner enforced setting for S3 Object Ownership, ACLs are
    #   disabled and no longer affect permissions. Buckets that use this
    #   setting only accept `PUT` requests that don't specify an ACL or
    #   `PUT` requests that specify bucket owner full control ACLs, such as
    #   the `bucket-owner-full-control` canned ACL or an equivalent form of
    #   this ACL expressed in the XML format. For more information, see
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
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the destination bucket.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Copying objects across different Amazon Web Services Regions isn't
    #   supported when the source or destination bucket is in Amazon Web
    #   Services Local Zones. The source and destination buckets must have
    #   the same parent Amazon Web Services Region. Otherwise, you get an
    #   HTTP `400 Bad Request` error with the error code `InvalidRequest`.
    #
    #    </note>
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must use the Outpost bucket access point ARN or the access point
    #   alias for the destination bucket. You can only copy objects within
    #   the same Outpost bucket. It's not supported to copy objects across
    #   different Amazon Web Services Outposts, between buckets on the same
    #   Outposts, or between Outposts buckets and any other bucket types.
    #   For more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *S3 on Outposts guide*. When you use this
    #   action with S3 on Outposts through the REST API, you must direct
    #   requests to the S3 on Outposts hostname, in the format `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   The hostname isn't required when you use the Amazon Web Services
    #   CLI or SDKs.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies the caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm that you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   When you copy an object, if the source object has a checksum, that
    #   checksum value will be copied to the new object by default. If the
    #   `CopyObject` request does not include this
    #   `x-amz-checksum-algorithm` header, the checksum algorithm will be
    #   copied from the source object to the destination object (if it's
    #   present on the source object). You can optionally specify a
    #   different checksum algorithm to use with the
    #   `x-amz-checksum-algorithm` header. Unrecognized or unsupported
    #   values will respond with the HTTP status code `400 Bad Request`.
    #
    #   <note markdown="1"> For directory buckets, when you use Amazon Web Services SDKs,
    #   `CRC32` is the default checksum algorithm that's used for
    #   performance.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object. Indicates
    #   whether an object should be displayed in a web browser or downloaded
    #   as a file. It allows specifying the desired filename for the
    #   downloaded file.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #
    #   <note markdown="1"> For directory buckets, only the `aws-chunked` value is supported in
    #   this header field.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type that describes the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] copy_source
    #   Specifies the source object for the copy operation. The source
    #   object can be up to 5 GB. If the source object is an object that was
    #   uploaded by using a multipart upload, the object copy will be a
    #   single part object after the source object is copied to the
    #   destination bucket.
    #
    #   You specify the value of the copy source in one of two formats,
    #   depending on whether you want to access the source object through an
    #   [access point][1]:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and the key of the source object, separated
    #     by a slash (/). For example, to copy the object
    #     `reports/january.pdf` from the general purpose bucket
    #     `awsexamplebucket`, use `awsexamplebucket/reports/january.pdf`.
    #     The value must be URL-encoded. To copy the object
    #     `reports/january.pdf` from the directory bucket
    #     `awsexamplebucket--use1-az5--x-s3`, use
    #     `awsexamplebucket--use1-az5--x-s3/reports/january.pdf`. The value
    #     must be URL-encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     access point `my-access-point` owned by account `123456789012` in
    #     Region `us-west-2`, use the URL encoding of
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
    #   header by default identifies the current version of an object to
    #   copy. If the current version is a delete marker, Amazon S3 behaves
    #   as if the object was deleted. To copy a different version, use the
    #   `versionId` query parameter. Specifically, append
    #   `?versionId=<version-id>` to the value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #   If you enable versioning on the destination bucket, Amazon S3
    #   generates a unique version ID for the copied object. This version ID
    #   is different from the version ID of the source object. Amazon S3
    #   returns the version ID of the copied object in the
    #   `x-amz-version-id` response header in the response.
    #
    #   If you do not enable versioning or suspend it on the destination
    #   bucket, the version ID that Amazon S3 generates in the
    #   `x-amz-version-id` response header is always null.
    #
    #   <note markdown="1"> **Directory buckets** - S3 Versioning isn't enabled and supported
    #   for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified
    #   tag.
    #
    #   If both the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns `200 OK` and
    #   copies the data:
    #
    #   * `x-amz-copy-source-if-match` condition evaluates to true
    #
    #   * `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #     false
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_modified_since
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
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_if_none_match
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
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #
    #   If both the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns `200 OK` and
    #   copies the data:
    #
    #   * `x-amz-copy-source-if-match` condition evaluates to true
    #
    #   * `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #     false
    #   @return [Time]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] if_match
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
    #   @return [String]
    #
    # @!attribute [rw] if_none_match
    #   Copies the object only if the object key name at the destination
    #   does not already exist in the bucket specified. Otherwise, Amazon S3
    #   returns a `412 Precondition Failed` error. If a concurrent operation
    #   occurs during the upload S3 returns a `409
    #   ConditionalRequestConflict` response. On a 409 failure you should
    #   retry the upload.
    #
    #   Expects the '*' (asterisk) character.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key of the destination object.
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] metadata_directive
    #   Specifies whether the metadata is copied from the source object or
    #   replaced with metadata that's provided in the request. When copying
    #   an object, you can preserve all metadata (the default) or specify
    #   new metadata. If this header isn’t specified, `COPY` is the default
    #   behavior.
    #
    #   **General purpose bucket** - For general purpose buckets, when you
    #   grant permissions, you can use the `s3:x-amz-metadata-directive`
    #   condition key to enforce certain metadata behavior when objects are
    #   uploaded. For more information, see [Amazon S3 condition key
    #   examples][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> `x-amz-website-redirect-location` is unique to each object and is
    #   not copied when using the `x-amz-metadata-directive` header. To copy
    #   the value, you must specify `x-amz-website-redirect-location` in the
    #   request header.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/amazon-s3-policy-keys.html
    #   @return [String]
    #
    # @!attribute [rw] tagging_directive
    #   Specifies whether the object tag-set is copied from the source
    #   object or replaced with the tag-set that's provided in the request.
    #
    #   The default value is `COPY`.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets in a `CopyObject`
    #   operation, only the empty tag-set is supported. Any requests that
    #   attempt to write non-empty tags into directory buckets will receive
    #   a `501 Not Implemented` status code. When the destination bucket is
    #   a directory bucket, you will receive a `501 Not Implemented`
    #   response in any of the following situations:
    #
    #    * When you attempt to `COPY` the tag-set from an S3 source object
    #     that has non-empty tags.
    #
    #   * When you attempt to `REPLACE` the tag-set of a source object and
    #     set a non-empty value to `x-amz-tagging`.
    #
    #   * When you don't set the `x-amz-tagging-directive` header and the
    #     source object has non-empty tags. This is because the default
    #     value of `x-amz-tagging-directive` is `COPY`.
    #
    #    Because only the empty tag-set is supported for directory buckets in
    #   a `CopyObject` operation, the following situations are allowed:
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
    #     `x-amz-tagging` value of the directory bucket destination object
    #     to empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and don't set the `x-amz-tagging` value of the
    #     directory bucket destination object. This is because the default
    #     value of `x-amz-tagging` is the empty value.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3. Unrecognized or unsupported values won’t write a
    #   destination object and will receive a `400 Bad Request` response.
    #
    #   Amazon S3 automatically encrypts all new objects that are copied to
    #   an S3 bucket. When copying an object, if you don't specify
    #   encryption information in your copy request, the encryption setting
    #   of the target object is set to the default encryption configuration
    #   of the destination bucket. By default, all buckets have a base level
    #   of encryption configuration that uses server-side encryption with
    #   Amazon S3 managed keys (SSE-S3). If the destination bucket has a
    #   different default encryption configuration, Amazon S3 uses the
    #   corresponding encryption key to encrypt the target object copy.
    #
    #   With server-side encryption, Amazon S3 encrypts your data as it
    #   writes your data to disks in its data centers and decrypts the data
    #   when you access it. For more information about server-side
    #   encryption, see [Using Server-Side Encryption][1] in the *Amazon S3
    #   User Guide*.
    #
    #   <b>General purpose buckets </b>
    #
    #   * For general purpose buckets, there are the following supported
    #     options for server-side encryption: server-side encryption with
    #     Key Management Service (KMS) keys (SSE-KMS), dual-layer
    #     server-side encryption with Amazon Web Services KMS keys
    #     (DSSE-KMS), and server-side encryption with customer-provided
    #     encryption keys (SSE-C). Amazon S3 uses the corresponding KMS key,
    #     or a customer-provided key to encrypt the target object copy.
    #
    #   * When you perform a `CopyObject` operation, if you want to use a
    #     different type of encryption setting for the target object, you
    #     can specify appropriate encryption-related headers to encrypt the
    #     target object with an Amazon S3 managed key, a KMS key, or a
    #     customer-provided key. If the encryption setting in your request
    #     is different from the default encryption configuration of the
    #     destination bucket, the encryption setting in your request takes
    #     precedence.
    #
    #   <b>Directory buckets </b>
    #
    #   * For directory buckets, there are only two supported options for
    #     server-side encryption: server-side encryption with Amazon S3
    #     managed keys (SSE-S3) (`AES256`) and server-side encryption with
    #     KMS keys (SSE-KMS) (`aws:kms`). We recommend that the bucket's
    #     default encryption uses the desired encryption configuration and
    #     you don't override the bucket default encryption in your
    #     `CreateSession` requests or `PUT` object requests. Then, new
    #     objects are automatically encrypted with the desired encryption
    #     settings. For more information, see [Protecting data with
    #     server-side encryption][2] in the *Amazon S3 User Guide*. For more
    #     information about the encryption overriding behaviors in directory
    #     buckets, see [Specifying server-side encryption with KMS for new
    #     object uploads][3].
    #
    #   * To encrypt new object copies to a directory bucket with SSE-KMS,
    #     we recommend you specify SSE-KMS as the directory bucket's
    #     default encryption configuration with a KMS key (specifically, a
    #     [customer managed key][4]). The [Amazon Web Services managed
    #     key][5] (`aws/s3`) isn't supported. Your SSE-KMS configuration
    #     can only support 1 [customer managed key][4] per directory bucket
    #     for the lifetime of the bucket. After you specify a customer
    #     managed key for SSE-KMS, you can't override the customer managed
    #     key for the bucket's SSE-KMS configuration. Then, when you
    #     perform a `CopyObject` operation and want to specify server-side
    #     encryption settings for new object copies with SSE-KMS in the
    #     encryption-related request headers, you must ensure the encryption
    #     key is the same customer managed key that you specified for the
    #     directory bucket's default encryption configuration.
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data
    #     stored in Amazon FSx file systems using S3 access points, the only
    #     valid server side encryption option is `aws:fsx`. All Amazon FSx
    #     file systems have encryption configured by default and are
    #     encrypted at rest. Data is automatically encrypted before being
    #     written to the file system, and automatically decrypted as it is
    #     read. These processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   If the `x-amz-storage-class` header is not used, the copied object
    #   will be stored in the `STANDARD` Storage Class by default. The
    #   `STANDARD` storage class provides high durability and high
    #   availability. Depending on performance needs, you can specify a
    #   different Storage Class.
    #
    #   <note markdown="1"> * <b>Directory buckets </b> - Directory buckets only support
    #     `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #     Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #     Access storage class) in Dedicated Local Zones. Unsupported
    #     storage class values won't write a destination object and will
    #     respond with the HTTP status code `400 Bad Request`.
    #
    #   * <b>Amazon S3 on Outposts </b> - S3 on Outposts only uses the
    #     `OUTPOSTS` Storage Class.
    #
    #    </note>
    #
    #   You can use the `CopyObject` action to change the storage class of
    #   an object that is already stored in Amazon S3 by using the
    #   `x-amz-storage-class` header. For more information, see [Storage
    #   Classes][1] in the *Amazon S3 User Guide*.
    #
    #   Before using an object as a source object for the copy operation,
    #   you must restore a copy of it if it meets any of the following
    #   conditions:
    #
    #   * The storage class of the source object is `GLACIER` or
    #     `DEEP_ARCHIVE`.
    #
    #   * The storage class of the source object is `INTELLIGENT_TIERING`
    #     and it's [S3 Intelligent-Tiering access tier][2] is `Archive
    #     Access` or `Deep Archive Access`.
    #
    #   For more information, see [RestoreObject][3] and [Copying
    #   Objects][4] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/intelligent-tiering-overview.html#intel-tiering-tier-definition
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjectsExamples.html
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the destination bucket is configured as a website, redirects
    #   requests for this object copy to another object in the same bucket
    #   or to an external URL. Amazon S3 stores the value of this header in
    #   the object metadata. This value is unique to each object and is not
    #   copied when using the `x-amz-metadata-directive` header. Instead,
    #   you may opt to provide this header in combination with the
    #   `x-amz-metadata-directive` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, `AES256`).
    #
    #   When you perform a `CopyObject` operation, if you want to use a
    #   different type of encryption setting for the target object, you can
    #   specify appropriate encryption-related headers to encrypt the target
    #   object with an Amazon S3 managed key, a KMS key, or a
    #   customer-provided key. If the encryption setting in your request is
    #   different from the default encryption configuration of the
    #   destination bucket, the encryption setting in your request takes
    #   precedence.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded. Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. All GET and PUT requests for an object protected
    #   by KMS will fail if they're not made via SSL or using SigV4. For
    #   information about configuring any of the officially supported Amazon
    #   Web Services SDKs and Amazon Web Services CLI, see [Specifying the
    #   Signature Version in Request Authentication][1] in the *Amazon S3
    #   User Guide*.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed
    #   key ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match
    #   the bucket's default customer managed key (using key ID or ARN, not
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
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context as an
    #   additional encryption context to use for the destination object
    #   encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #
    #   **General purpose buckets** - This value must be explicitly added to
    #   specify encryption context for `CopyObject` requests if you want an
    #   additional encryption context for your destination object. The
    #   additional encryption context of the source object won't be copied
    #   to the destination object. For more information, see [Encryption
    #   context][1] in the *Amazon S3 User Guide*.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default
    #   encryption context - the bucket Amazon Resource Name (ARN). An
    #   additional encryption context value is not supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html#encryption-context
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). If a target object uses SSE-KMS, you can
    #   enable an S3 Bucket Key for the object.
    #
    #   Setting this header to `true` causes Amazon S3 to use an S3 Bucket
    #   Key for object encryption with SSE-KMS. Specifying this header with
    #   a COPY action doesn’t affect bucket-level settings for S3 Bucket
    #   Key.
    #
    #   For more information, see [Amazon S3 Bucket Keys][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> **Directory buckets** - S3 Bucket Keys aren't supported, when you
    #   copy SSE-KMS encrypted objects from general purpose buckets to
    #   directory buckets, from directory buckets to general purpose
    #   buckets, or between directory buckets, through [CopyObject][2]. In
    #   this case, Amazon S3 makes a call to KMS every time a copy request
    #   is made for a KMS-encrypted object.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   @return [Boolean]
    #
    # @!attribute [rw] copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object
    #   (for example, `AES256`).
    #
    #   If the source object for the copy is stored in Amazon S3 using
    #   SSE-C, you must provide the necessary encryption information in your
    #   request so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   to decrypt the source object. The encryption key provided in this
    #   header must be the same one that was used when the source object was
    #   created.
    #
    #   If the source object for the copy is stored in Amazon S3 using
    #   SSE-C, you must provide the necessary encryption information in your
    #   request so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   If the source object for the copy is stored in Amazon S3 using
    #   SSE-C, you must provide the necessary encryption information in your
    #   request so that Amazon S3 can decrypt the object for copying.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object copy in the destination bucket. This
    #   value must be used in conjunction with the `x-amz-tagging-directive`
    #   if you choose `REPLACE` for the `x-amz-tagging-directive`. If you
    #   choose `COPY` for the `x-amz-tagging-directive`, you don't need to
    #   set the `x-amz-tagging` header, because the tag-set will be copied
    #   from the source object directly. The tag-set must be encoded as URL
    #   Query parameters.
    #
    #   The default value is the empty value.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets in a `CopyObject`
    #   operation, only the empty tag-set is supported. Any requests that
    #   attempt to write non-empty tags into directory buckets will receive
    #   a `501 Not Implemented` status code. When the destination bucket is
    #   a directory bucket, you will receive a `501 Not Implemented`
    #   response in any of the following situations:
    #
    #    * When you attempt to `COPY` the tag-set from an S3 source object
    #     that has non-empty tags.
    #
    #   * When you attempt to `REPLACE` the tag-set of a source object and
    #     set a non-empty value to `x-amz-tagging`.
    #
    #   * When you don't set the `x-amz-tagging-directive` header and the
    #     source object has non-empty tags. This is because the default
    #     value of `x-amz-tagging-directive` is `COPY`.
    #
    #    Because only the empty tag-set is supported for directory buckets in
    #   a `CopyObject` operation, the following situations are allowed:
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
    #     `x-amz-tagging` value of the directory bucket destination object
    #     to empty.
    #
    #   * When you attempt to `REPLACE` the tag-set of a directory bucket
    #     source object and don't set the `x-amz-tagging` value of the
    #     directory bucket destination object. This is because the default
    #     value of `x-amz-tagging` is the empty value.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode that you want to apply to the object copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when you want the Object Lock of the object copy
    #   to expire.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the object copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected destination bucket owner. If the
    #   account ID that you provide does not match the actual owner of the
    #   destination bucket, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #   @return [String]
    #
    # @!attribute [rw] expected_source_bucket_owner
    #   The account ID of the expected source bucket owner. If the account
    #   ID that you provide does not match the actual owner of the source
    #   bucket, the request fails with the HTTP status code `403 Forbidden`
    #   (access denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectRequest AWS API Documentation
    #
    class CopyObjectRequest < Struct.new(
      :acl,
      :bucket,
      :cache_control,
      :checksum_algorithm,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :copy_source,
      :copy_source_if_match,
      :copy_source_if_modified_since,
      :copy_source_if_none_match,
      :copy_source_if_unmodified_since,
      :expires,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :if_match,
      :if_none_match,
      :key,
      :metadata,
      :metadata_directive,
      :tagging_directive,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :copy_source_sse_customer_algorithm,
      :copy_source_sse_customer_key,
      :copy_source_sse_customer_key_md5,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner,
      :expected_source_bucket_owner)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context, :copy_source_sse_customer_key]
      include Aws::Structure
    end

    # Container for all response elements.
    #
    # @!attribute [rw] etag
    #   Returns the ETag of the new object. The ETag reflects only changes
    #   to the contents of an object, not its metadata.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Creation date of the object.
    #   @return [Time]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type that is used to calculate the object’s checksum
    #   value. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32` checksum of the object. This
    #   checksum is only present if the object was uploaded with the object.
    #   For more information, see [ Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the object. This
    #   checksum is present if the object being copied was uploaded with the
    #   `CRC64NVME` checksum algorithm, or if the object was uploaded
    #   without a checksum (and Amazon S3 added the default checksum,
    #   `CRC64NVME`, to the uploaded object). For more information, see
    #   [Checking object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectResult AWS API Documentation
    #
    class CopyObjectResult < Struct.new(
      :etag,
      :last_modified,
      :checksum_type,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all response elements.
    #
    # @!attribute [rw] etag
    #   Entity tag of the object.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Date and time at which the object was uploaded.
    #   @return [Time]
    #
    # @!attribute [rw] checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the part.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the part.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC64NVME` checksum algorithm to the uploaded object). For more
    #   information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 160-bit `SHA1` checksum of the part.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 256-bit `SHA256` checksum of the part.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyPartResult AWS API Documentation
    #
    class CopyPartResult < Struct.new(
      :etag,
      :last_modified,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256)
      SENSITIVE = []
      include Aws::Structure
    end

    # The configuration information for the bucket.
    #
    # @!attribute [rw] location_constraint
    #   Specifies the Region where the bucket will be created. You might
    #   choose a Region to optimize latency, minimize costs, or address
    #   regulatory requirements. For example, if you reside in Europe, you
    #   will probably find it advantageous to create buckets in the Europe
    #   (Ireland) Region.
    #
    #   If you don't specify a Region, the bucket is created in the US East
    #   (N. Virginia) Region (us-east-1) by default. Configurations using
    #   the value `EU` will create a bucket in `eu-west-1`.
    #
    #   For a list of the valid values for all of the Amazon Web Services
    #   Regions, see [Regions and Endpoints][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    #   @return [String]
    #
    # @!attribute [rw] location
    #   Specifies the location where the bucket will be created.
    #
    #   <b>Directory buckets </b> - The location type is Availability Zone
    #   or Local Zone. To use the Local Zone location type, your account
    #   must be enabled for Local Zones. Otherwise, you get an HTTP `403
    #   Forbidden` error with the error code `AccessDenied`. To learn more,
    #   see [Enable accounts for Local Zones][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/opt-in-directory-bucket-lz.html
    #   @return [Types::LocationInfo]
    #
    # @!attribute [rw] bucket
    #   Specifies the information about the bucket that will be created.
    #
    #   <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #    </note>
    #   @return [Types::BucketInfo]
    #
    # @!attribute [rw] tags
    #   An array of tags that you can apply to the bucket that you're
    #   creating. Tags are key-value pairs of metadata used to categorize
    #   and organize your buckets, track costs, and control access.
    #
    #   You must have the `s3:TagResource` permission to create a general
    #   purpose bucket with tags or the `s3express:TagResource` permission
    #   to create a directory bucket with tags.
    #
    #   When creating buckets with tags, note that tag-based conditions
    #   using `aws:ResourceTag` and `s3:BucketTag` condition keys are
    #   applicable only after ABAC is enabled on the bucket. To learn more,
    #   see [Enabling ABAC in general purpose buckets][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/buckets-tagging-enable-abac.html
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketConfiguration AWS API Documentation
    #
    class CreateBucketConfiguration < Struct.new(
      :location_constraint,
      :location,
      :bucket,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that you want to create the metadata
    #   configuration for.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The `Content-MD5` header for the metadata configuration.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The checksum algorithm to use with your metadata configuration.
    #   @return [String]
    #
    # @!attribute [rw] metadata_configuration
    #   The contents of your metadata configuration.
    #   @return [Types::MetadataConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that corresponds to
    #   your metadata configuration.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketMetadataConfigurationRequest AWS API Documentation
    #
    class CreateBucketMetadataConfigurationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :metadata_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that you want to create the metadata
    #   table configuration for.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The `Content-MD5` header for the metadata table configuration.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The checksum algorithm to use with your metadata table
    #   configuration.
    #   @return [String]
    #
    # @!attribute [rw] metadata_table_configuration
    #   The contents of your metadata table configuration.
    #   @return [Types::MetadataTableConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that corresponds to
    #   your metadata table configuration.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketMetadataTableConfigurationRequest AWS API Documentation
    #
    class CreateBucketMetadataTableConfigurationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :metadata_table_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location
    #   A forward slash followed by the name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] bucket_arn
    #   The Amazon Resource Name (ARN) of the S3 bucket. ARNs uniquely
    #   identify Amazon Web Services resources across all of Amazon Web
    #   Services.
    #
    #   <note markdown="1"> This parameter is only supported for S3 directory buckets. For more
    #   information, see [Using tags with directory buckets][1].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-tagging.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketOutput AWS API Documentation
    #
    class CreateBucketOutput < Struct.new(
      :location,
      :bucket_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] acl
    #   The canned ACL to apply to the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to create.
    #
    #   **General purpose buckets** - For information about bucket naming
    #   restrictions, see [Bucket naming rules][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][2] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] create_bucket_configuration
    #   The configuration information for the bucket.
    #   @return [Types::CreateBucketConfiguration]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_enabled_for_bucket
    #   Specifies whether you want S3 Object Lock to be enabled for the new
    #   bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] object_ownership
    #   The container element for object ownership for a bucket's ownership
    #   controls.
    #
    #   `BucketOwnerPreferred` - Objects uploaded to the bucket change
    #   ownership to the bucket owner if the objects are uploaded with the
    #   `bucket-owner-full-control` canned ACL.
    #
    #   `ObjectWriter` - The uploading account will own the object if the
    #   object is uploaded with the `bucket-owner-full-control` canned ACL.
    #
    #   `BucketOwnerEnforced` - Access control lists (ACLs) are disabled and
    #   no longer affect permissions. The bucket owner automatically owns
    #   and has full control over every object in the bucket. The bucket
    #   only accepts PUT requests that don't specify an ACL or specify
    #   bucket owner full control ACLs (such as the predefined
    #   `bucket-owner-full-control` canned ACL or a custom ACL in XML format
    #   that grants the same permissions).
    #
    #   By default, `ObjectOwnership` is set to `BucketOwnerEnforced` and
    #   ACLs are disabled. We recommend keeping ACLs disabled, except in
    #   uncommon use cases where you must control access for each object
    #   individually. For more information about S3 Object Ownership, see
    #   [Controlling ownership of objects and disabling ACLs for your
    #   bucket][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets use the bucket owner enforced setting for S3 Object
    #   Ownership.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    #   @return [String]
    #
    # @!attribute [rw] bucket_namespace
    #   Specifies the namespace where you want to create your general
    #   purpose bucket. When you create a general purpose bucket, you can
    #   choose to create a bucket in the shared global namespace or you can
    #   choose to create a bucket in your account regional namespace. Your
    #   account regional namespace is a subdivision of the global namespace
    #   that only your account can create buckets in. For more information
    #   on bucket namespaces, see [Namespaces for general purpose
    #   buckets][1].
    #
    #   General purpose buckets in your account regional namespace must
    #   follow a specific naming convention. These buckets consist of a
    #   bucket name prefix that you create, and a suffix that contains your
    #   12-digit Amazon Web Services Account ID, the Amazon Web Services
    #   Region code, and ends with `-an`. Bucket names must follow the
    #   format `bucket-name-prefix-accountId-region-an` (for example,
    #   `amzn-s3-demo-bucket-111122223333-us-west-2-an`). For information
    #   about bucket naming restrictions, see [Account regional namespace
    #   naming rules][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/gpbucketnamespaces.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html#account-regional-naming-rules
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketRequest AWS API Documentation
    #
    class CreateBucketRequest < Struct.new(
      :acl,
      :bucket,
      :create_bucket_configuration,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :object_lock_enabled_for_bucket,
      :object_ownership,
      :bucket_namespace)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] abort_date
    #   If the bucket has a lifecycle rule configured with an action to
    #   abort incomplete multipart uploads and the prefix in the lifecycle
    #   rule matches the object name in the request, the response includes
    #   this header. The header indicates when the initiated multipart
    #   upload becomes eligible for an abort operation. For more
    #   information, see [ Aborting Incomplete Multipart Uploads Using a
    #   Bucket Lifecycle Configuration][1] in the *Amazon S3 User Guide*.
    #
    #   The response also includes the `x-amz-abort-rule-id` header that
    #   provides the ID of the lifecycle configuration rule that defines the
    #   abort action.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Time]
    #
    # @!attribute [rw] abort_rule_id
    #   This header is returned along with the `x-amz-abort-date` header. It
    #   identifies the applicable lifecycle configuration rule that defines
    #   the action to abort incomplete multipart uploads.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #   Does not return the access point ARN or access point alias if used.
    #
    #   <note markdown="1"> Access points are not supported by directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   ID for the initiated multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, indicates the Amazon Web Services KMS Encryption Context
    #   to use for object encryption. The value of this header is a Base64
    #   encoded string of a UTF-8 encoded JSON, which contains the
    #   encryption context as key-value pairs.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the multipart upload uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The algorithm that was used to create a checksum of the object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   Indicates the checksum type that you want Amazon S3 to use to
    #   calculate the object’s checksum value. For more information, see
    #   [Checking object integrity in the Amazon S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateMultipartUploadOutput AWS API Documentation
    #
    class CreateMultipartUploadOutput < Struct.new(
      :abort_date,
      :abort_rule_id,
      :bucket,
      :key,
      :upload_id,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :request_charged,
      :checksum_algorithm,
      :checksum_type)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] acl
    #   The canned ACL to apply to the object. Amazon S3 supports a set of
    #   predefined ACLs, known as *canned ACLs*. Each canned ACL has a
    #   predefined set of grantees and permissions. For more information,
    #   see [Canned ACL][1] in the *Amazon S3 User Guide*.
    #
    #   By default, all objects are private. Only the owner has full access
    #   control. When uploading an object, you can grant access permissions
    #   to individual Amazon Web Services accounts or to predefined groups
    #   defined by Amazon S3. These permissions are then added to the access
    #   control list (ACL) on the new object. For more information, see
    #   [Using ACLs][2]. One way to grant the permissions using the request
    #   headers is to specify a canned ACL with the `x-amz-acl` request
    #   header.
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
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket where the multipart upload is initiated and
    #   where the object is uploaded.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #
    #   <note markdown="1"> For directory buckets, only the `aws-chunked` value is supported in
    #   this header field.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language that the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] grant_full_control
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
    #   * `id` – if the value specified is the canonical user ID of an
    #     Amazon Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
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
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the
    #   Amazon Web Services accounts identified by account IDs permissions
    #   to read object data and its metadata:
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
    #   @return [String]
    #
    # @!attribute [rw] grant_read
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
    #   * `id` – if the value specified is the canonical user ID of an
    #     Amazon Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
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
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the
    #   Amazon Web Services accounts identified by account IDs permissions
    #   to read object data and its metadata:
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
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
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
    #   * `id` – if the value specified is the canonical user ID of an
    #     Amazon Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
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
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the
    #   Amazon Web Services accounts identified by account IDs permissions
    #   to read object data and its metadata:
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
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
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
    #   * `id` – if the value specified is the canonical user ID of an
    #     Amazon Web Services account
    #
    #   * `uri` – if you are granting permissions to a predefined group
    #
    #   * `emailAddress` – if the value specified is the email address of an
    #     Amazon Web Services account
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
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
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][2] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    #   For example, the following `x-amz-grant-read` header grants the
    #   Amazon Web Services accounts identified by account IDs permissions
    #   to read object data and its metadata:
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
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload is to be initiated.
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   * <b>Directory buckets </b> - For directory buckets, there are only
    #     two supported options for server-side encryption: server-side
    #     encryption with Amazon S3 managed keys (SSE-S3) (`AES256`) and
    #     server-side encryption with KMS keys (SSE-KMS) (`aws:kms`). We
    #     recommend that the bucket's default encryption uses the desired
    #     encryption configuration and you don't override the bucket
    #     default encryption in your `CreateSession` requests or `PUT`
    #     object requests. Then, new objects are automatically encrypted
    #     with the desired encryption settings. For more information, see
    #     [Protecting data with server-side encryption][1] in the *Amazon S3
    #     User Guide*. For more information about the encryption overriding
    #     behaviors in directory buckets, see [Specifying server-side
    #     encryption with KMS for new object uploads][2].
    #
    #     In the Zonal endpoint API calls (except [CopyObject][3] and
    #     [UploadPartCopy][4]) using the REST API, the encryption request
    #     headers must match the encryption settings that are specified in
    #     the `CreateSession` request. You can't override the values of the
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
    #     `CreateSession`, the session token refreshes automatically to
    #     avoid service interruptions when a session expires. The CLI or the
    #     Amazon Web Services SDKs use the bucket's default encryption
    #     configuration for the `CreateSession` request. It's not supported
    #     to override the encryption settings values in the `CreateSession`
    #     request. So in the Zonal endpoint API calls (except
    #     [CopyObject][3] and [UploadPartCopy][4]), the encryption request
    #     headers must match the default encryption configuration of the
    #     directory bucket.
    #
    #      </note>
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data
    #     stored in Amazon FSx file systems using S3 access points, the only
    #     valid server side encryption option is `aws:fsx`. All Amazon FSx
    #     file systems have encryption configured by default and are
    #     encrypted at rest. Data is automatically encrypted before being
    #     written to the file system, and automatically decrypted as it is
    #     read. These processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can
    #   specify a different Storage Class. For more information, see
    #   [Storage Classes][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> * Directory buckets only support `EXPRESS_ONEZONE` (the S3 Express
    #     One Zone storage class) in Availability Zones and `ONEZONE_IA`
    #     (the S3 One Zone-Infrequent Access storage class) in Dedicated
    #     Local Zones.
    #
    #   * Amazon S3 on Outposts only uses the OUTPOSTS Storage Class.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the customer-provided encryption
    #   key according to RFC 1321. Amazon S3 uses this header for a message
    #   integrity check to ensure that the encryption key was transmitted
    #   without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. If the KMS key doesn't exist in the same account
    #   that's issuing the command, you must use the full Key ARN not the
    #   Key ID.
    #
    #   **General purpose buckets** - If you specify
    #   `x-amz-server-side-encryption` with `aws:kms` or `aws:kms:dsse`,
    #   this header specifies the ID (Key ID, Key ARN, or Key Alias) of the
    #   KMS key to use. If you specify
    #   `x-amz-server-side-encryption:aws:kms` or
    #   `x-amz-server-side-encryption:aws:kms:dsse`, but do not provide
    #   `x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the
    #   Amazon Web Services managed key (`aws/s3`) to protect the data.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed
    #   key ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match
    #   the bucket's default customer managed key (using key ID or ARN, not
    #   alias). Your SSE-KMS configuration can only support 1 [customer
    #   managed key][1] per directory bucket's lifetime. The [Amazon Web
    #   Services managed key][2] (`aws/s3`) isn't supported. Incorrect key
    #   specification results in an HTTP `400 Bad Request` error.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context to use for
    #   object encryption. The value of this header is a Base64 encoded
    #   string of a UTF-8 encoded JSON, which contains the encryption
    #   context as key-value pairs.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default
    #   encryption context - the bucket Amazon Resource Name (ARN). An
    #   additional encryption context value is not supported.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS).
    #
    #   **General purpose buckets** - Setting this header to `true` causes
    #   Amazon S3 to use an S3 Bucket Key for object encryption with
    #   SSE-KMS. Also, specifying this header with a PUT action doesn't
    #   affect bucket-level settings for S3 Bucket Key.
    #
    #   **Directory buckets** - S3 Bucket Keys are always enabled for `GET`
    #   and `PUT` operations in a directory bucket and can’t be disabled. S3
    #   Bucket Keys aren't supported, when you copy SSE-KMS encrypted
    #   objects from general purpose buckets to directory buckets, from
    #   directory buckets to general purpose buckets, or between directory
    #   buckets, through [CopyObject][1], [UploadPartCopy][2], [the Copy
    #   operation in Batch Operations][3], or [the import jobs][4]. In this
    #   case, Amazon S3 makes a call to KMS every time a copy request is
    #   made for a KMS-encrypted object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    #   @return [Boolean]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   Specifies the Object Lock mode that you want to apply to the
    #   uploaded object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   Specifies the date and time when you want the Object Lock to expire.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the uploaded
    #   object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm that you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   Indicates the checksum type that you want Amazon S3 to use to
    #   calculate the object’s checksum value. For more information, see
    #   [Checking object integrity in the Amazon S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateMultipartUploadRequest AWS API Documentation
    #
    class CreateMultipartUploadRequest < Struct.new(
      :acl,
      :bucket,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :expires,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :key,
      :metadata,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner,
      :checksum_algorithm,
      :checksum_type)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store objects in
    #   the directory bucket.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If you specify `x-amz-server-side-encryption` with `aws:kms`, this
    #   header indicates the ID of the KMS symmetric encryption customer
    #   managed key that was used for object encryption.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, indicates the Amazon Web Services KMS Encryption Context
    #   to use for object encryption. The value of this header is a Base64
    #   encoded string of a UTF-8 encoded JSON, which contains the
    #   encryption context as key-value pairs. This value is stored as
    #   object metadata and automatically gets passed on to Amazon Web
    #   Services KMS for future `GetObject` operations on this object.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether to use an S3 Bucket Key for server-side encryption
    #   with KMS keys (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] credentials
    #   The established temporary security credentials for the created
    #   session.
    #   @return [Types::SessionCredentials]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateSessionOutput AWS API Documentation
    #
    class CreateSessionOutput < Struct.new(
      :server_side_encryption,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :credentials)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] session_mode
    #   Specifies the mode of the session that will be created, either
    #   `ReadWrite` or `ReadOnly`. If no session mode is specified, the
    #   default behavior attempts to create a session with the maximum
    #   allowable privilege. It will first attempt to create a `ReadWrite`
    #   session, and if that is not allowed by permissions, it will attempt
    #   to create a `ReadOnly` session. If neither session type is allowed,
    #   the request will return an Access Denied error. A `ReadWrite`
    #   session is capable of executing all the Zonal endpoint API
    #   operations on a directory bucket. A `ReadOnly` session is
    #   constrained to execute the following Zonal endpoint API operations:
    #   `GetObject`, `HeadObject`, `ListObjectsV2`, `GetObjectAttributes`,
    #   `ListParts`, and `ListMultipartUploads`.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket that you create a session for.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm to use when you store objects
    #   in the directory bucket.
    #
    #   For directory buckets, there are only two supported options for
    #   server-side encryption: server-side encryption with Amazon S3
    #   managed keys (SSE-S3) (`AES256`) and server-side encryption with KMS
    #   keys (SSE-KMS) (`aws:kms`). By default, Amazon S3 encrypts data with
    #   SSE-S3. For more information, see [Protecting data with server-side
    #   encryption][1] in the *Amazon S3 User Guide*.
    #
    #   <b>S3 access points for Amazon FSx </b> - When accessing data stored
    #   in Amazon FSx file systems using S3 access points, the only valid
    #   server side encryption option is `aws:fsx`. All Amazon FSx file
    #   systems have encryption configured by default and are encrypted at
    #   rest. Data is automatically encrypted before being written to the
    #   file system, and automatically decrypted as it is read. These
    #   processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If you specify `x-amz-server-side-encryption` with `aws:kms`, you
    #   must specify the ` x-amz-server-side-encryption-aws-kms-key-id`
    #   header with the ID (Key ID or Key ARN) of the KMS symmetric
    #   encryption customer managed key to use. Otherwise, you get an HTTP
    #   `400 Bad Request` error. Only use the key ID or key ARN. The key
    #   alias format of the KMS key isn't supported. Also, if the KMS key
    #   doesn't exist in the same account that't issuing the command, you
    #   must use the full Key ARN not the Key ID.
    #
    #   Your SSE-KMS configuration can only support 1 [customer managed
    #   key][1] per directory bucket's lifetime. The [Amazon Web Services
    #   managed key][2] (`aws/s3`) isn't supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context as an
    #   additional encryption context to use for object encryption. The
    #   value of this header is a Base64 encoded string of a UTF-8 encoded
    #   JSON, which contains the encryption context as key-value pairs. This
    #   value is stored as object metadata and automatically gets passed on
    #   to Amazon Web Services KMS for future `GetObject` operations on this
    #   object.
    #
    #   **General purpose buckets** - This value must be explicitly added
    #   during `CopyObject` operations if you want an additional encryption
    #   context for your object. For more information, see [Encryption
    #   context][1] in the *Amazon S3 User Guide*.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default
    #   encryption context - the bucket Amazon Resource Name (ARN). An
    #   additional encryption context value is not supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html#encryption-context
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using KMS keys (SSE-KMS).
    #
    #   S3 Bucket Keys are always enabled for `GET` and `PUT` operations in
    #   a directory bucket and can’t be disabled. S3 Bucket Keys aren't
    #   supported, when you copy SSE-KMS encrypted objects from general
    #   purpose buckets to directory buckets, from directory buckets to
    #   general purpose buckets, or between directory buckets, through
    #   [CopyObject][1], [UploadPartCopy][2], [the Copy operation in Batch
    #   Operations][3], or [the import jobs][4]. In this case, Amazon S3
    #   makes a call to KMS every time a copy request is made for a
    #   KMS-encrypted object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateSessionRequest AWS API Documentation
    #
    class CreateSessionRequest < Struct.new(
      :session_mode,
      :bucket,
      :server_side_encryption,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # The container element for optionally specifying the default Object
    # Lock retention settings for new objects placed in the specified
    # bucket.
    #
    # <note markdown="1"> * The `DefaultRetention` settings require both a mode and a period.
    #
    # * The `DefaultRetention` period can be either `Days` or `Years` but
    #   you must select one. You cannot specify `Days` and `Years` at the
    #   same time.
    #
    #  </note>
    #
    # @!attribute [rw] mode
    #   The default Object Lock retention mode you want to apply to new
    #   objects placed in the specified bucket. Must be used with either
    #   `Days` or `Years`.
    #   @return [String]
    #
    # @!attribute [rw] days
    #   The number of days that you want to specify for the default
    #   retention period. Must be used with `Mode`.
    #   @return [Integer]
    #
    # @!attribute [rw] years
    #   The number of years that you want to specify for the default
    #   retention period. Must be used with `Mode`.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DefaultRetention AWS API Documentation
    #
    class DefaultRetention < Struct.new(
      :mode,
      :days,
      :years)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the objects to delete.
    #
    # @!attribute [rw] objects
    #   The object to delete.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, an object that's
    #   composed entirely of whitespace characters is not supported by the
    #   `DeleteObjects` API operation. The request will receive a `400 Bad
    #   Request` error and none of the objects in the request will be
    #   deleted.
    #
    #    </note>
    #   @return [Array<Types::ObjectIdentifier>]
    #
    # @!attribute [rw] quiet
    #   Element to enable quiet mode for the request. When you add this
    #   element, you must set its value to `true`.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Delete AWS API Documentation
    #
    class Delete < Struct.new(
      :objects,
      :quiet)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket from which an analytics configuration is
    #   deleted.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class DeleteBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Specifies the bucket whose `cors` configuration is being deleted.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketCorsRequest AWS API Documentation
    #
    class DeleteBucketCorsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the server-side encryption
    #   configuration to delete.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketEncryptionRequest AWS API Documentation
    #
    class DeleteBucketEncryptionRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketIntelligentTieringConfigurationRequest AWS API Documentation
    #
    class DeleteBucketIntelligentTieringConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configuration to
    #   delete.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketInventoryConfigurationRequest AWS API Documentation
    #
    class DeleteBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name of the lifecycle to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketLifecycleRequest AWS API Documentation
    #
    class DeleteBucketLifecycleRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that you want to remove the metadata
    #   configuration from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected bucket owner of the general purpose bucket that you
    #   want to remove the metadata table configuration from.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketMetadataConfigurationRequest AWS API Documentation
    #
    class DeleteBucketMetadataConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that you want to remove the metadata
    #   table configuration from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected bucket owner of the general purpose bucket that you
    #   want to remove the metadata table configuration from.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketMetadataTableConfigurationRequest AWS API Documentation
    #
    class DeleteBucketMetadataTableConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configuration to
    #   delete.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketMetricsConfigurationRequest AWS API Documentation
    #
    class DeleteBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The Amazon S3 bucket whose `OwnershipControls` you want to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketOwnershipControlsRequest AWS API Documentation
    #
    class DeleteBucketOwnershipControlsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketPolicyRequest AWS API Documentation
    #
    class DeleteBucketPolicyRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketReplicationRequest AWS API Documentation
    #
    class DeleteBucketReplicationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Specifies the bucket being deleted.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketRequest AWS API Documentation
    #
    class DeleteBucketRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket that has the tag set to be removed.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketTaggingRequest AWS API Documentation
    #
    class DeleteBucketTaggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name for which you want to remove the website
    #   configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketWebsiteRequest AWS API Documentation
    #
    class DeleteBucketWebsiteRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Information about the delete marker.
    #
    # @!attribute [rw] owner
    #   The account that created the delete marker.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of an object.
    #   @return [String]
    #
    # @!attribute [rw] is_latest
    #   Specifies whether the object is (true) or is not (false) the latest
    #   version of an object.
    #   @return [Boolean]
    #
    # @!attribute [rw] last_modified
    #   Date and time when the object was last modified.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteMarkerEntry AWS API Documentation
    #
    class DeleteMarkerEntry < Struct.new(
      :owner,
      :key,
      :version_id,
      :is_latest,
      :last_modified)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies whether Amazon S3 replicates delete markers. If you specify
    # a `Filter` in your replication configuration, you must also include a
    # `DeleteMarkerReplication` element. If your `Filter` includes a `Tag`
    # element, the `DeleteMarkerReplication` `Status` must be set to
    # Disabled, because Amazon S3 does not support replicating delete
    # markers for tag-based rules. For an example configuration, see [Basic
    # Rule Configuration][1].
    #
    # For more information about delete marker replication, see [Basic Rule
    # Configuration][2].
    #
    # <note markdown="1"> If you are using an earlier version of the replication configuration,
    # Amazon S3 handles replication of delete markers differently. For more
    # information, see [Backward Compatibility][3].
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-config-min-rule-config
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/delete-marker-replication.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations
    #
    # @!attribute [rw] status
    #   Indicates whether to replicate delete markers.
    #
    #   <note markdown="1"> Indicates whether to replicate delete markers.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteMarkerReplication AWS API Documentation
    #
    class DeleteMarkerReplication < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] delete_marker
    #   Indicates whether the specified object version that was permanently
    #   deleted was (true) or was not (false) a delete marker before
    #   deletion. In a simple DELETE, this header indicates whether (true)
    #   or not (false) the current version of the object is a delete marker.
    #   To learn more about delete markers, see [Working with delete
    #   markers][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html
    #   @return [Boolean]
    #
    # @!attribute [rw] version_id
    #   Returns the version ID of the delete marker created as a result of
    #   the DELETE operation.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectOutput AWS API Documentation
    #
    class DeleteObjectOutput < Struct.new(
      :delete_marker,
      :version_id,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name of the bucket containing the object.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key name of the object to delete.
    #   @return [String]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device. Required to permanently delete a versioned object if
    #   versioning is configured with MFA delete enabled.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> For directory buckets in this API operation, only the `null` value
    #   of the version ID is supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Indicates whether S3 Object Lock should bypass Governance-mode
    #   restrictions to process this operation. To use this header, you must
    #   have the `s3:BypassGovernanceRetention` permission.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Deletes the object if the ETag (entity tag) value provided during
    #   the delete operation matches the ETag of the object in S3. If the
    #   ETag values do not match, the operation returns a `412 Precondition
    #   Failed` error.
    #
    #   Expects the ETag value as a string. `If-Match` does accept a string
    #   value of an '*' (asterisk) character to denote a match of any
    #   ETag.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   @return [String]
    #
    # @!attribute [rw] if_match_last_modified_time
    #   If present, the object is deleted only if its modification times
    #   matches the provided `Timestamp`. If the `Timestamp` values do not
    #   match, the operation returns a `412 Precondition Failed` error. If
    #   the `Timestamp` matches or if the object doesn’t exist, the
    #   operation returns a `204 Success (No Content)` response.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] if_match_size
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
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectRequest AWS API Documentation
    #
    class DeleteObjectRequest < Struct.new(
      :bucket,
      :key,
      :mfa,
      :version_id,
      :request_payer,
      :bypass_governance_retention,
      :expected_bucket_owner,
      :if_match,
      :if_match_last_modified_time,
      :if_match_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object the tag-set was removed from.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectTaggingOutput AWS API Documentation
    #
    class DeleteObjectTaggingOutput < Struct.new(
      :version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the objects from which to remove the
    #   tags.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key that identifies the object in the bucket from which to
    #   remove all tags.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object that the tag-set will be removed from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectTaggingRequest AWS API Documentation
    #
    class DeleteObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] deleted
    #   Container element for a successful delete. It identifies the object
    #   that was successfully deleted.
    #   @return [Array<Types::DeletedObject>]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] errors
    #   Container for a failed delete action that describes the object that
    #   Amazon S3 attempted to delete and the error it encountered.
    #   @return [Array<Types::Error>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectsOutput AWS API Documentation
    #
    class DeleteObjectsOutput < Struct.new(
      :deleted,
      :request_charged,
      :errors)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the objects to delete.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] delete
    #   Container for the request.
    #   @return [Types::Delete]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device. Required to permanently delete a versioned object if
    #   versioning is configured with MFA delete enabled.
    #
    #   When performing the `DeleteObjects` operation on an MFA delete
    #   enabled bucket, which attempts to delete the specified versioned
    #   objects, you must include an MFA token. If you don't provide an MFA
    #   token, the entire request will fail, even if there are non-versioned
    #   objects that you are trying to delete. If you provide an invalid
    #   token, whether there are versioned object keys in the request or
    #   not, the entire Multi-Object Delete request will fail. For
    #   information about MFA Delete, see [ MFA Delete][1] in the *Amazon S3
    #   User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html#MultiFactorAuthenticationDelete
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Specifies whether you want to delete this object even if it has a
    #   Governance-type Object Lock in place. To use this header, you must
    #   have the `s3:BypassGovernanceRetention` permission.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum-algorithm ` or
    #   `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the request
    #   with the HTTP status code `400 Bad Request`.
    #
    #   For the `x-amz-checksum-algorithm ` header, replace ` algorithm `
    #   with the supported algorithm from the following list:
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
    #   `x-amz-checksum-algorithm ` doesn't match the checksum algorithm
    #   you set through `x-amz-sdk-checksum-algorithm`, Amazon S3 fails the
    #   request with a `BadDigest` error.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectsRequest AWS API Documentation
    #
    class DeleteObjectsRequest < Struct.new(
      :bucket,
      :delete,
      :mfa,
      :request_payer,
      :bypass_governance_retention,
      :expected_bucket_owner,
      :checksum_algorithm)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The Amazon S3 bucket whose `PublicAccessBlock` configuration you
    #   want to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeletePublicAccessBlockRequest AWS API Documentation
    #
    class DeletePublicAccessBlockRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Information about the deleted object.
    #
    # @!attribute [rw] key
    #   The name of the deleted object.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the deleted object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] delete_marker
    #   Indicates whether the specified object version that was permanently
    #   deleted was (true) or was not (false) a delete marker before
    #   deletion. In a simple DELETE, this header indicates whether (true)
    #   or not (false) the current version of the object is a delete marker.
    #   To learn more about delete markers, see [Working with delete
    #   markers][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html
    #   @return [Boolean]
    #
    # @!attribute [rw] delete_marker_version_id
    #   The version ID of the delete marker created as a result of the
    #   DELETE operation. If you delete a specific object version, the value
    #   returned by this header is the version ID of the object version
    #   deleted.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeletedObject AWS API Documentation
    #
    class DeletedObject < Struct.new(
      :key,
      :version_id,
      :delete_marker,
      :delete_marker_version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies information about where to publish analysis or configuration
    # results for an Amazon S3 bucket and S3 Replication Time Control (S3
    # RTC).
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket where you want Amazon
    #   S3 to store the results.
    #   @return [String]
    #
    # @!attribute [rw] account
    #   Destination bucket owner account ID. In a cross-account scenario, if
    #   you direct Amazon S3 to change replica ownership to the Amazon Web
    #   Services account that owns the destination bucket by specifying the
    #   `AccessControlTranslation` property, this is the account ID of the
    #   destination bucket owner. For more information, see [Replication
    #   Additional Configuration: Changing the Replica Owner][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-change-owner.html
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   The storage class to use when replicating objects, such as S3
    #   Standard or reduced redundancy. By default, Amazon S3 uses the
    #   storage class of the source object to create the object replica.
    #
    #   For valid values, see the `StorageClass` element of the [PUT Bucket
    #   replication][1] action in the *Amazon S3 API Reference*.
    #
    #   `FSX_OPENZFS` is not an accepted value when replicating objects.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTreplication.html
    #   @return [String]
    #
    # @!attribute [rw] access_control_translation
    #   Specify this only in a cross-account scenario (where source and
    #   destination bucket owners are not the same), and you want to change
    #   replica ownership to the Amazon Web Services account that owns the
    #   destination bucket. If this is not specified in the replication
    #   configuration, the replicas are owned by same Amazon Web Services
    #   account that owns the source object.
    #   @return [Types::AccessControlTranslation]
    #
    # @!attribute [rw] encryption_configuration
    #   A container that provides information about encryption. If
    #   `SourceSelectionCriteria` is specified, you must specify this
    #   element.
    #   @return [Types::EncryptionConfiguration]
    #
    # @!attribute [rw] replication_time
    #   A container specifying S3 Replication Time Control (S3 RTC),
    #   including whether S3 RTC is enabled and the time when all objects
    #   and operations on objects must be replicated. Must be specified
    #   together with a `Metrics` block.
    #   @return [Types::ReplicationTime]
    #
    # @!attribute [rw] metrics
    #   A container specifying replication metrics-related settings enabling
    #   replication metrics and events.
    #   @return [Types::Metrics]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Destination AWS API Documentation
    #
    class Destination < Struct.new(
      :bucket,
      :account,
      :storage_class,
      :access_control_translation,
      :encryption_configuration,
      :replication_time,
      :metrics)
      SENSITIVE = []
      include Aws::Structure
    end

    # The destination information for the S3 Metadata configuration.
    #
    # @!attribute [rw] table_bucket_type
    #   The type of the table bucket where the metadata configuration is
    #   stored. The `aws` value indicates an Amazon Web Services managed
    #   table bucket, and the `customer` value indicates a customer-managed
    #   table bucket. V2 metadata configurations are stored in Amazon Web
    #   Services managed table buckets, and V1 metadata configurations are
    #   stored in customer-managed table buckets.
    #   @return [String]
    #
    # @!attribute [rw] table_bucket_arn
    #   The Amazon Resource Name (ARN) of the table bucket where the
    #   metadata configuration is stored.
    #   @return [String]
    #
    # @!attribute [rw] table_namespace
    #   The namespace in the table bucket where the metadata tables for a
    #   metadata configuration are stored.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DestinationResult AWS API Documentation
    #
    class DestinationResult < Struct.new(
      :table_bucket_type,
      :table_bucket_arn,
      :table_namespace)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the type of server-side encryption used.
    #
    # @!attribute [rw] encryption_type
    #   The server-side encryption algorithm used when storing job results
    #   in Amazon S3 (for example, AES256, `aws:kms`).
    #   @return [String]
    #
    # @!attribute [rw] kms_key_id
    #   If the encryption type is `aws:kms`, this optional value specifies
    #   the ID of the symmetric encryption customer managed key to use for
    #   encryption of job results. Amazon S3 only supports symmetric
    #   encryption KMS keys. For more information, see [Asymmetric keys in
    #   KMS][1] in the *Amazon Web Services Key Management Service Developer
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @!attribute [rw] kms_context
    #   If the encryption type is `aws:kms`, this optional value can be used
    #   to specify the encryption context for the restore results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Encryption AWS API Documentation
    #
    class Encryption < Struct.new(
      :encryption_type,
      :kms_key_id,
      :kms_context)
      SENSITIVE = [:kms_key_id]
      include Aws::Structure
    end

    # Specifies encryption-related information for an Amazon S3 bucket that
    # is a destination for replicated objects.
    #
    # <note markdown="1"> If you're specifying a customer managed KMS key, we recommend using a
    # fully qualified KMS key ARN. If you use a KMS key alias instead, then
    # KMS resolves the key within the requester’s account. This behavior can
    # result in data that's encrypted with a KMS key that belongs to the
    # requester, and not the bucket owner.
    #
    #  </note>
    #
    # @!attribute [rw] replica_kms_key_id
    #   Specifies the ID (Key ARN or Alias ARN) of the customer managed
    #   Amazon Web Services KMS key stored in Amazon Web Services Key
    #   Management Service (KMS) for the destination bucket. Amazon S3 uses
    #   this key to encrypt replica objects. Amazon S3 only supports
    #   symmetric encryption KMS keys. For more information, see [Asymmetric
    #   keys in Amazon Web Services KMS][1] in the *Amazon Web Services Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EncryptionConfiguration AWS API Documentation
    #
    class EncryptionConfiguration < Struct.new(
      :replica_kms_key_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # The existing object was created with a different encryption type.
    # Subsequent write requests must include the appropriate encryption
    # parameters in the request or while creating the session.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EncryptionTypeMismatch AWS API Documentation
    #
    class EncryptionTypeMismatch < Aws::EmptyStructure; end

    # A message that indicates the request is complete and no more messages
    # will be sent. You should not assume that the request is complete until
    # the client receives an `EndEvent`.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EndEvent AWS API Documentation
    #
    class EndEvent < Struct.new(
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all error elements.
    #
    # @!attribute [rw] key
    #   The error key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] code
    #   The error code is a string that uniquely identifies an error
    #   condition. It is meant to be read and understood by programs that
    #   detect and handle errors by type. The following is a list of Amazon
    #   S3 error codes. For more information, see [Error responses][1].
    #
    #   * * *Code:* AccessDenied
    #
    #     * *Description:* Access Denied
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* AccountProblem
    #
    #     * *Description:* There is a problem with your Amazon Web Services
    #       account that prevents the action from completing successfully.
    #       Contact Amazon Web Services Support for further assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* AllAccessDisabled
    #
    #     * *Description:* All access to this Amazon S3 resource has been
    #       disabled. Contact Amazon Web Services Support for further
    #       assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* AmbiguousGrantByEmailAddress
    #
    #     * *Description:* The email address you provided is associated with
    #       more than one account.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* AuthorizationHeaderMalformed
    #
    #     * *Description:* The authorization header you provided is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *HTTP Status Code:* N/A
    #   * * *Code:* BadDigest
    #
    #     * *Description:* The Content-MD5 you specified did not match what
    #       we received.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* BucketAlreadyExists
    #
    #     * *Description:* The requested bucket name is not available. The
    #       bucket namespace is shared by all users of the system. Please
    #       select a different name and try again.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* BucketAlreadyOwnedByYou
    #
    #     * *Description:* The bucket you tried to create already exists,
    #       and you own it. Amazon S3 returns this error in all Amazon Web
    #       Services Regions except in the North Virginia Region. For legacy
    #       compatibility, if you re-create an existing bucket that you
    #       already own in the North Virginia Region, Amazon S3 returns 200
    #       OK and resets the bucket access control lists (ACLs).
    #
    #     * *Code:* 409 Conflict (in all Regions except the North Virginia
    #       Region)
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* BucketNotEmpty
    #
    #     * *Description:* The bucket you tried to delete is not empty.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* CredentialsNotSupported
    #
    #     * *Description:* This request does not support credentials.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* CrossLocationLoggingProhibited
    #
    #     * *Description:* Cross-location logging not allowed. Buckets in
    #       one geographic location cannot log information to a bucket in
    #       another location.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* EntityTooSmall
    #
    #     * *Description:* Your proposed upload is smaller than the minimum
    #       allowed object size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* EntityTooLarge
    #
    #     * *Description:* Your proposed upload exceeds the maximum allowed
    #       object size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* ExpiredToken
    #
    #     * *Description:* The provided token has expired.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* IllegalVersioningConfigurationException
    #
    #     * *Description:* Indicates that the versioning configuration
    #       specified in the request is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* IncompleteBody
    #
    #     * *Description:* You did not provide the number of bytes specified
    #       by the Content-Length HTTP header
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* IncorrectNumberOfFilesInPostRequest
    #
    #     * *Description:* POST requires exactly one file upload per
    #       request.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InlineDataTooLarge
    #
    #     * *Description:* Inline data exceeds the maximum allowed size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InternalError
    #
    #     * *Description:* We encountered an internal error. Please try
    #       again.
    #
    #     * *HTTP Status Code:* 500 Internal Server Error
    #
    #     * *SOAP Fault Code Prefix:* Server
    #   * * *Code:* InvalidAccessKeyId
    #
    #     * *Description:* The Amazon Web Services access key ID you
    #       provided does not exist in our records.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidAddressingHeader
    #
    #     * *Description:* You must specify the Anonymous role.
    #
    #     * *HTTP Status Code:* N/A
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidArgument
    #
    #     * *Description:* Invalid Argument
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidBucketName
    #
    #     * *Description:* The specified bucket is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidBucketState
    #
    #     * *Description:* The request is not valid with the current state
    #       of the bucket.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidDigest
    #
    #     * *Description:* The Content-MD5 you specified is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidEncryptionAlgorithmError
    #
    #     * *Description:* The encryption request you specified is not
    #       valid. The valid value is AES256.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidLocationConstraint
    #
    #     * *Description:* The specified location constraint is not valid.
    #       For more information about Regions, see [How to Select a Region
    #       for Your Buckets][2].
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidObjectState
    #
    #     * *Description:* The action is not valid for the current state of
    #       the object.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidPart
    #
    #     * *Description:* One or more of the specified parts could not be
    #       found. The part might not have been uploaded, or the specified
    #       entity tag might not have matched the part's entity tag.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidPartOrder
    #
    #     * *Description:* The list of parts was not in ascending order.
    #       Parts list must be specified in order by part number.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidPayer
    #
    #     * *Description:* All access to this object has been disabled.
    #       Please contact Amazon Web Services Support for further
    #       assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidPolicyDocument
    #
    #     * *Description:* The content of the form does not meet the
    #       conditions specified in the policy document.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidRange
    #
    #     * *Description:* The requested range cannot be satisfied.
    #
    #     * *HTTP Status Code:* 416 Requested Range Not Satisfiable
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Please use `AWS4-HMAC-SHA256`.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* SOAP requests must be made over an HTTPS
    #       connection.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       for buckets with non-DNS compliant names.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       for buckets with periods (.) in their names.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate endpoint only
    #       supports virtual style requests.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate is not configured
    #       on this bucket.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate is disabled on this
    #       bucket.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       on this bucket. Contact Amazon Web Services Support for more
    #       information.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration cannot be enabled
    #       on this bucket. Contact Amazon Web Services Support for more
    #       information.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #   * * *Code:* InvalidSecurity
    #
    #     * *Description:* The provided security credentials are not valid.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidSOAPRequest
    #
    #     * *Description:* The SOAP request body is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidStorageClass
    #
    #     * *Description:* The storage class you specified is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidTargetBucketForLogging
    #
    #     * *Description:* The target bucket for logging does not exist, is
    #       not owned by you, or does not have the appropriate grants for
    #       the log-delivery group.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidToken
    #
    #     * *Description:* The provided token is malformed or otherwise
    #       invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* InvalidURI
    #
    #     * *Description:* Couldn't parse the specified URI.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* KeyTooLongError
    #
    #     * *Description:* Your key is too long.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MalformedACLError
    #
    #     * *Description:* The XML you provided was not well-formed or did
    #       not validate against our published schema.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MalformedPOSTRequest
    #
    #     * *Description:* The body of your POST request is not well-formed
    #       multipart/form-data.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MalformedXML
    #
    #     * *Description:* This happens when the user sends malformed XML
    #       (XML that doesn't conform to the published XSD) for the
    #       configuration. The error message is, "The XML you provided was
    #       not well-formed or did not validate against our published
    #       schema."
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MaxMessageLengthExceeded
    #
    #     * *Description:* Your request was too big.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MaxPostPreDataLengthExceededError
    #
    #     * *Description:* Your POST request fields preceding the upload
    #       file were too large.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MetadataTooLarge
    #
    #     * *Description:* Your metadata headers exceed the maximum allowed
    #       metadata size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MethodNotAllowed
    #
    #     * *Description:* The specified method is not allowed against this
    #       resource.
    #
    #     * *HTTP Status Code:* 405 Method Not Allowed
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MissingAttachment
    #
    #     * *Description:* A SOAP attachment was expected, but none were
    #       found.
    #
    #     * *HTTP Status Code:* N/A
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MissingContentLength
    #
    #     * *Description:* You must provide the Content-Length HTTP header.
    #
    #     * *HTTP Status Code:* 411 Length Required
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MissingRequestBodyError
    #
    #     * *Description:* This happens when the user sends an empty XML
    #       document as a request. The error message is, "Request body is
    #       empty."
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MissingSecurityElement
    #
    #     * *Description:* The SOAP 1.1 request is missing a security
    #       element.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* MissingSecurityHeader
    #
    #     * *Description:* Your request is missing a required header.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoLoggingStatusForKey
    #
    #     * *Description:* There is no such thing as a logging status
    #       subresource for a key.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchBucket
    #
    #     * *Description:* The specified bucket does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchBucketPolicy
    #
    #     * *Description:* The specified bucket does not have a bucket
    #       policy.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchKey
    #
    #     * *Description:* The specified key does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchLifecycleConfiguration
    #
    #     * *Description:* The lifecycle configuration does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchUpload
    #
    #     * *Description:* The specified multipart upload does not exist.
    #       The upload ID might be invalid, or the multipart upload might
    #       have been aborted or completed.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NoSuchVersion
    #
    #     * *Description:* Indicates that the version ID specified in the
    #       request does not match an existing version.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* NotImplemented
    #
    #     * *Description:* A header you provided implies functionality that
    #       is not implemented.
    #
    #     * *HTTP Status Code:* 501 Not Implemented
    #
    #     * *SOAP Fault Code Prefix:* Server
    #   * * *Code:* NotSignedUp
    #
    #     * *Description:* Your account is not signed up for the Amazon S3
    #       service. You must sign up before you can use Amazon S3. You can
    #       sign up at the following URL: [Amazon S3][3]
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* OperationAborted
    #
    #     * *Description:* A conflicting conditional action is currently in
    #       progress against this resource. Try again.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* PermanentRedirect
    #
    #     * *Description:* The bucket you are attempting to access must be
    #       addressed using the specified endpoint. Send all future requests
    #       to this endpoint.
    #
    #     * *HTTP Status Code:* 301 Moved Permanently
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* PreconditionFailed
    #
    #     * *Description:* At least one of the preconditions you specified
    #       did not hold.
    #
    #     * *HTTP Status Code:* 412 Precondition Failed
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* Redirect
    #
    #     * *Description:* Temporary redirect.
    #
    #     * *HTTP Status Code:* 307 Moved Temporarily
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* RestoreAlreadyInProgress
    #
    #     * *Description:* Object restore is already in progress.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* RequestIsNotMultiPartContent
    #
    #     * *Description:* Bucket POST must be of the enclosure-type
    #       multipart/form-data.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* RequestTimeout
    #
    #     * *Description:* Your socket connection to the server was not read
    #       from or written to within the timeout period.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* RequestTimeTooSkewed
    #
    #     * *Description:* The difference between the request time and the
    #       server's time is too large.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* RequestTorrentOfBucketError
    #
    #     * *Description:* Requesting the torrent file of a bucket is not
    #       permitted.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* SignatureDoesNotMatch
    #
    #     * *Description:* The request signature we calculated does not
    #       match the signature you provided. Check your Amazon Web Services
    #       secret access key and signing method. For more information, see
    #       [REST Authentication][4] and [SOAP Authentication][5] for
    #       details.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* ServiceUnavailable
    #
    #     * *Description:* Service is unable to handle request.
    #
    #     * *HTTP Status Code:* 503 Service Unavailable
    #
    #     * *SOAP Fault Code Prefix:* Server
    #   * * *Code:* SlowDown
    #
    #     * *Description:* Reduce your request rate.
    #
    #     * *HTTP Status Code:* 503 Slow Down
    #
    #     * *SOAP Fault Code Prefix:* Server
    #   * * *Code:* TemporaryRedirect
    #
    #     * *Description:* You are being redirected to the bucket while DNS
    #       updates.
    #
    #     * *HTTP Status Code:* 307 Moved Temporarily
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* TokenRefreshRequired
    #
    #     * *Description:* The provided token must be refreshed.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* TooManyBuckets
    #
    #     * *Description:* You have attempted to create more buckets than
    #       allowed.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* UnexpectedContent
    #
    #     * *Description:* This request does not support content.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* UnresolvableGrantByEmailAddress
    #
    #     * *Description:* The email address you provided does not match any
    #       account on record.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #   * * *Code:* UserKeyMustBeSpecified
    #
    #     * *Description:* The bucket POST must contain the specified field
    #       name. If it is specified, check the order of the fields.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro
    #   [3]: http://aws.amazon.com/s3
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    #   [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/SOAPAuthentication.html
    #   @return [String]
    #
    # @!attribute [rw] message
    #   The error message contains a generic description of the error
    #   condition in English. It is intended for a human audience. Simple
    #   programs display the message directly to the end user if they
    #   encounter an error condition they don't know how or don't care to
    #   handle. Sophisticated programs with more exhaustive error handling
    #   and proper internationalization are more likely to ignore the error
    #   message.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Error AWS API Documentation
    #
    class Error < Struct.new(
      :key,
      :version_id,
      :code,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # If an S3 Metadata V1 `CreateBucketMetadataTableConfiguration` or V2
    # `CreateBucketMetadataConfiguration` request succeeds, but S3 Metadata
    # was unable to create the table, this structure contains the error code
    # and error message.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] error_code
    #   If the V1 `CreateBucketMetadataTableConfiguration` request succeeds,
    #   but S3 Metadata was unable to create the table, this structure
    #   contains the error code. The possible error codes and error messages
    #   are as follows:
    #
    #   * `AccessDeniedCreatingResources` - You don't have sufficient
    #     permissions to create the required resources. Make sure that you
    #     have `s3tables:CreateNamespace`, `s3tables:CreateTable`,
    #     `s3tables:GetTable` and `s3tables:PutTablePolicy` permissions, and
    #     then try again. To create a new metadata table, you must delete
    #     the metadata configuration for this bucket, and then create a new
    #     metadata configuration.
    #
    #   * `AccessDeniedWritingToTable` - Unable to write to the metadata
    #     table because of missing resource permissions. To fix the resource
    #     policy, Amazon S3 needs to create a new metadata table. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `DestinationTableNotFound` - The destination table doesn't exist.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `ServerInternalError` - An internal error has occurred. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `TableAlreadyExists` - The table that you specified already exists
    #     in the table bucket's namespace. Specify a different table name.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `TableBucketNotFound` - The table bucket that you specified
    #     doesn't exist in this Amazon Web Services Region and account.
    #     Create or choose a different table bucket. To create a new
    #     metadata table, you must delete the metadata configuration for
    #     this bucket, and then create a new metadata configuration.
    #
    #   If the V2 `CreateBucketMetadataConfiguration` request succeeds, but
    #   S3 Metadata was unable to create the table, this structure contains
    #   the error code. The possible error codes and error messages are as
    #   follows:
    #
    #   * `AccessDeniedCreatingResources` - You don't have sufficient
    #     permissions to create the required resources. Make sure that you
    #     have `s3tables:CreateTableBucket`, `s3tables:CreateNamespace`,
    #     `s3tables:CreateTable`, `s3tables:GetTable`,
    #     `s3tables:PutTablePolicy`, `kms:DescribeKey`, and
    #     `s3tables:PutTableEncryption` permissions. Additionally, ensure
    #     that the KMS key used to encrypt the table still exists, is active
    #     and has a resource policy granting access to the S3 service
    #     principals '`maintenance.s3tables.amazonaws.com`' and
    #     '`metadata.s3.amazonaws.com`'. To create a new metadata table,
    #     you must delete the metadata configuration for this bucket, and
    #     then create a new metadata configuration.
    #
    #   * `AccessDeniedWritingToTable` - Unable to write to the metadata
    #     table because of missing resource permissions. To fix the resource
    #     policy, Amazon S3 needs to create a new metadata table. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `DestinationTableNotFound` - The destination table doesn't exist.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `ServerInternalError` - An internal error has occurred. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `JournalTableAlreadyExists` - A journal table already exists in
    #     the Amazon Web Services managed table bucket's namespace. Delete
    #     the journal table, and then try again. To create a new metadata
    #     table, you must delete the metadata configuration for this bucket,
    #     and then create a new metadata configuration.
    #
    #   * `InventoryTableAlreadyExists` - An inventory table already exists
    #     in the Amazon Web Services managed table bucket's namespace.
    #     Delete the inventory table, and then try again. To create a new
    #     metadata table, you must delete the metadata configuration for
    #     this bucket, and then create a new metadata configuration.
    #
    #   * `JournalTableNotAvailable` - The journal table that the inventory
    #     table relies on has a `FAILED` status. An inventory table requires
    #     a journal table with an `ACTIVE` status. To create a new journal
    #     or inventory table, you must delete the metadata configuration for
    #     this bucket, along with any journal or inventory tables, and then
    #     create a new metadata configuration.
    #
    #   * `NoSuchBucket` - The specified general purpose bucket does not
    #     exist.
    #   @return [String]
    #
    # @!attribute [rw] error_message
    #   If the V1 `CreateBucketMetadataTableConfiguration` request succeeds,
    #   but S3 Metadata was unable to create the table, this structure
    #   contains the error message. The possible error codes and error
    #   messages are as follows:
    #
    #   * `AccessDeniedCreatingResources` - You don't have sufficient
    #     permissions to create the required resources. Make sure that you
    #     have `s3tables:CreateNamespace`, `s3tables:CreateTable`,
    #     `s3tables:GetTable` and `s3tables:PutTablePolicy` permissions, and
    #     then try again. To create a new metadata table, you must delete
    #     the metadata configuration for this bucket, and then create a new
    #     metadata configuration.
    #
    #   * `AccessDeniedWritingToTable` - Unable to write to the metadata
    #     table because of missing resource permissions. To fix the resource
    #     policy, Amazon S3 needs to create a new metadata table. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `DestinationTableNotFound` - The destination table doesn't exist.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `ServerInternalError` - An internal error has occurred. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `TableAlreadyExists` - The table that you specified already exists
    #     in the table bucket's namespace. Specify a different table name.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `TableBucketNotFound` - The table bucket that you specified
    #     doesn't exist in this Amazon Web Services Region and account.
    #     Create or choose a different table bucket. To create a new
    #     metadata table, you must delete the metadata configuration for
    #     this bucket, and then create a new metadata configuration.
    #
    #   If the V2 `CreateBucketMetadataConfiguration` request succeeds, but
    #   S3 Metadata was unable to create the table, this structure contains
    #   the error code. The possible error codes and error messages are as
    #   follows:
    #
    #   * `AccessDeniedCreatingResources` - You don't have sufficient
    #     permissions to create the required resources. Make sure that you
    #     have `s3tables:CreateTableBucket`, `s3tables:CreateNamespace`,
    #     `s3tables:CreateTable`, `s3tables:GetTable`,
    #     `s3tables:PutTablePolicy`, `kms:DescribeKey`, and
    #     `s3tables:PutTableEncryption` permissions. Additionally, ensure
    #     that the KMS key used to encrypt the table still exists, is active
    #     and has a resource policy granting access to the S3 service
    #     principals '`maintenance.s3tables.amazonaws.com`' and
    #     '`metadata.s3.amazonaws.com`'. To create a new metadata table,
    #     you must delete the metadata configuration for this bucket, and
    #     then create a new metadata configuration.
    #
    #   * `AccessDeniedWritingToTable` - Unable to write to the metadata
    #     table because of missing resource permissions. To fix the resource
    #     policy, Amazon S3 needs to create a new metadata table. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `DestinationTableNotFound` - The destination table doesn't exist.
    #     To create a new metadata table, you must delete the metadata
    #     configuration for this bucket, and then create a new metadata
    #     configuration.
    #
    #   * `ServerInternalError` - An internal error has occurred. To create
    #     a new metadata table, you must delete the metadata configuration
    #     for this bucket, and then create a new metadata configuration.
    #
    #   * `JournalTableAlreadyExists` - A journal table already exists in
    #     the Amazon Web Services managed table bucket's namespace. Delete
    #     the journal table, and then try again. To create a new metadata
    #     table, you must delete the metadata configuration for this bucket,
    #     and then create a new metadata configuration.
    #
    #   * `InventoryTableAlreadyExists` - An inventory table already exists
    #     in the Amazon Web Services managed table bucket's namespace.
    #     Delete the inventory table, and then try again. To create a new
    #     metadata table, you must delete the metadata configuration for
    #     this bucket, and then create a new metadata configuration.
    #
    #   * `JournalTableNotAvailable` - The journal table that the inventory
    #     table relies on has a `FAILED` status. An inventory table requires
    #     a journal table with an `ACTIVE` status. To create a new journal
    #     or inventory table, you must delete the metadata configuration for
    #     this bucket, along with any journal or inventory tables, and then
    #     create a new metadata configuration.
    #
    #   * `NoSuchBucket` - The specified general purpose bucket does not
    #     exist.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ErrorDetails AWS API Documentation
    #
    class ErrorDetails < Struct.new(
      :error_code,
      :error_message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The error information.
    #
    # @!attribute [rw] key
    #   The object key name to use when a 4XX class error occurs.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ErrorDocument AWS API Documentation
    #
    class ErrorDocument < Struct.new(
      :key)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for Amazon EventBridge.
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EventBridgeConfiguration AWS API Documentation
    #
    class EventBridgeConfiguration < Aws::EmptyStructure; end

    # Optional configuration to replicate existing source bucket objects.
    #
    # <note markdown="1"> This parameter is no longer supported. To replicate existing objects,
    # see [Replicating existing objects with S3 Batch Replication][1] in the
    # *Amazon S3 User Guide*.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html
    #
    # @!attribute [rw] status
    #   Specifies whether Amazon S3 replicates existing source bucket
    #   objects.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ExistingObjectReplication AWS API Documentation
    #
    class ExistingObjectReplication < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the Amazon S3 object key name to filter on. An object key
    # name is the name assigned to an object in your Amazon S3 bucket. You
    # specify whether to filter on the suffix or prefix of the object key
    # name. A prefix is a specific string of characters at the beginning of
    # an object key name, which you can use to organize objects. For
    # example, you can start the key names of related objects with a prefix,
    # such as `2023-` or `engineering/`. Then, you can use `FilterRule` to
    # find objects in a bucket with key names that have the same prefix. A
    # suffix is similar to a prefix, but it is at the end of the object key
    # name instead of at the beginning.
    #
    # @!attribute [rw] name
    #   The object key name prefix or suffix identifying one or more objects
    #   to which the filtering rule applies. The maximum length is 1,024
    #   characters. Overlapping prefixes and suffixes are not supported. For
    #   more information, see [Configuring Event Notifications][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [String]
    #
    # @!attribute [rw] value
    #   The value that the filter searches for in object key names.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/FilterRule AWS API Documentation
    #
    class FilterRule < Struct.new(
      :name,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] abac_status
    #   The ABAC status of the general purpose bucket.
    #   @return [Types::AbacStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAbacOutput AWS API Documentation
    #
    class GetBucketAbacOutput < Struct.new(
      :abac_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the general purpose bucket.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The Amazon Web Services account ID of the general purpose bucket's
    #   owner.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAbacRequest AWS API Documentation
    #
    class GetBucketAbacRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] status
    #   The accelerate configuration of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAccelerateConfigurationOutput AWS API Documentation
    #
    class GetBucketAccelerateConfigurationOutput < Struct.new(
      :status,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which the accelerate configuration is
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAccelerateConfigurationRequest AWS API Documentation
    #
    class GetBucketAccelerateConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner,
      :request_payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] owner
    #   Container for the bucket owner's ID.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAclOutput AWS API Documentation
    #
    class GetBucketAclOutput < Struct.new(
      :owner,
      :grants)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Specifies the S3 bucket whose ACL is being requested.
    #
    #   When you use this API operation with an access point, provide the
    #   alias of the access point in place of the bucket name.
    #
    #   When you use this API operation with an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is
    #   returned. For more information about `InvalidAccessPointAliasError`,
    #   see [List of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAclRequest AWS API Documentation
    #
    class GetBucketAclRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] analytics_configuration
    #   The configuration and any analyses for the analytics filter.
    #   @return [Types::AnalyticsConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAnalyticsConfigurationOutput AWS API Documentation
    #
    class GetBucketAnalyticsConfigurationOutput < Struct.new(
      :analytics_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket from which an analytics configuration is
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class GetBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] cors_rules
    #   A set of origins and methods (cross-origin access that you want to
    #   allow). You can add up to 100 rules to the configuration.
    #   @return [Array<Types::CORSRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketCorsOutput AWS API Documentation
    #
    class GetBucketCorsOutput < Struct.new(
      :cors_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name for which to get the cors configuration.
    #
    #   When you use this API operation with an access point, provide the
    #   alias of the access point in place of the bucket name.
    #
    #   When you use this API operation with an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is
    #   returned. For more information about `InvalidAccessPointAliasError`,
    #   see [List of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketCorsRequest AWS API Documentation
    #
    class GetBucketCorsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] server_side_encryption_configuration
    #   Specifies the default server-side-encryption configuration.
    #   @return [Types::ServerSideEncryptionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketEncryptionOutput AWS API Documentation
    #
    class GetBucketEncryptionOutput < Struct.new(
      :server_side_encryption_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket from which the server-side encryption
    #   configuration is retrieved.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketEncryptionRequest AWS API Documentation
    #
    class GetBucketEncryptionRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] intelligent_tiering_configuration
    #   Container for S3 Intelligent-Tiering configuration.
    #   @return [Types::IntelligentTieringConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketIntelligentTieringConfigurationOutput AWS API Documentation
    #
    class GetBucketIntelligentTieringConfigurationOutput < Struct.new(
      :intelligent_tiering_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketIntelligentTieringConfigurationRequest AWS API Documentation
    #
    class GetBucketIntelligentTieringConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] inventory_configuration
    #   Specifies the inventory configuration.
    #   @return [Types::InventoryConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketInventoryConfigurationOutput AWS API Documentation
    #
    class GetBucketInventoryConfigurationOutput < Struct.new(
      :inventory_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configuration to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketInventoryConfigurationRequest AWS API Documentation
    #
    class GetBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] rules
    #   Container for a lifecycle rule.
    #   @return [Array<Types::LifecycleRule>]
    #
    # @!attribute [rw] transition_default_minimum_object_size
    #   Indicates which default minimum object size behavior is applied to
    #   the lifecycle configuration.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It isn't
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #
    #   * `all_storage_classes_128K` - Objects smaller than 128 KB will not
    #     transition to any storage class by default.
    #
    #   * `varies_by_storage_class` - Objects smaller than 128 KB will
    #     transition to Glacier Flexible Retrieval or Glacier Deep Archive
    #     storage classes. By default, all other storage classes will
    #     prevent transitions smaller than 128 KB.
    #
    #   To customize the minimum object size for any transition you can add
    #   a filter that specifies a custom `ObjectSizeGreaterThan` or
    #   `ObjectSizeLessThan` in the body of your transition rule. Custom
    #   filters always take precedence over the default transition behavior.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleConfigurationOutput AWS API Documentation
    #
    class GetBucketLifecycleConfigurationOutput < Struct.new(
      :rules,
      :transition_default_minimum_object_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the lifecycle information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleConfigurationRequest AWS API Documentation
    #
    class GetBucketLifecycleConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] rules
    #   Container for a lifecycle rule.
    #   @return [Array<Types::Rule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleOutput AWS API Documentation
    #
    class GetBucketLifecycleOutput < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the lifecycle information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleRequest AWS API Documentation
    #
    class GetBucketLifecycleRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location_constraint
    #   Specifies the Region where the bucket resides. For a list of all the
    #   Amazon S3 supported location constraints by Region, see [Regions and
    #   Endpoints][1].
    #
    #   Buckets in Region `us-east-1` have a LocationConstraint of `null`.
    #   Buckets with a LocationConstraint of `EU` reside in `eu-west-1`.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLocationOutput AWS API Documentation
    #
    class GetBucketLocationOutput < Struct.new(
      :location_constraint)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the location.
    #
    #   When you use this API operation with an access point, provide the
    #   alias of the access point in place of the bucket name.
    #
    #   When you use this API operation with an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is
    #   returned. For more information about `InvalidAccessPointAliasError`,
    #   see [List of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLocationRequest AWS API Documentation
    #
    class GetBucketLocationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] logging_enabled
    #   Describes where logs are stored and the prefix that Amazon S3
    #   assigns to all log object keys for a bucket. For more information,
    #   see [PUT Bucket logging][1] in the *Amazon S3 API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #   @return [Types::LoggingEnabled]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLoggingOutput AWS API Documentation
    #
    class GetBucketLoggingOutput < Struct.new(
      :logging_enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name for which to get the logging information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLoggingRequest AWS API Documentation
    #
    class GetBucketLoggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] get_bucket_metadata_configuration_result
    #   The metadata configuration for the general purpose bucket.
    #   @return [Types::GetBucketMetadataConfigurationResult]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataConfigurationOutput AWS API Documentation
    #
    class GetBucketMetadataConfigurationOutput < Struct.new(
      :get_bucket_metadata_configuration_result)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that corresponds to the metadata
    #   configuration that you want to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that you want to
    #   retrieve the metadata table configuration for.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataConfigurationRequest AWS API Documentation
    #
    class GetBucketMetadataConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # The S3 Metadata configuration for a general purpose bucket.
    #
    # @!attribute [rw] metadata_configuration_result
    #   The metadata configuration for a general purpose bucket.
    #   @return [Types::MetadataConfigurationResult]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataConfigurationResult AWS API Documentation
    #
    class GetBucketMetadataConfigurationResult < Struct.new(
      :metadata_configuration_result)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] get_bucket_metadata_table_configuration_result
    #   The metadata table configuration for the general purpose bucket.
    #   @return [Types::GetBucketMetadataTableConfigurationResult]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataTableConfigurationOutput AWS API Documentation
    #
    class GetBucketMetadataTableConfigurationOutput < Struct.new(
      :get_bucket_metadata_table_configuration_result)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that corresponds to the metadata table
    #   configuration that you want to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that you want to
    #   retrieve the metadata table configuration for.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataTableConfigurationRequest AWS API Documentation
    #
    class GetBucketMetadataTableConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # The V1 S3 Metadata configuration for a general purpose bucket.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] metadata_table_configuration_result
    #   The V1 S3 Metadata configuration for a general purpose bucket.
    #   @return [Types::MetadataTableConfigurationResult]
    #
    # @!attribute [rw] status
    #   The status of the metadata table. The status values are:
    #
    #   * `CREATING` - The metadata table is in the process of being created
    #     in the specified table bucket.
    #
    #   * `ACTIVE` - The metadata table has been created successfully, and
    #     records are being delivered to the table.
    #
    #   * `FAILED` - Amazon S3 is unable to create the metadata table, or
    #     Amazon S3 is unable to deliver records. See `ErrorDetails` for
    #     details.
    #   @return [String]
    #
    # @!attribute [rw] error
    #   If the `CreateBucketMetadataTableConfiguration` request succeeds,
    #   but S3 Metadata was unable to create the table, this structure
    #   contains the error code and error message.
    #   @return [Types::ErrorDetails]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetadataTableConfigurationResult AWS API Documentation
    #
    class GetBucketMetadataTableConfigurationResult < Struct.new(
      :metadata_table_configuration_result,
      :status,
      :error)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] metrics_configuration
    #   Specifies the metrics configuration.
    #   @return [Types::MetricsConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetricsConfigurationOutput AWS API Documentation
    #
    class GetBucketMetricsConfigurationOutput < Struct.new(
      :metrics_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configuration to
    #   retrieve.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetricsConfigurationRequest AWS API Documentation
    #
    class GetBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the notification
    #   configuration.
    #
    #   When you use this API operation with an access point, provide the
    #   alias of the access point in place of the bucket name.
    #
    #   When you use this API operation with an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is
    #   returned. For more information about `InvalidAccessPointAliasError`,
    #   see [List of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketNotificationConfigurationRequest AWS API Documentation
    #
    class GetBucketNotificationConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] ownership_controls
    #   The `OwnershipControls` (BucketOwnerEnforced, BucketOwnerPreferred,
    #   or ObjectWriter) currently in effect for this Amazon S3 bucket.
    #   @return [Types::OwnershipControls]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketOwnershipControlsOutput AWS API Documentation
    #
    class GetBucketOwnershipControlsOutput < Struct.new(
      :ownership_controls)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `OwnershipControls` you want
    #   to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketOwnershipControlsRequest AWS API Documentation
    #
    class GetBucketOwnershipControlsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] policy
    #   The bucket policy as a JSON document.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyOutput AWS API Documentation
    #
    class GetBucketPolicyOutput < Struct.new(
      :policy)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name to get the bucket policy for.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #   **Access points** - When you use this API operation with an access
    #   point, provide the alias of the access point in place of the bucket
    #   name.
    #
    #   **Object Lambda access points** - When you use this API operation
    #   with an Object Lambda access point, provide the alias of the Object
    #   Lambda access point in place of the bucket name. If the Object
    #   Lambda access point alias in a request is not valid, the error code
    #   `InvalidAccessPointAliasError` is returned. For more information
    #   about `InvalidAccessPointAliasError`, see [List of Error Codes][2].
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyRequest AWS API Documentation
    #
    class GetBucketPolicyRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] policy_status
    #   The policy status for the specified bucket.
    #   @return [Types::PolicyStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyStatusOutput AWS API Documentation
    #
    class GetBucketPolicyStatusOutput < Struct.new(
      :policy_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose policy status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyStatusRequest AWS API Documentation
    #
    class GetBucketPolicyStatusRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] replication_configuration
    #   A container for replication rules. You can add up to 1,000 rules.
    #   The maximum size of a replication configuration is 2 MB.
    #   @return [Types::ReplicationConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketReplicationOutput AWS API Documentation
    #
    class GetBucketReplicationOutput < Struct.new(
      :replication_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name for which to get the replication information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketReplicationRequest AWS API Documentation
    #
    class GetBucketReplicationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] payer
    #   Specifies who pays for the download and request fees.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketRequestPaymentOutput AWS API Documentation
    #
    class GetBucketRequestPaymentOutput < Struct.new(
      :payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the payment request
    #   configuration
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketRequestPaymentRequest AWS API Documentation
    #
    class GetBucketRequestPaymentRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] tag_set
    #   Contains the tag set.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketTaggingOutput AWS API Documentation
    #
    class GetBucketTaggingOutput < Struct.new(
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the tagging information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketTaggingRequest AWS API Documentation
    #
    class GetBucketTaggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] status
    #   The versioning state of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] mfa_delete
    #   Specifies whether MFA delete is enabled in the bucket versioning
    #   configuration. This element is only returned if the bucket has been
    #   configured with MFA delete. If the bucket has never been so
    #   configured, this element is not returned.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketVersioningOutput AWS API Documentation
    #
    class GetBucketVersioningOutput < Struct.new(
      :status,
      :mfa_delete)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the versioning information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketVersioningRequest AWS API Documentation
    #
    class GetBucketVersioningRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] redirect_all_requests_to
    #   Specifies the redirect behavior of all requests to a website
    #   endpoint of an Amazon S3 bucket.
    #   @return [Types::RedirectAllRequestsTo]
    #
    # @!attribute [rw] index_document
    #   The name of the index document for the website (for example
    #   `index.html`).
    #   @return [Types::IndexDocument]
    #
    # @!attribute [rw] error_document
    #   The object key name of the website error document to use for 4XX
    #   class errors.
    #   @return [Types::ErrorDocument]
    #
    # @!attribute [rw] routing_rules
    #   Rules that define when a redirect is applied and the redirect
    #   behavior.
    #   @return [Array<Types::RoutingRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketWebsiteOutput AWS API Documentation
    #
    class GetBucketWebsiteOutput < Struct.new(
      :redirect_all_requests_to,
      :index_document,
      :error_document,
      :routing_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name for which to get the website configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketWebsiteRequest AWS API Documentation
    #
    class GetBucketWebsiteRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] owner
    #   Container for the bucket owner's ID.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAclOutput AWS API Documentation
    #
    class GetObjectAclOutput < Struct.new(
      :owner,
      :grants,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name that contains the object for which to get the ACL
    #   information.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key of the object for which to get the ACL information.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAclRequest AWS API Documentation
    #
    class GetObjectAclRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] delete_marker
    #   Specifies whether the object retrieved was (`true`) or was not
    #   (`false`) a delete marker. If `false`, this response header does not
    #   appear in the response. To learn more about delete markers, see
    #   [Working with delete markers][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html
    #   @return [Boolean]
    #
    # @!attribute [rw] last_modified
    #   Date and time when the object was last modified.
    #   @return [Time]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   An ETag is an opaque identifier assigned by a web server to a
    #   specific version of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] checksum
    #   The checksum or digest of the object.
    #   @return [Types::Checksum]
    #
    # @!attribute [rw] object_parts
    #   A collection of parts associated with a multipart upload.
    #   @return [Types::GetObjectAttributesParts]
    #
    # @!attribute [rw] storage_class
    #   Provides the storage class information of the object. Amazon S3
    #   returns this header for all objects except for S3 Standard storage
    #   class objects.
    #
    #   For more information, see [Storage Classes][1].
    #
    #   <note markdown="1"> **Directory buckets** - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] object_size
    #   The size of the object in bytes.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAttributesOutput AWS API Documentation
    #
    class GetObjectAttributesOutput < Struct.new(
      :delete_marker,
      :last_modified,
      :version_id,
      :request_charged,
      :etag,
      :checksum,
      :object_parts,
      :storage_class,
      :object_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # A collection of parts associated with a multipart upload.
    #
    # @!attribute [rw] total_parts_count
    #   The total number of parts.
    #   @return [Integer]
    #
    # @!attribute [rw] part_number_marker
    #   The marker for the current part.
    #   @return [Integer]
    #
    # @!attribute [rw] next_part_number_marker
    #   When a list is truncated, this element specifies the last part in
    #   the list, as well as the value to use for the `PartNumberMarker`
    #   request parameter in a subsequent request.
    #   @return [Integer]
    #
    # @!attribute [rw] max_parts
    #   The maximum number of parts allowed in the response.
    #   @return [Integer]
    #
    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of parts is truncated. A value
    #   of `true` indicates that the list was truncated. A list can be
    #   truncated if the number of parts exceeds the limit returned in the
    #   `MaxParts` element.
    #   @return [Boolean]
    #
    # @!attribute [rw] parts
    #   A container for elements related to a particular part. A response
    #   can contain zero or more `Parts` elements.
    #
    #   <note markdown="1"> * **General purpose buckets** - For `GetObjectAttributes`, if an
    #     additional checksum (including `x-amz-checksum-crc32`,
    #     `x-amz-checksum-crc32c`, `x-amz-checksum-sha1`, or
    #     `x-amz-checksum-sha256`) isn't applied to the object specified in
    #     the request, the response doesn't return the `Part` element.
    #
    #   * **Directory buckets** - For `GetObjectAttributes`, regardless of
    #     whether an additional checksum is applied to the object specified
    #     in the request, the response returns the `Part` element.
    #
    #    </note>
    #   @return [Array<Types::ObjectPart>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAttributesParts AWS API Documentation
    #
    class GetObjectAttributesParts < Struct.new(
      :total_parts_count,
      :part_number_marker,
      :next_part_number_marker,
      :max_parts,
      :is_truncated,
      :parts)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket that contains the object.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> S3 Versioning isn't enabled and supported for directory buckets.
    #   For this API operation, only the `null` value of the version ID is
    #   supported by directory buckets. You can only specify `null` to the
    #   `versionId` query parameter in the request.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] max_parts
    #   Sets the maximum number of parts to return. For more information,
    #   see [Uploading and copying objects using multipart upload in Amazon
    #   S3 ][1] in the *Amazon Simple Storage Service user guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html
    #   @return [Integer]
    #
    # @!attribute [rw] part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed. For more information, see
    #   [Uploading and copying objects using multipart upload in Amazon S3
    #   ][1] in the *Amazon Simple Storage Service user guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html
    #   @return [Integer]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] object_attributes
    #   Specifies the fields at the root level that you want returned in the
    #   response. Fields that you do not specify are not returned.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAttributesRequest AWS API Documentation
    #
    class GetObjectAttributesRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :max_parts,
      :part_number_marker,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :expected_bucket_owner,
      :object_attributes)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # @!attribute [rw] legal_hold
    #   The current legal hold status for the specified object.
    #   @return [Types::ObjectLockLegalHold]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLegalHoldOutput AWS API Documentation
    #
    class GetObjectLegalHoldOutput < Struct.new(
      :legal_hold)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object whose legal hold status you
    #   want to retrieve.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object whose legal hold status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object whose legal hold status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLegalHoldRequest AWS API Documentation
    #
    class GetObjectLegalHoldRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] object_lock_configuration
    #   The specified bucket's Object Lock configuration.
    #   @return [Types::ObjectLockConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLockConfigurationOutput AWS API Documentation
    #
    class GetObjectLockConfigurationOutput < Struct.new(
      :object_lock_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket whose Object Lock configuration you want to retrieve.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLockConfigurationRequest AWS API Documentation
    #
    class GetObjectLockConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] delete_marker
    #   Indicates whether the object retrieved was (true) or was not (false)
    #   a Delete Marker. If false, this response header does not appear in
    #   the response.
    #
    #   <note markdown="1"> * If the current version of the object is a delete marker, Amazon S3
    #     behaves as if the object was deleted and includes
    #     `x-amz-delete-marker: true` in the response.
    #
    #   * If the specified version in the request is a delete marker, the
    #     response returns a `405 Method Not Allowed` error and the
    #     `Last-Modified: timestamp` response header.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] accept_ranges
    #   Indicates that a range of bytes was specified in the request.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured (see [
    #   `PutBucketLifecycleConfiguration` ][1]), the response includes this
    #   header. It includes the `expiry-date` and `rule-id` key-value pairs
    #   providing object expiration information. The value of the `rule-id`
    #   is URL-encoded.
    #
    #   <note markdown="1"> Object expiration information is not returned in directory buckets
    #   and this header returns the value "`NotImplemented`" in all
    #   responses for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    #   @return [String]
    #
    # @!attribute [rw] restore
    #   Provides information about object restoration action and expiration
    #   time of the restored object copy.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets only support `EXPRESS_ONEZONE` (the S3 Express One Zone
    #   storage class) in Availability Zones and `ONEZONE_IA` (the S3 One
    #   Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Date and time when the object was last modified.
    #
    #   <b>General purpose buckets </b> - When you specify a `versionId` of
    #   the object in your request, if the specified version in the request
    #   is a delete marker, the response returns a `405 Method Not Allowed`
    #   error and the `Last-Modified: timestamp` response header.
    #   @return [Time]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] etag
    #   An entity tag (ETag) is an opaque identifier assigned by a web
    #   server to a specific version of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32` checksum of the object. This
    #   checksum is only present if the object was uploaded with the object.
    #   For more information, see [ Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the object. For
    #   more information, see [Checking object integrity in the Amazon S3
    #   User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. For more information, see [ Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type, which determines how part-level checksums are
    #   combined to create an object-level checksum for multipart objects.
    #   You can use this header response to verify that the checksum type
    #   that is received is the same checksum type that was specified in the
    #   `CreateMultipartUpload` request. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] missing_meta
    #   This is set to the number of metadata entries not returned in the
    #   headers that are prefixed with `x-amz-meta-`. This can happen if you
    #   create metadata using an API like SOAP that supports more flexible
    #   metadata than the REST API. For example, using SOAP, you can create
    #   metadata whose values are not legal HTTP headers.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Integer]
    #
    # @!attribute [rw] version_id
    #   Version ID of the object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Indicates what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_range
    #   The portion of the object returned in the response.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] expires_string
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the object uses an S3 Bucket Key for server-side
    #   encryption with Key Management Service (KMS) keys (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #
    #   <note markdown="1"> <b>Directory buckets </b> - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] replication_status
    #   Amazon S3 can return this if your request involves a bucket that is
    #   either a source or destination in a replication rule.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] parts_count
    #   The count of parts this object has. This value is only returned if
    #   you specify `partNumber` in your request and the object was uploaded
    #   as a multipart upload.
    #   @return [Integer]
    #
    # @!attribute [rw] tag_count
    #   The number of tags, if any, on the object, when you have the
    #   relevant permission to read object tags.
    #
    #   You can use [GetObjectTagging][1] to retrieve the tag set associated
    #   with an object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    #   @return [Integer]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode that's currently in place for this object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when this object's Object Lock will expire.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Indicates whether this object has an active legal hold. This field
    #   is only returned if you have permission to view an object's legal
    #   hold status.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectOutput AWS API Documentation
    #
    class GetObjectOutput < Struct.new(
      :body,
      :delete_marker,
      :accept_ranges,
      :expiration,
      :restore,
      :last_modified,
      :content_length,
      :etag,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type,
      :missing_meta,
      :version_id,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_range,
      :content_type,
      :expires,
      :expires_string,
      :website_redirect_location,
      :server_side_encryption,
      :metadata,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :bucket_key_enabled,
      :storage_class,
      :request_charged,
      :replication_status,
      :parts_count,
      :tag_count,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   **Object Lambda access points** - When you use this action with an
    #   Object Lambda access point, you must direct requests to the Object
    #   Lambda access point hostname. The Object Lambda access point
    #   hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-object-lambda.*Region*.amazonaws.com.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Return the object only if its entity tag (ETag) is the same as the
    #   one specified in this header; otherwise, return a `412 Precondition
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
    #   @return [String]
    #
    # @!attribute [rw] if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time; otherwise, return a `304 Not Modified` error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:` If-None-Match` condition
    #   evaluates to `false`, and; `If-Modified-Since` condition evaluates
    #   to `true`; then, S3 returns `304 Not Modified` status code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   @return [Time]
    #
    # @!attribute [rw] if_none_match
    #   Return the object only if its entity tag (ETag) is different from
    #   the one specified in this header; otherwise, return a `304 Not
    #   Modified` error.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:` If-None-Match` condition
    #   evaluates to `false`, and; `If-Modified-Since` condition evaluates
    #   to `true`; then, S3 returns `304 Not Modified` HTTP status code.
    #
    #   For more information about conditional requests, see [RFC 7232][1].
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   @return [String]
    #
    # @!attribute [rw] if_unmodified_since
    #   Return the object only if it has not been modified since the
    #   specified time; otherwise, return a `412 Precondition Failed` error.
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
    #   @return [Time]
    #
    # @!attribute [rw] key
    #   Key of the object to get.
    #   @return [String]
    #
    # @!attribute [rw] range
    #   Downloads the specified byte range of an object. For more
    #   information about the HTTP Range header, see
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
    #   @return [String]
    #
    # @!attribute [rw] response_cache_control
    #   Sets the `Cache-Control` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_disposition
    #   Sets the `Content-Disposition` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_encoding
    #   Sets the `Content-Encoding` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_language
    #   Sets the `Content-Language` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_type
    #   Sets the `Content-Type` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_expires
    #   Sets the `Expires` header of the response.
    #   @return [Time]
    #
    # @!attribute [rw] version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   By default, the `GetObject` operation returns the current version of
    #   an object. To return a different version, use the `versionId`
    #   subresource.
    #
    #   <note markdown="1"> * If you include a `versionId` in your request header, you must have
    #     the `s3:GetObjectVersion` permission to access a specific version
    #     of an object. The `s3:GetObject` permission is not required in
    #     this scenario.
    #
    #   * If you request the current version of an object without a specific
    #     `versionId` in the request header, only the `s3:GetObject`
    #     permission is required. The `s3:GetObjectVersion` permission is
    #     not required in this scenario.
    #
    #   * **Directory buckets** - S3 Versioning isn't enabled and supported
    #     for directory buckets. For this API operation, only the `null`
    #     value of the version ID is supported by directory buckets. You can
    #     only specify `null` to the `versionId` query parameter in the
    #     request.
    #
    #    </note>
    #
    #   For more information about versioning, see [PutBucketVersioning][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the object (for
    #   example, `AES256`).
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object
    #   in Amazon S3, then when you GET the object, you must use the
    #   following headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key that you originally
    #   provided for Amazon S3 to encrypt the data before storing it. This
    #   value is used to decrypt the object when recovering it and must
    #   match the one used when storing the data. The key must be
    #   appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object
    #   in Amazon S3, then when you GET the object, you must use the
    #   following headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the customer-provided encryption
    #   key according to RFC 1321. Amazon S3 uses this header for a message
    #   integrity check to ensure that the encryption key was transmitted
    #   without error.
    #
    #   If you encrypt an object by using server-side encryption with
    #   customer-provided encryption keys (SSE-C) when you store the object
    #   in Amazon S3, then when you GET the object, you must use the
    #   following headers:
    #
    #   * `x-amz-server-side-encryption-customer-algorithm`
    #
    #   * `x-amz-server-side-encryption-customer-key`
    #
    #   * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #   For more information about SSE-C, see [Server-Side Encryption (Using
    #   Customer-Provided Encryption Keys)][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' GET request
    #   for the part specified. Useful for downloading just a part of an
    #   object.
    #   @return [Integer]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] checksum_mode
    #   To retrieve the checksum, this mode must be enabled.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRequest AWS API Documentation
    #
    class GetObjectRequest < Struct.new(
      :bucket,
      :if_match,
      :if_modified_since,
      :if_none_match,
      :if_unmodified_since,
      :key,
      :range,
      :response_cache_control,
      :response_content_disposition,
      :response_content_encoding,
      :response_content_language,
      :response_content_type,
      :response_expires,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :part_number,
      :expected_bucket_owner,
      :checksum_mode)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # @!attribute [rw] retention
    #   The container element for an object's retention settings.
    #   @return [Types::ObjectLockRetention]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRetentionOutput AWS API Documentation
    #
    class GetObjectRetentionOutput < Struct.new(
      :retention)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object whose retention settings you
    #   want to retrieve.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object whose retention settings you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID for the object whose retention settings you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRetentionRequest AWS API Documentation
    #
    class GetObjectRetentionRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object for which you got the tagging
    #   information.
    #   @return [String]
    #
    # @!attribute [rw] tag_set
    #   Contains the tag set.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTaggingOutput AWS API Documentation
    #
    class GetObjectTaggingOutput < Struct.new(
      :version_id,
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object for which to get the tagging
    #   information.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which to get the tagging information.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object for which to get the tagging
    #   information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTaggingRequest AWS API Documentation
    #
    class GetObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :expected_bucket_owner,
      :request_payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] body
    #   A Bencoded dictionary as defined by the BitTorrent specification
    #   @return [IO]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTorrentOutput AWS API Documentation
    #
    class GetObjectTorrentOutput < Struct.new(
      :body,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the object for which to get the
    #   torrent files.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key for which to get the information.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTorrentRequest AWS API Documentation
    #
    class GetObjectTorrentRequest < Struct.new(
      :bucket,
      :key,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] public_access_block_configuration
    #   The `PublicAccessBlock` configuration currently in effect for this
    #   Amazon S3 bucket.
    #   @return [Types::PublicAccessBlockConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetPublicAccessBlockOutput AWS API Documentation
    #
    class GetPublicAccessBlockOutput < Struct.new(
      :public_access_block_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetPublicAccessBlockRequest AWS API Documentation
    #
    class GetPublicAccessBlockRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for S3 Glacier job parameters.
    #
    # @!attribute [rw] tier
    #   Retrieval tier at which the restore will be processed.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GlacierJobParameters AWS API Documentation
    #
    class GlacierJobParameters < Struct.new(
      :tier)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for grant information.
    #
    # @!attribute [rw] grantee
    #   The person being granted permissions.
    #   @return [Types::Grantee]
    #
    # @!attribute [rw] permission
    #   Specifies the permission given to the grantee.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Grant AWS API Documentation
    #
    class Grant < Struct.new(
      :grantee,
      :permission)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the person being granted permissions.
    #
    # @!attribute [rw] display_name
    #   @return [String]
    #
    # @!attribute [rw] email_address
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The canonical user ID of the grantee.
    #   @return [String]
    #
    # @!attribute [rw] type
    #   Type of grantee
    #   @return [String]
    #
    # @!attribute [rw] uri
    #   URI of the grantee group.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Grantee AWS API Documentation
    #
    class Grantee < Struct.new(
      :display_name,
      :email_address,
      :id,
      :type,
      :uri)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket_arn
    #   The Amazon Resource Name (ARN) of the S3 bucket. ARNs uniquely
    #   identify Amazon Web Services resources across all of Amazon Web
    #   Services.
    #
    #   <note markdown="1"> This parameter is only supported for S3 directory buckets. For more
    #   information, see [Using tags with directory buckets][1].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-tagging.html
    #   @return [String]
    #
    # @!attribute [rw] bucket_location_type
    #   The type of location where the bucket is created.
    #
    #   <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket_location_name
    #   The name of the location where the bucket will be created.
    #
    #   For directory buckets, the Zone ID of the Availability Zone or the
    #   Local Zone where the bucket is created. An example Zone ID value for
    #   an Availability Zone is `usw2-az1`.
    #
    #   <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket_region
    #   The Region that the bucket is located.
    #   @return [String]
    #
    # @!attribute [rw] access_point_alias
    #   Indicates whether the bucket name used in the request is an access
    #   point alias.
    #
    #   <note markdown="1"> For directory buckets, the value of this field is `false`.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadBucketOutput AWS API Documentation
    #
    class HeadBucketOutput < Struct.new(
      :bucket_arn,
      :bucket_location_type,
      :bucket_location_name,
      :bucket_region,
      :access_point_alias)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   **Object Lambda access points** - When you use this API operation
    #   with an Object Lambda access point, provide the alias of the Object
    #   Lambda access point in place of the bucket name. If the Object
    #   Lambda access point alias in a request is not valid, the error code
    #   `InvalidAccessPointAliasError` is returned. For more information
    #   about `InvalidAccessPointAliasError`, see [List of Error Codes][3].
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][4] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadBucketRequest AWS API Documentation
    #
    class HeadBucketRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] delete_marker
    #   Specifies whether the object retrieved was (true) or was not (false)
    #   a Delete Marker. If false, this response header does not appear in
    #   the response.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] accept_ranges
    #   Indicates that a range of bytes was specified.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured (see [
    #   `PutBucketLifecycleConfiguration` ][1]), the response includes this
    #   header. It includes the `expiry-date` and `rule-id` key-value pairs
    #   providing object expiration information. The value of the `rule-id`
    #   is URL-encoded.
    #
    #   <note markdown="1"> Object expiration information is not returned in directory buckets
    #   and this header returns the value "`NotImplemented`" in all
    #   responses for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    #   @return [String]
    #
    # @!attribute [rw] restore
    #   If the object is an archived object (an object whose storage class
    #   is GLACIER), the response includes this header if either the archive
    #   restoration is in progress (see [RestoreObject][1] or an archive
    #   copy is already restored.
    #
    #   If an archive copy is already restored, the header value indicates
    #   when Amazon S3 is scheduled to delete the object copy. For example:
    #
    #   `x-amz-restore: ongoing-request="false", expiry-date="Fri, 21 Dec
    #   2012 00:00:00 GMT"`
    #
    #   If the object restoration is in progress, the header returns the
    #   value `ongoing-request="true"`.
    #
    #   For more information about archiving objects, see [Transitioning
    #   Objects: General Considerations][2].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets only support `EXPRESS_ONEZONE` (the S3 Express One Zone
    #   storage class) in Availability Zones and `ONEZONE_IA` (the S3 One
    #   Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html#lifecycle-transition-general-considerations
    #   @return [String]
    #
    # @!attribute [rw] archive_status
    #   The archive state of the head object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Date and time when the object was last modified.
    #   @return [Time]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32 checksum` of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the object. For
    #   more information, see [Checking object integrity in the Amazon S3
    #   User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use the API operation on an object that was
    #   uploaded using multipart uploads, this value may not be a direct
    #   checksum value of the full object. Instead, it's a calculation
    #   based on the checksum values of each individual part. For more
    #   information about how checksums are calculated with multipart
    #   uploads, see [ Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type, which determines how part-level checksums are
    #   combined to create an object-level checksum for multipart objects.
    #   You can use this header response to verify that the checksum type
    #   that is received is the same checksum type that was specified in
    #   `CreateMultipartUpload` request. For more information, see [Checking
    #   object integrity in the Amazon S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   An entity tag (ETag) is an opaque identifier assigned by a web
    #   server to a specific version of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] missing_meta
    #   This is set to the number of metadata entries not returned in
    #   `x-amz-meta` headers. This can happen if you create metadata using
    #   an API like SOAP that supports more flexible metadata than the REST
    #   API. For example, using SOAP, you can create metadata whose values
    #   are not legal HTTP headers.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Integer]
    #
    # @!attribute [rw] version_id
    #   Version ID of the object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Indicates what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] content_range
    #   The portion of the object returned in the response for a `GET`
    #   request.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] expires_string
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the object uses an S3 Bucket Key for server-side
    #   encryption with Key Management Service (KMS) keys (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #
    #   For more information, see [Storage Classes][1].
    #
    #   <note markdown="1"> <b>Directory buckets </b> - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] replication_status
    #   Amazon S3 can return this header if your request involves a bucket
    #   that is either a source or a destination in a replication rule.
    #
    #   In replication, you have a source bucket on which you configure
    #   replication and destination bucket or buckets where Amazon S3 stores
    #   object replicas. When you request an object (`GetObject`) or object
    #   metadata (`HeadObject`) from these buckets, Amazon S3 will return
    #   the `x-amz-replication-status` header in the response as follows:
    #
    #   * **If requesting an object from the source bucket**, Amazon S3 will
    #     return the `x-amz-replication-status` header if the object in your
    #     request is eligible for replication.
    #
    #     For example, suppose that in your replication configuration, you
    #     specify object prefix `TaxDocs` requesting Amazon S3 to replicate
    #     objects with key prefix `TaxDocs`. Any objects you upload with
    #     this key name prefix, for example `TaxDocs/document1.pdf`, are
    #     eligible for replication. For any object request with this key
    #     name prefix, Amazon S3 will return the `x-amz-replication-status`
    #     header with value PENDING, COMPLETED or FAILED indicating object
    #     replication status.
    #
    #   * **If requesting an object from a destination bucket**, Amazon S3
    #     will return the `x-amz-replication-status` header with value
    #     REPLICA if the object in your request is a replica that Amazon S3
    #     created and there is no replica modification replication in
    #     progress.
    #
    #   * **When replicating objects to multiple destination buckets**, the
    #     `x-amz-replication-status` header acts differently. The header of
    #     the source object will only return a value of COMPLETED when
    #     replication is successful to all destinations. The header will
    #     remain at value PENDING until replication has completed for all
    #     destinations. If one or more destinations fails replication the
    #     header will return FAILED.
    #
    #   For more information, see [Replication][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [String]
    #
    # @!attribute [rw] parts_count
    #   The count of parts this object has. This value is only returned if
    #   you specify `partNumber` in your request and the object was uploaded
    #   as a multipart upload.
    #   @return [Integer]
    #
    # @!attribute [rw] tag_count
    #   The number of tags, if any, on the object, when you have the
    #   relevant permission to read object tags.
    #
    #   You can use [GetObjectTagging][1] to retrieve the tag set associated
    #   with an object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    #   @return [Integer]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode, if any, that's in effect for this object.
    #   This header is only returned if the requester has the
    #   `s3:GetObjectRetention` permission. For more information about S3
    #   Object Lock, see [Object Lock][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when the Object Lock retention period expires.
    #   This header is only returned if the requester has the
    #   `s3:GetObjectRetention` permission.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether a legal hold is in effect for this object. This
    #   header is only returned if the requester has the
    #   `s3:GetObjectLegalHold` permission. This header is not returned if
    #   the specified version of this object has never had a legal hold
    #   applied. For more information about S3 Object Lock, see [Object
    #   Lock][1].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadObjectOutput AWS API Documentation
    #
    class HeadObjectOutput < Struct.new(
      :delete_marker,
      :accept_ranges,
      :expiration,
      :restore,
      :archive_status,
      :last_modified,
      :content_length,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type,
      :etag,
      :missing_meta,
      :version_id,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :content_range,
      :expires,
      :expires_string,
      :website_redirect_location,
      :server_side_encryption,
      :metadata,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :bucket_key_enabled,
      :storage_class,
      :request_charged,
      :replication_status,
      :parts_count,
      :tag_count,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket that contains the object.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Return the object only if its entity tag (ETag) is the same as the
    #   one specified; otherwise, return a 412 (precondition failed) error.
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
    #   @return [String]
    #
    # @!attribute [rw] if_modified_since
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
    #   @return [Time]
    #
    # @!attribute [rw] if_none_match
    #   Return the object only if its entity tag (ETag) is different from
    #   the one specified; otherwise, return a 304 (not modified) error.
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
    #   @return [String]
    #
    # @!attribute [rw] if_unmodified_since
    #   Return the object only if it has not been modified since the
    #   specified time; otherwise, return a 412 (precondition failed) error.
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
    #   @return [Time]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] range
    #   HeadObject returns only the metadata for an object. If the Range is
    #   satisfiable, only the `ContentLength` is affected in the response.
    #   If the Range is not satisfiable, S3 returns a `416 - Requested Range
    #   Not Satisfiable` error.
    #   @return [String]
    #
    # @!attribute [rw] response_cache_control
    #   Sets the `Cache-Control` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_disposition
    #   Sets the `Content-Disposition` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_encoding
    #   Sets the `Content-Encoding` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_language
    #   Sets the `Content-Language` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_type
    #   Sets the `Content-Type` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_expires
    #   Sets the `Expires` header of the response.
    #   @return [Time]
    #
    # @!attribute [rw] version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> For directory buckets in this API operation, only the `null` value
    #   of the version ID is supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' HEAD request
    #   for the part specified. Useful querying about the size of the part
    #   and the number of parts in this object.
    #   @return [Integer]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] checksum_mode
    #   To retrieve the checksum, this parameter must be enabled.
    #
    #   **General purpose buckets** - If you enable checksum mode and the
    #   object is uploaded with a [checksum][1] and encrypted with an Key
    #   Management Service (KMS) key, you must have permission to use the
    #   `kms:Decrypt` action to retrieve the checksum.
    #
    #   **Directory buckets** - If you enable `ChecksumMode` and the object
    #   is encrypted with Amazon Web Services Key Management Service (Amazon
    #   Web Services KMS), you must also have the `kms:GenerateDataKey` and
    #   `kms:Decrypt` permissions in IAM identity-based policies and KMS key
    #   policies for the KMS key to retrieve the checksum of the object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_Checksum.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadObjectRequest AWS API Documentation
    #
    class HeadObjectRequest < Struct.new(
      :bucket,
      :if_match,
      :if_modified_since,
      :if_none_match,
      :if_unmodified_since,
      :key,
      :range,
      :response_cache_control,
      :response_content_disposition,
      :response_content_encoding,
      :response_content_language,
      :response_content_type,
      :response_expires,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :part_number,
      :expected_bucket_owner,
      :checksum_mode)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Parameters on this idempotent request are inconsistent with parameters
    # used in previous request(s).
    #
    # For a list of error codes and more information on Amazon S3 errors,
    # see [Error codes][1].
    #
    # <note markdown="1"> Idempotency ensures that an API request completes no more than one
    # time. With an idempotent request, if the original request completes
    # successfully, any subsequent retries complete successfully without
    # performing any further actions.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IdempotencyParameterMismatch AWS API Documentation
    #
    class IdempotencyParameterMismatch < Aws::EmptyStructure; end

    # Container for the `Suffix` element.
    #
    # @!attribute [rw] suffix
    #   A suffix that is appended to a request that is for a directory on
    #   the website endpoint. (For example, if the suffix is `index.html`
    #   and you make a request to `samplebucket/images/`, the data that is
    #   returned will be for the object with the key name
    #   `images/index.html`.) The suffix must not be empty and must not
    #   include a slash character.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IndexDocument AWS API Documentation
    #
    class IndexDocument < Struct.new(
      :suffix)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container element that identifies who initiated the multipart upload.
    #
    # @!attribute [rw] id
    #   If the principal is an Amazon Web Services account, it provides the
    #   Canonical User ID. If the principal is an IAM User, it provides a
    #   user ARN value.
    #
    #   <note markdown="1"> **Directory buckets** - If the principal is an Amazon Web Services
    #   account, it provides the Amazon Web Services account ID. If the
    #   principal is an IAM User, it provides a user ARN value.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] display_name
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Initiator AWS API Documentation
    #
    class Initiator < Struct.new(
      :id,
      :display_name)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the serialization format of the object.
    #
    # @!attribute [rw] csv
    #   Describes the serialization of a CSV-encoded object.
    #   @return [Types::CSVInput]
    #
    # @!attribute [rw] compression_type
    #   Specifies object's compression format. Valid values: NONE, GZIP,
    #   BZIP2. Default Value: NONE.
    #   @return [String]
    #
    # @!attribute [rw] json
    #   Specifies JSON as object's input serialization format.
    #   @return [Types::JSONInput]
    #
    # @!attribute [rw] parquet
    #   Specifies Parquet as object's input serialization format.
    #   @return [Types::ParquetInput]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InputSerialization AWS API Documentation
    #
    class InputSerialization < Struct.new(
      :csv,
      :compression_type,
      :json,
      :parquet)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying S3 Intelligent-Tiering filters. The filters
    # determine the subset of objects to which the rule applies.
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the configuration applies.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   All of these tags must exist in the object's tag set in order for
    #   the configuration to apply.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IntelligentTieringAndOperator AWS API Documentation
    #
    class IntelligentTieringAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the S3 Intelligent-Tiering configuration for an Amazon S3
    # bucket.
    #
    # For information about the S3 Intelligent-Tiering storage class, see
    # [Storage class for automatically optimizing frequently and
    # infrequently accessed objects][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    #
    # @!attribute [rw] id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   Specifies a bucket filter. The configuration only includes objects
    #   that meet the filter's criteria.
    #   @return [Types::IntelligentTieringFilter]
    #
    # @!attribute [rw] status
    #   Specifies the status of the configuration.
    #   @return [String]
    #
    # @!attribute [rw] tierings
    #   Specifies the S3 Intelligent-Tiering storage class tier of the
    #   configuration.
    #   @return [Array<Types::Tiering>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IntelligentTieringConfiguration AWS API Documentation
    #
    class IntelligentTieringConfiguration < Struct.new(
      :id,
      :filter,
      :status,
      :tierings)
      SENSITIVE = []
      include Aws::Structure
    end

    # The `Filter` is used to identify objects that the S3
    # Intelligent-Tiering configuration applies to.
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the rule applies.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   A container of a key value name pair.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A conjunction (logical AND) of predicates, which is used in
    #   evaluating a metrics filter. The operator must have at least two
    #   predicates, and an object must match all of the predicates in order
    #   for the filter to apply.
    #   @return [Types::IntelligentTieringAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IntelligentTieringFilter AWS API Documentation
    #
    class IntelligentTieringFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # Object is archived and inaccessible until restored.
    #
    # If the object you are retrieving is stored in the S3 Glacier Flexible
    # Retrieval storage class, the S3 Glacier Deep Archive storage class,
    # the S3 Intelligent-Tiering Archive Access tier, or the S3
    # Intelligent-Tiering Deep Archive Access tier, before you can retrieve
    # the object you must first restore a copy using [RestoreObject][1].
    # Otherwise, this operation returns an `InvalidObjectState` error. For
    # information about restoring archived objects, see [Restoring Archived
    # Objects][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html
    #
    # @!attribute [rw] storage_class
    #   @return [String]
    #
    # @!attribute [rw] access_tier
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InvalidObjectState AWS API Documentation
    #
    class InvalidObjectState < Struct.new(
      :storage_class,
      :access_tier)
      SENSITIVE = []
      include Aws::Structure
    end

    # A parameter or header in your request isn't valid. For details, see
    # the description of this API operation.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InvalidRequest AWS API Documentation
    #
    class InvalidRequest < Aws::EmptyStructure; end

    # The write offset value that you specified does not match the current
    # object size.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InvalidWriteOffset AWS API Documentation
    #
    class InvalidWriteOffset < Aws::EmptyStructure; end

    # Specifies the S3 Inventory configuration for an Amazon S3 bucket. For
    # more information, see [GET Bucket inventory][1] in the *Amazon S3 API
    # Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETInventoryConfig.html
    #
    # @!attribute [rw] destination
    #   Contains information about where to publish the inventory results.
    #   @return [Types::InventoryDestination]
    #
    # @!attribute [rw] is_enabled
    #   Specifies whether the inventory is enabled or disabled. If set to
    #   `True`, an inventory list is generated. If set to `False`, no
    #   inventory list is generated.
    #   @return [Boolean]
    #
    # @!attribute [rw] filter
    #   Specifies an inventory filter. The inventory only includes objects
    #   that meet the filter's criteria.
    #   @return [Types::InventoryFilter]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] included_object_versions
    #   Object versions to include in the inventory list. If set to `All`,
    #   the list includes all the object versions, which adds the
    #   version-related fields `VersionId`, `IsLatest`, and `DeleteMarker`
    #   to the list. If set to `Current`, the list does not contain these
    #   version-related fields.
    #   @return [String]
    #
    # @!attribute [rw] optional_fields
    #   Contains the optional fields that are included in the inventory
    #   results.
    #   @return [Array<String>]
    #
    # @!attribute [rw] schedule
    #   Specifies the schedule for generating inventory results.
    #   @return [Types::InventorySchedule]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryConfiguration AWS API Documentation
    #
    class InventoryConfiguration < Struct.new(
      :destination,
      :is_enabled,
      :filter,
      :id,
      :included_object_versions,
      :optional_fields,
      :schedule)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the S3 Inventory configuration for an Amazon S3 bucket.
    #
    # @!attribute [rw] s3_bucket_destination
    #   Contains the bucket name, file format, bucket owner (optional), and
    #   prefix (optional) where inventory results are published.
    #   @return [Types::InventoryS3BucketDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryDestination AWS API Documentation
    #
    class InventoryDestination < Struct.new(
      :s3_bucket_destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the type of server-side encryption used to encrypt the S3
    # Inventory results.
    #
    # @!attribute [rw] sses3
    #   Specifies the use of SSE-S3 to encrypt delivered inventory reports.
    #   @return [Types::SSES3]
    #
    # @!attribute [rw] ssekms
    #   Specifies the use of SSE-KMS to encrypt delivered inventory reports.
    #   @return [Types::SSEKMS]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryEncryption AWS API Documentation
    #
    class InventoryEncryption < Struct.new(
      :sses3,
      :ssekms)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies an S3 Inventory filter. The inventory only includes objects
    # that meet the filter's criteria.
    #
    # @!attribute [rw] prefix
    #   The prefix that an object must have to be included in the inventory
    #   results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryFilter AWS API Documentation
    #
    class InventoryFilter < Struct.new(
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the bucket name, file format, bucket owner (optional), and
    # prefix (optional) where S3 Inventory results are published.
    #
    # @!attribute [rw] account_id
    #   The account ID that owns the destination S3 bucket. If no account ID
    #   is provided, the owner is not validated before exporting data.
    #
    #   <note markdown="1"> Although this value is optional, we strongly recommend that you set
    #   it to help prevent problems if the destination bucket ownership
    #   changes.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket where inventory results
    #   will be published.
    #   @return [String]
    #
    # @!attribute [rw] format
    #   Specifies the output format of the inventory results.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix that is prepended to all inventory results.
    #   @return [String]
    #
    # @!attribute [rw] encryption
    #   Contains the type of server-side encryption used to encrypt the
    #   inventory results.
    #   @return [Types::InventoryEncryption]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryS3BucketDestination AWS API Documentation
    #
    class InventoryS3BucketDestination < Struct.new(
      :account_id,
      :bucket,
      :format,
      :prefix,
      :encryption)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the schedule for generating S3 Inventory results.
    #
    # @!attribute [rw] frequency
    #   Specifies how frequently inventory results are produced.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventorySchedule AWS API Documentation
    #
    class InventorySchedule < Struct.new(
      :frequency)
      SENSITIVE = []
      include Aws::Structure
    end

    # The inventory table configuration for an S3 Metadata configuration.
    #
    # @!attribute [rw] configuration_state
    #   The configuration state of the inventory table, indicating whether
    #   the inventory table is enabled or disabled.
    #   @return [String]
    #
    # @!attribute [rw] encryption_configuration
    #   The encryption configuration for the inventory table.
    #   @return [Types::MetadataTableEncryptionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryTableConfiguration AWS API Documentation
    #
    class InventoryTableConfiguration < Struct.new(
      :configuration_state,
      :encryption_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # The inventory table configuration for an S3 Metadata configuration.
    #
    # @!attribute [rw] configuration_state
    #   The configuration state of the inventory table, indicating whether
    #   the inventory table is enabled or disabled.
    #   @return [String]
    #
    # @!attribute [rw] table_status
    #   The status of the inventory table. The status values are:
    #
    #   * `CREATING` - The inventory table is in the process of being
    #     created in the specified Amazon Web Services managed table bucket.
    #
    #   * `BACKFILLING` - The inventory table is in the process of being
    #     backfilled. When you enable the inventory table for your metadata
    #     configuration, the table goes through a process known as
    #     backfilling, during which Amazon S3 scans your general purpose
    #     bucket to retrieve the initial metadata for all objects in the
    #     bucket. Depending on the number of objects in your bucket, this
    #     process can take several hours. When the backfilling process is
    #     finished, the status of your inventory table changes from
    #     `BACKFILLING` to `ACTIVE`. After backfilling is completed, updates
    #     to your objects are reflected in the inventory table within one
    #     hour.
    #
    #   * `ACTIVE` - The inventory table has been created successfully, and
    #     records are being delivered to the table.
    #
    #   * `FAILED` - Amazon S3 is unable to create the inventory table, or
    #     Amazon S3 is unable to deliver records.
    #   @return [String]
    #
    # @!attribute [rw] error
    #   If an S3 Metadata V1 `CreateBucketMetadataTableConfiguration` or V2
    #   `CreateBucketMetadataConfiguration` request succeeds, but S3
    #   Metadata was unable to create the table, this structure contains the
    #   error code and error message.
    #
    #   <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025,
    #   we recommend that you delete and re-create your configuration by
    #   using [CreateBucketMetadataConfiguration][1] so that you can expire
    #   journal table records and create a live inventory table.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #   @return [Types::ErrorDetails]
    #
    # @!attribute [rw] table_name
    #   The name of the inventory table.
    #   @return [String]
    #
    # @!attribute [rw] table_arn
    #   The Amazon Resource Name (ARN) for the inventory table.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryTableConfigurationResult AWS API Documentation
    #
    class InventoryTableConfigurationResult < Struct.new(
      :configuration_state,
      :table_status,
      :error,
      :table_name,
      :table_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # The specified updates to the S3 Metadata inventory table
    # configuration.
    #
    # @!attribute [rw] configuration_state
    #   The configuration state of the inventory table, indicating whether
    #   the inventory table is enabled or disabled.
    #   @return [String]
    #
    # @!attribute [rw] encryption_configuration
    #   The encryption configuration for the inventory table.
    #   @return [Types::MetadataTableEncryptionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryTableConfigurationUpdates AWS API Documentation
    #
    class InventoryTableConfigurationUpdates < Struct.new(
      :configuration_state,
      :encryption_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies JSON as object's input serialization format.
    #
    # @!attribute [rw] type
    #   The type of JSON. Valid values: Document, Lines.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JSONInput AWS API Documentation
    #
    class JSONInput < Struct.new(
      :type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies JSON as request's output serialization format.
    #
    # @!attribute [rw] record_delimiter
    #   The value used to separate individual records in the output. If no
    #   value is specified, Amazon S3 uses a newline character ('\\n').
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JSONOutput AWS API Documentation
    #
    class JSONOutput < Struct.new(
      :record_delimiter)
      SENSITIVE = []
      include Aws::Structure
    end

    # The journal table configuration for an S3 Metadata configuration.
    #
    # @!attribute [rw] record_expiration
    #   The journal table record expiration settings for the journal table.
    #   @return [Types::RecordExpiration]
    #
    # @!attribute [rw] encryption_configuration
    #   The encryption configuration for the journal table.
    #   @return [Types::MetadataTableEncryptionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JournalTableConfiguration AWS API Documentation
    #
    class JournalTableConfiguration < Struct.new(
      :record_expiration,
      :encryption_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # The journal table configuration for the S3 Metadata configuration.
    #
    # @!attribute [rw] table_status
    #   The status of the journal table. The status values are:
    #
    #   * `CREATING` - The journal table is in the process of being created
    #     in the specified table bucket.
    #
    #   * `ACTIVE` - The journal table has been created successfully, and
    #     records are being delivered to the table.
    #
    #   * `FAILED` - Amazon S3 is unable to create the journal table, or
    #     Amazon S3 is unable to deliver records.
    #   @return [String]
    #
    # @!attribute [rw] error
    #   If an S3 Metadata V1 `CreateBucketMetadataTableConfiguration` or V2
    #   `CreateBucketMetadataConfiguration` request succeeds, but S3
    #   Metadata was unable to create the table, this structure contains the
    #   error code and error message.
    #
    #   <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025,
    #   we recommend that you delete and re-create your configuration by
    #   using [CreateBucketMetadataConfiguration][1] so that you can expire
    #   journal table records and create a live inventory table.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #   @return [Types::ErrorDetails]
    #
    # @!attribute [rw] table_name
    #   The name of the journal table.
    #   @return [String]
    #
    # @!attribute [rw] table_arn
    #   The Amazon Resource Name (ARN) for the journal table.
    #   @return [String]
    #
    # @!attribute [rw] record_expiration
    #   The journal table record expiration settings for the journal table.
    #   @return [Types::RecordExpiration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JournalTableConfigurationResult AWS API Documentation
    #
    class JournalTableConfigurationResult < Struct.new(
      :table_status,
      :error,
      :table_name,
      :table_arn,
      :record_expiration)
      SENSITIVE = []
      include Aws::Structure
    end

    # The specified updates to the S3 Metadata journal table configuration.
    #
    # @!attribute [rw] record_expiration
    #   The journal table record expiration settings for the journal table.
    #   @return [Types::RecordExpiration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JournalTableConfigurationUpdates AWS API Documentation
    #
    class JournalTableConfigurationUpdates < Struct.new(
      :record_expiration)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for Lambda notifications.
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] lambda_function_arn
    #   The Amazon Resource Name (ARN) of the Lambda function that Amazon S3
    #   invokes when the specified event type occurs.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   The Amazon S3 bucket event for which to invoke the Lambda function.
    #   For more information, see [Supported Event Types][1] in the *Amazon
    #   S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring event notifications using object
    #   key name filtering][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-filtering.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LambdaFunctionConfiguration AWS API Documentation
    #
    class LambdaFunctionConfiguration < Struct.new(
      :id,
      :lambda_function_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for lifecycle rules. You can add as many as 1000 rules.
    #
    # For more information see, [Managing your storage lifecycle][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
    #
    # @!attribute [rw] rules
    #   Specifies lifecycle configuration rules for an Amazon S3 bucket.
    #   @return [Array<Types::Rule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleConfiguration AWS API Documentation
    #
    class LifecycleConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the expiration for the lifecycle of the object.
    #
    # For more information see, [Managing your storage lifecycle][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
    #
    # @!attribute [rw] date
    #   Indicates at what date the object is to be moved or deleted. The
    #   date value must conform to the ISO 8601 format. The time is always
    #   midnight UTC.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] days
    #   Indicates the lifetime, in days, of the objects that are subject to
    #   the rule. The value must be a non-zero positive integer.
    #   @return [Integer]
    #
    # @!attribute [rw] expired_object_delete_marker
    #   Indicates whether Amazon S3 will remove a delete marker with no
    #   noncurrent versions. If set to true, the delete marker will be
    #   expired; if set to false the policy takes no action. This cannot be
    #   specified with Days or Date in a Lifecycle Expiration Policy.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleExpiration AWS API Documentation
    #
    class LifecycleExpiration < Struct.new(
      :date,
      :days,
      :expired_object_delete_marker)
      SENSITIVE = []
      include Aws::Structure
    end

    # A lifecycle rule for individual objects in an Amazon S3 bucket.
    #
    # For more information see, [Managing your storage lifecycle][1] in the
    # *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
    #
    # @!attribute [rw] expiration
    #   Specifies the expiration for the lifecycle of the object in the form
    #   of date, days and, whether the object has a delete marker.
    #   @return [Types::LifecycleExpiration]
    #
    # @!attribute [rw] id
    #   Unique identifier for the rule. The value cannot be longer than 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The general purpose bucket prefix that identifies one or more
    #   objects to which the rule applies. We recommend using `Filter`
    #   instead of `Prefix` for new PUTs. Previous configurations where a
    #   prefix is defined will continue to operate as before.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   The `Filter` is used to identify objects that a Lifecycle Rule
    #   applies to. A `Filter` must have exactly one of `Prefix`, `Tag`,
    #   `ObjectSizeGreaterThan`, `ObjectSizeLessThan`, or `And` specified.
    #   `Filter` is required if the `LifecycleRule` does not contain a
    #   `Prefix` element.
    #
    #   For more information about `Tag` filters, see [Adding filters to
    #   Lifecycle rules][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> `Tag` filters are not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/intro-lifecycle-filters.html
    #   @return [Types::LifecycleRuleFilter]
    #
    # @!attribute [rw] status
    #   If 'Enabled', the rule is currently being applied. If
    #   'Disabled', the rule is not currently being applied.
    #   @return [String]
    #
    # @!attribute [rw] transitions
    #   Specifies when an Amazon S3 object transitions to a specified
    #   storage class.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Array<Types::Transition>]
    #
    # @!attribute [rw] noncurrent_version_transitions
    #   Specifies the transition rule for the lifecycle rule that describes
    #   when noncurrent objects transition to a specific storage class. If
    #   your bucket is versioning-enabled (or versioning is suspended), you
    #   can set this action to request that Amazon S3 transition noncurrent
    #   object versions to a specific storage class at a set period in the
    #   object's lifetime.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Array<Types::NoncurrentVersionTransition>]
    #
    # @!attribute [rw] noncurrent_version_expiration
    #   Specifies when noncurrent object versions expire. Upon expiration,
    #   Amazon S3 permanently deletes the noncurrent object versions. You
    #   set this lifecycle configuration action on a bucket that has
    #   versioning enabled (or suspended) to request that Amazon S3 delete
    #   noncurrent object versions at a specific period in the object's
    #   lifetime.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Types::NoncurrentVersionExpiration]
    #
    # @!attribute [rw] abort_incomplete_multipart_upload
    #   Specifies the days since the initiation of an incomplete multipart
    #   upload that Amazon S3 will wait before permanently removing all
    #   parts of the upload. For more information, see [ Aborting Incomplete
    #   Multipart Uploads Using a Bucket Lifecycle Configuration][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Types::AbortIncompleteMultipartUpload]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRule AWS API Documentation
    #
    class LifecycleRule < Struct.new(
      :expiration,
      :id,
      :prefix,
      :filter,
      :status,
      :transitions,
      :noncurrent_version_transitions,
      :noncurrent_version_expiration,
      :abort_incomplete_multipart_upload)
      SENSITIVE = []
      include Aws::Structure
    end

    # This is used in a Lifecycle Rule Filter to apply a logical AND to two
    # or more predicates. The Lifecycle Rule will apply to any object
    # matching all of the predicates configured inside the And operator.
    #
    # @!attribute [rw] prefix
    #   Prefix identifying one or more objects to which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   All of these tags must exist in the object's tag set in order for
    #   the rule to apply.
    #   @return [Array<Types::Tag>]
    #
    # @!attribute [rw] object_size_greater_than
    #   Minimum object size to which the rule applies.
    #   @return [Integer]
    #
    # @!attribute [rw] object_size_less_than
    #   Maximum object size to which the rule applies.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRuleAndOperator AWS API Documentation
    #
    class LifecycleRuleAndOperator < Struct.new(
      :prefix,
      :tags,
      :object_size_greater_than,
      :object_size_less_than)
      SENSITIVE = []
      include Aws::Structure
    end

    # The `Filter` is used to identify objects that a Lifecycle Rule applies
    # to. A `Filter` can have exactly one of `Prefix`, `Tag`,
    # `ObjectSizeGreaterThan`, `ObjectSizeLessThan`, or `And` specified. If
    # the `Filter` element is left empty, the Lifecycle Rule applies to all
    # objects in the bucket.
    #
    # @!attribute [rw] prefix
    #   Prefix identifying one or more objects to which the rule applies.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   This tag must exist in the object's tag set in order for the rule
    #   to apply.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Types::Tag]
    #
    # @!attribute [rw] object_size_greater_than
    #   Minimum object size to which the rule applies.
    #   @return [Integer]
    #
    # @!attribute [rw] object_size_less_than
    #   Maximum object size to which the rule applies.
    #   @return [Integer]
    #
    # @!attribute [rw] and
    #   This is used in a Lifecycle Rule Filter to apply a logical AND to
    #   two or more predicates. The Lifecycle Rule will apply to any object
    #   matching all of the predicates configured inside the And operator.
    #   @return [Types::LifecycleRuleAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRuleFilter AWS API Documentation
    #
    class LifecycleRuleFilter < Struct.new(
      :prefix,
      :tag,
      :object_size_greater_than,
      :object_size_less_than,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of analytics configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken will be provided for a subsequent
    #   request.
    #   @return [Boolean]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used as a starting point for this analytics
    #   configuration list response. This value is present if it was sent in
    #   the request.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   `NextContinuationToken` is sent when `isTruncated` is true, which
    #   indicates that there are more analytics configurations to list. The
    #   next request must include this `NextContinuationToken`. The token is
    #   obfuscated and is not a usable value.
    #   @return [String]
    #
    # @!attribute [rw] analytics_configuration_list
    #   The list of analytics configurations for a bucket.
    #   @return [Array<Types::AnalyticsConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketAnalyticsConfigurationsOutput AWS API Documentation
    #
    class ListBucketAnalyticsConfigurationsOutput < Struct.new(
      :is_truncated,
      :continuation_token,
      :next_continuation_token,
      :analytics_configuration_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket from which analytics configurations are
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The `ContinuationToken` that represents a placeholder from where
    #   this request should begin.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketAnalyticsConfigurationsRequest AWS API Documentation
    #
    class ListBucketAnalyticsConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of analytics configurations is
    #   complete. A value of `true` indicates that the list is not complete
    #   and the `NextContinuationToken` will be provided for a subsequent
    #   request.
    #   @return [Boolean]
    #
    # @!attribute [rw] continuation_token
    #   The `ContinuationToken` that represents a placeholder from where
    #   this request should begin.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   The marker used to continue this inventory configuration listing.
    #   Use the `NextContinuationToken` from this response to continue the
    #   listing in a subsequent request. The continuation token is an opaque
    #   value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] intelligent_tiering_configuration_list
    #   The list of S3 Intelligent-Tiering configurations for a bucket.
    #   @return [Array<Types::IntelligentTieringConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketIntelligentTieringConfigurationsOutput AWS API Documentation
    #
    class ListBucketIntelligentTieringConfigurationsOutput < Struct.new(
      :is_truncated,
      :continuation_token,
      :next_continuation_token,
      :intelligent_tiering_configuration_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The `ContinuationToken` that represents a placeholder from where
    #   this request should begin.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketIntelligentTieringConfigurationsRequest AWS API Documentation
    #
    class ListBucketIntelligentTieringConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] continuation_token
    #   If sent in the request, the marker that is used as a starting point
    #   for this inventory configuration list response.
    #   @return [String]
    #
    # @!attribute [rw] inventory_configuration_list
    #   The list of inventory configurations for a bucket.
    #   @return [Array<Types::InventoryConfiguration>]
    #
    # @!attribute [rw] is_truncated
    #   Tells whether the returned list of inventory configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken is provided for a subsequent request.
    #   @return [Boolean]
    #
    # @!attribute [rw] next_continuation_token
    #   The marker used to continue this inventory configuration listing.
    #   Use the `NextContinuationToken` from this response to continue the
    #   listing in a subsequent request. The continuation token is an opaque
    #   value that Amazon S3 understands.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketInventoryConfigurationsOutput AWS API Documentation
    #
    class ListBucketInventoryConfigurationsOutput < Struct.new(
      :continuation_token,
      :inventory_configuration_list,
      :is_truncated,
      :next_continuation_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configurations to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The marker used to continue an inventory configuration listing that
    #   has been truncated. Use the `NextContinuationToken` from a
    #   previously truncated list response to continue the listing. The
    #   continuation token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketInventoryConfigurationsRequest AWS API Documentation
    #
    class ListBucketInventoryConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of metrics configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken will be provided for a subsequent
    #   request.
    #   @return [Boolean]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used as a starting point for this metrics
    #   configuration list response. This value is present if it was sent in
    #   the request.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   The marker used to continue a metrics configuration listing that has
    #   been truncated. Use the `NextContinuationToken` from a previously
    #   truncated list response to continue the listing. The continuation
    #   token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] metrics_configuration_list
    #   The list of metrics configurations for a bucket.
    #   @return [Array<Types::MetricsConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketMetricsConfigurationsOutput AWS API Documentation
    #
    class ListBucketMetricsConfigurationsOutput < Struct.new(
      :is_truncated,
      :continuation_token,
      :next_continuation_token,
      :metrics_configuration_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configurations to
    #   retrieve.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used to continue a metrics configuration listing
    #   that has been truncated. Use the `NextContinuationToken` from a
    #   previously truncated list response to continue the listing. The
    #   continuation token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketMetricsConfigurationsRequest AWS API Documentation
    #
    class ListBucketMetricsConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] buckets
    #   The list of buckets owned by the requester.
    #   @return [Array<Types::Bucket>]
    #
    # @!attribute [rw] owner
    #   The owner of the buckets listed.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] continuation_token
    #   `ContinuationToken` is included in the response when there are more
    #   buckets that can be listed with pagination. The next `ListBuckets`
    #   request to Amazon S3 can be continued with this `ContinuationToken`.
    #   `ContinuationToken` is obfuscated and is not a real bucket.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   If `Prefix` was sent with the request, it is included in the
    #   response.
    #
    #   All bucket names in the response begin with the specified bucket
    #   name prefix.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketsOutput AWS API Documentation
    #
    class ListBucketsOutput < Struct.new(
      :buckets,
      :owner,
      :continuation_token,
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] max_buckets
    #   Maximum number of buckets to be returned in response. When the
    #   number is more than the count of buckets that are owned by an Amazon
    #   Web Services account, return all the buckets in response.
    #   @return [Integer]
    #
    # @!attribute [rw] continuation_token
    #   `ContinuationToken` indicates to Amazon S3 that the list is being
    #   continued on this bucket with a token. `ContinuationToken` is
    #   obfuscated and is not a real key. You can use this
    #   `ContinuationToken` for pagination of the list results.
    #
    #   Length Constraints: Minimum length of 0. Maximum length of 1024.
    #
    #   Required: No.
    #
    #   <note markdown="1"> If you specify the `bucket-region`, `prefix`, or
    #   `continuation-token` query parameters without using `max-buckets` to
    #   set the maximum number of buckets returned in the response, Amazon
    #   S3 applies a default page size of 10,000 and provides a continuation
    #   token if there are more buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Limits the response to bucket names that begin with the specified
    #   bucket name prefix.
    #   @return [String]
    #
    # @!attribute [rw] bucket_region
    #   Limits the response to buckets that are located in the specified
    #   Amazon Web Services Region. The Amazon Web Services Region must be
    #   expressed according to the Amazon Web Services Region code, such as
    #   `us-west-2` for the US West (Oregon) Region. For a list of the valid
    #   values for all of the Amazon Web Services Regions, see [Regions and
    #   Endpoints][1].
    #
    #   <note markdown="1"> Requests made to a Regional endpoint that is different from the
    #   `bucket-region` parameter are not supported. For example, if you
    #   want to limit the response to your buckets in Region `us-west-2`,
    #   the request must be made to an endpoint in Region `us-west-2`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketsRequest AWS API Documentation
    #
    class ListBucketsRequest < Struct.new(
      :max_buckets,
      :continuation_token,
      :prefix,
      :bucket_region)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] buckets
    #   The list of buckets owned by the requester.
    #   @return [Array<Types::Bucket>]
    #
    # @!attribute [rw] continuation_token
    #   If `ContinuationToken` was sent with the request, it is included in
    #   the response. You can use the returned `ContinuationToken` for
    #   pagination of the list response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListDirectoryBucketsOutput AWS API Documentation
    #
    class ListDirectoryBucketsOutput < Struct.new(
      :buckets,
      :continuation_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] continuation_token
    #   `ContinuationToken` indicates to Amazon S3 that the list is being
    #   continued on buckets in this account with a token.
    #   `ContinuationToken` is obfuscated and is not a real bucket name. You
    #   can use this `ContinuationToken` for the pagination of the list
    #   results.
    #   @return [String]
    #
    # @!attribute [rw] max_directory_buckets
    #   Maximum number of buckets to be returned in response. When the
    #   number is more than the count of buckets that are owned by an Amazon
    #   Web Services account, return all the buckets in response.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListDirectoryBucketsRequest AWS API Documentation
    #
    class ListDirectoryBucketsRequest < Struct.new(
      :continuation_token,
      :max_directory_buckets)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #   Does not return the access point ARN or access point alias if used.
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   The key at or after which the listing began.
    #   @return [String]
    #
    # @!attribute [rw] upload_id_marker
    #   Together with key-marker, specifies the multipart upload after which
    #   listing should begin. If key-marker is not specified, the
    #   upload-id-marker parameter is ignored. Otherwise, any multipart
    #   uploads for a key equal to the key-marker might be included in the
    #   list only if they have an upload ID lexicographically greater than
    #   the specified `upload-id-marker`.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] next_key_marker
    #   When a list is truncated, this element specifies the value that
    #   should be used for the key-marker request parameter in a subsequent
    #   request.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   When a prefix is provided in the request, this field contains the
    #   specified prefix. The result contains only keys starting with the
    #   specified prefix.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, only prefixes that
    #   end in a delimiter (`/`) are supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Contains the delimiter you specified in the request. If you don't
    #   specify a delimiter in your request, this element is absent from the
    #   response.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, `/` is the only
    #   supported delimiter.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] next_upload_id_marker
    #   When a list is truncated, this element specifies the value that
    #   should be used for the `upload-id-marker` request parameter in a
    #   subsequent request.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] max_uploads
    #   Maximum number of multipart uploads that could have been included in
    #   the response.
    #   @return [Integer]
    #
    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of multipart uploads is
    #   truncated. A value of true indicates that the list was truncated.
    #   The list can be truncated if the number of multipart uploads exceeds
    #   the limit allowed or specified by max uploads.
    #   @return [Boolean]
    #
    # @!attribute [rw] uploads
    #   Container for elements related to a particular multipart upload. A
    #   response can contain zero or more `Upload` elements.
    #   @return [Array<Types::MultipartUpload>]
    #
    # @!attribute [rw] common_prefixes
    #   If you specify a delimiter in the request, then the result returns
    #   each distinct key prefix containing the delimiter in a
    #   `CommonPrefixes` element. The distinct key prefixes are returned in
    #   the `Prefix` child element.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, only prefixes that
    #   end in a delimiter (`/`) are supported.
    #
    #    </note>
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object keys in the
    #   response.
    #
    #   If you specify the `encoding-type` request parameter, Amazon S3
    #   includes this element in the response, and returns encoded key name
    #   values in the following response elements:
    #
    #   `Delimiter`, `KeyMarker`, `Prefix`, `NextKeyMarker`, `Key`.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListMultipartUploadsOutput AWS API Documentation
    #
    class ListMultipartUploadsOutput < Struct.new(
      :bucket,
      :key_marker,
      :upload_id_marker,
      :next_key_marker,
      :prefix,
      :delimiter,
      :next_upload_id_marker,
      :max_uploads,
      :is_truncated,
      :uploads,
      :common_prefixes,
      :encoding_type,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Character you use to group keys.
    #
    #   All keys that contain the same string between the prefix, if
    #   specified, and the first occurrence of the delimiter after the
    #   prefix are grouped under a single result element, `CommonPrefixes`.
    #   If you don't specify the prefix parameter, then the substring
    #   starts at the beginning of the key. The keys that are grouped under
    #   `CommonPrefixes` result element are not returned elsewhere in the
    #   response.
    #
    #   `CommonPrefixes` is filtered out from results if it is not
    #   lexicographically greater than the key-marker.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, `/` is the only
    #   supported delimiter.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode the [object keys][1] in
    #   the response. Responses are encoded only in UTF-8. An object key can
    #   contain any Unicode character. However, the XML 1.0 parser can't
    #   parse certain characters, such as characters with an ASCII value
    #   from 0 to 10. For characters that aren't supported in XML 1.0, you
    #   can add this parameter to request that Amazon S3 encode the keys in
    #   the response. For more information about characters to avoid in
    #   object key names, see [Object key naming guidelines][2].
    #
    #   <note markdown="1"> When using the URL encoding type, non-ASCII characters that are used
    #   in an object's key name will be percent-encoded according to UTF-8
    #   code values. For example, the object `test_file(3).png` will appear
    #   as `test_file%283%29.png`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   Specifies the multipart upload after which listing should begin.
    #
    #   <note markdown="1"> * **General purpose buckets** - For general purpose buckets,
    #     `key-marker` is an object key. Together with `upload-id-marker`,
    #     this parameter specifies the multipart upload after which listing
    #     should begin.
    #
    #     If `upload-id-marker` is not specified, only the keys
    #     lexicographically greater than the specified `key-marker` will be
    #     included in the list.
    #
    #     If `upload-id-marker` is specified, any multipart uploads for a
    #     key equal to the `key-marker` might also be included, provided
    #     those multipart uploads have upload IDs lexicographically greater
    #     than the specified `upload-id-marker`.
    #
    #   * **Directory buckets** - For directory buckets, `key-marker` is
    #     obfuscated and isn't a real object key. The `upload-id-marker`
    #     parameter isn't supported by directory buckets. To list the
    #     additional multipart uploads, you only need to set the value of
    #     `key-marker` to the `NextKeyMarker` value from the previous
    #     response.
    #
    #     In the `ListMultipartUploads` response, the multipart uploads
    #     aren't sorted lexicographically based on the object keys.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] max_uploads
    #   Sets the maximum number of multipart uploads, from 1 to 1,000, to
    #   return in the response body. 1,000 is the maximum number of uploads
    #   that can be returned in a response.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Lists in-progress uploads only for those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different grouping of keys. (You can think of using `prefix` to make
    #   groups in the same way that you'd use a folder in a file system.)
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, only prefixes that
    #   end in a delimiter (`/`) are supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] upload_id_marker
    #   Together with key-marker, specifies the multipart upload after which
    #   listing should begin. If key-marker is not specified, the
    #   upload-id-marker parameter is ignored. Otherwise, any multipart
    #   uploads for a key equal to the key-marker might be included in the
    #   list only if they have an upload ID lexicographically greater than
    #   the specified `upload-id-marker`.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListMultipartUploadsRequest AWS API Documentation
    #
    class ListMultipartUploadsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :key_marker,
      :max_uploads,
      :prefix,
      :upload_id_marker,
      :expected_bucket_owner,
      :request_payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   A flag that indicates whether Amazon S3 returned all of the results
    #   that satisfied the search criteria. If your results were truncated,
    #   you can make a follow-up paginated request by using the
    #   `NextKeyMarker` and `NextVersionIdMarker` response parameters as a
    #   starting place in another request to return the rest of the results.
    #   @return [Boolean]
    #
    # @!attribute [rw] key_marker
    #   Marks the last key returned in a truncated response.
    #   @return [String]
    #
    # @!attribute [rw] version_id_marker
    #   Marks the last version of the key returned in a truncated response.
    #   @return [String]
    #
    # @!attribute [rw] next_key_marker
    #   When the number of responses exceeds the value of `MaxKeys`,
    #   `NextKeyMarker` specifies the first key not returned that satisfies
    #   the search criteria. Use this value for the key-marker request
    #   parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] next_version_id_marker
    #   When the number of responses exceeds the value of `MaxKeys`,
    #   `NextVersionIdMarker` specifies the first object version not
    #   returned that satisfies the search criteria. Use this value for the
    #   `version-id-marker` request parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] versions
    #   Container for version information.
    #   @return [Array<Types::ObjectVersion>]
    #
    # @!attribute [rw] delete_markers
    #   Container for an object that is a delete marker. To learn more about
    #   delete markers, see [Working with delete markers][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html
    #   @return [Array<Types::DeleteMarkerEntry>]
    #
    # @!attribute [rw] name
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Selects objects that start with the value supplied by this
    #   parameter.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   The delimiter grouping the included keys. A delimiter is a character
    #   that you specify to group keys. All keys that contain the same
    #   string between the prefix and the first occurrence of the delimiter
    #   are grouped under a single result element in `CommonPrefixes`. These
    #   groups are counted as one result against the `max-keys` limitation.
    #   These keys are not returned elsewhere in the response.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Specifies the maximum number of objects to return.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys rolled up into a common prefix count as a single
    #   return when calculating the number of returns.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object key names in the
    #   XML response.
    #
    #   If you specify the `encoding-type` request parameter, Amazon S3
    #   includes this element in the response, and returns encoded key name
    #   values in the following response elements:
    #
    #   `KeyMarker, NextKeyMarker, Prefix, Key`, and `Delimiter`.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectVersionsOutput AWS API Documentation
    #
    class ListObjectVersionsOutput < Struct.new(
      :is_truncated,
      :key_marker,
      :version_id_marker,
      :next_key_marker,
      :next_version_id_marker,
      :versions,
      :delete_markers,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name that contains the objects.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character that you specify to group keys. All keys
    #   that contain the same string between the `prefix` and the first
    #   occurrence of the delimiter are grouped under a single result
    #   element in `CommonPrefixes`. These groups are counted as one result
    #   against the `max-keys` limitation. These keys are not returned
    #   elsewhere in the response.
    #
    #   `CommonPrefixes` is filtered out from results if it is not
    #   lexicographically greater than the key-marker.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode the [object keys][1] in
    #   the response. Responses are encoded only in UTF-8. An object key can
    #   contain any Unicode character. However, the XML 1.0 parser can't
    #   parse certain characters, such as characters with an ASCII value
    #   from 0 to 10. For characters that aren't supported in XML 1.0, you
    #   can add this parameter to request that Amazon S3 encode the keys in
    #   the response. For more information about characters to avoid in
    #   object key names, see [Object key naming guidelines][2].
    #
    #   <note markdown="1"> When using the URL encoding type, non-ASCII characters that are used
    #   in an object's key name will be percent-encoded according to UTF-8
    #   code values. For example, the object `test_file(3).png` will appear
    #   as `test_file%283%29.png`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   Specifies the key to start with when listing objects in a bucket.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By
    #   default, the action returns up to 1,000 key names. The response
    #   might contain fewer keys but will never contain more. If additional
    #   keys satisfy the search criteria, but were not returned because
    #   `max-keys` was exceeded, the response contains
    #   `<isTruncated>true</isTruncated>`. To return the additional keys,
    #   see `key-marker` and `version-id-marker`.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Use this parameter to select only those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different groupings of keys. (You can think of using `prefix` to
    #   make groups in the same way that you'd use a folder in a file
    #   system.) You can use `prefix` with `delimiter` to roll up numerous
    #   objects into a single result under `CommonPrefixes`.
    #   @return [String]
    #
    # @!attribute [rw] version_id_marker
    #   Specifies the object version you want to start listing from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] optional_object_attributes
    #   Specifies the optional fields that you want returned in the
    #   response. Fields that you do not specify are not returned.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectVersionsRequest AWS API Documentation
    #
    class ListObjectVersionsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :key_marker,
      :max_keys,
      :prefix,
      :version_id_marker,
      :expected_bucket_owner,
      :request_payer,
      :optional_object_attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   A flag that indicates whether Amazon S3 returned all of the results
    #   that satisfied the search criteria.
    #   @return [Boolean]
    #
    # @!attribute [rw] marker
    #   Indicates where in the bucket listing begins. Marker is included in
    #   the response if it was sent with the request.
    #   @return [String]
    #
    # @!attribute [rw] next_marker
    #   When the response is truncated (the `IsTruncated` element value in
    #   the response is `true`), you can use the key name in this field as
    #   the `marker` parameter in the subsequent request to get the next set
    #   of objects. Amazon S3 lists objects in alphabetical order.
    #
    #   <note markdown="1"> This element is returned only if you have the `delimiter` request
    #   parameter specified. If the response does not include the
    #   `NextMarker` element and it is truncated, you can use the value of
    #   the last `Key` element in the response as the `marker` parameter in
    #   the subsequent request to get the next set of object keys.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] contents
    #   Metadata about each object returned.
    #   @return [Array<Types::Object>]
    #
    # @!attribute [rw] name
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Keys that begin with the indicated prefix.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Causes keys that contain the same string between the prefix and the
    #   first occurrence of the delimiter to be rolled up into a single
    #   result element in the `CommonPrefixes` collection. These rolled-up
    #   keys are not returned elsewhere in the response. Each rolled-up
    #   result counts as only one return against the `MaxKeys` value.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   The maximum number of keys returned in the response body.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys (up to 1,000) rolled up in a common prefix count as
    #   a single return when calculating the number of returns.
    #
    #   A response can contain `CommonPrefixes` only if you specify a
    #   delimiter.
    #
    #   `CommonPrefixes` contains all (if there are any) keys between
    #   `Prefix` and the next occurrence of the string specified by the
    #   delimiter.
    #
    #   `CommonPrefixes` lists keys that act like subdirectories in the
    #   directory specified by `Prefix`.
    #
    #   For example, if the prefix is `notes/` and the delimiter is a slash
    #   (`/`), as in `notes/summer/july`, the common prefix is
    #   `notes/summer/`. All of the keys that roll up into a common prefix
    #   count as a single return when calculating the number of returns.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode the [object keys][1] in
    #   the response. Responses are encoded only in UTF-8. An object key can
    #   contain any Unicode character. However, the XML 1.0 parser can't
    #   parse certain characters, such as characters with an ASCII value
    #   from 0 to 10. For characters that aren't supported in XML 1.0, you
    #   can add this parameter to request that Amazon S3 encode the keys in
    #   the response. For more information about characters to avoid in
    #   object key names, see [Object key naming guidelines][2].
    #
    #   <note markdown="1"> When using the URL encoding type, non-ASCII characters that are used
    #   in an object's key name will be percent-encoded according to UTF-8
    #   code values. For example, the object `test_file(3).png` will appear
    #   as `test_file%283%29.png`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsOutput AWS API Documentation
    #
    class ListObjectsOutput < Struct.new(
      :is_truncated,
      :marker,
      :next_marker,
      :contents,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket containing the objects.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character that you use to group keys.
    #
    #   `CommonPrefixes` is filtered out from results if it is not
    #   lexicographically greater than the key-marker.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode the [object keys][1] in
    #   the response. Responses are encoded only in UTF-8. An object key can
    #   contain any Unicode character. However, the XML 1.0 parser can't
    #   parse certain characters, such as characters with an ASCII value
    #   from 0 to 10. For characters that aren't supported in XML 1.0, you
    #   can add this parameter to request that Amazon S3 encode the keys in
    #   the response. For more information about characters to avoid in
    #   object key names, see [Object key naming guidelines][2].
    #
    #   <note markdown="1"> When using the URL encoding type, non-ASCII characters that are used
    #   in an object's key name will be percent-encoded according to UTF-8
    #   code values. For example, the object `test_file(3).png` will appear
    #   as `test_file%283%29.png`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
    #   @return [String]
    #
    # @!attribute [rw] marker
    #   Marker is where you want Amazon S3 to start listing from. Amazon S3
    #   starts listing after this specified key. Marker can be any key in
    #   the bucket.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By
    #   default, the action returns up to 1,000 key names. The response
    #   might contain fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Limits the response to keys that begin with the specified prefix.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request. Bucket owners need not specify this
    #   parameter in their requests.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] optional_object_attributes
    #   Specifies the optional fields that you want returned in the
    #   response. Fields that you do not specify are not returned.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsRequest AWS API Documentation
    #
    class ListObjectsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :marker,
      :max_keys,
      :prefix,
      :request_payer,
      :expected_bucket_owner,
      :optional_object_attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Set to `false` if all of the results were returned. Set to `true` if
    #   more keys are available to return. If the number of results exceeds
    #   that specified by `MaxKeys`, all of the results might not be
    #   returned.
    #   @return [Boolean]
    #
    # @!attribute [rw] contents
    #   Metadata about each object returned.
    #   @return [Array<Types::Object>]
    #
    # @!attribute [rw] name
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Keys that begin with the indicated prefix.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, only prefixes that
    #   end in a delimiter (`/`) are supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Causes keys that contain the same string between the `prefix` and
    #   the first occurrence of the delimiter to be rolled up into a single
    #   result element in the `CommonPrefixes` collection. These rolled-up
    #   keys are not returned elsewhere in the response. Each rolled-up
    #   result counts as only one return against the `MaxKeys` value.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, `/` is the only
    #   supported delimiter.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By
    #   default, the action returns up to 1,000 key names. The response
    #   might contain fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys (up to 1,000) that share the same prefix are grouped
    #   together. When counting the total numbers of returns by this API
    #   operation, this group of keys is considered as one item.
    #
    #   A response can contain `CommonPrefixes` only if you specify a
    #   delimiter.
    #
    #   `CommonPrefixes` contains all (if there are any) keys between
    #   `Prefix` and the next occurrence of the string specified by a
    #   delimiter.
    #
    #   `CommonPrefixes` lists keys that act like subdirectories in the
    #   directory specified by `Prefix`.
    #
    #   For example, if the prefix is `notes/` and the delimiter is a slash
    #   (`/`) as in `notes/summer/july`, the common prefix is
    #   `notes/summer/`. All of the keys that roll up into a common prefix
    #   count as a single return when calculating the number of returns.
    #
    #   <note markdown="1"> * **Directory buckets** - For directory buckets, only prefixes that
    #     end in a delimiter (`/`) are supported.
    #
    #   * <b>Directory buckets </b> - When you query `ListObjectsV2` with a
    #     delimiter during in-progress multipart uploads, the
    #     `CommonPrefixes` response parameter contains the prefixes that are
    #     associated with the in-progress multipart uploads. For more
    #     information about multipart uploads, see [Multipart Upload
    #     Overview][1] in the *Amazon S3 User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object key names in the
    #   XML response.
    #
    #   If you specify the `encoding-type` request parameter, Amazon S3
    #   includes this element in the response, and returns encoded key name
    #   values in the following response elements:
    #
    #   `Delimiter, Prefix, Key,` and `StartAfter`.
    #   @return [String]
    #
    # @!attribute [rw] key_count
    #   `KeyCount` is the number of keys returned with this request.
    #   `KeyCount` will always be less than or equal to the `MaxKeys` field.
    #   For example, if you ask for 50 keys, your result will include 50
    #   keys or fewer.
    #   @return [Integer]
    #
    # @!attribute [rw] continuation_token
    #   If `ContinuationToken` was sent with the request, it is included in
    #   the response. You can use the returned `ContinuationToken` for
    #   pagination of the list response.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   `NextContinuationToken` is sent when `isTruncated` is true, which
    #   means there are more keys in the bucket that can be listed. The next
    #   list requests to Amazon S3 can be continued with this
    #   `NextContinuationToken`. `NextContinuationToken` is obfuscated and
    #   is not a real key
    #   @return [String]
    #
    # @!attribute [rw] start_after
    #   If StartAfter was sent with the request, it is included in the
    #   response.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsV2Output AWS API Documentation
    #
    class ListObjectsV2Output < Struct.new(
      :is_truncated,
      :contents,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type,
      :key_count,
      :continuation_token,
      :next_continuation_token,
      :start_after,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character that you use to group keys.
    #
    #   `CommonPrefixes` is filtered out from results if it is not
    #   lexicographically greater than the `StartAfter` value.
    #
    #   <note markdown="1"> * **Directory buckets** - For directory buckets, `/` is the only
    #     supported delimiter.
    #
    #   * <b>Directory buckets </b> - When you query `ListObjectsV2` with a
    #     delimiter during in-progress multipart uploads, the
    #     `CommonPrefixes` response parameter contains the prefixes that are
    #     associated with the in-progress multipart uploads. For more
    #     information about multipart uploads, see [Multipart Upload
    #     Overview][1] in the *Amazon S3 User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode the [object keys][1] in
    #   the response. Responses are encoded only in UTF-8. An object key can
    #   contain any Unicode character. However, the XML 1.0 parser can't
    #   parse certain characters, such as characters with an ASCII value
    #   from 0 to 10. For characters that aren't supported in XML 1.0, you
    #   can add this parameter to request that Amazon S3 encode the keys in
    #   the response. For more information about characters to avoid in
    #   object key names, see [Object key naming guidelines][2].
    #
    #   <note markdown="1"> When using the URL encoding type, non-ASCII characters that are used
    #   in an object's key name will be percent-encoded according to UTF-8
    #   code values. For example, the object `test_file(3).png` will appear
    #   as `test_file%283%29.png`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By
    #   default, the action returns up to 1,000 key names. The response
    #   might contain fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Limits the response to keys that begin with the specified prefix.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, only prefixes that
    #   end in a delimiter (`/`) are supported.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   `ContinuationToken` indicates to Amazon S3 that the list is being
    #   continued on this bucket with a token. `ContinuationToken` is
    #   obfuscated and is not a real key. You can use this
    #   `ContinuationToken` for pagination of the list results.
    #   @return [String]
    #
    # @!attribute [rw] fetch_owner
    #   The owner field is not present in `ListObjectsV2` by default. If you
    #   want to return the owner field with each key in the result, then set
    #   the `FetchOwner` field to `true`.
    #
    #   <note markdown="1"> **Directory buckets** - For directory buckets, the bucket owner is
    #   returned as the object owner for all objects.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] start_after
    #   StartAfter is where you want Amazon S3 to start listing from. Amazon
    #   S3 starts listing after this specified key. StartAfter can be any
    #   key in the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request in V2 style. Bucket owners need not specify
    #   this parameter in their requests.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] optional_object_attributes
    #   Specifies the optional fields that you want returned in the
    #   response. Fields that you do not specify are not returned.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsV2Request AWS API Documentation
    #
    class ListObjectsV2Request < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :max_keys,
      :prefix,
      :continuation_token,
      :fetch_owner,
      :start_after,
      :request_payer,
      :expected_bucket_owner,
      :optional_object_attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] abort_date
    #   If the bucket has a lifecycle rule configured with an action to
    #   abort incomplete multipart uploads and the prefix in the lifecycle
    #   rule matches the object name in the request, then the response
    #   includes this header indicating when the initiated multipart upload
    #   will become eligible for abort operation. For more information, see
    #   [Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle
    #   Configuration][1].
    #
    #   The response will also include the `x-amz-abort-rule-id` header that
    #   will provide the ID of the lifecycle configuration rule that defines
    #   this action.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Time]
    #
    # @!attribute [rw] abort_rule_id
    #   This header is returned along with the `x-amz-abort-date` header. It
    #   identifies applicable lifecycle configuration rule that defines the
    #   action to abort incomplete multipart uploads.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #   Does not return the access point ARN or access point alias if used.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose parts are being
    #   listed.
    #   @return [String]
    #
    # @!attribute [rw] part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed.
    #   @return [Integer]
    #
    # @!attribute [rw] next_part_number_marker
    #   When a list is truncated, this element specifies the last part in
    #   the list, as well as the value to use for the `part-number-marker`
    #   request parameter in a subsequent request.
    #   @return [Integer]
    #
    # @!attribute [rw] max_parts
    #   Maximum number of parts that were allowed in the response.
    #   @return [Integer]
    #
    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of parts is truncated. A true
    #   value indicates that the list was truncated. A list can be truncated
    #   if the number of parts exceeds the limit returned in the MaxParts
    #   element.
    #   @return [Boolean]
    #
    # @!attribute [rw] parts
    #   Container for elements related to a particular part. A response can
    #   contain zero or more `Part` elements.
    #   @return [Array<Types::Part>]
    #
    # @!attribute [rw] initiator
    #   Container element that identifies who initiated the multipart
    #   upload. If the initiator is an Amazon Web Services account, this
    #   element provides the same information as the `Owner` element. If the
    #   initiator is an IAM User, this element provides the user ARN.
    #   @return [Types::Initiator]
    #
    # @!attribute [rw] owner
    #   Container element that identifies the object owner, after the object
    #   is created. If multipart upload is initiated by an IAM user, this
    #   element provides the parent account ID.
    #
    #   <note markdown="1"> **Directory buckets** - The bucket owner is returned as the object
    #   owner for all the parts.
    #
    #    </note>
    #   @return [Types::Owner]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the uploaded object.
    #
    #   <note markdown="1"> **Directory buckets** - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The algorithm that was used to create a checksum of the object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type, which determines how part-level checksums are
    #   combined to create an object-level checksum for multipart objects.
    #   You can use this header response to verify that the checksum type
    #   that is received is the same checksum type that was specified in
    #   `CreateMultipartUpload` request. For more information, see [Checking
    #   object integrity in the Amazon S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListPartsOutput AWS API Documentation
    #
    class ListPartsOutput < Struct.new(
      :abort_date,
      :abort_rule_id,
      :bucket,
      :key,
      :upload_id,
      :part_number_marker,
      :next_part_number_marker,
      :max_parts,
      :is_truncated,
      :parts,
      :initiator,
      :owner,
      :storage_class,
      :request_charged,
      :checksum_algorithm,
      :checksum_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket to which the parts are being uploaded.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] max_parts
    #   Sets the maximum number of parts to return.
    #   @return [Integer]
    #
    # @!attribute [rw] part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose parts are being
    #   listed.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the
    #   object. This parameter is needed only when the object was created
    #   using a checksum algorithm. For more information, see [Protecting
    #   data using SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListPartsRequest AWS API Documentation
    #
    class ListPartsRequest < Struct.new(
      :bucket,
      :key,
      :max_parts,
      :part_number_marker,
      :upload_id,
      :request_payer,
      :expected_bucket_owner,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Specifies the location where the bucket will be created.
    #
    # For directory buckets, the location type is Availability Zone or Local
    # Zone. For more information about directory buckets, see [Working with
    # directory buckets][1] in the *Amazon S3 User Guide*.
    #
    # <note markdown="1"> This functionality is only supported by directory buckets.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html
    #
    # @!attribute [rw] type
    #   The type of location where the bucket will be created.
    #   @return [String]
    #
    # @!attribute [rw] name
    #   The name of the location where the bucket will be created.
    #
    #   For directory buckets, the name of the location is the Zone ID of
    #   the Availability Zone (AZ) or Local Zone (LZ) where the bucket will
    #   be created. An example AZ ID value is `usw2-az1`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LocationInfo AWS API Documentation
    #
    class LocationInfo < Struct.new(
      :type,
      :name)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes where logs are stored and the prefix that Amazon S3 assigns
    # to all log object keys for a bucket. For more information, see [PUT
    # Bucket logging][1] in the *Amazon S3 API Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #
    # @!attribute [rw] target_bucket
    #   Specifies the bucket where you want Amazon S3 to store server access
    #   logs. You can have your logs delivered to any bucket that you own,
    #   including the same bucket that is being logged. You can also
    #   configure multiple buckets to deliver their logs to the same target
    #   bucket. In this case, you should choose a different `TargetPrefix`
    #   for each source bucket so that the delivered log files can be
    #   distinguished by key.
    #   @return [String]
    #
    # @!attribute [rw] target_grants
    #   Container for granting information.
    #
    #   Buckets that use the bucket owner enforced setting for Object
    #   Ownership don't support target grants. For more information, see
    #   [Permissions for server access log delivery][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
    #   @return [Array<Types::TargetGrant>]
    #
    # @!attribute [rw] target_prefix
    #   A prefix for all log object keys. If you store log files from
    #   multiple Amazon S3 buckets in a single bucket, you can use a prefix
    #   to distinguish which log files came from which bucket.
    #   @return [String]
    #
    # @!attribute [rw] target_object_key_format
    #   Amazon S3 key format for log objects.
    #   @return [Types::TargetObjectKeyFormat]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LoggingEnabled AWS API Documentation
    #
    class LoggingEnabled < Struct.new(
      :target_bucket,
      :target_grants,
      :target_prefix,
      :target_object_key_format)
      SENSITIVE = []
      include Aws::Structure
    end

    # The S3 Metadata configuration for a general purpose bucket.
    #
    # @!attribute [rw] journal_table_configuration
    #   The journal table configuration for a metadata configuration.
    #   @return [Types::JournalTableConfiguration]
    #
    # @!attribute [rw] inventory_table_configuration
    #   The inventory table configuration for a metadata configuration.
    #   @return [Types::InventoryTableConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataConfiguration AWS API Documentation
    #
    class MetadataConfiguration < Struct.new(
      :journal_table_configuration,
      :inventory_table_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # The S3 Metadata configuration for a general purpose bucket.
    #
    # @!attribute [rw] destination_result
    #   The destination settings for a metadata configuration.
    #   @return [Types::DestinationResult]
    #
    # @!attribute [rw] journal_table_configuration_result
    #   The journal table configuration for a metadata configuration.
    #   @return [Types::JournalTableConfigurationResult]
    #
    # @!attribute [rw] inventory_table_configuration_result
    #   The inventory table configuration for a metadata configuration.
    #   @return [Types::InventoryTableConfigurationResult]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataConfigurationResult AWS API Documentation
    #
    class MetadataConfigurationResult < Struct.new(
      :destination_result,
      :journal_table_configuration_result,
      :inventory_table_configuration_result)
      SENSITIVE = []
      include Aws::Structure
    end

    # A metadata key-value pair to store with an object.
    #
    # @!attribute [rw] name
    #   Name of the object.
    #   @return [String]
    #
    # @!attribute [rw] value
    #   Value of the object.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataEntry AWS API Documentation
    #
    class MetadataEntry < Struct.new(
      :name,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # The V1 S3 Metadata configuration for a general purpose bucket.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] s3_tables_destination
    #   The destination information for the metadata table configuration.
    #   The destination table bucket must be in the same Region and Amazon
    #   Web Services account as the general purpose bucket. The specified
    #   metadata table name must be unique within the `aws_s3_metadata`
    #   namespace in the destination table bucket.
    #   @return [Types::S3TablesDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataTableConfiguration AWS API Documentation
    #
    class MetadataTableConfiguration < Struct.new(
      :s3_tables_destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # The V1 S3 Metadata configuration for a general purpose bucket. The
    # destination table bucket must be in the same Region and Amazon Web
    # Services account as the general purpose bucket. The specified metadata
    # table name must be unique within the `aws_s3_metadata` namespace in
    # the destination table bucket.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] s3_tables_destination_result
    #   The destination information for the metadata table configuration.
    #   The destination table bucket must be in the same Region and Amazon
    #   Web Services account as the general purpose bucket. The specified
    #   metadata table name must be unique within the `aws_s3_metadata`
    #   namespace in the destination table bucket.
    #   @return [Types::S3TablesDestinationResult]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataTableConfigurationResult AWS API Documentation
    #
    class MetadataTableConfigurationResult < Struct.new(
      :s3_tables_destination_result)
      SENSITIVE = []
      include Aws::Structure
    end

    # The encryption settings for an S3 Metadata journal table or inventory
    # table configuration.
    #
    # @!attribute [rw] sse_algorithm
    #   The encryption type specified for a metadata table. To specify
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS), use the `aws:kms` value. To specify server-side
    #   encryption with Amazon S3 managed keys (SSE-S3), use the `AES256`
    #   value.
    #   @return [String]
    #
    # @!attribute [rw] kms_key_arn
    #   If server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS) is specified, you must also specify the KMS key Amazon
    #   Resource Name (ARN). You must specify a customer-managed KMS key
    #   that's located in the same Region as the general purpose bucket
    #   that corresponds to the metadata table configuration.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataTableEncryptionConfiguration AWS API Documentation
    #
    class MetadataTableEncryptionConfiguration < Struct.new(
      :sse_algorithm,
      :kms_key_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying replication metrics-related settings enabling
    # replication metrics and events.
    #
    # @!attribute [rw] status
    #   Specifies whether the replication metrics are enabled.
    #   @return [String]
    #
    # @!attribute [rw] event_threshold
    #   A container specifying the time threshold for emitting the
    #   `s3:Replication:OperationMissedThreshold` event.
    #   @return [Types::ReplicationTimeValue]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Metrics AWS API Documentation
    #
    class Metrics < Struct.new(
      :status,
      :event_threshold)
      SENSITIVE = []
      include Aws::Structure
    end

    # A conjunction (logical AND) of predicates, which is used in evaluating
    # a metrics filter. The operator must have at least two predicates, and
    # an object must match all of the predicates in order for the filter to
    # apply.
    #
    # @!attribute [rw] prefix
    #   The prefix used when evaluating an AND predicate.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   The list of tags used when evaluating an AND predicate.
    #
    #   <note markdown="1"> `Tag` filters are not supported for directory buckets.
    #
    #    </note>
    #   @return [Array<Types::Tag>]
    #
    # @!attribute [rw] access_point_arn
    #   The access point ARN used when evaluating an `AND` predicate.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsAndOperator AWS API Documentation
    #
    class MetricsAndOperator < Struct.new(
      :prefix,
      :tags,
      :access_point_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a metrics configuration for the CloudWatch request metrics
    # (specified by the metrics configuration ID) from an Amazon S3 bucket.
    # If you're updating an existing metrics configuration, note that this
    # is a full replacement of the existing metrics configuration. If you
    # don't include the elements you want to keep, they are erased. For
    # more information, see [PutBucketMetricsConfiguration][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTMetricConfiguration.html
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   Specifies a metrics configuration filter. The metrics configuration
    #   will only include objects that meet the filter's criteria. A filter
    #   must be a prefix, an object tag, an access point ARN, or a
    #   conjunction (MetricsAndOperator).
    #
    #   <note markdown="1"> Metrics configurations for directory buckets do not support tag
    #   filters.
    #
    #    </note>
    #   @return [Types::MetricsFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsConfiguration AWS API Documentation
    #
    class MetricsConfiguration < Struct.new(
      :id,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a metrics configuration filter. The metrics configuration
    # only includes objects that meet the filter's criteria. A filter must
    # be a prefix, an object tag, an access point ARN, or a conjunction
    # (MetricsAndOperator). For more information, see
    # [PutBucketMetricsConfiguration][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html
    #
    # @!attribute [rw] prefix
    #   The prefix used when evaluating a metrics filter.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   The tag used when evaluating a metrics filter.
    #
    #   <note markdown="1"> `Tag` filters are not supported for directory buckets.
    #
    #    </note>
    #   @return [Types::Tag]
    #
    # @!attribute [rw] access_point_arn
    #   The access point ARN used when evaluating a metrics filter.
    #   @return [String]
    #
    # @!attribute [rw] and
    #   A conjunction (logical AND) of predicates, which is used in
    #   evaluating a metrics filter. The operator must have at least two
    #   predicates, and an object must match all of the predicates in order
    #   for the filter to apply.
    #   @return [Types::MetricsAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsFilter AWS API Documentation
    #
    class MetricsFilter < Struct.new(
      :prefix,
      :tag,
      :access_point_arn,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the `MultipartUpload` for the Amazon S3 object.
    #
    # @!attribute [rw] upload_id
    #   Upload ID that identifies the multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key of the object for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] initiated
    #   Date and time at which the multipart upload was initiated.
    #   @return [Time]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #
    #   <note markdown="1"> **Directory buckets** - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] owner
    #   Specifies the owner of the object that is part of the multipart
    #   upload.
    #
    #   <note markdown="1"> **Directory buckets** - The bucket owner is returned as the object
    #   owner for all the objects.
    #
    #    </note>
    #   @return [Types::Owner]
    #
    # @!attribute [rw] initiator
    #   Identifies who initiated the multipart upload.
    #   @return [Types::Initiator]
    #
    # @!attribute [rw] checksum_algorithm
    #   The algorithm that was used to create a checksum of the object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type that is used to calculate the object’s checksum
    #   value. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MultipartUpload AWS API Documentation
    #
    class MultipartUpload < Struct.new(
      :upload_id,
      :key,
      :initiated,
      :storage_class,
      :owner,
      :initiator,
      :checksum_algorithm,
      :checksum_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # The specified bucket does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchBucket AWS API Documentation
    #
    class NoSuchBucket < Aws::EmptyStructure; end

    # The specified key does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchKey AWS API Documentation
    #
    class NoSuchKey < Aws::EmptyStructure; end

    # The specified multipart upload does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchUpload AWS API Documentation
    #
    class NoSuchUpload < Aws::EmptyStructure; end

    # Specifies when noncurrent object versions expire. Upon expiration,
    # Amazon S3 permanently deletes the noncurrent object versions. You set
    # this lifecycle configuration action on a bucket that has versioning
    # enabled (or suspended) to request that Amazon S3 delete noncurrent
    # object versions at a specific period in the object's lifetime.
    #
    # <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    # supported for directory bucket lifecycle configurations.
    #
    #  </note>
    #
    # @!attribute [rw] noncurrent_days
    #   Specifies the number of days an object is noncurrent before Amazon
    #   S3 can perform the associated action. The value must be a non-zero
    #   positive integer. For information about the noncurrent days
    #   calculations, see [How Amazon S3 Calculates When an Object Became
    #   Noncurrent][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#non-current-days-calculations
    #   @return [Integer]
    #
    # @!attribute [rw] newer_noncurrent_versions
    #   Specifies how many noncurrent versions Amazon S3 will retain. You
    #   can specify up to 100 noncurrent versions to retain. Amazon S3 will
    #   permanently delete any additional noncurrent versions beyond the
    #   specified number to retain. For more information about noncurrent
    #   versions, see [Lifecycle configuration elements][1] in the *Amazon
    #   S3 User Guide*.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/intro-lifecycle-rules.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoncurrentVersionExpiration AWS API Documentation
    #
    class NoncurrentVersionExpiration < Struct.new(
      :noncurrent_days,
      :newer_noncurrent_versions)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the transition rule that describes when noncurrent
    # objects transition to the `STANDARD_IA`, `ONEZONE_IA`,
    # `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`, or `DEEP_ARCHIVE`
    # storage class. If your bucket is versioning-enabled (or versioning is
    # suspended), you can set this action to request that Amazon S3
    # transition noncurrent object versions to the `STANDARD_IA`,
    # `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`, or
    # `DEEP_ARCHIVE` storage class at a specific period in the object's
    # lifetime.
    #
    # @!attribute [rw] noncurrent_days
    #   Specifies the number of days an object is noncurrent before Amazon
    #   S3 can perform the associated action. For information about the
    #   noncurrent days calculations, see [How Amazon S3 Calculates How Long
    #   an Object Has Been Noncurrent][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#non-current-days-calculations
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @!attribute [rw] newer_noncurrent_versions
    #   Specifies how many noncurrent versions Amazon S3 will retain in the
    #   same storage class before transitioning objects. You can specify up
    #   to 100 noncurrent versions to retain. Amazon S3 will transition any
    #   additional noncurrent versions beyond the specified number to
    #   retain. For more information about noncurrent versions, see
    #   [Lifecycle configuration elements][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/intro-lifecycle-rules.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoncurrentVersionTransition AWS API Documentation
    #
    class NoncurrentVersionTransition < Struct.new(
      :noncurrent_days,
      :storage_class,
      :newer_noncurrent_versions)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the notification configuration of the
    # bucket. If this element is empty, notifications are turned off for the
    # bucket.
    #
    # @!attribute [rw] topic_configurations
    #   The topic to which notifications are sent and the events for which
    #   notifications are generated.
    #   @return [Array<Types::TopicConfiguration>]
    #
    # @!attribute [rw] queue_configurations
    #   The Amazon Simple Queue Service queues to publish messages to and
    #   the events for which to publish messages.
    #   @return [Array<Types::QueueConfiguration>]
    #
    # @!attribute [rw] lambda_function_configurations
    #   Describes the Lambda functions to invoke and the events for which to
    #   invoke them.
    #   @return [Array<Types::LambdaFunctionConfiguration>]
    #
    # @!attribute [rw] event_bridge_configuration
    #   Enables delivery of events to Amazon EventBridge.
    #   @return [Types::EventBridgeConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfiguration AWS API Documentation
    #
    class NotificationConfiguration < Struct.new(
      :topic_configurations,
      :queue_configurations,
      :lambda_function_configurations,
      :event_bridge_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] topic_configuration
    #   This data type is deprecated. A container for specifying the
    #   configuration for publication of messages to an Amazon Simple
    #   Notification Service (Amazon SNS) topic when Amazon S3 detects
    #   specified events.
    #   @return [Types::TopicConfigurationDeprecated]
    #
    # @!attribute [rw] queue_configuration
    #   This data type is deprecated. This data type specifies the
    #   configuration for publishing messages to an Amazon Simple Queue
    #   Service (Amazon SQS) queue when Amazon S3 detects specified events.
    #   @return [Types::QueueConfigurationDeprecated]
    #
    # @!attribute [rw] cloud_function_configuration
    #   Container for specifying the Lambda notification configuration.
    #   @return [Types::CloudFunctionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfigurationDeprecated AWS API Documentation
    #
    class NotificationConfigurationDeprecated < Struct.new(
      :topic_configuration,
      :queue_configuration,
      :cloud_function_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies object key name filtering rules. For information about key
    # name filtering, see [Configuring event notifications using object key
    # name filtering][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-filtering.html
    #
    # @!attribute [rw] key
    #   A container for object key name prefix and suffix filtering rules.
    #   @return [Types::S3KeyFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfigurationFilter AWS API Documentation
    #
    class NotificationConfigurationFilter < Struct.new(
      :key)
      SENSITIVE = []
      include Aws::Structure
    end

    # An object consists of data and its descriptive metadata.
    #
    # @!attribute [rw] key
    #   The name that you assign to an object. You use the object key to
    #   retrieve the object.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Creation date of the object.
    #   @return [Time]
    #
    # @!attribute [rw] etag
    #   The entity tag is a hash of the object. The ETag reflects changes
    #   only to the contents of an object, not its metadata. The ETag may or
    #   may not be an MD5 digest of the object data. Whether or not it is
    #   depends on how the object was created and how it is encrypted as
    #   described below:
    #
    #   * Objects created by the PUT Object, POST Object, or Copy operation,
    #     or through the Amazon Web Services Management Console, and are
    #     encrypted by SSE-S3 or plaintext, have ETags that are an MD5
    #     digest of their object data.
    #
    #   * Objects created by the PUT Object, POST Object, or Copy operation,
    #     or through the Amazon Web Services Management Console, and are
    #     encrypted by SSE-C or SSE-KMS, have ETags that are not an MD5
    #     digest of their object data.
    #
    #   * If an object is created by either the Multipart Upload or Part
    #     Copy operation, the ETag is not an MD5 digest, regardless of the
    #     method of encryption. If an object is larger than 16 MB, the
    #     Amazon Web Services Management Console will upload or copy that
    #     object as a Multipart Upload, and therefore the ETag will not be
    #     an MD5 digest.
    #
    #   <note markdown="1"> **Directory buckets** - MD5 is not supported by directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The algorithm that was used to create a checksum of the object.
    #   @return [Array<String>]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type that is used to calculate the object’s checksum
    #   value. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the object
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #
    #   <note markdown="1"> **Directory buckets** - Directory buckets only support
    #   `EXPRESS_ONEZONE` (the S3 Express One Zone storage class) in
    #   Availability Zones and `ONEZONE_IA` (the S3 One Zone-Infrequent
    #   Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] owner
    #   The owner of the object
    #
    #   <note markdown="1"> **Directory buckets** - The bucket owner is returned as the object
    #   owner.
    #
    #    </note>
    #   @return [Types::Owner]
    #
    # @!attribute [rw] restore_status
    #   Specifies the restoration status of an object. Objects in certain
    #   storage classes must be restored before they can be retrieved. For
    #   more information about these storage classes and how to work with
    #   archived objects, see [ Working with archived objects][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets only support `EXPRESS_ONEZONE` (the S3 Express One Zone
    #   storage class) in Availability Zones and `ONEZONE_IA` (the S3 One
    #   Zone-Infrequent Access storage class) in Dedicated Local Zones.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/archived-objects.html
    #   @return [Types::RestoreStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Object AWS API Documentation
    #
    class Object < Struct.new(
      :key,
      :last_modified,
      :etag,
      :checksum_algorithm,
      :checksum_type,
      :size,
      :storage_class,
      :owner,
      :restore_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # This action is not allowed against this storage tier.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectAlreadyInActiveTierError AWS API Documentation
    #
    class ObjectAlreadyInActiveTierError < Aws::EmptyStructure; end

    # The updated server-side encryption type for this object. The
    # `UpdateObjectEncryption` operation supports the SSE-S3 and SSE-KMS
    # encryption types.
    #
    # Valid Values: `SSES3` \| `SSEKMS`
    #
    # @note ObjectEncryption is a union - when making an API calls you must set exactly one of the members.
    #
    # @!attribute [rw] ssekms
    #   Specifies to update the object encryption type to server-side
    #   encryption with Key Management Service (KMS) keys (SSE-KMS).
    #   @return [Types::SSEKMSEncryption]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectEncryption AWS API Documentation
    #
    class ObjectEncryption < Struct.new(
      :ssekms,
      :unknown)
      SENSITIVE = []
      include Aws::Structure
      include Aws::Structure::Union

      class Ssekms < ObjectEncryption; end
      class Unknown < ObjectEncryption; end
    end

    # Object Identifier is unique value to identify objects.
    #
    # @!attribute [rw] key
    #   Key name of the object.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID for the specific version of the object to delete.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   An entity tag (ETag) is an identifier assigned by a web server to a
    #   specific version of a resource found at a URL. This header field
    #   makes the request method conditional on `ETags`.
    #
    #   <note markdown="1"> Entity tags (ETags) for S3 Express One Zone are random alphanumeric
    #   strings unique to the object.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] last_modified_time
    #   If present, the objects are deleted only if its modification times
    #   matches the provided `Timestamp`.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] size
    #   If present, the objects are deleted only if its size matches the
    #   provided size in bytes.
    #
    #   <note markdown="1"> This functionality is only supported for directory buckets.
    #
    #    </note>
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectIdentifier AWS API Documentation
    #
    class ObjectIdentifier < Struct.new(
      :key,
      :version_id,
      :etag,
      :last_modified_time,
      :size)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for Object Lock configuration parameters.
    #
    # @!attribute [rw] object_lock_enabled
    #   Indicates whether this bucket has an Object Lock configuration
    #   enabled. Enable `ObjectLockEnabled` when you apply
    #   `ObjectLockConfiguration` to a bucket.
    #   @return [String]
    #
    # @!attribute [rw] rule
    #   Specifies the Object Lock rule for the specified object. Enable the
    #   this rule when you apply `ObjectLockConfiguration` to a bucket.
    #   Bucket settings require both a mode and a period. The period can be
    #   either `Days` or `Years` but you must select one. You cannot specify
    #   `Days` and `Years` at the same time.
    #   @return [Types::ObjectLockRule]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockConfiguration AWS API Documentation
    #
    class ObjectLockConfiguration < Struct.new(
      :object_lock_enabled,
      :rule)
      SENSITIVE = []
      include Aws::Structure
    end

    # A legal hold configuration for an object.
    #
    # @!attribute [rw] status
    #   Indicates whether the specified object has a legal hold in place.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockLegalHold AWS API Documentation
    #
    class ObjectLockLegalHold < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # A Retention configuration for an object.
    #
    # @!attribute [rw] mode
    #   Indicates the Retention mode for the specified object.
    #   @return [String]
    #
    # @!attribute [rw] retain_until_date
    #   The date on which this Object Lock Retention will expire.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockRetention AWS API Documentation
    #
    class ObjectLockRetention < Struct.new(
      :mode,
      :retain_until_date)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for an Object Lock rule.
    #
    # @!attribute [rw] default_retention
    #   The default Object Lock retention mode and period that you want to
    #   apply to new objects placed in the specified bucket. Bucket settings
    #   require both a mode and a period. The period can be either `Days` or
    #   `Years` but you must select one. You cannot specify `Days` and
    #   `Years` at the same time.
    #   @return [Types::DefaultRetention]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockRule AWS API Documentation
    #
    class ObjectLockRule < Struct.new(
      :default_retention)
      SENSITIVE = []
      include Aws::Structure
    end

    # The source object of the COPY action is not in the active tier and is
    # only stored in Amazon S3 Glacier.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectNotInActiveTierError AWS API Documentation
    #
    class ObjectNotInActiveTierError < Aws::EmptyStructure; end

    # A container for elements related to an individual part.
    #
    # @!attribute [rw] part_number
    #   The part number identifying the part. This value is a positive
    #   integer between 1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] size
    #   The size of the uploaded part in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC32` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC32C` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC64NVME` checksum algorithm, or if the object was uploaded
    #   without a checksum (and Amazon S3 added the default checksum,
    #   `CRC64NVME`, to the uploaded object). For more information, see
    #   [Checking object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `SHA1` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `SHA256` checksum algorithm. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectPart AWS API Documentation
    #
    class ObjectPart < Struct.new(
      :part_number,
      :size,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256)
      SENSITIVE = []
      include Aws::Structure
    end

    # The version of an object.
    #
    # @!attribute [rw] etag
    #   The entity tag is an MD5 hash of that version of the object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The algorithm that was used to create a checksum of the object.
    #   @return [Array<String>]
    #
    # @!attribute [rw] checksum_type
    #   The checksum type that is used to calculate the object’s checksum
    #   value. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the object.
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of an object.
    #   @return [String]
    #
    # @!attribute [rw] is_latest
    #   Specifies whether the object is (true) or is not (false) the latest
    #   version of an object.
    #   @return [Boolean]
    #
    # @!attribute [rw] last_modified
    #   Date and time when the object was last modified.
    #   @return [Time]
    #
    # @!attribute [rw] owner
    #   Specifies the owner of the object.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] restore_status
    #   Specifies the restoration status of an object. Objects in certain
    #   storage classes must be restored before they can be retrieved. For
    #   more information about these storage classes and how to work with
    #   archived objects, see [ Working with archived objects][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/archived-objects.html
    #   @return [Types::RestoreStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectVersion AWS API Documentation
    #
    class ObjectVersion < Struct.new(
      :etag,
      :checksum_algorithm,
      :checksum_type,
      :size,
      :storage_class,
      :key,
      :version_id,
      :is_latest,
      :last_modified,
      :owner,
      :restore_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the location where the restore job's output is stored.
    #
    # @!attribute [rw] s3
    #   Describes an S3 location that will receive the results of the
    #   restore request.
    #   @return [Types::S3Location]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OutputLocation AWS API Documentation
    #
    class OutputLocation < Struct.new(
      :s3)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how results of the Select job are serialized.
    #
    # @!attribute [rw] csv
    #   Describes the serialization of CSV-encoded Select results.
    #   @return [Types::CSVOutput]
    #
    # @!attribute [rw] json
    #   Specifies JSON as request's output serialization format.
    #   @return [Types::JSONOutput]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OutputSerialization AWS API Documentation
    #
    class OutputSerialization < Struct.new(
      :csv,
      :json)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the owner's display name and ID.
    #
    # @!attribute [rw] display_name
    #   @return [String]
    #
    # @!attribute [rw] id
    #   Container for the ID of the owner.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Owner AWS API Documentation
    #
    class Owner < Struct.new(
      :display_name,
      :id)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for a bucket's ownership controls.
    #
    # @!attribute [rw] rules
    #   The container element for an ownership control rule.
    #   @return [Array<Types::OwnershipControlsRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OwnershipControls AWS API Documentation
    #
    class OwnershipControls < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for an ownership control rule.
    #
    # @!attribute [rw] object_ownership
    #   The container element for object ownership for a bucket's ownership
    #   controls.
    #
    #   `BucketOwnerPreferred` - Objects uploaded to the bucket change
    #   ownership to the bucket owner if the objects are uploaded with the
    #   `bucket-owner-full-control` canned ACL.
    #
    #   `ObjectWriter` - The uploading account will own the object if the
    #   object is uploaded with the `bucket-owner-full-control` canned ACL.
    #
    #   `BucketOwnerEnforced` - Access control lists (ACLs) are disabled and
    #   no longer affect permissions. The bucket owner automatically owns
    #   and has full control over every object in the bucket. The bucket
    #   only accepts PUT requests that don't specify an ACL or specify
    #   bucket owner full control ACLs (such as the predefined
    #   `bucket-owner-full-control` canned ACL or a custom ACL in XML format
    #   that grants the same permissions).
    #
    #   By default, `ObjectOwnership` is set to `BucketOwnerEnforced` and
    #   ACLs are disabled. We recommend keeping ACLs disabled, except in
    #   uncommon use cases where you must control access for each object
    #   individually. For more information about S3 Object Ownership, see
    #   [Controlling ownership of objects and disabling ACLs for your
    #   bucket][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets use the bucket owner enforced setting for S3 Object
    #   Ownership.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OwnershipControlsRule AWS API Documentation
    #
    class OwnershipControlsRule < Struct.new(
      :object_ownership)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for Parquet.
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ParquetInput AWS API Documentation
    #
    class ParquetInput < Aws::EmptyStructure; end

    # Container for elements related to a part.
    #
    # @!attribute [rw] part_number
    #   Part number identifying the part. This is a positive integer between
    #   1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] last_modified
    #   Date and time at which the part was uploaded.
    #   @return [Time]
    #
    # @!attribute [rw] etag
    #   Entity tag returned when the part was uploaded.
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the uploaded part data.
    #   @return [Integer]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32` checksum of the part. This
    #   checksum is present if the object was uploaded with the `CRC32`
    #   checksum algorithm. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the part. This
    #   checksum is present if the object was uploaded with the `CRC32C`
    #   checksum algorithm. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the part. This
    #   checksum is present if the multipart upload request was created with
    #   the `CRC64NVME` checksum algorithm, or if the object was uploaded
    #   without a checksum (and Amazon S3 added the default checksum,
    #   `CRC64NVME`, to the uploaded object). For more information, see
    #   [Checking object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` checksum of the part. This
    #   checksum is present if the object was uploaded with the `SHA1`
    #   checksum algorithm. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` checksum of the part. This
    #   checksum is present if the object was uploaded with the `SHA256`
    #   checksum algorithm. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Part AWS API Documentation
    #
    class Part < Struct.new(
      :part_number,
      :last_modified,
      :etag,
      :size,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256)
      SENSITIVE = []
      include Aws::Structure
    end

    # Amazon S3 keys for log objects are partitioned in the following
    # format:
    #
    # `[DestinationPrefix][SourceAccountId]/[SourceRegion]/[SourceBucket]/[YYYY]/[MM]/[DD]/[YYYY]-[MM]-[DD]-[hh]-[mm]-[ss]-[UniqueString]`
    #
    # PartitionedPrefix defaults to EventTime delivery when server access
    # logs are delivered.
    #
    # @!attribute [rw] partition_date_source
    #   Specifies the partition date source for the partitioned prefix.
    #   `PartitionDateSource` can be `EventTime` or `DeliveryTime`.
    #
    #   For `DeliveryTime`, the time in the log file names corresponds to
    #   the delivery time for the log files.
    #
    #   For `EventTime`, The logs delivered are for a specific day only. The
    #   year, month, and day correspond to the day on which the event
    #   occurred, and the hour, minutes and seconds are set to 00 in the
    #   key.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PartitionedPrefix AWS API Documentation
    #
    class PartitionedPrefix < Struct.new(
      :partition_date_source)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for a bucket's policy status.
    #
    # @!attribute [rw] is_public
    #   The policy status for this bucket. `TRUE` indicates that this bucket
    #   is public. `FALSE` indicates that the bucket is not public.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PolicyStatus AWS API Documentation
    #
    class PolicyStatus < Struct.new(
      :is_public)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type contains information about progress of an operation.
    #
    # @!attribute [rw] bytes_scanned
    #   The current number of object bytes scanned.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_processed
    #   The current number of uncompressed object bytes processed.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_returned
    #   The current number of bytes of records payload data returned.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Progress AWS API Documentation
    #
    class Progress < Struct.new(
      :bytes_scanned,
      :bytes_processed,
      :bytes_returned)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type contains information about the progress event of an
    # operation.
    #
    # @!attribute [rw] details
    #   The Progress event details.
    #   @return [Types::Progress]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ProgressEvent AWS API Documentation
    #
    class ProgressEvent < Struct.new(
      :details,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # The PublicAccessBlock configuration that you want to apply to this
    # Amazon S3 bucket. You can enable the configuration options in any
    # combination. Bucket-level settings work alongside account-level
    # settings (which may inherit from organization-level policies). For
    # more information about when Amazon S3 considers a bucket or object
    # public, see [The Meaning of "Public"][1] in the *Amazon S3 User
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    #
    # @!attribute [rw] block_public_acls
    #   Specifies whether Amazon S3 should block public access control lists
    #   (ACLs) for this bucket and objects in this bucket. Setting this
    #   element to `TRUE` causes the following behavior:
    #
    #   * PUT Bucket ACL and PUT Object ACL calls fail if the specified ACL
    #     is public.
    #
    #   * PUT Object calls fail if the request includes a public ACL.
    #
    #   * PUT Bucket calls fail if the request includes a public ACL.
    #
    #   Enabling this setting doesn't affect existing policies or ACLs.
    #   @return [Boolean]
    #
    # @!attribute [rw] ignore_public_acls
    #   Specifies whether Amazon S3 should ignore public ACLs for this
    #   bucket and objects in this bucket. Setting this element to `TRUE`
    #   causes Amazon S3 to ignore all public ACLs on this bucket and
    #   objects in this bucket.
    #
    #   Enabling this setting doesn't affect the persistence of any
    #   existing ACLs and doesn't prevent new public ACLs from being set.
    #   @return [Boolean]
    #
    # @!attribute [rw] block_public_policy
    #   Specifies whether Amazon S3 should block public bucket policies for
    #   this bucket. Setting this element to `TRUE` causes Amazon S3 to
    #   reject calls to PUT Bucket policy if the specified bucket policy
    #   allows public access.
    #
    #   Enabling this setting doesn't affect existing bucket policies.
    #   @return [Boolean]
    #
    # @!attribute [rw] restrict_public_buckets
    #   Specifies whether Amazon S3 should restrict public bucket policies
    #   for this bucket. Setting this element to `TRUE` restricts access to
    #   this bucket to only Amazon Web Services service principals and
    #   authorized users within this account if the bucket has a public
    #   policy.
    #
    #   Enabling this setting doesn't affect previously stored bucket
    #   policies, except that public and cross-account access within any
    #   public bucket policy, including non-public delegation to specific
    #   accounts, is blocked.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PublicAccessBlockConfiguration AWS API Documentation
    #
    class PublicAccessBlockConfiguration < Struct.new(
      :block_public_acls,
      :ignore_public_acls,
      :block_public_policy,
      :restrict_public_buckets)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the general purpose bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutBucketAbac` request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm that you want Amazon S3 to use to create the
    #   checksum. For more information, see [ Checking object integrity][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The Amazon Web Services account ID of the general purpose bucket's
    #   owner.
    #   @return [String]
    #
    # @!attribute [rw] abac_status
    #   The ABAC status of the general purpose bucket. When ABAC is enabled
    #   for the general purpose bucket, you can use tags to manage access to
    #   the general purpose buckets as well as for cost tracking purposes.
    #   When ABAC is disabled for the general purpose buckets, you can only
    #   use tags for cost tracking purposes. For more information, see
    #   [Using tags with S3 general purpose buckets][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/buckets-tagging.html
    #   @return [Types::AbacStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAbacRequest AWS API Documentation
    #
    class PutBucketAbacRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner,
      :abac_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which the accelerate configuration is
    #   set.
    #   @return [String]
    #
    # @!attribute [rw] accelerate_configuration
    #   Container for setting the transfer acceleration state.
    #   @return [Types::AccelerateConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAccelerateConfigurationRequest AWS API Documentation
    #
    class PutBucketAccelerateConfigurationRequest < Struct.new(
      :bucket,
      :accelerate_configuration,
      :expected_bucket_owner,
      :checksum_algorithm)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] acl
    #   The canned ACL to apply to the bucket.
    #   @return [String]
    #
    # @!attribute [rw] access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #   @return [Types::AccessControlPolicy]
    #
    # @!attribute [rw] bucket
    #   The bucket to which to apply the ACL.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. This header
    #   must be used as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, go to [RFC
    #   1864.][1]
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAclRequest AWS API Documentation
    #
    class PutBucketAclRequest < Struct.new(
      :acl,
      :access_control_policy,
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket to which an analytics configuration is
    #   stored.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] analytics_configuration
    #   The configuration and any analyses for the analytics filter.
    #   @return [Types::AnalyticsConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class PutBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :analytics_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Specifies the bucket impacted by the `cors`configuration.
    #   @return [String]
    #
    # @!attribute [rw] cors_configuration
    #   Describes the cross-origin access configuration for objects in an
    #   Amazon S3 bucket. For more information, see [Enabling Cross-Origin
    #   Resource Sharing][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    #   @return [Types::CORSConfiguration]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. This header
    #   must be used as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, go to [RFC
    #   1864.][1]
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketCorsRequest AWS API Documentation
    #
    class PutBucketCorsRequest < Struct.new(
      :bucket,
      :cors_configuration,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Specifies default encryption for a bucket using server-side
    #   encryption with different key options.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the server-side
    #   encryption configuration.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #   <note markdown="1"> For directory buckets, when you use Amazon Web Services SDKs,
    #   `CRC32` is the default checksum algorithm that's used for
    #   performance.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption_configuration
    #   Specifies the default server-side-encryption configuration.
    #   @return [Types::ServerSideEncryptionConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketEncryptionRequest AWS API Documentation
    #
    class PutBucketEncryptionRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :server_side_encryption_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] intelligent_tiering_configuration
    #   Container for S3 Intelligent-Tiering configuration.
    #   @return [Types::IntelligentTieringConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketIntelligentTieringConfigurationRequest AWS API Documentation
    #
    class PutBucketIntelligentTieringConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner,
      :intelligent_tiering_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket where the inventory configuration will be
    #   stored.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] inventory_configuration
    #   Specifies the inventory configuration.
    #   @return [Types::InventoryConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketInventoryConfigurationRequest AWS API Documentation
    #
    class PutBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :inventory_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] transition_default_minimum_object_size
    #   Indicates which default minimum object size behavior is applied to
    #   the lifecycle configuration.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #
    #   * `all_storage_classes_128K` - Objects smaller than 128 KB will not
    #     transition to any storage class by default.
    #
    #   * `varies_by_storage_class` - Objects smaller than 128 KB will
    #     transition to Glacier Flexible Retrieval or Glacier Deep Archive
    #     storage classes. By default, all other storage classes will
    #     prevent transitions smaller than 128 KB.
    #
    #   To customize the minimum object size for any transition you can add
    #   a filter that specifies a custom `ObjectSizeGreaterThan` or
    #   `ObjectSizeLessThan` in the body of your transition rule. Custom
    #   filters always take precedence over the default transition behavior.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleConfigurationOutput AWS API Documentation
    #
    class PutBucketLifecycleConfigurationOutput < Struct.new(
      :transition_default_minimum_object_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to set the configuration.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] lifecycle_configuration
    #   Container for lifecycle rules. You can add as many as 1,000 rules.
    #   @return [Types::BucketLifecycleConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] transition_default_minimum_object_size
    #   Indicates which default minimum object size behavior is applied to
    #   the lifecycle configuration.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #
    #   * `all_storage_classes_128K` - Objects smaller than 128 KB will not
    #     transition to any storage class by default.
    #
    #   * `varies_by_storage_class` - Objects smaller than 128 KB will
    #     transition to Glacier Flexible Retrieval or Glacier Deep Archive
    #     storage classes. By default, all other storage classes will
    #     prevent transitions smaller than 128 KB.
    #
    #   To customize the minimum object size for any transition you can add
    #   a filter that specifies a custom `ObjectSizeGreaterThan` or
    #   `ObjectSizeLessThan` in the body of your transition rule. Custom
    #   filters always take precedence over the default transition behavior.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleConfigurationRequest AWS API Documentation
    #
    class PutBucketLifecycleConfigurationRequest < Struct.new(
      :bucket,
      :checksum_algorithm,
      :lifecycle_configuration,
      :expected_bucket_owner,
      :transition_default_minimum_object_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] lifecycle_configuration
    #   @return [Types::LifecycleConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleRequest AWS API Documentation
    #
    class PutBucketLifecycleRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :lifecycle_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which to set the logging parameters.
    #   @return [String]
    #
    # @!attribute [rw] bucket_logging_status
    #   Container for logging status information.
    #   @return [Types::BucketLoggingStatus]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutBucketLogging` request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLoggingRequest AWS API Documentation
    #
    class PutBucketLoggingRequest < Struct.new(
      :bucket,
      :bucket_logging_status,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket for which the metrics configuration is set.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #   @return [String]
    #
    # @!attribute [rw] metrics_configuration
    #   Specifies the metrics configuration.
    #   @return [Types::MetricsConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketMetricsConfigurationRequest AWS API Documentation
    #
    class PutBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :metrics_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] notification_configuration
    #   A container for specifying the notification configuration of the
    #   bucket. If this element is empty, notifications are turned off for
    #   the bucket.
    #   @return [Types::NotificationConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] skip_destination_validation
    #   Skips validation of Amazon SQS, Amazon SNS, and Lambda destinations.
    #   True or false value.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotificationConfigurationRequest AWS API Documentation
    #
    class PutBucketNotificationConfigurationRequest < Struct.new(
      :bucket,
      :notification_configuration,
      :expected_bucket_owner,
      :skip_destination_validation)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] notification_configuration
    #   The container for the configuration.
    #   @return [Types::NotificationConfigurationDeprecated]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotificationRequest AWS API Documentation
    #
    class PutBucketNotificationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :notification_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `OwnershipControls` you want
    #   to set.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `OwnershipControls` request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] ownership_controls
    #   The `OwnershipControls` (BucketOwnerEnforced, BucketOwnerPreferred,
    #   or ObjectWriter) that you want to apply to this Amazon S3 bucket.
    #   @return [Types::OwnershipControls]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum-algorithm ` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status
    #   code `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketOwnershipControlsRequest AWS API Documentation
    #
    class PutBucketOwnershipControlsRequest < Struct.new(
      :bucket,
      :content_md5,
      :expected_bucket_owner,
      :ownership_controls,
      :checksum_algorithm)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket.
    #
    #   <b>Directory buckets </b> - When you use this operation with a
    #   directory bucket, you must use path-style requests in the format
    #   `https://s3express-control.region-code.amazonaws.com/bucket-name `.
    #   Virtual-hosted-style requests aren't supported. Directory bucket
    #   names must be unique in the chosen Zone (Availability Zone or Local
    #   Zone). Bucket names must also follow the format `
    #   bucket-base-name--zone-id--x-s3` (for example, `
    #   DOC-EXAMPLE-BUCKET--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum-algorithm ` or
    #   `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the request
    #   with the HTTP status code `400 Bad Request`.
    #
    #   For the `x-amz-checksum-algorithm ` header, replace ` algorithm `
    #   with the supported algorithm from the following list:
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
    #   `x-amz-checksum-algorithm ` doesn't match the checksum algorithm
    #   you set through `x-amz-sdk-checksum-algorithm`, Amazon S3 fails the
    #   request with a `BadDigest` error.
    #
    #   <note markdown="1"> For directory buckets, when you use Amazon Web Services SDKs,
    #   `CRC32` is the default checksum algorithm that's used for
    #   performance.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] confirm_remove_self_bucket_access
    #   Set this parameter to true to confirm that you want to remove your
    #   permissions to change this bucket policy in the future.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Boolean]
    #
    # @!attribute [rw] policy
    #   The bucket policy as a JSON document.
    #
    #   For directory buckets, the only IAM action supported in the bucket
    #   policy is `s3express:CreateSession`.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #
    #   <note markdown="1"> For directory buckets, this header is not supported in this API
    #   operation. If you specify this header, the request fails with the
    #   HTTP status code `501 Not Implemented`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketPolicyRequest AWS API Documentation
    #
    class PutBucketPolicyRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :confirm_remove_self_bucket_access,
      :policy,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the bucket
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] replication_configuration
    #   A container for replication rules. You can add up to 1,000 rules.
    #   The maximum size of a replication configuration is 2 MB.
    #   @return [Types::ReplicationConfiguration]
    #
    # @!attribute [rw] token
    #   A token to allow Object Lock to be enabled for an existing bucket.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketReplicationRequest AWS API Documentation
    #
    class PutBucketReplicationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :replication_configuration,
      :token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] request_payment_configuration
    #   Container for Payer.
    #   @return [Types::RequestPaymentConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketRequestPaymentRequest AWS API Documentation
    #
    class PutBucketRequestPaymentRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :request_payment_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   Container for the `TagSet` and `Tag` elements.
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketTaggingRequest AWS API Documentation
    #
    class PutBucketTaggingRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :tagging,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   &gt;The Base64 encoded 128-bit `MD5` digest of the data. You must
    #   use this header as a message integrity check to verify that the
    #   request body was not corrupted in transit. For more information, see
    #   [RFC 1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device. The serial number is the number that uniquely identifies the
    #   MFA device. For physical MFA devices, this is the unique serial
    #   number that's provided with the device. For virtual MFA devices,
    #   the serial number is the device ARN. For more information, see
    #   [Enabling versioning on buckets][1] and [Configuring MFA delete][2]
    #   in the *Amazon Simple Storage Service User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/manage-versioning-examples.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html
    #   @return [String]
    #
    # @!attribute [rw] versioning_configuration
    #   Container for setting the versioning state.
    #   @return [Types::VersioningConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketVersioningRequest AWS API Documentation
    #
    class PutBucketVersioningRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :mfa,
      :versioning_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] website_configuration
    #   Container for the request.
    #   @return [Types::WebsiteConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketWebsiteRequest AWS API Documentation
    #
    class PutBucketWebsiteRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :website_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectAclOutput AWS API Documentation
    #
    class PutObjectAclOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #   @return [String]
    #
    # @!attribute [rw] access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #   @return [Types::AccessControlPolicy]
    #
    # @!attribute [rw] bucket
    #   The bucket name that contains the object to which you want to attach
    #   the ACL.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the data. This header
    #   must be used as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, go to [RFC
    #   1864.&gt;][1]
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #
    #   This functionality is not supported for Amazon S3 on Outposts.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    #   This functionality is not supported for Amazon S3 on Outposts.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    #   This functionality is not supported for Amazon S3 on Outposts.
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    #   This functionality is not supported for Amazon S3 on Outposts.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key for which the PUT action was initiated.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID used to reference a specific version of the object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectAclRequest AWS API Documentation
    #
    class PutObjectAclRequest < Struct.new(
      :acl,
      :access_control_policy,
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :key,
      :request_payer,
      :version_id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLegalHoldOutput AWS API Documentation
    #
    class PutObjectLegalHoldOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object that you want to place a legal
    #   hold on.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object that you want to place a legal hold on.
    #   @return [String]
    #
    # @!attribute [rw] legal_hold
    #   Container element for the legal hold configuration you want to apply
    #   to the specified object.
    #   @return [Types::ObjectLockLegalHold]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object that you want to place a legal hold on.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLegalHoldRequest AWS API Documentation
    #
    class PutObjectLegalHoldRequest < Struct.new(
      :bucket,
      :key,
      :legal_hold,
      :request_payer,
      :version_id,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLockConfigurationOutput AWS API Documentation
    #
    class PutObjectLockConfigurationOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket whose Object Lock configuration you want to create or
    #   replace.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_configuration
    #   The Object Lock configuration that you want to apply to the
    #   specified bucket.
    #   @return [Types::ObjectLockConfiguration]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] token
    #   A token to allow Object Lock to be enabled for an existing bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLockConfigurationRequest AWS API Documentation
    #
    class PutObjectLockConfigurationRequest < Struct.new(
      :bucket,
      :object_lock_configuration,
      :request_payer,
      :token,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] expiration
    #   If the expiration is configured for the object (see
    #   [PutBucketLifecycleConfiguration][1]) in the *Amazon S3 User Guide*,
    #   the response includes this header. It includes the `expiry-date` and
    #   `rule-id` key-value pairs that provide information about object
    #   expiration. The value of the `rule-id` is URL-encoded.
    #
    #   <note markdown="1"> Object expiration information is not returned in directory buckets
    #   and this header returns the value "`NotImplemented`" in all
    #   responses for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag for the uploaded object.
    #
    #   <b>General purpose buckets </b> - To ensure that data is not
    #   corrupted traversing the network, for objects where the ETag is the
    #   MD5 digest of the object, you can calculate the MD5 while putting an
    #   object to Amazon S3 and compare the returned ETag to the calculated
    #   MD5 value.
    #
    #   <b>Directory buckets </b> - The ETag for the object in a directory
    #   bucket isn't the MD5 digest of the object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32 checksum` of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   The Base64 encoded, 64-bit `CRC64NVME` checksum of the object. This
    #   header is present if the object was uploaded with the `CRC64NVME`
    #   checksum algorithm, or if it was uploaded without a checksum (and
    #   Amazon S3 added the default checksum, `CRC64NVME`, to the uploaded
    #   object). For more information about how checksums are calculated
    #   with multipart uploads, see [Checking object integrity in the Amazon
    #   S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use the API operation on an object that was
    #   uploaded using multipart uploads, this value may not be a direct
    #   checksum value of the full object. Instead, it's a calculation
    #   based on the checksum values of each individual part. For more
    #   information about how checksums are calculated with multipart
    #   uploads, see [ Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_type
    #   This header specifies the checksum type of the object, which
    #   determines how part-level checksums are combined to create an
    #   object-level checksum for multipart objects. For `PutObject`
    #   uploads, the checksum type is always `FULL_OBJECT`. You can use this
    #   header as a data integrity check to verify that the checksum type
    #   that is received is the same checksum that was specified. For more
    #   information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of the object.
    #
    #   If you enable versioning for a bucket, Amazon S3 automatically
    #   generates a unique version ID for the object being stored. Amazon S3
    #   returns this ID in the response. When you enable versioning for a
    #   bucket, if Amazon S3 receives multiple write requests for the same
    #   object simultaneously, it stores all of the objects. For more
    #   information about versioning, see [Adding Objects to
    #   Versioning-Enabled Buckets][1] in the *Amazon S3 User Guide*. For
    #   information about returning the versioning state of a bucket, see
    #   [GetBucketVersioning][2].
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/AddingObjectstoVersioningEnabledBuckets.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, indicates the Amazon Web Services KMS Encryption Context
    #   to use for object encryption. The value of this header is a Base64
    #   encoded string of a UTF-8 encoded JSON, which contains the
    #   encryption context as key-value pairs. This value is stored as
    #   object metadata and automatically gets passed on to Amazon Web
    #   Services KMS for future `GetObject` operations on this object.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the uploaded object uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] size
    #   The size of the object in bytes. This value is only be present if
    #   you append to an object.
    #
    #   <note markdown="1"> This functionality is only supported for objects in the Amazon S3
    #   Express One Zone storage class in directory buckets.
    #
    #    </note>
    #   @return [Integer]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectOutput AWS API Documentation
    #
    class PutObjectOutput < Struct.new(
      :expiration,
      :etag,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :checksum_type,
      :server_side_encryption,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :size,
      :request_charged)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] acl
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
    #   If the bucket that you're uploading objects to uses the bucket
    #   owner enforced setting for S3 Object Ownership, ACLs are disabled
    #   and no longer affect permissions. Buckets that use this setting only
    #   accept PUT requests that don't specify an ACL or PUT requests that
    #   specify bucket owner full control ACLs, such as the
    #   `bucket-owner-full-control` canned ACL or an equivalent form of this
    #   ACL expressed in the XML format. PUT requests that contain other
    #   ACLs (for example, custom grants to certain Amazon Web Services
    #   accounts) fail and return a `400` error with the error code
    #   `AccessControlListNotSupported`. For more information, see [
    #   Controlling ownership of objects and disabling ACLs][4] in the
    #   *Amazon S3 User Guide*.
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
    #   @return [String]
    #
    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] bucket
    #   The bucket name to which the PUT action was initiated.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Can be used to specify caching behavior along the request/reply
    #   chain. For more information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc6266#section-4][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc6266#section-4
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically. For more information,
    #   see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length
    #   @return [Integer]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit `MD5` digest of the message (without the
    #   headers) according to RFC 1864. This header can be used as a message
    #   integrity check to verify that the data is the same data that was
    #   originally sent. Although it is optional, we recommend using the
    #   Content-MD5 mechanism as an end-to-end integrity check. For more
    #   information about REST request authentication, see [REST
    #   Authentication][1].
    #
    #   <note markdown="1"> The `Content-MD5` or `x-amz-sdk-checksum-algorithm` header is
    #   required for any request to upload an object with a retention period
    #   configured using Amazon S3 Object Lock. For more information, see
    #   [Uploading objects to an Object Lock enabled bucket ][2] in the
    #   *Amazon S3 User Guide*.
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
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the contents. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum-algorithm ` or
    #   `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the request
    #   with the HTTP status code `400 Bad Request`.
    #
    #   For the `x-amz-checksum-algorithm ` header, replace ` algorithm `
    #   with the supported algorithm from the following list:
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
    #   `x-amz-checksum-algorithm ` doesn't match the checksum algorithm
    #   you set through `x-amz-sdk-checksum-algorithm`, Amazon S3 fails the
    #   request with a `BadDigest` error.
    #
    #   <note markdown="1"> The `Content-MD5` or `x-amz-sdk-checksum-algorithm` header is
    #   required for any request to upload an object with a retention period
    #   configured using Amazon S3 Object Lock. For more information, see
    #   [Uploading objects to an Object Lock enabled bucket ][2] in the
    #   *Amazon S3 User Guide*.
    #
    #    </note>
    #
    #   For directory buckets, when you use Amazon Web Services SDKs,
    #   `CRC32` is the default checksum algorithm that's used for
    #   performance.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-managing.html#object-lock-put-object
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the
    #   object. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   object. The `CRC64NVME` checksum is always a full object checksum.
    #   For more information, see [Checking object integrity in the Amazon
    #   S3 User Guide][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 160-bit `SHA1` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 256-bit `SHA256` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable. For
    #   more information, see
    #   [https://www.rfc-editor.org/rfc/rfc7234#section-5.3][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc7234#section-5.3
    #   @return [Time]
    #
    # @!attribute [rw] if_match
    #   Uploads the object only if the ETag (entity tag) value provided
    #   during the WRITE operation matches the ETag of the object in S3. If
    #   the ETag values do not match, the operation returns a `412
    #   Precondition Failed` error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a
    #   `409 ConditionalRequestConflict` response. On a 409 failure you
    #   should fetch the object's ETag and retry the upload.
    #
    #   Expects the ETag value as a string.
    #
    #   For more information about conditional requests, see [RFC 7232][1],
    #   or [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    #   @return [String]
    #
    # @!attribute [rw] if_none_match
    #   Uploads the object only if the object key name does not already
    #   exist in the bucket specified. Otherwise, Amazon S3 returns a `412
    #   Precondition Failed` error.
    #
    #   If a conflicting operation occurs during the upload S3 returns a
    #   `409 ConditionalRequestConflict` response. On a 409 failure you
    #   should retry the upload.
    #
    #   Expects the '*' (asterisk) character.
    #
    #   For more information about conditional requests, see [RFC 7232][1],
    #   or [Conditional requests][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc7232
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-requests.html
    #   @return [String]
    #
    # @!attribute [rw] grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   <note markdown="1"> * This functionality is not supported for directory buckets.
    #
    #   * This functionality is not supported for Amazon S3 on Outposts.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the PUT action was initiated.
    #   @return [String]
    #
    # @!attribute [rw] write_offset_bytes
    #   Specifies the offset for appending data to existing objects in
    #   bytes. The offset must be equal to the size of the existing object
    #   being appended to. If no object exists, setting this header to 0
    #   will create a new object.
    #
    #   <note markdown="1"> This functionality is only supported for objects in the Amazon S3
    #   Express One Zone storage class in directory buckets.
    #
    #    </note>
    #   @return [Integer]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm that was used when you store
    #   this object in Amazon S3 or Amazon FSx.
    #
    #   * <b>General purpose buckets </b> - You have four mutually exclusive
    #     options to protect data using server-side encryption in Amazon S3,
    #     depending on how you choose to manage the encryption keys.
    #     Specifically, the encryption key options are Amazon S3 managed
    #     keys (SSE-S3), Amazon Web Services KMS keys (SSE-KMS or DSSE-KMS),
    #     and customer-provided keys (SSE-C). Amazon S3 encrypts data with
    #     server-side encryption by using Amazon S3 managed keys (SSE-S3) by
    #     default. You can optionally tell Amazon S3 to encrypt data at rest
    #     by using server-side encryption with other key options. For more
    #     information, see [Using Server-Side Encryption][1] in the *Amazon
    #     S3 User Guide*.
    #
    #   * <b>Directory buckets </b> - For directory buckets, there are only
    #     two supported options for server-side encryption: server-side
    #     encryption with Amazon S3 managed keys (SSE-S3) (`AES256`) and
    #     server-side encryption with KMS keys (SSE-KMS) (`aws:kms`). We
    #     recommend that the bucket's default encryption uses the desired
    #     encryption configuration and you don't override the bucket
    #     default encryption in your `CreateSession` requests or `PUT`
    #     object requests. Then, new objects are automatically encrypted
    #     with the desired encryption settings. For more information, see
    #     [Protecting data with server-side encryption][2] in the *Amazon S3
    #     User Guide*. For more information about the encryption overriding
    #     behaviors in directory buckets, see [Specifying server-side
    #     encryption with KMS for new object uploads][3].
    #
    #     In the Zonal endpoint API calls (except [CopyObject][4] and
    #     [UploadPartCopy][5]) using the REST API, the encryption request
    #     headers must match the encryption settings that are specified in
    #     the `CreateSession` request. You can't override the values of the
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
    #     `CreateSession`, the session token refreshes automatically to
    #     avoid service interruptions when a session expires. The CLI or the
    #     Amazon Web Services SDKs use the bucket's default encryption
    #     configuration for the `CreateSession` request. It's not supported
    #     to override the encryption settings values in the `CreateSession`
    #     request. So in the Zonal endpoint API calls (except
    #     [CopyObject][4] and [UploadPartCopy][5]), the encryption request
    #     headers must match the default encryption configuration of the
    #     directory bucket.
    #
    #      </note>
    #
    #   * <b>S3 access points for Amazon FSx </b> - When accessing data
    #     stored in Amazon FSx file systems using S3 access points, the only
    #     valid server side encryption option is `aws:fsx`. All Amazon FSx
    #     file systems have encryption configured by default and are
    #     encrypted at rest. Data is automatically encrypted before being
    #     written to the file system, and automatically decrypted as it is
    #     read. These processes are handled transparently by Amazon FSx.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-serv-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-specifying-kms-encryption.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can
    #   specify a different Storage Class. For more information, see
    #   [Storage Classes][1] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> * Directory buckets only support `EXPRESS_ONEZONE` (the S3 Express
    #     One Zone storage class) in Availability Zones and `ONEZONE_IA`
    #     (the S3 One Zone-Infrequent Access storage class) in Dedicated
    #     Local Zones.
    #
    #   * Amazon S3 on Outposts only uses the OUTPOSTS Storage Class.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata. For information about object metadata, see [Object Key and
    #   Metadata][1] in the *Amazon S3 User Guide*.
    #
    #   In the following example, the request header sets the redirect to an
    #   object (anotherPage.html) in the same bucket:
    #
    #   `x-amz-website-redirect-location: /anotherPage.html`
    #
    #   In the following example, the request header sets the object
    #   redirect to another website:
    #
    #   `x-amz-website-redirect-location: http://www.example.com/`
    #
    #   For more information about website hosting in Amazon S3, see
    #   [Hosting Websites on Amazon S3][2] and [How to Configure Website
    #   Page Redirects][3] in the *Amazon S3 User Guide*.
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
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, `AES256`).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   Specifies the KMS key ID (Key ID, Key ARN, or Key Alias) to use for
    #   object encryption. If the KMS key doesn't exist in the same account
    #   that's issuing the command, you must use the full Key ARN not the
    #   Key ID.
    #
    #   **General purpose buckets** - If you specify
    #   `x-amz-server-side-encryption` with `aws:kms` or `aws:kms:dsse`,
    #   this header specifies the ID (Key ID, Key ARN, or Key Alias) of the
    #   KMS key to use. If you specify
    #   `x-amz-server-side-encryption:aws:kms` or
    #   `x-amz-server-side-encryption:aws:kms:dsse`, but do not provide
    #   `x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the
    #   Amazon Web Services managed key (`aws/s3`) to protect the data.
    #
    #   **Directory buckets** - To encrypt data using SSE-KMS, it's
    #   recommended to specify the `x-amz-server-side-encryption` header to
    #   `aws:kms`. Then, the `x-amz-server-side-encryption-aws-kms-key-id`
    #   header implicitly uses the bucket's default KMS customer managed
    #   key ID. If you want to explicitly set the `
    #   x-amz-server-side-encryption-aws-kms-key-id` header, it must match
    #   the bucket's default customer managed key (using key ID or ARN, not
    #   alias). Your SSE-KMS configuration can only support 1 [customer
    #   managed key][1] per directory bucket's lifetime. The [Amazon Web
    #   Services managed key][2] (`aws/s3`) isn't supported. Incorrect key
    #   specification results in an HTTP `400 Bad Request` error.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context as an
    #   additional encryption context to use for object encryption. The
    #   value of this header is a Base64 encoded string of a UTF-8 encoded
    #   JSON, which contains the encryption context as key-value pairs. This
    #   value is stored as object metadata and automatically gets passed on
    #   to Amazon Web Services KMS for future `GetObject` operations on this
    #   object.
    #
    #   **General purpose buckets** - This value must be explicitly added
    #   during `CopyObject` operations if you want an additional encryption
    #   context for your object. For more information, see [Encryption
    #   context][1] in the *Amazon S3 User Guide*.
    #
    #   **Directory buckets** - You can optionally provide an explicit
    #   encryption context value. The value must match the default
    #   encryption context - the bucket Amazon Resource Name (ARN). An
    #   additional encryption context value is not supported.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html#encryption-context
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS).
    #
    #   **General purpose buckets** - Setting this header to `true` causes
    #   Amazon S3 to use an S3 Bucket Key for object encryption with
    #   SSE-KMS. Also, specifying this header with a PUT action doesn't
    #   affect bucket-level settings for S3 Bucket Key.
    #
    #   **Directory buckets** - S3 Bucket Keys are always enabled for `GET`
    #   and `PUT` operations in a directory bucket and can’t be disabled. S3
    #   Bucket Keys aren't supported, when you copy SSE-KMS encrypted
    #   objects from general purpose buckets to directory buckets, from
    #   directory buckets to general purpose buckets, or between directory
    #   buckets, through [CopyObject][1], [UploadPartCopy][2], [the Copy
    #   operation in Batch Operations][3], or [the import jobs][4]. In this
    #   case, Amazon S3 makes a call to KMS every time a copy request is
    #   made for a KMS-encrypted object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    #   @return [Boolean]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters. (For example, "Key1=Value1")
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode that you want to apply to this object.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when you want this object's Object Lock to
    #   expire. Must be formatted as a timestamp parameter.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
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
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRequest AWS API Documentation
    #
    class PutObjectRequest < Struct.new(
      :acl,
      :body,
      :bucket,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_length,
      :content_md5,
      :content_type,
      :checksum_algorithm,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :expires,
      :if_match,
      :if_none_match,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :key,
      :write_offset_bytes,
      :metadata,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :bucket_key_enabled,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRetentionOutput AWS API Documentation
    #
    class PutObjectRetentionOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name that contains the object you want to apply this
    #   Object Retention configuration to.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object that you want to apply this Object
    #   Retention configuration to.
    #   @return [String]
    #
    # @!attribute [rw] retention
    #   The container element for the Object Retention configuration.
    #   @return [Types::ObjectLockRetention]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID for the object that you want to apply this Object
    #   Retention configuration to.
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Indicates whether this action should bypass Governance-mode
    #   restrictions.
    #   @return [Boolean]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRetentionRequest AWS API Documentation
    #
    class PutObjectRetentionRequest < Struct.new(
      :bucket,
      :key,
      :retention,
      :request_payer,
      :version_id,
      :bypass_governance_retention,
      :content_md5,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object the tag-set was added to.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectTaggingOutput AWS API Documentation
    #
    class PutObjectTaggingOutput < Struct.new(
      :version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Name of the object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object that the tag-set will be added to.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   Container for the `TagSet` and `Tag` elements
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the tagging object request. Bucket owners need not specify this
    #   parameter in their requests.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectTaggingRequest AWS API Documentation
    #
    class PutObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :content_md5,
      :checksum_algorithm,
      :tagging,
      :expected_bucket_owner,
      :request_payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to set.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #
    #   For requests made using the Amazon Web Services Command Line
    #   Interface (CLI) or Amazon Web Services SDKs, this field is
    #   calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] public_access_block_configuration
    #   The `PublicAccessBlock` configuration that you want to apply to this
    #   Amazon S3 bucket. You can enable the configuration options in any
    #   combination. For more information about when Amazon S3 considers a
    #   bucket or object public, see [The Meaning of "Public"][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    #   @return [Types::PublicAccessBlockConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutPublicAccessBlockRequest AWS API Documentation
    #
    class PutPublicAccessBlockRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :public_access_block_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the configuration for publishing messages to an Amazon
    # Simple Queue Service (Amazon SQS) queue when Amazon S3 detects
    # specified events.
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] queue_arn
    #   The Amazon Resource Name (ARN) of the Amazon SQS queue to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of bucket events for which to send notifications
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring event notifications using object
    #   key name filtering][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-filtering.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/QueueConfiguration AWS API Documentation
    #
    class QueueConfiguration < Struct.new(
      :id,
      :queue_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type is deprecated. Use [QueueConfiguration][1] for the same
    # purposes. This data type specifies the configuration for publishing
    # messages to an Amazon Simple Queue Service (Amazon SQS) queue when
    # Amazon S3 detects specified events.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_QueueConfiguration.html
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] event
    #   The bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of bucket events for which to send notifications.
    #   @return [Array<String>]
    #
    # @!attribute [rw] queue
    #   The Amazon Resource Name (ARN) of the Amazon SQS queue to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/QueueConfigurationDeprecated AWS API Documentation
    #
    class QueueConfigurationDeprecated < Struct.new(
      :id,
      :event,
      :events,
      :queue)
      SENSITIVE = []
      include Aws::Structure
    end

    # The journal table record expiration settings for a journal table in an
    # S3 Metadata configuration.
    #
    # @!attribute [rw] expiration
    #   Specifies whether journal table record expiration is enabled or
    #   disabled.
    #   @return [String]
    #
    # @!attribute [rw] days
    #   If you enable journal table record expiration, you can set the
    #   number of days to retain your journal table records. Journal table
    #   records must be retained for a minimum of 7 days. To set this value,
    #   specify any whole number from `7` to `2147483647`. For example, to
    #   retain your journal table records for one year, set this value to
    #   `365`.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RecordExpiration AWS API Documentation
    #
    class RecordExpiration < Struct.new(
      :expiration,
      :days)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container for the records event.
    #
    # @!attribute [rw] payload
    #   The byte array of partial, one or more result records. S3 Select
    #   doesn't guarantee that a record will be self-contained in one
    #   record frame. To ensure continuous streaming of data, S3 Select
    #   might split the same record across multiple record frames instead of
    #   aggregating the results in memory. Some S3 clients (for example, the
    #   SDK for Java) handle this behavior by creating a `ByteStream` out of
    #   the response by default. Other clients might not handle this
    #   behavior by default. In those cases, you must aggregate the results
    #   on the client side and parse the response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RecordsEvent AWS API Documentation
    #
    class RecordsEvent < Struct.new(
      :payload,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies how requests are redirected. In the event of an error, you
    # can specify a different error code to return.
    #
    # @!attribute [rw] host_name
    #   The host name to use in the redirect request.
    #   @return [String]
    #
    # @!attribute [rw] http_redirect_code
    #   The HTTP redirect code to use on the response. Not required if one
    #   of the siblings is present.
    #   @return [String]
    #
    # @!attribute [rw] protocol
    #   Protocol to use when redirecting requests. The default is the
    #   protocol that is used in the original request.
    #   @return [String]
    #
    # @!attribute [rw] replace_key_prefix_with
    #   The object key prefix to use in the redirect request. For example,
    #   to redirect requests for all pages with prefix `docs/` (objects in
    #   the `docs/` folder) to `documents/`, you can set a condition block
    #   with `KeyPrefixEquals` set to `docs/` and in the Redirect set
    #   `ReplaceKeyPrefixWith` to `/documents`. Not required if one of the
    #   siblings is present. Can be present only if `ReplaceKeyWith` is not
    #   provided.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] replace_key_with
    #   The specific object key to use in the redirect request. For example,
    #   redirect request to `error.html`. Not required if one of the
    #   siblings is present. Can be present only if `ReplaceKeyPrefixWith`
    #   is not provided.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Redirect AWS API Documentation
    #
    class Redirect < Struct.new(
      :host_name,
      :http_redirect_code,
      :protocol,
      :replace_key_prefix_with,
      :replace_key_with)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the redirect behavior of all requests to a website endpoint
    # of an Amazon S3 bucket.
    #
    # @!attribute [rw] host_name
    #   Name of the host where requests are redirected.
    #   @return [String]
    #
    # @!attribute [rw] protocol
    #   Protocol to use when redirecting requests. The default is the
    #   protocol that is used in the original request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RedirectAllRequestsTo AWS API Documentation
    #
    class RedirectAllRequestsTo < Struct.new(
      :host_name,
      :protocol)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RenameObjectOutput AWS API Documentation
    #
    class RenameObjectOutput < Aws::EmptyStructure; end

    # @!attribute [rw] bucket
    #   The bucket name of the directory bucket containing the object.
    #
    #   You must use virtual-hosted-style requests in the format
    #   `Bucket-name.s3express-zone-id.region-code.amazonaws.com`.
    #   Path-style requests are not supported. Directory bucket names must
    #   be unique in the chosen Availability Zone. Bucket names must follow
    #   the format `bucket-base-name--zone-id--x-s3 ` (for example,
    #   `amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key name of the object to rename.
    #   @return [String]
    #
    # @!attribute [rw] rename_source
    #   Specifies the source for the rename operation. The value must be URL
    #   encoded.
    #   @return [String]
    #
    # @!attribute [rw] destination_if_match
    #   Renames the object only if the ETag (entity tag) value provided
    #   during the operation matches the ETag of the object in S3. The
    #   `If-Match` header field makes the request method conditional on
    #   ETags. If the ETag values do not match, the operation returns a `412
    #   Precondition Failed` error.
    #
    #   Expects the ETag value as a string.
    #   @return [String]
    #
    # @!attribute [rw] destination_if_none_match
    #   Renames the object only if the destination does not already exist in
    #   the specified directory bucket. If the object does exist when you
    #   send a request with `If-None-Match:*`, the S3 API will return a `412
    #   Precondition Failed` error, preventing an overwrite. The
    #   `If-None-Match` header prevents overwrites of existing data by
    #   validating that there's not an object with the same key name
    #   already in your directory bucket.
    #
    #   Expects the `*` character (asterisk).
    #   @return [String]
    #
    # @!attribute [rw] destination_if_modified_since
    #   Renames the object if the destination exists and if it has been
    #   modified since the specified time.
    #   @return [Time]
    #
    # @!attribute [rw] destination_if_unmodified_since
    #   Renames the object if it hasn't been modified since the specified
    #   time.
    #   @return [Time]
    #
    # @!attribute [rw] source_if_match
    #   Renames the object if the source exists and if its entity tag (ETag)
    #   matches the specified ETag.
    #   @return [String]
    #
    # @!attribute [rw] source_if_none_match
    #   Renames the object if the source exists and if its entity tag (ETag)
    #   is different than the specified ETag. If an asterisk (`*`) character
    #   is provided, the operation will fail and return a `412 Precondition
    #   Failed` error.
    #   @return [String]
    #
    # @!attribute [rw] source_if_modified_since
    #   Renames the object if the source exists and if it has been modified
    #   since the specified time.
    #   @return [Time]
    #
    # @!attribute [rw] source_if_unmodified_since
    #   Renames the object if the source exists and hasn't been modified
    #   since the specified time.
    #   @return [Time]
    #
    # @!attribute [rw] client_token
    #   A unique string with a max of 64 ASCII characters in the ASCII range
    #   of 33 - 126.
    #
    #   <note markdown="1"> `RenameObject` supports idempotency using a client token. To make an
    #   idempotent API request using `RenameObject`, specify a client token
    #   in the request. You should not reuse the same client token for other
    #   API requests. If you retry a request that completed successfully
    #   using the same client token and the same parameters, the retry
    #   succeeds without performing any further actions. If you retry a
    #   successful request using the same client token, but one or more of
    #   the parameters are different, the retry fails and an
    #   `IdempotentParameterMismatch` error is returned.
    #
    #    </note>
    #
    #   **A suitable default value is auto-generated.** You should normally
    #   not need to pass this option.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RenameObjectRequest AWS API Documentation
    #
    class RenameObjectRequest < Struct.new(
      :bucket,
      :key,
      :rename_source,
      :destination_if_match,
      :destination_if_none_match,
      :destination_if_modified_since,
      :destination_if_unmodified_since,
      :source_if_match,
      :source_if_none_match,
      :source_if_modified_since,
      :source_if_unmodified_since,
      :client_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # A filter that you can specify for selection for modifications on
    # replicas. Amazon S3 doesn't replicate replica modifications by
    # default. In the latest version of replication configuration (when
    # `Filter` is specified), you can specify this element and set the
    # status to `Enabled` to replicate modifications on replicas.
    #
    # <note markdown="1"> If you don't specify the `Filter` element, Amazon S3 assumes that the
    # replication configuration is the earlier version, V1. In the earlier
    # version, this element is not allowed.
    #
    #  </note>
    #
    # @!attribute [rw] status
    #   Specifies whether Amazon S3 replicates modifications on replicas.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicaModifications AWS API Documentation
    #
    class ReplicaModifications < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for replication rules. You can add up to 1,000 rules. The
    # maximum size of a replication configuration is 2 MB.
    #
    # @!attribute [rw] role
    #   The Amazon Resource Name (ARN) of the Identity and Access Management
    #   (IAM) role that Amazon S3 assumes when replicating objects. For more
    #   information, see [How to Set Up Replication][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-how-setup.html
    #   @return [String]
    #
    # @!attribute [rw] rules
    #   A container for one or more replication rules. A replication
    #   configuration must have at least one rule and can contain a maximum
    #   of 1,000 rules.
    #   @return [Array<Types::ReplicationRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationConfiguration AWS API Documentation
    #
    class ReplicationConfiguration < Struct.new(
      :role,
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies which Amazon S3 objects to replicate and where to store the
    # replicas.
    #
    # @!attribute [rw] id
    #   A unique identifier for the rule. The maximum value is 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] priority
    #   The priority indicates which rule has precedence whenever two or
    #   more replication rules conflict. Amazon S3 will attempt to replicate
    #   objects according to all replication rules. However, if there are
    #   two or more rules with the same destination bucket, then objects
    #   will be replicated according to the rule with the highest priority.
    #   The higher the number, the higher the priority.
    #
    #   For more information, see [Replication][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the object or objects to
    #   which the rule applies. The maximum prefix length is 1,024
    #   characters. To include all objects in a bucket, specify an empty
    #   string.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   A filter that identifies the subset of objects to which the
    #   replication rule applies. A `Filter` must specify exactly one
    #   `Prefix`, `Tag`, or an `And` child element.
    #   @return [Types::ReplicationRuleFilter]
    #
    # @!attribute [rw] status
    #   Specifies whether the rule is enabled.
    #   @return [String]
    #
    # @!attribute [rw] source_selection_criteria
    #   A container that describes additional filters for identifying the
    #   source objects that you want to replicate. You can choose to enable
    #   or disable the replication of these objects. Currently, Amazon S3
    #   supports only the filter that you can specify for objects created
    #   with server-side encryption using a customer managed key stored in
    #   Amazon Web Services Key Management Service (SSE-KMS).
    #   @return [Types::SourceSelectionCriteria]
    #
    # @!attribute [rw] existing_object_replication
    #   Optional configuration to replicate existing source bucket objects.
    #
    #   <note markdown="1"> This parameter is no longer supported. To replicate existing
    #   objects, see [Replicating existing objects with S3 Batch
    #   Replication][1] in the *Amazon S3 User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html
    #   @return [Types::ExistingObjectReplication]
    #
    # @!attribute [rw] destination
    #   A container for information about the replication destination and
    #   its configurations including enabling the S3 Replication Time
    #   Control (S3 RTC).
    #   @return [Types::Destination]
    #
    # @!attribute [rw] delete_marker_replication
    #   Specifies whether Amazon S3 replicates delete markers. If you
    #   specify a `Filter` in your replication configuration, you must also
    #   include a `DeleteMarkerReplication` element. If your `Filter`
    #   includes a `Tag` element, the `DeleteMarkerReplication` `Status`
    #   must be set to Disabled, because Amazon S3 does not support
    #   replicating delete markers for tag-based rules. For an example
    #   configuration, see [Basic Rule Configuration][1].
    #
    #   For more information about delete marker replication, see [Basic
    #   Rule Configuration][2].
    #
    #   <note markdown="1"> If you are using an earlier version of the replication
    #   configuration, Amazon S3 handles replication of delete markers
    #   differently. For more information, see [Backward Compatibility][3].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-config-min-rule-config
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/delete-marker-replication.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations
    #   @return [Types::DeleteMarkerReplication]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRule AWS API Documentation
    #
    class ReplicationRule < Struct.new(
      :id,
      :priority,
      :prefix,
      :filter,
      :status,
      :source_selection_criteria,
      :existing_object_replication,
      :destination,
      :delete_marker_replication)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying rule filters. The filters determine the
    # subset of objects to which the rule applies. This element is required
    # only if you specify more than one filter.
    #
    # For example:
    #
    # * If you specify both a `Prefix` and a `Tag` filter, wrap these
    #   filters in an `And` tag.
    #
    # * If you specify a filter based on multiple tags, wrap the `Tag`
    #   elements in an `And` tag.
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   An array of tags containing key and value pairs.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRuleAndOperator AWS API Documentation
    #
    class ReplicationRuleAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # A filter that identifies the subset of objects to which the
    # replication rule applies. A `Filter` must specify exactly one
    # `Prefix`, `Tag`, or an `And` child element.
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the rule applies.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   A container for specifying a tag key and value.
    #
    #   The rule applies only to objects that have the tag in their tag set.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A container for specifying rule filters. The filters determine the
    #   subset of objects to which the rule applies. This element is
    #   required only if you specify more than one filter. For example:
    #
    #   * If you specify both a `Prefix` and a `Tag` filter, wrap these
    #     filters in an `And` tag.
    #
    #   * If you specify a filter based on multiple tags, wrap the `Tag`
    #     elements in an `And` tag.
    #   @return [Types::ReplicationRuleAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRuleFilter AWS API Documentation
    #
    class ReplicationRuleFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying S3 Replication Time Control (S3 RTC) related
    # information, including whether S3 RTC is enabled and the time when all
    # objects and operations on objects must be replicated. Must be
    # specified together with a `Metrics` block.
    #
    # @!attribute [rw] status
    #   Specifies whether the replication time is enabled.
    #   @return [String]
    #
    # @!attribute [rw] time
    #   A container specifying the time by which replication should be
    #   complete for all objects and operations on objects.
    #   @return [Types::ReplicationTimeValue]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationTime AWS API Documentation
    #
    class ReplicationTime < Struct.new(
      :status,
      :time)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying the time value for S3 Replication Time Control
    # (S3 RTC) and replication metrics `EventThreshold`.
    #
    # @!attribute [rw] minutes
    #   Contains an integer specifying time in minutes.
    #
    #   Valid value: 15
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationTimeValue AWS API Documentation
    #
    class ReplicationTimeValue < Struct.new(
      :minutes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for Payer.
    #
    # @!attribute [rw] payer
    #   Specifies who pays for the download and request fees.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RequestPaymentConfiguration AWS API Documentation
    #
    class RequestPaymentConfiguration < Struct.new(
      :payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for specifying if periodic `QueryProgress` messages should
    # be sent.
    #
    # @!attribute [rw] enabled
    #   Specifies whether periodic QueryProgress frames should be sent.
    #   Valid values: TRUE, FALSE. Default value: FALSE.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RequestProgress AWS API Documentation
    #
    class RequestProgress < Struct.new(
      :enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] restore_output_path
    #   Indicates the path in the provided S3 output location where Select
    #   results will be restored to.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreObjectOutput AWS API Documentation
    #
    class RestoreObjectOutput < Struct.new(
      :request_charged,
      :restore_output_path)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name containing the object to restore.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][1] in the *Amazon S3 User Guide*.
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the action was initiated.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] restore_request
    #   Container for restore job parameters.
    #   @return [Types::RestoreRequest]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreObjectRequest AWS API Documentation
    #
    class RestoreObjectRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :restore_request,
      :request_payer,
      :checksum_algorithm,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for restore job parameters.
    #
    # @!attribute [rw] days
    #   Lifetime of the active copy in days. Do not use with restores that
    #   specify `OutputLocation`.
    #
    #   The Days element is required for regular restores, and must not be
    #   provided for select requests.
    #   @return [Integer]
    #
    # @!attribute [rw] glacier_job_parameters
    #   S3 Glacier related parameters pertaining to this job. Do not use
    #   with restores that specify `OutputLocation`.
    #   @return [Types::GlacierJobParameters]
    #
    # @!attribute [rw] type
    #   Amazon S3 Select is no longer available to new customers. Existing
    #   customers of Amazon S3 Select can continue to use the feature as
    #   usual. [Learn more][1]
    #
    #   Type of restore request.
    #
    #
    #
    #   [1]: http://aws.amazon.com/blogs/storage/how-to-optimize-querying-your-data-in-amazon-s3/
    #   @return [String]
    #
    # @!attribute [rw] tier
    #   Retrieval tier at which the restore will be processed.
    #   @return [String]
    #
    # @!attribute [rw] description
    #   The optional description for the job.
    #   @return [String]
    #
    # @!attribute [rw] select_parameters
    #   Amazon S3 Select is no longer available to new customers. Existing
    #   customers of Amazon S3 Select can continue to use the feature as
    #   usual. [Learn more][1]
    #
    #   Describes the parameters for Select job types.
    #
    #
    #
    #   [1]: http://aws.amazon.com/blogs/storage/how-to-optimize-querying-your-data-in-amazon-s3/
    #   @return [Types::SelectParameters]
    #
    # @!attribute [rw] output_location
    #   Describes the location where the restore job's output is stored.
    #   @return [Types::OutputLocation]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreRequest AWS API Documentation
    #
    class RestoreRequest < Struct.new(
      :days,
      :glacier_job_parameters,
      :type,
      :tier,
      :description,
      :select_parameters,
      :output_location)
      SENSITIVE = []
      include Aws::Structure
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
    #
    # @!attribute [rw] is_restore_in_progress
    #   Specifies whether the object is currently being restored. If the
    #   object restoration is in progress, the header returns the value
    #   `TRUE`. For example:
    #
    #   `x-amz-optional-object-attributes: IsRestoreInProgress="true"`
    #
    #   If the object restoration has completed, the header returns the
    #   value `FALSE`. For example:
    #
    #   `x-amz-optional-object-attributes: IsRestoreInProgress="false",
    #   RestoreExpiryDate="2012-12-21T00:00:00.000Z"`
    #
    #   If the object hasn't been restored, there is no header response.
    #   @return [Boolean]
    #
    # @!attribute [rw] restore_expiry_date
    #   Indicates when the restored copy will expire. This value is
    #   populated only if the object has already been restored. For example:
    #
    #   `x-amz-optional-object-attributes: IsRestoreInProgress="false",
    #   RestoreExpiryDate="2012-12-21T00:00:00.000Z"`
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreStatus AWS API Documentation
    #
    class RestoreStatus < Struct.new(
      :is_restore_in_progress,
      :restore_expiry_date)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the redirect behavior and when a redirect is applied. For
    # more information about routing rules, see [Configuring advanced
    # conditional redirects][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html#advanced-conditional-redirects
    #
    # @!attribute [rw] condition
    #   A container for describing a condition that must be met for the
    #   specified redirect to apply. For example, 1. If request is for pages
    #   in the `/docs` folder, redirect to the `/documents` folder. 2. If
    #   request results in HTTP error 4xx, redirect request to another host
    #   where you might process the error.
    #   @return [Types::Condition]
    #
    # @!attribute [rw] redirect
    #   Container for redirect information. You can redirect requests to
    #   another host, to another page, or with another protocol. In the
    #   event of an error, you can specify a different error code to return.
    #   @return [Types::Redirect]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RoutingRule AWS API Documentation
    #
    class RoutingRule < Struct.new(
      :condition,
      :redirect)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies lifecycle rules for an Amazon S3 bucket. For more
    # information, see [Put Bucket Lifecycle Configuration][1] in the
    # *Amazon S3 API Reference*. For examples, see [Put Bucket Lifecycle
    # Configuration Examples][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html#API_PutBucketLifecycleConfiguration_Examples
    #
    # @!attribute [rw] expiration
    #   Specifies the expiration for the lifecycle of the object.
    #   @return [Types::LifecycleExpiration]
    #
    # @!attribute [rw] id
    #   Unique identifier for the rule. The value can't be longer than 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Object key prefix that identifies one or more objects to which this
    #   rule applies.
    #
    #   Replacement must be made for object keys containing special
    #   characters (such as carriage returns) when using XML requests. For
    #   more information, see [ XML related object key constraints][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-xml-related-constraints
    #   @return [String]
    #
    # @!attribute [rw] status
    #   If `Enabled`, the rule is currently being applied. If `Disabled`,
    #   the rule is not currently being applied.
    #   @return [String]
    #
    # @!attribute [rw] transition
    #   Specifies when an object transitions to a specified storage class.
    #   For more information about Amazon S3 lifecycle configuration rules,
    #   see [Transitioning Objects Using Amazon S3 Lifecycle][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-transition-general-considerations.html
    #   @return [Types::Transition]
    #
    # @!attribute [rw] noncurrent_version_transition
    #   Container for the transition rule that describes when noncurrent
    #   objects transition to the `STANDARD_IA`, `ONEZONE_IA`,
    #   `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`, or `DEEP_ARCHIVE`
    #   storage class. If your bucket is versioning-enabled (or versioning
    #   is suspended), you can set this action to request that Amazon S3
    #   transition noncurrent object versions to the `STANDARD_IA`,
    #   `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`, or
    #   `DEEP_ARCHIVE` storage class at a specific period in the object's
    #   lifetime.
    #   @return [Types::NoncurrentVersionTransition]
    #
    # @!attribute [rw] noncurrent_version_expiration
    #   Specifies when noncurrent object versions expire. Upon expiration,
    #   Amazon S3 permanently deletes the noncurrent object versions. You
    #   set this lifecycle configuration action on a bucket that has
    #   versioning enabled (or suspended) to request that Amazon S3 delete
    #   noncurrent object versions at a specific period in the object's
    #   lifetime.
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    #   @return [Types::NoncurrentVersionExpiration]
    #
    # @!attribute [rw] abort_incomplete_multipart_upload
    #   Specifies the days since the initiation of an incomplete multipart
    #   upload that Amazon S3 will wait before permanently removing all
    #   parts of the upload. For more information, see [ Aborting Incomplete
    #   Multipart Uploads Using a Bucket Lifecycle Configuration][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Types::AbortIncompleteMultipartUpload]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Rule AWS API Documentation
    #
    class Rule < Struct.new(
      :expiration,
      :id,
      :prefix,
      :status,
      :transition,
      :noncurrent_version_transition,
      :noncurrent_version_expiration,
      :abort_incomplete_multipart_upload)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for object key name prefix and suffix filtering rules.
    #
    # @!attribute [rw] filter_rules
    #   A list of containers for the key-value pair that defines the
    #   criteria for the filter rule.
    #   @return [Array<Types::FilterRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3KeyFilter AWS API Documentation
    #
    class S3KeyFilter < Struct.new(
      :filter_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes an Amazon S3 location that will receive the results of the
    # restore request.
    #
    # @!attribute [rw] bucket_name
    #   The name of the bucket where the restore results will be placed.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix that is prepended to the restore results for this
    #   request.
    #   @return [String]
    #
    # @!attribute [rw] encryption
    #   Contains the type of server-side encryption used.
    #   @return [Types::Encryption]
    #
    # @!attribute [rw] canned_acl
    #   The canned ACL to apply to the restore results.
    #   @return [String]
    #
    # @!attribute [rw] access_control_list
    #   A list of grants that control access to the staged results.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] tagging
    #   The tag-set that is applied to the restore results.
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] user_metadata
    #   A list of metadata to store with the restore results in S3.
    #   @return [Array<Types::MetadataEntry>]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the restore results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3Location AWS API Documentation
    #
    class S3Location < Struct.new(
      :bucket_name,
      :prefix,
      :encryption,
      :canned_acl,
      :access_control_list,
      :tagging,
      :user_metadata,
      :storage_class)
      SENSITIVE = []
      include Aws::Structure
    end

    # The destination information for a V1 S3 Metadata configuration. The
    # destination table bucket must be in the same Region and Amazon Web
    # Services account as the general purpose bucket. The specified metadata
    # table name must be unique within the `aws_s3_metadata` namespace in
    # the destination table bucket.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] table_bucket_arn
    #   The Amazon Resource Name (ARN) for the table bucket that's
    #   specified as the destination in the metadata table configuration.
    #   The destination table bucket must be in the same Region and Amazon
    #   Web Services account as the general purpose bucket.
    #   @return [String]
    #
    # @!attribute [rw] table_name
    #   The name for the metadata table in your metadata table
    #   configuration. The specified metadata table name must be unique
    #   within the `aws_s3_metadata` namespace in the destination table
    #   bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3TablesDestination AWS API Documentation
    #
    class S3TablesDestination < Struct.new(
      :table_bucket_arn,
      :table_name)
      SENSITIVE = []
      include Aws::Structure
    end

    # The destination information for a V1 S3 Metadata configuration. The
    # destination table bucket must be in the same Region and Amazon Web
    # Services account as the general purpose bucket. The specified metadata
    # table name must be unique within the `aws_s3_metadata` namespace in
    # the destination table bucket.
    #
    # <note markdown="1"> If you created your S3 Metadata configuration before July 15, 2025, we
    # recommend that you delete and re-create your configuration by using
    # [CreateBucketMetadataConfiguration][1] so that you can expire journal
    # table records and create a live inventory table.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucketMetadataConfiguration.html
    #
    # @!attribute [rw] table_bucket_arn
    #   The Amazon Resource Name (ARN) for the table bucket that's
    #   specified as the destination in the metadata table configuration.
    #   The destination table bucket must be in the same Region and Amazon
    #   Web Services account as the general purpose bucket.
    #   @return [String]
    #
    # @!attribute [rw] table_name
    #   The name for the metadata table in your metadata table
    #   configuration. The specified metadata table name must be unique
    #   within the `aws_s3_metadata` namespace in the destination table
    #   bucket.
    #   @return [String]
    #
    # @!attribute [rw] table_arn
    #   The Amazon Resource Name (ARN) for the metadata table in the
    #   metadata table configuration. The specified metadata table name must
    #   be unique within the `aws_s3_metadata` namespace in the destination
    #   table bucket.
    #   @return [String]
    #
    # @!attribute [rw] table_namespace
    #   The table bucket namespace for the metadata table in your metadata
    #   table configuration. This value is always `aws_s3_metadata`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3TablesDestinationResult AWS API Documentation
    #
    class S3TablesDestinationResult < Struct.new(
      :table_bucket_arn,
      :table_name,
      :table_arn,
      :table_namespace)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the use of SSE-KMS to encrypt delivered inventory reports.
    #
    # @!attribute [rw] key_id
    #   Specifies the ID of the Key Management Service (KMS) symmetric
    #   encryption customer managed key to use for encrypting inventory
    #   reports.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SSEKMS AWS API Documentation
    #
    class SSEKMS < Struct.new(
      :key_id)
      SENSITIVE = [:key_id]
      include Aws::Structure
    end

    # If `SSEKMS` is specified for `ObjectEncryption`, this data type
    # specifies the Amazon Web Services KMS key Amazon Resource Name (ARN)
    # to use and whether to use an S3 Bucket Key for server-side encryption
    # using Key Management Service (KMS) keys (SSE-KMS).
    #
    # @!attribute [rw] kms_key_arn
    #   Specifies the Amazon Web Services KMS key Amazon Resource Name (ARN)
    #   to use for the updated server-side encryption type. Required if
    #   `ObjectEncryption` specifies `SSEKMS`.
    #
    #   <note markdown="1"> You must specify the full Amazon Web Services KMS key ARN. The KMS
    #   key ID and KMS key alias aren't supported.
    #
    #    </note>
    #
    #   Pattern: (`arn:aws[-a-z0-9]*:kms:[-a-z0-9]*:[0-9]{12}:key/.+`)
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). If this value isn't specified, it defaults to
    #   `false`. Setting this value to `true` causes Amazon S3 to use an S3
    #   Bucket Key for object encryption with SSE-KMS. For more information,
    #   see [ Using Amazon S3 Bucket Keys][1] in the *Amazon S3 User Guide*.
    #
    #   Valid Values: `true` \| `false`
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SSEKMSEncryption AWS API Documentation
    #
    class SSEKMSEncryption < Struct.new(
      :kms_key_arn,
      :bucket_key_enabled)
      SENSITIVE = [:kms_key_arn]
      include Aws::Structure
    end

    # Specifies the use of SSE-S3 to encrypt delivered inventory reports.
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SSES3 AWS API Documentation
    #
    class SSES3 < Aws::EmptyStructure; end

    # Specifies the byte range of the object to get the records from. A
    # record is processed when its first byte is contained by the range.
    # This parameter is optional, but when specified, it must not be empty.
    # See RFC 2616, Section 14.35.1 about how to specify the start and end
    # of the range.
    #
    # @!attribute [rw] start
    #   Specifies the start of the byte range. This parameter is optional.
    #   Valid values: non-negative integers. The default value is 0. If only
    #   `start` is supplied, it means scan from that point to the end of the
    #   file. For example, `<scanrange><start>50</start></scanrange>` means
    #   scan from byte 50 until the end of the file.
    #   @return [Integer]
    #
    # @!attribute [rw] end
    #   Specifies the end of the byte range. This parameter is optional.
    #   Valid values: non-negative integers. The default value is one less
    #   than the size of the object being queried. If only the End parameter
    #   is supplied, it is interpreted to mean scan the last N bytes of the
    #   file. For example, `<scanrange><end>50</end></scanrange>` means scan
    #   the last 50 bytes.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ScanRange AWS API Documentation
    #
    class ScanRange < Struct.new(
      :start,
      :end)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] payload
    #   The array of results.
    #   @return [Types::SelectObjectContentEventStream]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentOutput AWS API Documentation
    #
    class SelectObjectContentOutput < Struct.new(
      :payload)
      SENSITIVE = []
      include Aws::Structure
    end

    # <note markdown="1"> Learn Amazon S3 Select is no longer available to new customers.
    # Existing customers of Amazon S3 Select can continue to use the feature
    # as usual. [Learn more][1]
    #
    #  </note>
    #
    # Request to filter the contents of an Amazon S3 object based on a
    # simple Structured Query Language (SQL) statement. In the request,
    # along with the SQL expression, you must specify a data serialization
    # format (JSON or CSV) of the object. Amazon S3 uses this to parse
    # object data into records. It returns only records that match the
    # specified SQL expression. You must also specify the data serialization
    # format for the response. For more information, see [S3Select API
    # Documentation][2].
    #
    #
    #
    # [1]: http://aws.amazon.com/blogs/storage/how-to-optimize-querying-your-data-in-amazon-s3/
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectSELECTContent.html
    #
    # @!attribute [rw] bucket
    #   The S3 bucket.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the
    #   object. This parameter is needed only when the object was created
    #   using a checksum algorithm. For more information, see [Protecting
    #   data using SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] expression
    #   The expression that is used to query the object.
    #   @return [String]
    #
    # @!attribute [rw] expression_type
    #   The type of the provided expression (for example, SQL).
    #   @return [String]
    #
    # @!attribute [rw] request_progress
    #   Specifies if periodic request progress information should be
    #   enabled.
    #   @return [Types::RequestProgress]
    #
    # @!attribute [rw] input_serialization
    #   Describes the format of the data in the object that is being
    #   queried.
    #   @return [Types::InputSerialization]
    #
    # @!attribute [rw] output_serialization
    #   Describes the format of the data that you want Amazon S3 to return
    #   in response.
    #   @return [Types::OutputSerialization]
    #
    # @!attribute [rw] scan_range
    #   Specifies the byte range of the object to get the records from. A
    #   record is processed when its first byte is contained by the range.
    #   This parameter is optional, but when specified, it must not be
    #   empty. See RFC 2616, Section 14.35.1 about how to specify the start
    #   and end of the range.
    #
    #   `ScanRange`may be used in the following ways:
    #
    #   * `<scanrange><start>50</start><end>100</end></scanrange>` - process
    #     only the records starting between the bytes 50 and 100 (inclusive,
    #     counting from zero)
    #
    #   * `<scanrange><start>50</start></scanrange>` - process only the
    #     records starting after the byte 50
    #
    #   * `<scanrange><end>50</end></scanrange>` - process only the records
    #     within the last 50 bytes of the file.
    #   @return [Types::ScanRange]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentRequest AWS API Documentation
    #
    class SelectObjectContentRequest < Struct.new(
      :bucket,
      :key,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :expression,
      :expression_type,
      :request_progress,
      :input_serialization,
      :output_serialization,
      :scan_range,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Amazon S3 Select is no longer available to new customers. Existing
    # customers of Amazon S3 Select can continue to use the feature as
    # usual. [Learn more][1]
    #
    # Describes the parameters for Select job types.
    #
    # Learn [How to optimize querying your data in Amazon S3][1] using
    # [Amazon Athena][2], [S3 Object Lambda][3], or client-side filtering.
    #
    #
    #
    # [1]: http://aws.amazon.com/blogs/storage/how-to-optimize-querying-your-data-in-amazon-s3/
    # [2]: https://docs.aws.amazon.com/athena/latest/ug/what-is.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html
    #
    # @!attribute [rw] input_serialization
    #   Describes the serialization format of the object.
    #   @return [Types::InputSerialization]
    #
    # @!attribute [rw] expression_type
    #   The type of the provided expression (for example, SQL).
    #   @return [String]
    #
    # @!attribute [rw] expression
    #   Amazon S3 Select is no longer available to new customers. Existing
    #   customers of Amazon S3 Select can continue to use the feature as
    #   usual. [Learn more][1]
    #
    #   The expression that is used to query the object.
    #
    #
    #
    #   [1]: http://aws.amazon.com/blogs/storage/how-to-optimize-querying-your-data-in-amazon-s3/
    #   @return [String]
    #
    # @!attribute [rw] output_serialization
    #   Describes how the results of the Select job are serialized.
    #   @return [Types::OutputSerialization]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectParameters AWS API Documentation
    #
    class SelectParameters < Struct.new(
      :input_serialization,
      :expression_type,
      :expression,
      :output_serialization)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the default server-side encryption to apply to new objects
    # in the bucket. If a PUT Object request doesn't specify any
    # server-side encryption, this default encryption will be applied. For
    # more information, see [PutBucketEncryption][1].
    #
    # <note markdown="1"> * **General purpose buckets** - If you don't specify a customer
    #   managed key at configuration, Amazon S3 automatically creates an
    #   Amazon Web Services KMS key (`aws/s3`) in your Amazon Web Services
    #   account the first time that you add an object encrypted with SSE-KMS
    #   to a bucket. By default, Amazon S3 uses this KMS key for SSE-KMS.
    #
    # * **Directory buckets** - Your SSE-KMS configuration can only support
    #   1 [customer managed key][2] per directory bucket's lifetime. The
    #   [Amazon Web Services managed key][3] (`aws/s3`) isn't supported.
    #
    # * **Directory buckets** - For directory buckets, there are only two
    #   supported options for server-side encryption: SSE-S3 and SSE-KMS.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTencryption.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    #
    # @!attribute [rw] sse_algorithm
    #   Server-side encryption algorithm to use for the default encryption.
    #
    #   <note markdown="1"> For directory buckets, there are only two supported values for
    #   server-side encryption: `AES256` and `aws:kms`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] kms_master_key_id
    #   Amazon Web Services Key Management Service (KMS) customer managed
    #   key ID to use for the default encryption.
    #
    #   <note markdown="1"> * **General purpose buckets** - This parameter is allowed if and
    #     only if `SSEAlgorithm` is set to `aws:kms` or `aws:kms:dsse`.
    #
    #   * **Directory buckets** - This parameter is allowed if and only if
    #     `SSEAlgorithm` is set to `aws:kms`.
    #
    #    </note>
    #
    #   You can specify the key ID, key alias, or the Amazon Resource Name
    #   (ARN) of the KMS key.
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key Alias: `alias/alias-name`
    #
    #   If you are using encryption with cross-account or Amazon Web
    #   Services service operations, you must use a fully qualified KMS key
    #   ARN. For more information, see [Using encryption for cross-account
    #   operations][1].
    #
    #   <note markdown="1"> * **General purpose buckets** - If you're specifying a customer
    #     managed KMS key, we recommend using a fully qualified KMS key ARN.
    #     If you use a KMS key alias instead, then KMS resolves the key
    #     within the requester’s account. This behavior can result in data
    #     that's encrypted with a KMS key that belongs to the requester,
    #     and not the bucket owner. Also, if you use a key ID, you can run
    #     into a LogDestination undeliverable error when creating a VPC flow
    #     log.
    #
    #   * **Directory buckets** - When you specify an [KMS customer managed
    #     key][2] for encryption in your directory bucket, only use the key
    #     ID or key ARN. The key alias format of the KMS key isn't
    #     supported.
    #
    #    </note>
    #
    #   Amazon S3 only supports symmetric encryption KMS keys. For more
    #   information, see [Asymmetric keys in Amazon Web Services KMS][3] in
    #   the *Amazon Web Services Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html#bucket-encryption-update-bucket-policy
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionByDefault AWS API Documentation
    #
    class ServerSideEncryptionByDefault < Struct.new(
      :sse_algorithm,
      :kms_master_key_id)
      SENSITIVE = [:kms_master_key_id]
      include Aws::Structure
    end

    # Specifies the default server-side-encryption configuration.
    #
    # @!attribute [rw] rules
    #   Container for information about a particular server-side encryption
    #   configuration rule.
    #   @return [Array<Types::ServerSideEncryptionRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionConfiguration AWS API Documentation
    #
    class ServerSideEncryptionConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the default server-side encryption configuration.
    #
    # <note markdown="1"> * **General purpose buckets** - If you're specifying a customer
    #   managed KMS key, we recommend using a fully qualified KMS key ARN.
    #   If you use a KMS key alias instead, then KMS resolves the key within
    #   the requester’s account. This behavior can result in data that's
    #   encrypted with a KMS key that belongs to the requester, and not the
    #   bucket owner.
    #
    # * **Directory buckets** - When you specify an [KMS customer managed
    #   key][1] for encryption in your directory bucket, only use the key ID
    #   or key ARN. The key alias format of the KMS key isn't supported.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    #
    # @!attribute [rw] apply_server_side_encryption_by_default
    #   Specifies the default server-side encryption to apply to new objects
    #   in the bucket. If a PUT Object request doesn't specify any
    #   server-side encryption, this default encryption will be applied.
    #   @return [Types::ServerSideEncryptionByDefault]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key with
    #   server-side encryption using KMS (SSE-KMS) for new objects in the
    #   bucket. Existing objects are not affected. Setting the
    #   `BucketKeyEnabled` element to `true` causes Amazon S3 to use an S3
    #   Bucket Key.
    #
    #   <note markdown="1"> * **General purpose buckets** - By default, S3 Bucket Key is not
    #     enabled. For more information, see [Amazon S3 Bucket Keys][1] in
    #     the *Amazon S3 User Guide*.
    #
    #   * **Directory buckets** - S3 Bucket Keys are always enabled for
    #     `GET` and `PUT` operations in a directory bucket and can’t be
    #     disabled. S3 Bucket Keys aren't supported, when you copy SSE-KMS
    #     encrypted objects from general purpose buckets to directory
    #     buckets, from directory buckets to general purpose buckets, or
    #     between directory buckets, through [CopyObject][2],
    #     [UploadPartCopy][3], [the Copy operation in Batch Operations][4],
    #     or [the import jobs][5]. In this case, Amazon S3 makes a call to
    #     KMS every time a copy request is made for a KMS-encrypted object.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    #   [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-objects-Batch-Ops
    #   [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-import-job
    #   @return [Boolean]
    #
    # @!attribute [rw] blocked_encryption_types
    #   A bucket-level setting for Amazon S3 general purpose buckets used to
    #   prevent the upload of new objects encrypted with the specified
    #   server-side encryption type. For example, blocking an encryption
    #   type will block `PutObject`, `CopyObject`, `PostObject`, multipart
    #   upload, and replication requests to the bucket for objects with the
    #   specified encryption type. However, you can continue to read and
    #   list any pre-existing objects already encrypted with the specified
    #   encryption type. For more information, see [Blocking or unblocking
    #   SSE-C for a general purpose bucket][1].
    #
    #   <note markdown="1"> Currently, this parameter only supports blocking or unblocking
    #   server-side encryption with customer-provided keys (SSE-C). For more
    #   information about SSE-C, see [Using server-side encryption with
    #   customer-provided keys (SSE-C)][2].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/blocking-unblocking-s3-c-encryption-gpb.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html
    #   @return [Types::BlockedEncryptionTypes]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionRule AWS API Documentation
    #
    class ServerSideEncryptionRule < Struct.new(
      :apply_server_side_encryption_by_default,
      :bucket_key_enabled,
      :blocked_encryption_types)
      SENSITIVE = []
      include Aws::Structure
    end

    # The established temporary security credentials of the session.
    #
    # <note markdown="1"> **Directory buckets** - These session credentials are only supported
    # for the authentication and authorization of Zonal endpoint API
    # operations on directory buckets.
    #
    #  </note>
    #
    # @!attribute [rw] access_key_id
    #   A unique identifier that's associated with a secret access key. The
    #   access key ID and the secret access key are used together to sign
    #   programmatic Amazon Web Services requests cryptographically.
    #   @return [String]
    #
    # @!attribute [rw] secret_access_key
    #   A key that's used with the access key ID to cryptographically sign
    #   programmatic Amazon Web Services requests. Signing a request
    #   identifies the sender and prevents the request from being altered.
    #   @return [String]
    #
    # @!attribute [rw] session_token
    #   A part of the temporary security credentials. The session token is
    #   used to validate the temporary security credentials.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   Temporary security credentials expire after a specified interval.
    #   After temporary credentials expire, any calls that you make with
    #   those credentials will fail. So you must generate a new set of
    #   temporary credentials. Temporary credentials cannot be extended or
    #   refreshed beyond the original specified interval.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SessionCredentials AWS API Documentation
    #
    class SessionCredentials < Struct.new(
      :access_key_id,
      :secret_access_key,
      :session_token,
      :expiration)
      SENSITIVE = [:secret_access_key, :session_token]
      include Aws::Structure
    end

    # To use simple format for S3 keys for log objects, set SimplePrefix to
    # an empty object.
    #
    # `[DestinationPrefix][YYYY]-[MM]-[DD]-[hh]-[mm]-[ss]-[UniqueString]`
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SimplePrefix AWS API Documentation
    #
    class SimplePrefix < Aws::EmptyStructure; end

    # A container that describes additional filters for identifying the
    # source objects that you want to replicate. You can choose to enable or
    # disable the replication of these objects. Currently, Amazon S3
    # supports only the filter that you can specify for objects created with
    # server-side encryption using a customer managed key stored in Amazon
    # Web Services Key Management Service (SSE-KMS).
    #
    # @!attribute [rw] sse_kms_encrypted_objects
    #   A container for filter information for the selection of Amazon S3
    #   objects encrypted with Amazon Web Services KMS. If you include
    #   `SourceSelectionCriteria` in the replication configuration, this
    #   element is required.
    #   @return [Types::SseKmsEncryptedObjects]
    #
    # @!attribute [rw] replica_modifications
    #   A filter that you can specify for selections for modifications on
    #   replicas. Amazon S3 doesn't replicate replica modifications by
    #   default. In the latest version of replication configuration (when
    #   `Filter` is specified), you can specify this element and set the
    #   status to `Enabled` to replicate modifications on replicas.
    #
    #   <note markdown="1"> If you don't specify the `Filter` element, Amazon S3 assumes that
    #   the replication configuration is the earlier version, V1. In the
    #   earlier version, this element is not allowed
    #
    #    </note>
    #   @return [Types::ReplicaModifications]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SourceSelectionCriteria AWS API Documentation
    #
    class SourceSelectionCriteria < Struct.new(
      :sse_kms_encrypted_objects,
      :replica_modifications)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for filter information for the selection of S3 objects
    # encrypted with Amazon Web Services KMS.
    #
    # @!attribute [rw] status
    #   Specifies whether Amazon S3 replicates objects created with
    #   server-side encryption using an Amazon Web Services KMS key stored
    #   in Amazon Web Services Key Management Service.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SseKmsEncryptedObjects AWS API Documentation
    #
    class SseKmsEncryptedObjects < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the stats details.
    #
    # @!attribute [rw] bytes_scanned
    #   The total number of object bytes scanned.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_processed
    #   The total number of uncompressed object bytes processed.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_returned
    #   The total number of bytes of records payload data returned.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Stats AWS API Documentation
    #
    class Stats < Struct.new(
      :bytes_scanned,
      :bytes_processed,
      :bytes_returned)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the Stats Event.
    #
    # @!attribute [rw] details
    #   The Stats event details.
    #   @return [Types::Stats]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StatsEvent AWS API Documentation
    #
    class StatsEvent < Struct.new(
      :details,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies data related to access patterns to be collected and made
    # available to analyze the tradeoffs between different storage classes
    # for an Amazon S3 bucket.
    #
    # @!attribute [rw] data_export
    #   Specifies how data related to the storage class analysis for an
    #   Amazon S3 bucket should be exported.
    #   @return [Types::StorageClassAnalysisDataExport]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StorageClassAnalysis AWS API Documentation
    #
    class StorageClassAnalysis < Struct.new(
      :data_export)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for data related to the storage class analysis for an Amazon
    # S3 bucket for export.
    #
    # @!attribute [rw] output_schema_version
    #   The version of the output schema to use when exporting data. Must be
    #   `V_1`.
    #   @return [String]
    #
    # @!attribute [rw] destination
    #   The place to store the data for an analysis.
    #   @return [Types::AnalyticsExportDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StorageClassAnalysisDataExport AWS API Documentation
    #
    class StorageClassAnalysisDataExport < Struct.new(
      :output_schema_version,
      :destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container of a key value name pair.
    #
    # @!attribute [rw] key
    #   Name of the object key.
    #   @return [String]
    #
    # @!attribute [rw] value
    #   Value of the tag.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Tag AWS API Documentation
    #
    class Tag < Struct.new(
      :key,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for `TagSet` elements.
    #
    # @!attribute [rw] tag_set
    #   A collection for a set of tags
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Tagging AWS API Documentation
    #
    class Tagging < Struct.new(
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for granting information.
    #
    # Buckets that use the bucket owner enforced setting for Object
    # Ownership don't support target grants. For more information, see
    # [Permissions server access log delivery][1] in the *Amazon S3 User
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
    #
    # @!attribute [rw] grantee
    #   Container for the person being granted permissions.
    #   @return [Types::Grantee]
    #
    # @!attribute [rw] permission
    #   Logging permissions assigned to the grantee for the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TargetGrant AWS API Documentation
    #
    class TargetGrant < Struct.new(
      :grantee,
      :permission)
      SENSITIVE = []
      include Aws::Structure
    end

    # Amazon S3 key format for log objects. Only one format,
    # PartitionedPrefix or SimplePrefix, is allowed.
    #
    # @!attribute [rw] simple_prefix
    #   To use the simple format for S3 keys for log objects. To specify
    #   SimplePrefix format, set SimplePrefix to \{}.
    #   @return [Types::SimplePrefix]
    #
    # @!attribute [rw] partitioned_prefix
    #   Partitioned S3 key for log objects.
    #   @return [Types::PartitionedPrefix]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TargetObjectKeyFormat AWS API Documentation
    #
    class TargetObjectKeyFormat < Struct.new(
      :simple_prefix,
      :partitioned_prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # The S3 Intelligent-Tiering storage class is designed to optimize
    # storage costs by automatically moving data to the most cost-effective
    # storage access tier, without additional operational overhead.
    #
    # @!attribute [rw] days
    #   The number of consecutive days of no access after which an object
    #   will be eligible to be transitioned to the corresponding tier. The
    #   minimum number of days specified for Archive Access tier must be at
    #   least 90 days and Deep Archive Access tier must be at least 180
    #   days. The maximum can be up to 2 years (730 days).
    #   @return [Integer]
    #
    # @!attribute [rw] access_tier
    #   S3 Intelligent-Tiering access tier. See [Storage class for
    #   automatically optimizing frequently and infrequently accessed
    #   objects][1] for a list of access tiers in the S3 Intelligent-Tiering
    #   storage class.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Tiering AWS API Documentation
    #
    class Tiering < Struct.new(
      :days,
      :access_tier)
      SENSITIVE = []
      include Aws::Structure
    end

    # You have attempted to add more parts than the maximum of 10000 that
    # are allowed for this object. You can use the CopyObject operation to
    # copy this object to another and then add more data to the newly copied
    # object.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TooManyParts AWS API Documentation
    #
    class TooManyParts < Aws::EmptyStructure; end

    # A container for specifying the configuration for publication of
    # messages to an Amazon Simple Notification Service (Amazon SNS) topic
    # when Amazon S3 detects specified events.
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] topic_arn
    #   The Amazon Resource Name (ARN) of the Amazon SNS topic to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   The Amazon S3 bucket event about which to send notifications. For
    #   more information, see [Supported Event Types][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring event notifications using object
    #   key name filtering][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-filtering.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TopicConfiguration AWS API Documentation
    #
    class TopicConfiguration < Struct.new(
      :id,
      :topic_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for publication of
    # messages to an Amazon Simple Notification Service (Amazon SNS) topic
    # when Amazon S3 detects specified events. This data type is deprecated.
    # Use [TopicConfiguration][1] instead.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_TopicConfiguration.html
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of events related to objects
    #   @return [Array<String>]
    #
    # @!attribute [rw] event
    #   Bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] topic
    #   Amazon SNS topic to which Amazon S3 will publish a message to report
    #   the specified events for the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TopicConfigurationDeprecated AWS API Documentation
    #
    class TopicConfigurationDeprecated < Struct.new(
      :id,
      :events,
      :event,
      :topic)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies when an object transitions to a specified storage class. For
    # more information about Amazon S3 lifecycle configuration rules, see
    # [Transitioning Objects Using Amazon S3 Lifecycle][1] in the *Amazon S3
    # User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-transition-general-considerations.html
    #
    # @!attribute [rw] date
    #   Indicates when objects are transitioned to the specified storage
    #   class. The date value must be in ISO 8601 format. The time is always
    #   midnight UTC.
    #   @return [Time]
    #
    # @!attribute [rw] days
    #   Indicates the number of days after creation when objects are
    #   transitioned to the specified storage class. If the specified
    #   storage class is `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`, or
    #   `DEEP_ARCHIVE`, valid values are `0` or positive integers. If the
    #   specified storage class is `STANDARD_IA` or `ONEZONE_IA`, valid
    #   values are positive integers greater than `30`. Be aware that some
    #   storage classes have a minimum storage duration and that you're
    #   charged for transitioning objects before their minimum storage
    #   duration. For more information, see [ Constraints and considerations
    #   for transitions][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-transition-general-considerations.html#lifecycle-configuration-constraints
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The storage class to which you want the object to transition.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Transition AWS API Documentation
    #
    class Transition < Struct.new(
      :date,
      :days,
      :storage_class)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that corresponds to the metadata
    #   configuration that you want to enable or disable an inventory table
    #   for.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The `Content-MD5` header for the inventory table configuration.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The checksum algorithm to use with your inventory table
    #   configuration.
    #   @return [String]
    #
    # @!attribute [rw] inventory_table_configuration
    #   The contents of your inventory table configuration.
    #   @return [Types::InventoryTableConfigurationUpdates]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that corresponds to
    #   the metadata table configuration that you want to enable or disable
    #   an inventory table for.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UpdateBucketMetadataInventoryTableConfigurationRequest AWS API Documentation
    #
    class UpdateBucketMetadataInventoryTableConfigurationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :inventory_table_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The general purpose bucket that corresponds to the metadata
    #   configuration that you want to enable or disable journal table
    #   record expiration for.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The `Content-MD5` header for the journal table configuration.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   The checksum algorithm to use with your journal table configuration.
    #   @return [String]
    #
    # @!attribute [rw] journal_table_configuration
    #   The contents of your journal table configuration.
    #   @return [Types::JournalTableConfigurationUpdates]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The expected owner of the general purpose bucket that corresponds to
    #   the metadata table configuration that you want to enable or disable
    #   journal table record expiration for.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UpdateBucketMetadataJournalTableConfigurationRequest AWS API Documentation
    #
    class UpdateBucketMetadataJournalTableConfigurationRequest < Struct.new(
      :bucket,
      :content_md5,
      :checksum_algorithm,
      :journal_table_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The name of the general purpose bucket that contains the specified
    #   object key name.
    #
    #   When you use this operation with an access point attached to a
    #   general purpose bucket, you must either provide the alias of the
    #   access point in place of the bucket name or you must specify the
    #   access point Amazon Resource Name (ARN). When using the access point
    #   ARN, you must direct requests to the access point hostname. The
    #   access point hostname takes the form `
    #   AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com`. When
    #   using this operation with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see [
    #   Referencing access points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points-naming.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name of the object that you want to update the server-side
    #   encryption type for.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object that you want to update the server-side
    #   encryption type for.
    #   @return [String]
    #
    # @!attribute [rw] object_encryption
    #   The updated server-side encryption type for this object. The
    #   `UpdateObjectEncryption` operation supports the SSE-S3 and SSE-KMS
    #   encryption types.
    #
    #   Valid Values: `SSES3` \| `SSEKMS`
    #   @return [Types::ObjectEncryption]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide doesn't match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body. For requests made using the
    #   Amazon Web Services Command Line Interface (CLI) or Amazon Web
    #   Services SDKs, this field is calculated automatically.
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use an Amazon Web Services SDK. This header doesn't
    #   provide any additional functionality if you don't use the SDK. When
    #   you send this header, there must be a corresponding `x-amz-checksum`
    #   or `x-amz-trailer` header sent. Otherwise, Amazon S3 fails the
    #   request with the HTTP status code `400 Bad Request`. For more
    #   information, see [ Checking object integrity ][1] in the *Amazon S3
    #   User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UpdateObjectEncryptionRequest AWS API Documentation
    #
    class UpdateObjectEncryptionRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :object_encryption,
      :request_payer,
      :expected_bucket_owner,
      :content_md5,
      :checksum_algorithm)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UpdateObjectEncryptionResponse AWS API Documentation
    #
    class UpdateObjectEncryptionResponse < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] copy_source_version_id
    #   The version of the source object that was copied, if you have
    #   enabled versioning on the source bucket.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_part_result
    #   Container for all response elements.
    #   @return [Types::CopyPartResult]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the multipart upload uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartCopyOutput AWS API Documentation
    #
    class UploadPartCopyOutput < Struct.new(
      :copy_source_version_id,
      :copy_part_result,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :bucket_key_enabled,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   The bucket name.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Copying objects across different Amazon Web Services Regions isn't
    #   supported when the source or destination bucket is in Amazon Web
    #   Services Local Zones. The source and destination buckets must have
    #   the same parent Amazon Web Services Region. Otherwise, you get an
    #   HTTP `400 Bad Request` error with the error code `InvalidRequest`.
    #
    #    </note>
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] copy_source
    #   Specifies the source object for the copy operation. You specify the
    #   value in one of two formats, depending on whether you want to access
    #   the source object through an [access point][1]:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and key of the source object, separated by a
    #     slash (/). For example, to copy the object `reports/january.pdf`
    #     from the bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be
    #     URL-encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     access point `my-access-point` owned by account `123456789012` in
    #     Region `us-west-2`, use the URL encoding of
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
    #   If your bucket has versioning enabled, you could have multiple
    #   versions of the same object. By default, `x-amz-copy-source`
    #   identifies the current version of the source object to copy. To copy
    #   a specific version of the source object to copy, append
    #   `?versionId=<version-id>` to the `x-amz-copy-source` request header
    #   (for example, `x-amz-copy-source:
    #   /awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #
    #   If the current version is a delete marker and you don't specify a
    #   versionId in the `x-amz-copy-source` request header, Amazon S3
    #   returns a `404 Not Found` error, because the object does not exist.
    #   If you specify versionId in the `x-amz-copy-source` and the
    #   versionId is a delete marker, Amazon S3 returns an HTTP `400 Bad
    #   Request` error, because you are not allowed to specify a delete
    #   marker as a version for the `x-amz-copy-source`.
    #
    #   <note markdown="1"> **Directory buckets** - S3 Versioning isn't enabled and supported
    #   for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified
    #   tag.
    #
    #   If both of the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request as follows:
    #
    #   `x-amz-copy-source-if-match` condition evaluates to `true`, and;
    #
    #   `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #   `false`;
    #
    #   Amazon S3 returns `200 OK` and copies the data.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #
    #   If both of the `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request as follows:
    #
    #   `x-amz-copy-source-if-none-match` condition evaluates to `false`,
    #   and;
    #
    #   `x-amz-copy-source-if-modified-since` condition evaluates to `true`;
    #
    #   Amazon S3 returns `412 Precondition Failed` response code.
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #
    #   If both of the `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request as follows:
    #
    #   `x-amz-copy-source-if-none-match` condition evaluates to `false`,
    #   and;
    #
    #   `x-amz-copy-source-if-modified-since` condition evaluates to `true`;
    #
    #   Amazon S3 returns `412 Precondition Failed` response code.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #
    #   If both of the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request as follows:
    #
    #   `x-amz-copy-source-if-match` condition evaluates to `true`, and;
    #
    #   `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #   `false`;
    #
    #   Amazon S3 returns `200 OK` and copies the data.
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_range
    #   The range of bytes to copy from the source object. The range value
    #   must use the form bytes=first-last, where the first and last are the
    #   zero-based byte offsets to copy. For example, bytes=0-9 indicates
    #   that you want to copy the first 10 bytes of the source. You can copy
    #   a range only if the source object is greater than 5 MB.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of part being copied. This is a positive integer between
    #   1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose part is being
    #   copied.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header. This must
    #   be the same encryption key specified in the initiate multipart
    #   upload request.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported when the destination bucket is a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object
    #   (for example, `AES256`).
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   to decrypt the source object. The encryption key provided in this
    #   header must be one that was used when the source object was created.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported when the source object is in a
    #   directory bucket.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected destination bucket owner. If the
    #   account ID that you provide does not match the actual owner of the
    #   destination bucket, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #   @return [String]
    #
    # @!attribute [rw] expected_source_bucket_owner
    #   The account ID of the expected source bucket owner. If the account
    #   ID that you provide does not match the actual owner of the source
    #   bucket, the request fails with the HTTP status code `403 Forbidden`
    #   (access denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartCopyRequest AWS API Documentation
    #
    class UploadPartCopyRequest < Struct.new(
      :bucket,
      :copy_source,
      :copy_source_if_match,
      :copy_source_if_modified_since,
      :copy_source_if_none_match,
      :copy_source_if_unmodified_since,
      :copy_source_range,
      :key,
      :part_number,
      :upload_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :copy_source_sse_customer_algorithm,
      :copy_source_sse_customer_key,
      :copy_source_sse_customer_key_md5,
      :request_payer,
      :expected_bucket_owner,
      :expected_source_bucket_owner)
      SENSITIVE = [:sse_customer_key, :copy_source_sse_customer_key]
      include Aws::Structure
    end

    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when you store this object
    #   in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag for the uploaded object.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   The Base64 encoded, 32-bit `CRC32 checksum` of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   The Base64 encoded, 32-bit `CRC32C` checksum of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   part. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   The Base64 encoded, 160-bit `SHA1` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use the API operation on an object that was
    #   uploaded using multipart uploads, this value may not be a direct
    #   checksum value of the full object. Instead, it's a calculation
    #   based on the checksum values of each individual part. For more
    #   information about how checksums are calculated with multipart
    #   uploads, see [ Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   The Base64 encoded, 256-bit `SHA256` digest of the object. This
    #   checksum is only present if the checksum was uploaded with the
    #   object. When you use an API operation on an object that was uploaded
    #   using multipart uploads, this value may not be a direct checksum
    #   value of the full object. Instead, it's a calculation based on the
    #   checksum values of each individual part. For more information about
    #   how checksums are calculated with multipart uploads, see [ Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to confirm the
    #   encryption algorithm that's used.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide the
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, indicates the ID of the KMS key that was used for object
    #   encryption.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the multipart upload uses an S3 Bucket Key for
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartOutput AWS API Documentation
    #
    class UploadPartOutput < Struct.new(
      :server_side_encryption,
      :etag,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :bucket_key_enabled,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #
    #   **Directory buckets** - When you use this operation with a directory
    #   bucket, you must use virtual-hosted-style requests in the format `
    #   Bucket-name.s3express-zone-id.region-code.amazonaws.com`. Path-style
    #   requests are not supported. Directory bucket names must be unique in
    #   the chosen Zone (Availability Zone or Local Zone). Bucket names must
    #   follow the format ` bucket-base-name--zone-id--x-s3` (for example, `
    #   amzn-s3-demo-bucket--usw2-az1--x-s3`). For information about bucket
    #   naming restrictions, see [Directory bucket naming rules][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   **Access points** - When you use this action with an access point
    #   for general purpose buckets, you must provide the alias of the
    #   access point in place of the bucket name or specify the access point
    #   ARN. When you use this action with an access point for directory
    #   buckets, you must provide the access point name in place of the
    #   bucket name. When using the access point ARN, you must direct
    #   requests to the access point hostname. The access point hostname
    #   takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the
    #   bucket name. For more information about access point ARNs, see
    #   [Using access points][2] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> Object Lambda access points are not supported by directory buckets.
    #
    #    </note>
    #
    #   **S3 on Outposts** - When you use this action with S3 on Outposts,
    #   you must direct requests to the S3 on Outposts hostname. The S3 on
    #   Outposts hostname takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts, the destination bucket
    #   must be the Outposts access point ARN or the access point alias. For
    #   more information about S3 on Outposts, see [What is S3 on
    #   Outposts?][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-naming-rules.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #   @return [String]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically.
    #   @return [Integer]
    #
    # @!attribute [rw] content_md5
    #   The Base64 encoded 128-bit MD5 digest of the part data. This
    #   parameter is auto-populated when using the command from the CLI.
    #   This parameter is required if object lock parameters are specified.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any
    #   provided `ChecksumAlgorithm` parameter.
    #
    #   This checksum algorithm must be the same for all parts and it match
    #   the checksum value supplied in the `CreateMultipartUpload` request.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the
    #   object. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   part. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 160-bit `SHA1` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 256-bit `SHA256` digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of part being uploaded. This is a positive integer
    #   between 1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose part is being
    #   uploaded.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm header`. This must
    #   be the same encryption key specified in the initiate multipart
    #   upload request.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. If either the source or destination S3 bucket has
    #   Requester Pays enabled, the requester will pay for the corresponding
    #   charges. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the
    #   request fails with the HTTP status code `403 Forbidden` (access
    #   denied).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartRequest AWS API Documentation
    #
    class UploadPartRequest < Struct.new(
      :body,
      :bucket,
      :content_length,
      :content_md5,
      :checksum_algorithm,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :key,
      :part_number,
      :upload_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Describes the versioning state of an Amazon S3 bucket. For more
    # information, see [PUT Bucket versioning][1] in the *Amazon S3 API
    # Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
    #
    # @!attribute [rw] mfa_delete
    #   Specifies whether MFA delete is enabled in the bucket versioning
    #   configuration. This element is only returned if the bucket has been
    #   configured with MFA delete. If the bucket has never been so
    #   configured, this element is not returned.
    #   @return [String]
    #
    # @!attribute [rw] status
    #   The versioning state of the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/VersioningConfiguration AWS API Documentation
    #
    class VersioningConfiguration < Struct.new(
      :mfa_delete,
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies website configuration parameters for an Amazon S3 bucket.
    #
    # @!attribute [rw] error_document
    #   The name of the error document for the website.
    #   @return [Types::ErrorDocument]
    #
    # @!attribute [rw] index_document
    #   The name of the index document for the website.
    #   @return [Types::IndexDocument]
    #
    # @!attribute [rw] redirect_all_requests_to
    #   The redirect behavior for every request to this bucket's website
    #   endpoint.
    #
    #   If you specify this property, you can't specify any other property.
    #   @return [Types::RedirectAllRequestsTo]
    #
    # @!attribute [rw] routing_rules
    #   Rules that define when a redirect is applied and the redirect
    #   behavior.
    #   @return [Array<Types::RoutingRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/WebsiteConfiguration AWS API Documentation
    #
    class WebsiteConfiguration < Struct.new(
      :error_document,
      :index_document,
      :redirect_all_requests_to,
      :routing_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_route
    #   Route prefix to the HTTP URL generated.
    #   @return [String]
    #
    # @!attribute [rw] request_token
    #   A single use encrypted token that maps `WriteGetObjectResponse` to
    #   the end user `GetObject` request.
    #   @return [String]
    #
    # @!attribute [rw] body
    #   The object data.
    #   @return [IO]
    #
    # @!attribute [rw] status_code
    #   The integer status code for an HTTP response of a corresponding
    #   `GetObject` request. The following is a list of status codes.
    #
    #   * `200 - OK`
    #
    #   * `206 - Partial Content`
    #
    #   * `304 - Not Modified`
    #
    #   * `400 - Bad Request`
    #
    #   * `401 - Unauthorized`
    #
    #   * `403 - Forbidden`
    #
    #   * `404 - Not Found`
    #
    #   * `405 - Method Not Allowed`
    #
    #   * `409 - Conflict`
    #
    #   * `411 - Length Required`
    #
    #   * `412 - Precondition Failed`
    #
    #   * `416 - Range Not Satisfiable`
    #
    #   * `500 - Internal Server Error`
    #
    #   * `503 - Service Unavailable`
    #   @return [Integer]
    #
    # @!attribute [rw] error_code
    #   A string that uniquely identifies an error condition. Returned in
    #   the &lt;Code&gt; tag of the error XML response for a corresponding
    #   `GetObject` call. Cannot be used with a successful `StatusCode`
    #   header or when the transformed object is provided in the body. All
    #   error codes from S3 are sentence-cased. The regular expression
    #   (regex) value is `"^[A-Z][a-zA-Z]+$"`.
    #   @return [String]
    #
    # @!attribute [rw] error_message
    #   Contains a generic description of the error condition. Returned in
    #   the &lt;Message&gt; tag of the error XML response for a
    #   corresponding `GetObject` call. Cannot be used with a successful
    #   `StatusCode` header or when the transformed object is provided in
    #   body.
    #   @return [String]
    #
    # @!attribute [rw] accept_ranges
    #   Indicates that a range of bytes was specified.
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_length
    #   The size of the content body in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] content_range
    #   The portion of the object returned in the response.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the Base64 encoded, 32-bit `CRC32` checksum of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the Base64 encoded, 32-bit `CRC32C` checksum of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_crc64nvme
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the Base64 encoded, 64-bit `CRC64NVME` checksum of the
    #   part. For more information, see [Checking object integrity][1] in
    #   the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the Base64 encoded, 160-bit `SHA1` digest of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the Base64 encoded, 256-bit `SHA256` digest of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #   @return [String]
    #
    # @!attribute [rw] delete_marker
    #   Specifies whether an object stored in Amazon S3 is (`true`) or is
    #   not (`false`) a delete marker. To learn more about delete markers,
    #   see [Working with delete markers][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html
    #   @return [Boolean]
    #
    # @!attribute [rw] etag
    #   An opaque identifier assigned by a web server to a specific version
    #   of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured (see PUT Bucket lifecycle),
    #   the response includes this header. It includes the `expiry-date` and
    #   `rule-id` key-value pairs that provide the object expiration
    #   information. The value of the `rule-id` is URL-encoded.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   The date and time that the object was last modified.
    #   @return [Time]
    #
    # @!attribute [rw] missing_meta
    #   Set to the number of metadata entries not returned in `x-amz-meta`
    #   headers. This can happen if you create metadata using an API like
    #   SOAP that supports more flexible metadata than the REST API. For
    #   example, using SOAP, you can create metadata whose values are not
    #   legal HTTP headers.
    #   @return [Integer]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] object_lock_mode
    #   Indicates whether an object stored in Amazon S3 has Object Lock
    #   enabled. For more information about S3 Object Lock, see [Object
    #   Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
    #   @return [String]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Indicates whether an object stored in Amazon S3 has an active legal
    #   hold.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when Object Lock is configured to expire.
    #   @return [Time]
    #
    # @!attribute [rw] parts_count
    #   The count of parts this object has.
    #   @return [Integer]
    #
    # @!attribute [rw] replication_status
    #   Indicates if request involves bucket that is either a source or
    #   destination in a Replication rule. For more information about S3
    #   Replication, see [Replication][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request. For more information, see [Using Requester Pays
    #   buckets for storage transfers and usage][1] in the *Amazon Simple
    #   Storage Service user guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] restore
    #   Provides information about object restoration operation and
    #   expiration time of the restored object copy.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing requested
    #   object in Amazon S3 or Amazon FSx.
    #
    #   <note markdown="1"> When accessing data stored in Amazon FSx file systems using S3
    #   access points, the only valid server side encryption option is
    #   `aws:fsx`.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Encryption algorithm used if server-side encryption with a
    #   customer-provided encryption key was specified for object stored in
    #   Amazon S3.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID (Key ID, Key ARN, or Key Alias) of the
    #   Amazon Web Services Key Management Service (Amazon Web Services KMS)
    #   symmetric encryption customer managed key that was used for stored
    #   in Amazon S3 object.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   128-bit MD5 digest of customer-provided encryption key used in
    #   Amazon S3 to encrypt data stored in S3. For more information, see
    #   [Protecting data using server-side encryption with customer-provided
    #   encryption keys (SSE-C)][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #
    #   For more information, see [Storage Classes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] tag_count
    #   The number of tags, if any, on the object.
    #   @return [Integer]
    #
    # @!attribute [rw] version_id
    #   An ID used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] bucket_key_enabled
    #   Indicates whether the object stored in Amazon S3 uses an S3 bucket
    #   key for server-side encryption with Amazon Web Services KMS
    #   (SSE-KMS).
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/WriteGetObjectResponseRequest AWS API Documentation
    #
    class WriteGetObjectResponseRequest < Struct.new(
      :request_route,
      :request_token,
      :body,
      :status_code,
      :error_code,
      :error_message,
      :accept_ranges,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_length,
      :content_range,
      :content_type,
      :checksum_crc32,
      :checksum_crc32c,
      :checksum_crc64nvme,
      :checksum_sha1,
      :checksum_sha256,
      :delete_marker,
      :etag,
      :expires,
      :expiration,
      :last_modified,
      :missing_meta,
      :metadata,
      :object_lock_mode,
      :object_lock_legal_hold_status,
      :object_lock_retain_until_date,
      :parts_count,
      :replication_status,
      :request_charged,
      :restore,
      :server_side_encryption,
      :sse_customer_algorithm,
      :ssekms_key_id,
      :sse_customer_key_md5,
      :storage_class,
      :tag_count,
      :version_id,
      :bucket_key_enabled)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # The container for selecting objects from a content event stream.
    #
    # EventStream is an Enumerator of Events.
    #  #event_types #=> Array, returns all modeled event types in the stream
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentEventStream AWS API Documentation
    #
    class SelectObjectContentEventStream < Enumerator

      def event_types
        [
          :records,
          :stats,
          :progress,
          :cont,
          :end
        ]
      end

    end

  end
end

require "aws-sdk-s3/customizations/types/list_object_versions_output"
require "aws-sdk-s3/customizations/types/permanent_redirect"
