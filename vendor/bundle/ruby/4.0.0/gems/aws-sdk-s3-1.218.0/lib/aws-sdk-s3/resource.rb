# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  # This class provides a resource oriented interface for S3.
  # To create a resource object:
  #
  #     resource = Aws::S3::Resource.new(region: 'us-west-2')
  #
  # You can supply a client object with custom configuration that will be used for all resource operations.
  # If you do not pass `:client`, a default client will be constructed.
  #
  #     client = Aws::S3::Client.new(region: 'us-west-2')
  #     resource = Aws::S3::Resource.new(client: client)
  #
  class Resource

    # @param options ({})
    # @option options [Client] :client
    def initialize(options = {})
      @client = options[:client] || Client.new(options)
    end

    # @return [Client]
    def client
      @client
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   bucket = s3.create_bucket({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #     bucket: "BucketName", # required
    #     create_bucket_configuration: {
    #       location_constraint: "af-south-1", # accepts af-south-1, ap-east-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1, ap-south-2, ap-southeast-1, ap-southeast-2, ap-southeast-3, ap-southeast-4, ap-southeast-5, ca-central-1, cn-north-1, cn-northwest-1, EU, eu-central-1, eu-central-2, eu-north-1, eu-south-1, eu-south-2, eu-west-1, eu-west-2, eu-west-3, il-central-1, me-central-1, me-south-1, sa-east-1, us-east-2, us-gov-east-1, us-gov-west-1, us-west-1, us-west-2
    #       location: {
    #         type: "AvailabilityZone", # accepts AvailabilityZone, LocalZone
    #         name: "LocationNameAsString",
    #       },
    #       bucket: {
    #         data_redundancy: "SingleAvailabilityZone", # accepts SingleAvailabilityZone, SingleLocalZone
    #         type: "Directory", # accepts Directory
    #       },
    #       tags: [
    #         {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #       ],
    #     },
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write: "GrantWrite",
    #     grant_write_acp: "GrantWriteACP",
    #     object_lock_enabled_for_bucket: false,
    #     object_ownership: "BucketOwnerPreferred", # accepts BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
    #     bucket_namespace: "account-regional", # accepts account-regional, global
    #   })
    # @param [Hash] options ({})
    # @option options [String] :acl
    #   The canned ACL to apply to the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [required, String] :bucket
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
    # @option options [Types::CreateBucketConfiguration] :create_bucket_configuration
    #   The configuration information for the bucket.
    # @option options [String] :grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions on
    #   the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [Boolean] :object_lock_enabled_for_bucket
    #   Specifies whether you want S3 Object Lock to be enabled for the new
    #   bucket.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets.
    #
    #    </note>
    # @option options [String] :object_ownership
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
    #   no longer affect permissions. The bucket owner automatically owns and
    #   has full control over every object in the bucket. The bucket only
    #   accepts PUT requests that don't specify an ACL or specify bucket
    #   owner full control ACLs (such as the predefined
    #   `bucket-owner-full-control` canned ACL or a custom ACL in XML format
    #   that grants the same permissions).
    #
    #   By default, `ObjectOwnership` is set to `BucketOwnerEnforced` and ACLs
    #   are disabled. We recommend keeping ACLs disabled, except in uncommon
    #   use cases where you must control access for each object individually.
    #   For more information about S3 Object Ownership, see [Controlling
    #   ownership of objects and disabling ACLs for your bucket][1] in the
    #   *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> This functionality is not supported for directory buckets. Directory
    #   buckets use the bucket owner enforced setting for S3 Object Ownership.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # @option options [String] :bucket_namespace
    #   Specifies the namespace where you want to create your general purpose
    #   bucket. When you create a general purpose bucket, you can choose to
    #   create a bucket in the shared global namespace or you can choose to
    #   create a bucket in your account regional namespace. Your account
    #   regional namespace is a subdivision of the global namespace that only
    #   your account can create buckets in. For more information on bucket
    #   namespaces, see [Namespaces for general purpose buckets][1].
    #
    #   General purpose buckets in your account regional namespace must follow
    #   a specific naming convention. These buckets consist of a bucket name
    #   prefix that you create, and a suffix that contains your 12-digit
    #   Amazon Web Services Account ID, the Amazon Web Services Region code,
    #   and ends with `-an`. Bucket names must follow the format
    #   `bucket-name-prefix-accountId-region-an` (for example,
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
    # @return [Bucket]
    def create_bucket(options = {})
      Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.create_bucket(options)
      end
      Bucket.new(
        name: options[:bucket],
        client: @client
      )
    end

    # @!group Associations

    # @param [String] name
    # @return [Bucket]
    def bucket(name)
      Bucket.new(
        name: name,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   buckets = s3.buckets({
    #     prefix: "Prefix",
    #     bucket_region: "BucketRegion",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :prefix
    #   Limits the response to bucket names that begin with the specified
    #   bucket name prefix.
    # @option options [String] :bucket_region
    #   Limits the response to buckets that are located in the specified
    #   Amazon Web Services Region. The Amazon Web Services Region must be
    #   expressed according to the Amazon Web Services Region code, such as
    #   `us-west-2` for the US West (Oregon) Region. For a list of the valid
    #   values for all of the Amazon Web Services Regions, see [Regions and
    #   Endpoints][1].
    #
    #   <note markdown="1"> Requests made to a Regional endpoint that is different from the
    #   `bucket-region` parameter are not supported. For example, if you want
    #   to limit the response to your buckets in Region `us-west-2`, the
    #   request must be made to an endpoint in Region `us-west-2`.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # @return [Bucket::Collection]
    def buckets(options = {})
      batches = Enumerator.new do |y|
        resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
          @client.list_buckets(options)
        end
        resp.each_page do |page|
          batch = []
          page.data.buckets.each do |b|
            batch << Bucket.new(
              name: b.name,
              data: b,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      Bucket::Collection.new(batches)
    end

  end
end
