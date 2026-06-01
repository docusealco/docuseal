# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::S3
  # @api private
  module Endpoints

    class AbortMultipartUpload
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class CompleteMultipartUpload
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class CopyObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
          copy_source: context.params[:copy_source],
          disable_s3_express_session_auth: true,
        )
      end
    end

    class CreateBucket
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          disable_access_points: true,
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class CreateBucketMetadataConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class CreateBucketMetadataTableConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class CreateMultipartUpload
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class CreateSession
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          disable_s3_express_session_auth: true,
        )
      end
    end

    class DeleteBucket
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketAnalyticsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketCors
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketEncryption
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketIntelligentTieringConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketInventoryConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketLifecycle
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketMetadataConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketMetadataTableConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketMetricsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketOwnershipControls
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketPolicy
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketReplication
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteBucketWebsite
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class DeleteObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class DeleteObjectTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class DeleteObjects
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class DeletePublicAccessBlock
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketAbac
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetBucketAccelerateConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketAcl
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketAnalyticsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketCors
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketEncryption
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketIntelligentTieringConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketInventoryConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketLifecycle
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketLifecycleConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketLocation
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketLogging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketMetadataConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketMetadataTableConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketMetricsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketNotification
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketNotificationConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketOwnershipControls
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketPolicy
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketPolicyStatus
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketReplication
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketRequestPayment
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketVersioning
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetBucketWebsite
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class GetObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class GetObjectAcl
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class GetObjectAttributes
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetObjectLegalHold
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetObjectLockConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetObjectRetention
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetObjectTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetObjectTorrent
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class GetPublicAccessBlock
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class HeadBucket
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class HeadObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class ListBucketAnalyticsConfigurations
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class ListBucketIntelligentTieringConfigurations
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class ListBucketInventoryConfigurations
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class ListBucketMetricsConfigurations
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class ListBuckets
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class ListDirectoryBuckets
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class ListMultipartUploads
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          prefix: context.params[:prefix],
        )
      end
    end

    class ListObjectVersions
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          prefix: context.params[:prefix],
        )
      end
    end

    class ListObjects
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          prefix: context.params[:prefix],
        )
      end
    end

    class ListObjectsV2
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          prefix: context.params[:prefix],
        )
      end
    end

    class ListParts
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class PutBucketAbac
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class PutBucketAccelerateConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketAcl
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketAnalyticsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketCors
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketEncryption
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketIntelligentTieringConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketInventoryConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketLifecycle
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketLifecycleConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketLogging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketMetricsConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketNotification
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketNotificationConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketOwnershipControls
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketPolicy
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketReplication
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketRequestPayment
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketVersioning
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutBucketWebsite
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class PutObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class PutObjectAcl
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class PutObjectLegalHold
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class PutObjectLockConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class PutObjectRetention
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class PutObjectTagging
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class PutPublicAccessBlock
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class RenameObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class RestoreObject
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class SelectObjectContent
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class UpdateBucketMetadataInventoryTableConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class UpdateBucketMetadataJournalTableConfiguration
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_s3_express_control_endpoint: true,
        )
      end
    end

    class UpdateObjectEncryption
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
        )
      end
    end

    class UploadPart
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          key: context.params[:key],
        )
      end
    end

    class UploadPartCopy
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          bucket: context.params[:bucket],
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          disable_s3_express_session_auth: true,
        )
      end
    end

    class WriteGetObjectResponse
      def self.build(context)
        Aws::S3::EndpointParameters.create(
          context.config,
          use_dual_stack: context[:use_dualstack_endpoint],
          accelerate: context[:use_accelerate_endpoint],
          use_object_lambda_endpoint: true,
        )
      end
    end


    def self.parameters_for_operation(context)
      case context.operation_name
      when :abort_multipart_upload
        AbortMultipartUpload.build(context)
      when :complete_multipart_upload
        CompleteMultipartUpload.build(context)
      when :copy_object
        CopyObject.build(context)
      when :create_bucket
        CreateBucket.build(context)
      when :create_bucket_metadata_configuration
        CreateBucketMetadataConfiguration.build(context)
      when :create_bucket_metadata_table_configuration
        CreateBucketMetadataTableConfiguration.build(context)
      when :create_multipart_upload
        CreateMultipartUpload.build(context)
      when :create_session
        CreateSession.build(context)
      when :delete_bucket
        DeleteBucket.build(context)
      when :delete_bucket_analytics_configuration
        DeleteBucketAnalyticsConfiguration.build(context)
      when :delete_bucket_cors
        DeleteBucketCors.build(context)
      when :delete_bucket_encryption
        DeleteBucketEncryption.build(context)
      when :delete_bucket_intelligent_tiering_configuration
        DeleteBucketIntelligentTieringConfiguration.build(context)
      when :delete_bucket_inventory_configuration
        DeleteBucketInventoryConfiguration.build(context)
      when :delete_bucket_lifecycle
        DeleteBucketLifecycle.build(context)
      when :delete_bucket_metadata_configuration
        DeleteBucketMetadataConfiguration.build(context)
      when :delete_bucket_metadata_table_configuration
        DeleteBucketMetadataTableConfiguration.build(context)
      when :delete_bucket_metrics_configuration
        DeleteBucketMetricsConfiguration.build(context)
      when :delete_bucket_ownership_controls
        DeleteBucketOwnershipControls.build(context)
      when :delete_bucket_policy
        DeleteBucketPolicy.build(context)
      when :delete_bucket_replication
        DeleteBucketReplication.build(context)
      when :delete_bucket_tagging
        DeleteBucketTagging.build(context)
      when :delete_bucket_website
        DeleteBucketWebsite.build(context)
      when :delete_object
        DeleteObject.build(context)
      when :delete_object_tagging
        DeleteObjectTagging.build(context)
      when :delete_objects
        DeleteObjects.build(context)
      when :delete_public_access_block
        DeletePublicAccessBlock.build(context)
      when :get_bucket_abac
        GetBucketAbac.build(context)
      when :get_bucket_accelerate_configuration
        GetBucketAccelerateConfiguration.build(context)
      when :get_bucket_acl
        GetBucketAcl.build(context)
      when :get_bucket_analytics_configuration
        GetBucketAnalyticsConfiguration.build(context)
      when :get_bucket_cors
        GetBucketCors.build(context)
      when :get_bucket_encryption
        GetBucketEncryption.build(context)
      when :get_bucket_intelligent_tiering_configuration
        GetBucketIntelligentTieringConfiguration.build(context)
      when :get_bucket_inventory_configuration
        GetBucketInventoryConfiguration.build(context)
      when :get_bucket_lifecycle
        GetBucketLifecycle.build(context)
      when :get_bucket_lifecycle_configuration
        GetBucketLifecycleConfiguration.build(context)
      when :get_bucket_location
        GetBucketLocation.build(context)
      when :get_bucket_logging
        GetBucketLogging.build(context)
      when :get_bucket_metadata_configuration
        GetBucketMetadataConfiguration.build(context)
      when :get_bucket_metadata_table_configuration
        GetBucketMetadataTableConfiguration.build(context)
      when :get_bucket_metrics_configuration
        GetBucketMetricsConfiguration.build(context)
      when :get_bucket_notification
        GetBucketNotification.build(context)
      when :get_bucket_notification_configuration
        GetBucketNotificationConfiguration.build(context)
      when :get_bucket_ownership_controls
        GetBucketOwnershipControls.build(context)
      when :get_bucket_policy
        GetBucketPolicy.build(context)
      when :get_bucket_policy_status
        GetBucketPolicyStatus.build(context)
      when :get_bucket_replication
        GetBucketReplication.build(context)
      when :get_bucket_request_payment
        GetBucketRequestPayment.build(context)
      when :get_bucket_tagging
        GetBucketTagging.build(context)
      when :get_bucket_versioning
        GetBucketVersioning.build(context)
      when :get_bucket_website
        GetBucketWebsite.build(context)
      when :get_object
        GetObject.build(context)
      when :get_object_acl
        GetObjectAcl.build(context)
      when :get_object_attributes
        GetObjectAttributes.build(context)
      when :get_object_legal_hold
        GetObjectLegalHold.build(context)
      when :get_object_lock_configuration
        GetObjectLockConfiguration.build(context)
      when :get_object_retention
        GetObjectRetention.build(context)
      when :get_object_tagging
        GetObjectTagging.build(context)
      when :get_object_torrent
        GetObjectTorrent.build(context)
      when :get_public_access_block
        GetPublicAccessBlock.build(context)
      when :head_bucket
        HeadBucket.build(context)
      when :head_object
        HeadObject.build(context)
      when :list_bucket_analytics_configurations
        ListBucketAnalyticsConfigurations.build(context)
      when :list_bucket_intelligent_tiering_configurations
        ListBucketIntelligentTieringConfigurations.build(context)
      when :list_bucket_inventory_configurations
        ListBucketInventoryConfigurations.build(context)
      when :list_bucket_metrics_configurations
        ListBucketMetricsConfigurations.build(context)
      when :list_buckets
        ListBuckets.build(context)
      when :list_directory_buckets
        ListDirectoryBuckets.build(context)
      when :list_multipart_uploads
        ListMultipartUploads.build(context)
      when :list_object_versions
        ListObjectVersions.build(context)
      when :list_objects
        ListObjects.build(context)
      when :list_objects_v2
        ListObjectsV2.build(context)
      when :list_parts
        ListParts.build(context)
      when :put_bucket_abac
        PutBucketAbac.build(context)
      when :put_bucket_accelerate_configuration
        PutBucketAccelerateConfiguration.build(context)
      when :put_bucket_acl
        PutBucketAcl.build(context)
      when :put_bucket_analytics_configuration
        PutBucketAnalyticsConfiguration.build(context)
      when :put_bucket_cors
        PutBucketCors.build(context)
      when :put_bucket_encryption
        PutBucketEncryption.build(context)
      when :put_bucket_intelligent_tiering_configuration
        PutBucketIntelligentTieringConfiguration.build(context)
      when :put_bucket_inventory_configuration
        PutBucketInventoryConfiguration.build(context)
      when :put_bucket_lifecycle
        PutBucketLifecycle.build(context)
      when :put_bucket_lifecycle_configuration
        PutBucketLifecycleConfiguration.build(context)
      when :put_bucket_logging
        PutBucketLogging.build(context)
      when :put_bucket_metrics_configuration
        PutBucketMetricsConfiguration.build(context)
      when :put_bucket_notification
        PutBucketNotification.build(context)
      when :put_bucket_notification_configuration
        PutBucketNotificationConfiguration.build(context)
      when :put_bucket_ownership_controls
        PutBucketOwnershipControls.build(context)
      when :put_bucket_policy
        PutBucketPolicy.build(context)
      when :put_bucket_replication
        PutBucketReplication.build(context)
      when :put_bucket_request_payment
        PutBucketRequestPayment.build(context)
      when :put_bucket_tagging
        PutBucketTagging.build(context)
      when :put_bucket_versioning
        PutBucketVersioning.build(context)
      when :put_bucket_website
        PutBucketWebsite.build(context)
      when :put_object
        PutObject.build(context)
      when :put_object_acl
        PutObjectAcl.build(context)
      when :put_object_legal_hold
        PutObjectLegalHold.build(context)
      when :put_object_lock_configuration
        PutObjectLockConfiguration.build(context)
      when :put_object_retention
        PutObjectRetention.build(context)
      when :put_object_tagging
        PutObjectTagging.build(context)
      when :put_public_access_block
        PutPublicAccessBlock.build(context)
      when :rename_object
        RenameObject.build(context)
      when :restore_object
        RestoreObject.build(context)
      when :select_object_content
        SelectObjectContent.build(context)
      when :update_bucket_metadata_inventory_table_configuration
        UpdateBucketMetadataInventoryTableConfiguration.build(context)
      when :update_bucket_metadata_journal_table_configuration
        UpdateBucketMetadataJournalTableConfiguration.build(context)
      when :update_object_encryption
        UpdateObjectEncryption.build(context)
      when :upload_part
        UploadPart.build(context)
      when :upload_part_copy
        UploadPartCopy.build(context)
      when :write_get_object_response
        WriteGetObjectResponse.build(context)
      else
        Aws::S3::EndpointParameters.create(context.config)
      end
    end
  end
end
