# frozen_string_literal: true

require_relative "block_list"
require_relative "blob_list"
require_relative "blob"
require_relative "container"
require_relative "tags"
require_relative "http"
require_relative "shared_key_signer"
require_relative "entra_id_signer"
require "time"
require "base64"
require "stringio"

module AzureBlob
  # AzureBlob Client class. You interact with the Azure Blob api
  # through an instance of this class.
  class Client
    def initialize(account_name:, access_key: nil, principal_id: nil, container:, host: nil, **options)
      @account_name = account_name
      @container = container
      @host = host
      @cloud_regions = options[:cloud_regions]&.to_sym || :global
      @access_key = access_key
      @principal_id = principal_id
      @use_managed_identities = options[:use_managed_identities]
      signer unless options[:lazy]
    end

    # Create a blob of type block. Will automatically split the the blob in multiple block and send the blob in pieces (blocks) if the blob is too big.
    #
    # When the blob is small enough this method will send the blob through {Put Blob}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-blob]
    #
    # If the blob is too big, the blob is split in blocks sent through a series of {Put Block}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-block] requests
    # followed by a {Put Block List}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list] to commit the block list.
    #
    # Takes a key (path), the content (String or IO object), and options.
    #
    # Options:
    #
    # [+:content_type+]
    #   Will be saved on the blob in Azure.
    # [+:content_disposition+]
    #   Will be saved on the blob in Azure.
    # [+:content_md5+]
    #   Will ensure integrity of the upload. The checksum must be a base64 digest. Can be produced with +OpenSSL::Digest::MD5.base64digest+.
    #   The checksum is only checked on a single upload! To verify checksum when uploading multiple blocks, call directly put_blob_block with
    #   a checksum for each block, then commit the blocks with commit_blob_blocks.
    # [+:block_size+]
    #   Block size in bytes, can be used to force the method to split the upload in smaller chunk. Defaults to +AzureBlob::DEFAULT_BLOCK_SIZE+ and cannot be bigger than +AzureBlob::MAX_UPLOAD_SIZE+
    def create_block_blob(key, content, options = {})
      if content_size(content) > (options[:block_size] || DEFAULT_BLOCK_SIZE)
        put_blob_multiple(key, content, **options)
      else
        put_blob_single(key, content, **options)
      end
    end

    # Returns the full or partial content of the blob
    #
    # Calls to the {Get Blob}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-blob] endpoint.
    #
    # Takes a key (path) and options.
    #
    # Options:
    #
    # [+:start+]
    #   Starting point in bytes
    # [+:end+]
    #   Ending point in bytes
    def get_blob(key, options = {})
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      headers = {
        "x-ms-range": options[:start] && "bytes=#{options[:start]}-#{options[:end]}",
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:).get
    end

    # Copy a blob between containers or within the same container
    #
    # Calls to {Copy Blob From URL}[https://learn.microsoft.com/en-us/rest/api/storageservices/copy-blob-from-url]
    #
    # Parameters:
    # - key: destination blob path
    # - source_key: source blob path
    # - options: additional options
    #   - source_client: AzureBlob::Client instance for the source container (optional)
    #     If not provided, copies from within the same container
    #
    def copy_blob(key, source_key, options = {})
      source_client = options.delete(:source_client) || self
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      source_uri = source_client.signed_uri(source_key, permissions: "r", expiry: Time.at(Time.now.to_i + 300).utc.iso8601)

      headers = {
        "x-ms-copy-source": source_uri.to_s,
        "x-ms-requires-sync": "true",
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:, **options.slice(:metadata, :tags)).put
    end

    # Delete a blob
    #
    # Calls to {Delete Blob}[https://learn.microsoft.com/en-us/rest/api/storageservices/delete-blob]
    #
    # Takes a key (path) and options.
    #
    # Options:
    # [+:delete_snapshots+]
    #   Sets the value of the x-ms-delete-snapshots header. Default to +include+
    def delete_blob(key, options = {})
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      headers = {
        "x-ms-delete-snapshots": options[:delete_snapshots] || "include",
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:).delete
    end

    # Delete all blobs prefixed by the given prefix.
    #
    # Calls to {List blobs}[https://learn.microsoft.com/en-us/rest/api/storageservices/list-blobs]
    # followed to a series of calls to {Delete Blob}[https://learn.microsoft.com/en-us/rest/api/storageservices/delete-blob]
    #
    # Takes a prefix and options
    #
    # Look delete_blob for the list of options.
    def delete_prefix(prefix, options = {})
      results = list_blobs(prefix:)
      results.each { |key| delete_blob(key) }
    end

    # Returns a BlobList containing a list of keys (paths)
    #
    # Calls to {List blobs}[https://learn.microsoft.com/en-us/rest/api/storageservices/list-blobs]
    #
    # Options:
    # [+:prefix+]
    #   Prefix of the blobs to be listed. Defaults to listing everything in the container.
    # [:+max_results+]
    #   Maximum number of results to return per page.
    def list_blobs(options = {})
      uri = generate_uri(container)
      query = {
        comp: "list",
        restype: "container",
        prefix: options[:prefix].to_s.gsub(/\\/, "/"),
      }
      query[:maxresults] = options[:max_results] if options[:max_results]
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)

      fetcher = ->(marker) do
        query[:marker] = marker
        query.reject! { |key, value| value.to_s.empty? }
        uri.query = URI.encode_www_form(**query)
        response = Http.new(uri, additional_headers(options), signer:).get
      end

      BlobList.new(fetcher)
    end

    # Returns a Blob object without the content.
    #
    # Calls to {Get Blob Properties}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-blob-properties]
    #
    # This can be used to obtain metadata such as content type, disposition, checksum or Azure custom metadata.
    # To check for blob presence, look for `blob_exist?` as `get_blob_properties` raises on missing blob.
    def get_blob_properties(key, options = {})
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      response = Http.new(uri, additional_headers(options), signer:).head

      Blob.new(response)
    end

    # Returns a boolean indicating if the blob exists.
    #
    # Calls to {Get Blob Properties}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-blob-properties]
    def blob_exist?(key, options = {})
      get_blob_properties(key, options).present?
    rescue AzureBlob::Http::FileNotFoundError
      false
    end

    # Returns the tags associated with a blob
    #
    # Calls to the {Get Blob Tags}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-blob-tags] endpoint.
    #
    # Takes a key (path) of the blob.
    #
    # Returns a hash of the blob's tags.
    def get_blob_tags(key, options = {})
      uri = generate_uri("#{container}/#{key}")
      query = { comp: "tags" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)
      response = Http.new(uri, additional_headers(options), signer:).get

      Tags.from_response(response).to_h
    end

    # Returns a Container object.
    #
    # Calls to {Get Container Properties}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-container-properties]
    #
    # This can be used to see if the container exist or obtain metadata.
    def get_container_properties(options = {})
      uri = generate_uri(container)
      query = { restype: "container" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)
      response = Http.new(uri, additional_headers(options), signer:, raise_on_error: false).head

      Container.new(response)
    end

    # Returns a boolean indicating if the container exists.
    #
    # Calls to {Get Container Properties}[https://learn.microsoft.com/en-us/rest/api/storageservices/get-container-properties]
    def container_exist?(options = {})
      get_container_properties(options = {}).present?
    end

    # Create the container
    #
    # Calls to {Create Container}[https://learn.microsoft.com/en-us/rest/api/storageservices/create-container]
    def create_container(options = {})
      uri = generate_uri(container)
      headers = {}
      headers[:"x-ms-blob-public-access"] = "blob" if options[:public_access]
      headers[:"x-ms-blob-public-access"] = options[:public_access] if [ "container", "blob" ].include?(options[:public_access])
      headers.merge!(additional_headers(options))

      query = { restype: "container" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)
      response = Http.new(uri, headers, signer:).put
    end

    # Delete the container
    #
    # Calls to {Delete Container}[https://learn.microsoft.com/en-us/rest/api/storageservices/delete-container]
    def delete_container(options = {})
      uri = generate_uri(container)
      query = { restype: "container" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)
      response = Http.new(uri, additional_headers(options), signer:).delete
    end

    # Return a URI object to a resource in the container. Takes a path.
    #
    # Example: +generate_uri("#{container}/#{key}")+
    def generate_uri(path)
      # https://github.com/Azure/azure-storage-ruby/blob/master/common/lib/azure/storage/common/service/storage_service.rb#L191-L201
      encoded_path = CGI.escape(path.encode("UTF-8"))
      encoded_path = encoded_path.gsub(/%2F/, "/")
      encoded_path = encoded_path.gsub(/%5C/, "/")
      encoded_path = encoded_path.gsub(/\+/, "%20")
      URI.parse(File.join(host, encoded_path))
    end

    # Returns an SAS signed URI
    #
    # Takes a
    # - key (path)
    # - A permission string (+"r"+, +"rw"+)
    # - expiry as a UTC iso8601 time string
    # - options
    def signed_uri(key, permissions:, expiry:, **options)
      uri = generate_uri("#{container}/#{key}")
      uri.query = signer.sas_token(uri, permissions:, expiry:, **options)
      uri
    end

    # Creates a Blob of type append.
    #
    # Calls to {Put Blob}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-blob]
    #
    # You are expected to append blocks to the blob with append_blob_block after creating the blob.
    # Options:
    #
    # [+:content_type+]
    #   Will be saved on the blob in Azure.
    # [+:content_disposition+]
    #   Will be saved on the blob in Azure.
    def create_append_blob(key, options = {})
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      headers = {
        "x-ms-blob-type": "AppendBlob",
        "Content-Length": 0,
        "Content-Type": options[:content_type],
        "Content-MD5": options[:content_md5],
        "x-ms-blob-content-disposition": options[:content_disposition],
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:, **options.slice(:metadata, :tags)).put(nil)
    end

    # Append a block to an Append Blob
    #
    # Calls to {Append Block}[https://learn.microsoft.com/en-us/rest/api/storageservices/append-block]
    #
    # Options:
    #
    # [+:content_md5+]
    #   Will ensure integrity of the upload. The checksum must be a base64 digest. Can be produced with +OpenSSL::Digest::MD5.base64digest+.
    #   The checksum must be the checksum of the block not the blob.
    def append_blob_block(key, content, options = {})
      uri = generate_uri("#{container}/#{key}")
      query = { comp: "appendblock" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)

      headers = {
        "Content-Length": content_size(content),
        "Content-Type": options[:content_type],
        "Content-MD5": options[:content_md5],
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:).put(content)
    end

    # Uploads a block to a blob.
    #
    # Calls to {Put Block}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-block]
    #
    # Returns the id of the block. Required to commit the list of blocks to a blob.
    #
    # Options:
    #
    # [+:content_md5+]
    #   Must be the checksum for the block not the blob. The checksum must be a base64 digest. Can be produced with +OpenSSL::Digest::MD5.base64digest+.
    def put_blob_block(key, index, content, options = {})
      block_id = generate_block_id(index)
      uri = generate_uri("#{container}/#{key}")
      query = { comp: "block", blockid: block_id }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)

      headers = {
        "Content-Length": content_size(content),
        "Content-Type": options[:content_type],
        "Content-MD5": options[:content_md5],
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:).put(content)

      block_id
    end

    # Commits the list of blocks to a blob.
    #
    # Calls to {Put Block List}[https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list]
    #
    # Takes a key (path) and an array of block ids
    #
    # Options:
    #
    # [+:content_md5+]
    #   This is the checksum for the whole blob. The checksum is saved on the blob, but it is not validated!
    #   Add a checksum for each block if you want Azure to validate integrity.
    def commit_blob_blocks(key, block_ids, options = {})
      block_list = BlockList.new(block_ids)
      content = block_list.to_s
      uri = generate_uri("#{container}/#{key}")
      query = { comp: "blocklist" }
      query[:timeout] = options[:timeout] if options[:timeout]
      uri.query = URI.encode_www_form(**query)

      headers = {
        "Content-Length": content_size(content),
        "Content-Type": options[:content_type],
        "x-ms-blob-content-md5": options[:content_md5],
        "x-ms-blob-content-disposition": options[:content_disposition],
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:, **options.slice(:metadata, :tags)).put(content)
    end

  private

    def additional_headers(options)
      (options[:headers] || {}).transform_keys { |k| "x-ms-#{k}".to_sym }.
        transform_values(&:to_s)
    end

    def generate_block_id(index)
      Base64.urlsafe_encode64(index.to_s.rjust(6, "0"))
    end

    def put_blob_multiple(key, content, options = {})
      content = StringIO.new(content) if content.is_a? String
      block_size = options[:block_size] || DEFAULT_BLOCK_SIZE
      block_count = (content_size(content).to_f / block_size).ceil
      block_ids = block_count.times.map do |i|
        put_blob_block(key, i, content.read(block_size), options.slice(:timeout))
      end

      commit_blob_blocks(key, block_ids, options)
    end

    def put_blob_single(key, content, options = {})
      content = StringIO.new(content) if content.is_a? String
      uri = generate_uri("#{container}/#{key}")
      uri.query = URI.encode_www_form(timeout: options[:timeout]) if options[:timeout]

      headers = {
        "x-ms-blob-type": "BlockBlob",
        "Content-Length": content_size(content),
        "Content-Type": options[:content_type],
        "x-ms-blob-content-md5": options[:content_md5],
        "x-ms-blob-content-disposition": options[:content_disposition],
      }.merge(additional_headers(options))

      Http.new(uri, headers, signer:, **options.slice(:metadata, :tags)).put(content.read)
    end

    def content_size(content)
      if content.respond_to?(:bytesize)
        content.bytesize
      else
        content.size
      end
    end

    def host
      @host ||= "https://#{account_name}.blob.#{CLOUD_REGIONS_SUFFIX[cloud_regions]}"
    end

    def signer
      @signer ||=
        begin
          no_access_key = access_key.nil? || access_key&.empty?
          using_managed_identities = no_access_key && !principal_id.nil? || use_managed_identities

          if !using_managed_identities && no_access_key
            raise AzureBlob::Error.new(
              "`access_key` cannot be empty. To use managed identities instead, pass a `principal_id` or set `use_managed_identities` to true."
            )
          end

          using_managed_identities ?
            AzureBlob::EntraIdSigner.new(account_name:, host:, principal_id:) :
            AzureBlob::SharedKeySigner.new(account_name:, access_key:, host:)
        end
    end

    attr_reader :account_name, :container, :http, :cloud_regions, :access_key, :principal_id, :use_managed_identities
  end
end
