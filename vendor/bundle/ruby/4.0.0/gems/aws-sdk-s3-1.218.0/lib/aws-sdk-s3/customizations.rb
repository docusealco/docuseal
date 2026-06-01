# frozen_string_literal: true

module Aws
  module S3
    # utility classes
    autoload :BucketRegionCache, 'aws-sdk-s3/bucket_region_cache'
    autoload :Encryption, 'aws-sdk-s3/encryption'
    autoload :EncryptionV2, 'aws-sdk-s3/encryption_v2'
    autoload :EncryptionV3, 'aws-sdk-s3/encryption_v3'
    autoload :LegacySigner, 'aws-sdk-s3/legacy_signer'

    # transfer manager + multipart upload/download utilities
    autoload :DefaultExecutor, 'aws-sdk-s3/default_executor'
    autoload :FilePart, 'aws-sdk-s3/file_part'
    autoload :FileUploader, 'aws-sdk-s3/file_uploader'
    autoload :FileDownloader, 'aws-sdk-s3/file_downloader'
    autoload :MultipartDownloadError, 'aws-sdk-s3/multipart_download_error'
    autoload :MultipartFileUploader, 'aws-sdk-s3/multipart_file_uploader'
    autoload :MultipartStreamUploader, 'aws-sdk-s3/multipart_stream_uploader'
    autoload :MultipartUploadError, 'aws-sdk-s3/multipart_upload_error'
    autoload :DirectoryDownloadError, 'aws-sdk-s3/directory_download_error'
    autoload :DirectoryDownloader, 'aws-sdk-s3/directory_downloader'
    autoload :DirectoryUploadError, 'aws-sdk-s3/directory_upload_error'
    autoload :DirectoryUploader, 'aws-sdk-s3/directory_uploader'
    autoload :ObjectCopier, 'aws-sdk-s3/object_copier'
    autoload :ObjectMultipartCopier, 'aws-sdk-s3/object_multipart_copier'
    autoload :PresignedPost, 'aws-sdk-s3/presigned_post'
    autoload :Presigner, 'aws-sdk-s3/presigner'
    autoload :TransferManager, 'aws-sdk-s3/transfer_manager'

    # s3 express session auth
    autoload :ExpressCredentials, 'aws-sdk-s3/express_credentials'
    autoload :ExpressCredentialsProvider, 'aws-sdk-s3/express_credentials_provider'

    # s3 access grants auth
    autoload :AccessGrantsCredentials, 'aws-sdk-s3/access_grants_credentials'
    autoload :AccessGrantsCredentialsProvider, 'aws-sdk-s3/access_grants_credentials_provider'
  end
end
