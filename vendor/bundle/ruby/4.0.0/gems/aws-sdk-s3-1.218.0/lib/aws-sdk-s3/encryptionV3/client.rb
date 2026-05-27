# frozen_string_literal: true

require 'forwardable'

module Aws
  module S3
    # Provides an encryption client that encrypts and decrypts data client-side,
    # storing the encrypted data in Amazon S3. The `EncryptionV3::Client` (V3 Client)
    # provides improved security over the `EncryptionV2::Client` (V2 Client)
    # through key commitment. You can use the V3 Client to continue decrypting 
    # objects encrypted by V2 by setting security_profile: :v3_and_legacy. 
    # The latest V2 Client also supports reading and decrypting objects 
    # encrypted by the V3 Client.
    #
    # This client uses a process called "envelope encryption". Your private
    # encryption keys and your data's plain-text are **never** sent to
    # Amazon S3. **If you lose you encryption keys, you will not be able to
    # decrypt your data.**
    #
    # ## Key Commitment
    #
    # Key commitment (also known as robustness) is a security property that 
    # guarantees that each ciphertext can be decrypted to only a single plaintext.
    # This prevents sophisticated attacks where a ciphertext could theoretically 
    # decrypt to different plaintexts under different keys.
    #
    # The V3 client encrypts with key commitment by default using the 
    # `:alg_aes_256_gcm_hkdf_sha512_commit_key` algorithm. Key commitment adds 
    # approximately 32 bytes to each encrypted object and slightly increases 
    # processing time, but significantly enhances security.
    #
    # ## Envelope Encryption Overview
    #
    # The goal of envelope encryption is to combine the performance of
    # fast symmetric encryption while maintaining the secure key management
    # that asymmetric keys provide.
    #
    # A one-time-use symmetric key (envelope key) is generated client-side.
    # This is used to encrypt the data client-side. This key is then
    # encrypted by your master key and stored alongside your data in Amazon
    # S3.
    #
    # When accessing your encrypted data with the encryption client,
    # the encrypted envelope key is retrieved and decrypted client-side
    # with your master key. The envelope key is then used to decrypt the
    # data client-side.
    #
    # One of the benefits of envelope encryption is that if your master key
    # is compromised, you have the option of just re-encrypting the stored
    # envelope symmetric keys, instead of re-encrypting all of the
    # data in your account.
    #
    # ## Basic Usage
    #
    # The encryption client requires an {Aws::S3::Client}. If you do not
    # provide a `:client`, then a client will be constructed for you.
    #
    #     require 'openssl'
    #     key = OpenSSL::PKey::RSA.new(1024)
    #
    #     # encryption client
    #     s3 = Aws::S3::EncryptionV3::Client.new(
    #       encryption_key: key,
    #       key_wrap_schema: :rsa_oaep_sha1 # the key_wrap_schema must be rsa_oaep_sha1 for asymmetric keys
    #     )
    #
    #     # round-trip an object, encrypted/decrypted locally
    #     s3.put_object(bucket:'aws-sdk', key:'secret', body:'handshake')
    #     s3.get_object(bucket:'aws-sdk', key:'secret').body.read
    #     #=> 'handshake'
    #
    #     # reading encrypted object without the encryption client
    #     # results in the getting the cipher text
    #     Aws::S3::Client.new.get_object(bucket:'aws-sdk', key:'secret').body.read
    #     #=> "... cipher text ..."
    #
    # ## Required Configuration
    #
    # You must configure the following:
    #
    # * a key or key provider - See the Keys section below. The key provided determines
    #   the key wrapping schema(s) supported for both encryption and decryption.
    # * `key_wrap_schema` - The key wrapping schema. It must match the type of key configured.
    #
    # The following have defaults and are optional:
    #
    # * `content_encryption_schema` - Defaults to `:alg_aes_256_gcm_hkdf_sha512_commit_key`
    # * `security_profile` - Defaults to `:v3`. Set to `:v3_and_legacy` to read V2-encrypted objects.
    # * `commitment_policy` - Defaults to `:require_encrypt_require_decrypt` (most secure)
    #
    # ## Keys
    #
    # For client-side encryption to work, you must provide one of the following:
    #
    # * An encryption key
    # * A {KeyProvider}
    # * A KMS encryption key id
    #
    # Additionally, the key wrapping schema must agree with the type of the key:
    # * :aes_gcm: An AES encryption key or a key provider.
    # * :rsa_oaep_sha1: An RSA encryption key or key provider.
    # * :kms_context: A KMS encryption key id
    #
    # ### An Encryption Key
    #
    # You can pass a single encryption key. This is used as a master key
    # encrypting and decrypting all object keys.
    #
    #     key = OpenSSL::Cipher.new("AES-256-ECB").random_key # symmetric key - used with `key_wrap_schema: :aes_gcm`
    #     key = OpenSSL::PKey::RSA.new(1024) # asymmetric key pair - used with `key_wrap_schema: :rsa_oaep_sha1`
    #
    #     s3 = Aws::S3::EncryptionV3::Client.new(
    #       encryption_key: key,
    #       key_wrap_schema: :aes_gcm # or :rsa_oaep_sha1 if using RSA
    #     )
    #
    # ### Key Provider
    #
    # Alternatively, you can use a {KeyProvider}. A key provider makes
    # it easy to work with multiple keys and simplifies key rotation.
    #
    # ### KMS Encryption Key Id
    #
    # If you pass the id of an AWS Key Management Service (KMS) key and
    # use :kms_content for the key_wrap_schema, then KMS will be used to
    # generate, encrypt and decrypt object keys.
    #
    #     # keep track of the kms key id
    #     kms = Aws::KMS::Client.new
    #     key_id = kms.create_key.key_metadata.key_id
    #
    #     Aws::S3::EncryptionV3::Client.new(
    #       kms_key_id: key_id,
    #       kms_client: kms,
    #       key_wrap_schema: :kms_context
    #     )
    #
    # ## Custom Key Providers
    #
    # A {KeyProvider} is any object that responds to:
    #
    # * `#encryption_materials`
    # * `#key_for(materials_description)`
    #
    # Here is a trivial implementation of an in-memory key provider.
    # This is provided as a demonstration of the key provider interface,
    # and should not be used in production:
    #
    #     class KeyProvider
    #
    #       def initialize(default_key_name, keys)
    #         @keys = keys
    #         @encryption_materials = Aws::S3::EncryptionV3::Materials.new(
    #           key: @keys[default_key_name],
    #           description: JSON.dump(key: default_key_name),
    #         )
    #       end
    #
    #       attr_reader :encryption_materials
    #
    #       def key_for(matdesc)
    #         key_name = JSON.parse(matdesc)['key']
    #         if key = @keys[key_name]
    #           key
    #         else
    #           raise "encryption key not found for: #{matdesc.inspect}"
    #         end
    #       end
    #     end
    #
    # Given the above key provider, you can create an encryption client that
    # chooses the key to use based on the materials description stored with
    # the encrypted object. This makes it possible to use multiple keys
    # and simplifies key rotation.
    #
    #     # uses "new-key" for encrypting objects, uses either for decrypting
    #     keys = KeyProvider.new('new-key', {
    #       "old-key" => Base64.decode64("kM5UVbhE/4rtMZJfsadYEdm2vaKFsmV2f5+URSeUCV4="),
    #       "new-key" => Base64.decode64("w1WLio3agRWRTSJK/Ouh8NHoqRQ6fn5WbSXDTHjXMSo="),
    #     }),
    #
    #     # chooses the key based on the materials description stored
    #     # with the encrypted object
    #     s3 = Aws::S3::EncryptionV3::Client.new(
    #       key_provider: keys,
    #       key_wrap_schema: :aes_gcm # or :rsa_oaep_sha1 for RSA keys
    #     )
    #
    # ## Materials Description
    #
    # A materials description is JSON document string that is stored
    # in the metadata (or instruction file) of an encrypted object.
    # The {DefaultKeyProvider} uses the empty JSON document `"{}"`.
    #
    # When building a key provider, you are free to store whatever
    # information you need to identify the master key that was used
    # to encrypt the object.
    #
    # ## Envelope Location
    #
    # By default, the encryption client store the encryption envelope
    # with the object, as metadata. You can choose to have the envelope
    # stored in a separate "instruction file". An instruction file
    # is an object, with the key of the encrypted object, suffixed with
    # `".instruction"`.
    #
    # Specify the `:envelope_location` option as `:instruction_file` to
    # use an instruction file for storing the envelope.
    #
    #     # default behavior
    #     s3 = Aws::S3::EncryptionV3::Client.new(
    #       encryption_key: your_key,
    #       key_wrap_schema: :aes_gcm,
    #       envelope_location: :metadata
    #     )
    #
    #     # store envelope in a separate object
    #     s3 = Aws::S3::EncryptionV3::Client.new(
    #       encryption_key: your_key,
    #       key_wrap_schema: :aes_gcm,
    #       envelope_location: :instruction_file,
    #       instruction_file_suffix: '.instruction' # default
    #     )
    #
    # When using an instruction file, multiple requests are made when
    # putting and getting the object. **This may cause issues if you are
    # issuing concurrent PUT and GET requests to an encrypted object.**
    #
    # ## Commitment Policies Explained
    #
    # * `:forbid_encrypt_allow_decrypt` - Encrypts without key commitment (for
    #   backward compatibility with systems that have not been updated), but can decrypt
    #   objects with or without commitment. Use if you are not sure that all readers
    #   can decrypt objects encrypted with key commitment.
    #
    # * `:require_encrypt_allow_decrypt` - Encrypts with key commitment, can decrypt
    #   objects with or without commitment. Use once all readers
    #   can decrypt objects encrypted with key commitment.
    #
    # * `:require_encrypt_require_decrypt` - Encrypts with key commitment, can only
    #   decrypt objects with key commitment. **Recommended for new applications and
    #   after migrations are complete.** This is the default.
    #
    module EncryptionV3
      class Client
        ##= ../specification/s3-encryption/client.md#aws-sdk-compatibility
        ##= type=implication
        ##% The S3EC MUST provide a different set of configuration options than the conventional S3 client.

        REQUIRED_PARAMS = [:key_wrap_schema].freeze

        OPTIONAL_PARAMS = [
          :kms_key_id,
          :kms_client,
          :key_provider,
          :encryption_key,
          :envelope_location,
          ##= ../specification/s3-encryption/client.md#instruction-file-configuration
          ##% In this case, the Instruction File Configuration SHOULD be optional, such that its default configuration is used when none is provided.
          :instruction_file_suffix,
          ##= ../specification/s3-encryption/client.md#encryption-algorithm
          ##% The S3EC MUST support configuration of the encryption algorithm (or algorithm suite) during its initialization.
          :content_encryption_schema,
          :security_profile,
          ##= ../specification/s3-encryption/client.md#key-commitment
          ##% The S3EC MUST support configuration of the [Key Commitment policy](./key-commitment.md) during its initialization.
          :commitment_policy
        ].freeze
        SUPPORTED_COMMITMENT_POLICIES = %i[
          forbid_encrypt_allow_decrypt
          require_encrypt_allow_decrypt
          require_encrypt_require_decrypt
        ].freeze

        ##= ../specification/s3-encryption/client.md#enable-legacy-wrapping-algorithms
        ##% The S3EC MUST support the option to enable or disable legacy wrapping algorithms.
        ##= ../specification/s3-encryption/client.md#enable-legacy-unauthenticated-modes
        ##% The S3EC MUST support the option to enable or disable legacy unauthenticated modes (content encryption algorithms).
        SUPPORTED_SECURITY_PROFILES = %i[v3 v3_and_legacy].freeze

        ##= ../specification/s3-encryption/client.md#enable-legacy-unauthenticated-modes
        ##% The option to enable legacy unauthenticated modes MUST be set to false by default.
        ##= ../specification/s3-encryption/client.md#enable-legacy-wrapping-algorithms
        ##% The option to enable legacy wrapping algorithms MUST be set to false by default.
        DEFAULT_SECURITY_PROFILES = :v3
        DEFAULT_COMMITMENT_POLICIES = :require_encrypt_require_decrypt
        DEFAULT_CONTENT_ENCRYPTION_SCHEMA = :alg_aes_256_gcm_hkdf_sha512_commit_key

        extend Deprecations
        extend Forwardable
        def_delegators :@client, :config, :delete_object, :head_object, :build_request

        # Creates a new encryption client.
        #
        # ## Required Configuration
        #
        # * a key or key provider - The key provided also determines the key wrapping
        #   schema(s) supported for both encryption and decryption.
        # * `key_wrap_schema` - The key wrapping schema. It must match the type of key configured.
        #
        # ## Optional Configuration (with defaults)
        #
        # * `content_encryption_schema` - Defaults to `:alg_aes_256_gcm_hkdf_sha512_commit_key`
        # * `security_profile` - Defaults to `:v3`. Set to `:v3_and_legacy` to read V2-encrypted objects.
        # * `commitment_policy` - Defaults to `:require_encrypt_require_decrypt` (most secure)
        #
        # To configure the key you must provide one of the following set of options:
        #
        # * `:encryption_key`
        # * `:kms_key_id`
        # * `:key_provider`
        #
        # You may also pass any other options accepted by `Client#initialize`.
        #
        # @option options [S3::Client] :client A basic S3 client that is used
        #   to make api calls. If a `:client` is not provided, a new {S3::Client}
        #   will be constructed.
        #
        # @option options [OpenSSL::PKey::RSA, String] :encryption_key The master
        #   key to use for encrypting/decrypting all objects.
        #
        # @option options [String] :kms_key_id When you provide a `:kms_key_id`,
        #   then AWS Key Management Service (KMS) will be used to manage the
        #   object encryption keys. By default a {KMS::Client} will be
        #   constructed for KMS API calls. Alternatively, you can provide
        #   your own via `:kms_client`. To only support decryption/reads, you may
        #   provide `:allow_decrypt_with_any_cmk` which will use
        #   the implicit CMK associated with the data during reads but will
        #   not allow you to encrypt/write objects with this client.
        #
        # @option options [#key_for] :key_provider Any object that responds
        #   to `#key_for`. This method should accept a materials description
        #   JSON document string and return return an encryption key.
        #
        # @option options [required, Symbol] :key_wrap_schema The Key wrapping
        #   schema to be used. It must match the type of key configured.
        #   Must be one of the following:
        #
        #   * :kms_context  (Must provide kms_key_id)
        #   * :aes_gcm (Must provide an AES (string) key)
        #   * :rsa_oaep_sha1 (Must provide an RSA key)
        #
        # @option options [Symbol] :content_encryption_schema (:alg_aes_256_gcm_hkdf_sha512_commit_key)
        #   The content encryption algorithm to use. Defaults to the V3 algorithm with key commitment.
        #
        # @option options [Symbol] :security_profile (:v3)
        #   Determines the support for reading objects written using older
        #   encryption schemas. Must be one of the following:
        #
        #   * :v3 - Only reads V3-encrypted objects (default, most secure)
        #   * :v3_and_legacy - Enables reading of V2-encrypted objects
        #
        # @option options [Symbol] :commitment_policy (:require_encrypt_require_decrypt)
        #   Determines support for key commitment. Must be one of the following:
        #
        #   * :forbid_encrypt_allow_decrypt - Does not encrypt with key commitment,
        #     can decrypt with or without. Use only for specific compatibility needs.
        #   * :require_encrypt_allow_decrypt - Encrypts with key commitment, can
        #     decrypt with or without.
        #   * :require_encrypt_require_decrypt - Encrypts with key commitment, only
        #     decrypts objects with key commitment (default, most secure)
        #
        # @option options [Symbol] :envelope_location (:metadata) Where to
        #   store the envelope encryption keys. By default, the envelope is
        #   stored with the encrypted object. If you pass `:instruction_file`,
        #   then the envelope is stored in a separate object in Amazon S3.
        #
        # @option options [String] :instruction_file_suffix ('.instruction')
        #   When `:envelope_location` is `:instruction_file` then the
        #   instruction file uses the object key with this suffix appended.
        #
        # @option options [KMS::Client] :kms_client A default {KMS::Client}
        #   is constructed when using KMS to manage encryption keys.
        #
        def initialize(options = {})
          validate_params(options)
          ##= ../specification/s3-encryption/client.md#wrapped-s3-client-s
          ##% The S3EC MUST support the option to provide an SDK S3 client instance during its initialization.
          @client = extract_client(options)
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
          ##% Instruction File writes MUST be optionally configured during client creation or on each PutObject request.
          ##= ../specification/s3-encryption/client.md#instruction-file-configuration
          ##% The S3EC MAY support the option to provide Instruction File Configuration during its initialization.
          ##= ../specification/s3-encryption/client.md#instruction-file-configuration
          ##% If the S3EC in a given language supports Instruction Files, then it MUST accept Instruction File Configuration during its initialization.
          @envelope_location = extract_location(options)
          @instruction_file_suffix = extract_suffix(options)
          @kms_allow_decrypt_with_any_cmk =
            options[:kms_key_id] == :kms_allow_decrypt_with_any_cmk
          @commitment_policy = extract_commitment_policy(options)
          @security_profile = extract_security_profile(options)

          ##= ../specification/s3-encryption/client.md#key-commitment
          ##% The S3EC MUST validate the configured Encryption Algorithm against the provided key commitment policy.
          if @commitment_policy != :require_encrypt_require_decrypt
            new_options = options.merge(
              {
                security_profile: security_profile_to_v2(@security_profile),
                ##= ../specification/s3-encryption/client.md#key-commitment
                ##% If the configured Encryption Algorithm is incompatible with the key commitment policy, then it MUST throw an exception.
                content_encryption_schema: if @commitment_policy == :forbid_encrypt_allow_decrypt
                                             options[:content_encryption_schema]
                                           else
                                             # assert @commitment_policy = :require_encrypt_allow_decrypt
                                             # In this case the v2_cipher_provider is only used for decrypt
                                             :aes_gcm_no_padding
                                           end
              }
            )
            @v2_cipher_provider = build_v2_cipher_provider_for_decrypt(new_options)
            # In this case the v3 cipher is only used for decrypt.
            @v3_cipher_provider = build_cipher_provider(options.reject { |k, _| k == :content_encryption_schema })
            @key_provider = @v2_cipher_provider.key_provider if @v2_cipher_provider.is_a?(DefaultCipherProvider)
          else
            @v3_cipher_provider = build_cipher_provider(options)
            @key_provider = @v3_cipher_provider.key_provider if @v3_cipher_provider.is_a?(DefaultCipherProvider)
          end
        end

        # @return [S3::Client]
        attr_reader :client

        # @return [KeyProvider, nil] Returns `nil` if you are using
        #   AWS Key Management Service (KMS).
        attr_reader :key_provider

        # @return [Symbol] Determines the support for reading objects written
        #   using older key wrap or content encryption schemas.
        attr_reader :commitment_policy

        # @return [Boolean] If true the provided KMS key_id will not be used
        #   during decrypt, allowing decryption with the key_id from the object.
        attr_reader :kms_allow_decrypt_with_any_cmk

        # @return [Symbol<:metadata, :instruction_file>]
        attr_reader :envelope_location

        # @return [String] When {#envelope_location} is `:instruction_file`,
        #   the envelope is stored in the object with the object key suffixed
        #   by this string.
        attr_reader :instruction_file_suffix

        ##= ../specification/s3-encryption/client.md#aws-sdk-compatibility
        ##= type=implication
        ##% The S3EC MUST adhere to the same interface for API operations as the conventional AWS SDK S3 client.
        ##= ../specification/s3-encryption/client.md#aws-sdk-compatibility
        ##= type=exception
        ##= reason=The ruby client does not support other operations
        ##% The S3EC SHOULD support invoking operations unrelated to client-side encryption e.g.

        # Uploads an object to Amazon S3, encrypting data client-side.
        # See {S3::Client#put_object} for documentation on accepted
        # request parameters.
        # @option params [Hash] :kms_encryption_context Additional encryption
        #   context to use with KMS.  Applies only when KMS is used. In order
        #   to decrypt the object you will need to provide the identical
        #   :kms_encryption_context to `get_object`.
        # @option (see S3::Client#put_object)
        # @return (see S3::Client#put_object)
        # @see S3::Client#put_object
        def put_object(params = {})
          kms_encryption_context = params.delete(:kms_encryption_context)
          ##= ../specification/s3-encryption/client.md#required-api-operations
          ##% - PutObject MUST be implemented by the S3EC.
          req = @client.build_request(:put_object, params)
          ##= ../specification/s3-encryption/client.md#required-api-operations
          ##% - PutObject MUST encrypt its input data before it is uploaded to S3.
          req.handlers.add(EncryptHandler, priority: 95)
          req.context[:encryption] = {
            cipher_provider:
            if @commitment_policy == :forbid_encrypt_allow_decrypt
              ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
              ##% When the commitment policy is FORBID_ENCRYPT_ALLOW_DECRYPT, the S3EC MUST NOT encrypt using an algorithm suite which supports key commitment.
              @v2_cipher_provider
            else
              ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
              ##% When the commitment policy is REQUIRE_ENCRYPT_ALLOW_DECRYPT, the S3EC MUST only encrypt using an algorithm suite which supports key commitment.
              ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
              ##% When the commitment policy is REQUIRE_ENCRYPT_REQUIRE_DECRYPT, the S3EC MUST only encrypt using an algorithm suite which supports key commitment.
              @v3_cipher_provider
            end,
            envelope_location: @envelope_location,
            instruction_file_suffix: @instruction_file_suffix,
            kms_encryption_context: kms_encryption_context
          }
          Aws::Plugins::UserAgent.metric('S3_CRYPTO_V3') do
            req.send_request
          end
        end

        # Gets an object from Amazon S3, decrypting data locally.
        # See {S3::Client#get_object} for documentation on accepted
        # request parameters.
        # Warning: If you provide a block to get_object or set the request
        # parameter :response_target to a Proc, then read the entire object to the
        # end before you start using the decrypted data. This is to verify that
        # the object has not been modified since it was encrypted.
        #
        # @option options [Symbol] :security_profile
        #   Determines the support for reading objects written using older
        #   encryption schemas. Overrides the value set on client construction if provided.
        #   Must be one of the following:
        #
        #   * :v3 - Only reads V3-encrypted objects (most secure)
        #   * :v3_and_legacy - Enables reading of V2-encrypted objects
        # @option params [String] :instruction_file_suffix The suffix
        #   used to find the instruction file containing the encryption
        #   envelope. You should not set this option when the envelope
        #   is stored in the object metadata. Defaults to
        #   {#instruction_file_suffix}.
        # @option params [Hash] :kms_encryption_context Additional encryption
        #   context to use with KMS.  Applies only when KMS is used.
        # @option options [Boolean] :kms_allow_decrypt_with_any_cmk (false)
        #   By default the KMS CMK ID (kms_key_id) will be used during decrypt
        #   and will fail if there is a mismatch.  Setting this to true
        #   will use the implicit CMK associated with the data.
        # @option (see S3::Client#get_object)
        # @return (see S3::Client#get_object)
        # @see S3::Client#get_object
        # @note The `:range` request parameter is not supported.
        def get_object(params = {}, &block)
          raise NotImplementedError, '#get_object with :range not supported' if params[:range]

          envelope_location, instruction_file_suffix = envelope_options(params)
          kms_encryption_context = params.delete(:kms_encryption_context)
          kms_any_cmk_mode = kms_any_cmk_mode(params)
          commitment_policy = commitment_policy_from_params(params)

          ##= ../specification/s3-encryption/client.md#required-api-operations
          ##% - GetObject MUST be implemented by the S3EC.
          req = @client.build_request(:get_object, params)
          ##= ../specification/s3-encryption/client.md#required-api-operations
          ##% - GetObject MUST decrypt data received from the S3 server and return it as plaintext.
          req.handlers.add(DecryptHandler)
          req.context[:encryption] = {
            v3_cipher_provider: @v3_cipher_provider,
            envelope_location: envelope_location,
            instruction_file_suffix: instruction_file_suffix,
            kms_encryption_context: kms_encryption_context,
            kms_allow_decrypt_with_any_cmk: kms_any_cmk_mode,
            commitment_policy: commitment_policy
          }.tap do |hash|
            if commitment_policy != :require_encrypt_require_decrypt
              security_profile = security_profile_from_params(params)
              hash[:security_profile] = security_profile_to_v2(security_profile)
              hash[:cipher_provider] = @v2_cipher_provider
            end
          end
          Aws::Plugins::UserAgent.metric('S3_CRYPTO_V3') do
            req.send_request(target: block)
          end
        end

        ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% The S3EC MAY support re-encryption/key rotation via Instruction Files.
        ##= ../specification/s3-encryption/decryption.md#ranged-gets
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% The S3EC MAY support the "range" parameter on GetObject which specifies a subset of bytes to download and decrypt.
        ##= ../specification/s3-encryption/decryption.md#ranged-gets
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% If the S3EC supports Ranged Gets, the S3EC MUST adjust the customer-provided range to include the beginning and end of the cipher blocks for the given range.
        ##= ../specification/s3-encryption/decryption.md#ranged-gets
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% If the object was encrypted with ALG_AES_256_GCM_IV12_TAG16_NO_KDF, then ALG_AES_256_CTR_IV16_TAG16_NO_KDF MUST be used to decrypt the range of the object.
        ##= ../specification/s3-encryption/decryption.md#ranged-gets
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% If the object was encrypted with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY, then ALG_AES_256_CTR_HKDF_SHA512_COMMIT_KEY MUST be used to decrypt the range of the object.
        ##= ../specification/s3-encryption/decryption.md#ranged-gets
        ##= type=exception
        ##= reason=This has never been supported in Ruby
        ##% If the GetObject response contains a range, but the GetObject request does not contain a range, the S3EC MUST throw an exception.

        private

        def build_cipher_provider(options)
          if options[:kms_key_id]
            KmsCipherProvider.new(
              kms_key_id: options[:kms_key_id],
              kms_client: kms_client(options),
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          else
            ##= ../specification/s3-encryption/client.md#cryptographic-materials
            ##% The S3EC MAY accept key material directly.
            key_provider = extract_key_provider(options)
            DefaultCipherProvider.new(
              key_provider: key_provider,
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          end
        end

        def build_v2_cipher_provider_for_decrypt(options)
          if options[:kms_key_id]
            Aws::S3::EncryptionV2::KmsCipherProvider.new(
              kms_key_id: options[:kms_key_id],
              kms_client: kms_client(options),
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          else
            # Create V2 key provider explicitly for proper namespace consistency
            key_provider = if options[:key_provider]
                             options[:key_provider]
                           elsif options[:encryption_key]
                             Aws::S3::EncryptionV2::DefaultKeyProvider.new(options)
                           else
                             msg = 'you must pass a :kms_key_id, :key_provider, or :encryption_key'
                             raise ArgumentError, msg
                           end
            Aws::S3::EncryptionV2::DefaultCipherProvider.new(
              key_provider: key_provider,
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          end
        end

        # Validate required parameters exist and don't conflict.
        # The cek_alg and wrap_alg are passed on to the CipherProviders
        # and further validated there
        def validate_params(options)
          unless (missing_params = REQUIRED_PARAMS - options.keys).empty?
            raise ArgumentError, 'Missing required parameter(s): '\
              "#{missing_params.map { |s| ":#{s}" }.join(', ')}"
          end

          wrap_alg = options[:key_wrap_schema]

          # validate that the wrap alg matches the type of key given
          case wrap_alg
          when :kms_context
            raise ArgumentError, 'You must provide :kms_key_id to use :kms_context' unless options[:kms_key_id]
          end
        end

        def extract_client(options)
          ##= ../specification/s3-encryption/client.md#wrapped-s3-client-s
          ##= type=exception
          ##= reason=this would be a breaking change to ruby
          ##% The S3EC MUST NOT support use of S3EC as the provided S3 client during its initialization; it MUST throw an exception in this case.
          options[:client] || begin
            ##= ../specification/s3-encryption/client.md#inherited-sdk-configuration
            ##% The S3EC MAY support directly configuring the wrapped SDK clients through its initialization.
            ##= ../specification/s3-encryption/client.md#inherited-sdk-configuration
            ##% For example, the S3EC MAY accept a credentials provider instance during its initialization.
            ##= ../specification/s3-encryption/client.md#inherited-sdk-configuration
            ##% If the S3EC accepts SDK client configuration, the configuration MUST be applied to all wrapped S3 clients.
            S3::Client.new(extract_sdk_options(options))
          end
        end

        def kms_client(options)
          options[:kms_client] || (@kms_client ||=
                                     KMS::Client.new(
                                       # extract the region and credentials first, if they are not configured, then getting them from an existing client is faster
                                       ##= ../specification/s3-encryption/client.md#inherited-sdk-configuration
                                       ##% If the S3EC accepts SDK client configuration, the configuration MUST be applied to all wrapped SDK clients including the KMS client.
                                       {
                                         region: @client.config.region,
                                         credentials: @client.config.credentials
                                       }.merge(extract_sdk_options(options))
                                     )
                                  )
        end

        def extract_sdk_options(options)
          options = options.dup
          OPTIONAL_PARAMS.each { |p| options.delete(p) }
          REQUIRED_PARAMS.each { |p| options.delete(p) }
          options
        end

        def extract_key_provider(options)
          if options[:key_provider]
            options[:key_provider]
          elsif options[:encryption_key]
            DefaultKeyProvider.new(options)
          else
            msg = 'you must pass a :kms_key_id, :key_provider, or :encryption_key'
            raise ArgumentError, msg
          end
        end

        def envelope_options(params)
          location = params.delete(:envelope_location) || @envelope_location
          suffix = params.delete(:instruction_file_suffix)
          if suffix
            ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
            ##% The S3EC SHOULD support providing a custom Instruction File suffix on GetObject requests, regardless of whether or not re-encryption is supported.
            [:instruction_file, suffix]
          else
            [location, @instruction_file_suffix]
          end
        end

        def extract_location(options)
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#object-metadata
          ##% By default, the S3EC MUST store content metadata in the S3 Object Metadata.
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
          ##% Instruction File writes MUST NOT be enabled by default.
          location = options[:envelope_location] || :metadata
          if %i[metadata instruction_file].include?(location)
            location
          else
            msg = ':envelope_location must be :metadata or :instruction_file '\
                  "got #{location.inspect}"
            raise ArgumentError, msg
          end
        end

        def extract_suffix(options)
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
          ##% The default Instruction File behavior uses the same S3 object key as its associated object suffixed with ".instruction".
          suffix = options[:instruction_file_suffix] || '.instruction'
          if suffix.is_a? String
            ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
            ##= type=exception
            ##= reason=Ruby has always supported this option
            ##% The S3EC MUST NOT support providing a custom Instruction File suffix on ordinary writes; custom suffixes MUST only be used during re-encryption.
            suffix
          else
            msg = ':instruction_file_suffix must be a String'
            raise ArgumentError, msg
          end
        end

        def kms_any_cmk_mode(params)
          if !params[:kms_allow_decrypt_with_any_cmk].nil?
            params.delete(:kms_allow_decrypt_with_any_cmk)
          else
            @kms_allow_decrypt_with_any_cmk
          end
        end

        def extract_commitment_policy(options)
          validate_commitment_policy(options[:commitment_policy])
        end

        def commitment_policy_from_params(params)
          commitment_policy =
            if !params[:commitment_policy].nil?
              params.delete(:commitment_policy)
            else
              @commitment_policy
            end
          validate_commitment_policy(commitment_policy)
        end

        def validate_commitment_policy(commitment_policy)
          return DEFAULT_COMMITMENT_POLICIES if commitment_policy.nil?

          unless SUPPORTED_COMMITMENT_POLICIES.include? commitment_policy
            raise ArgumentError, "Unsupported security profile: :#{commitment_policy}. " \
            "Please provide one of: #{SUPPORTED_COMMITMENT_POLICIES.map { |s| ":#{s}" }.join(', ')}"
          end
          commitment_policy
        end

        def extract_security_profile(options)
          validate_security_profile(options[:security_profile])
        end

        def security_profile_from_params(params)
          security_profile =
            if !params[:security_profile].nil?
              params.delete(:security_profile)
            else
              @security_profile
            end
          validate_security_profile(security_profile)
        end

        def validate_security_profile(security_profile)
          return DEFAULT_SECURITY_PROFILES if security_profile.nil?

          unless SUPPORTED_SECURITY_PROFILES.include? security_profile
            raise ArgumentError, "Unsupported security profile: :#{security_profile}. " \
            "Please provide one of: #{SUPPORTED_SECURITY_PROFILES.map { |s| ":#{s}" }.join(', ')}"
          end
          if security_profile == :v3_and_legacy && !@warned_about_legacy
            @warned_about_legacy = true
            warn(
              'The S3 Encryption Client is configured to read encrypted objects ' \
              "with legacy encryption modes. If you don't have objects " \
              'encrypted with these legacy modes, you should disable support ' \
              'for them to enhance security.'
            )
          end
          security_profile
        end

        def security_profile_to_v2(security_profile)
          case security_profile
          when :v3
            :v2
          when :v3_and_legacy
            :v2_and_legacy
          end
        end
      end
    end
  end
end

##= ../specification/s3-encryption/client.md#cryptographic-materials
##= type=exception
##= reason=the ruby client does not use keyrings
##% The S3EC MUST accept either one CMM or one Keyring instance upon initialization.
##= ../specification/s3-encryption/client.md#cryptographic-materials
##= type=exception
##= reason=the ruby client does not use keyrings
##% If both a CMM and a Keyring are provided, the S3EC MUST throw an exception.
##= ../specification/s3-encryption/client.md#cryptographic-materials
##= type=exception
##= reason=the ruby client does not use keyrings
##% When a Keyring is provided, the S3EC MUST create an instance of the DefaultCMM using the provided Keyring.
##= ../specification/s3-encryption/client.md#enable-delayed-authentication
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% The S3EC MUST support the option to enable or disable Delayed Authentication mode.
##= ../specification/s3-encryption/client.md#enable-delayed-authentication
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% Delayed Authentication mode MUST be set to false by default.
##= ../specification/s3-encryption/client.md#enable-delayed-authentication
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% When enabled, the S3EC MAY release plaintext from a stream which has not been authenticated.
##= ../specification/s3-encryption/client.md#enable-delayed-authentication
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% When disabled the S3EC MUST NOT release plaintext from a stream which has not been authenticated.
##= ../specification/s3-encryption/client.md#set-buffer-size
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% The S3EC SHOULD accept a configurable buffer size which refers to the maximum ciphertext length in bytes to store in memory when Delayed Authentication mode is disabled.
##= ../specification/s3-encryption/client.md#set-buffer-size
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% If Delayed Authentication mode is enabled, and the buffer size has been set to a value other than its default, the S3EC MUST throw an exception.
##= ../specification/s3-encryption/client.md#set-buffer-size
##= type=exception
##= reason=the ruby client does not support delayed authentication
##% If Delayed Authentication mode is disabled, and no buffer size is provided, the S3EC MUST set the buffer size to a reasonable default.
##= ../specification/s3-encryption/client.md#randomness
##= type=exception
##= reason=the ruby client does not support a configured source of randomness
##% The S3EC MAY accept a source of randomness during client initialization.
##= ../specification/s3-encryption/client.md#optional-api-operations
##= type=exception
##= reason=the ruby client does not support any additional S3 operations
##% - CreateMultipartUpload MAY be implemented by the S3EC.
##%   - If implemented, CreateMultipartUpload MUST initiate a multipart upload.
##% - UploadPart MAY be implemented by the S3EC.
##%   - UploadPart MUST encrypt each part.
##%   - Each part MUST be encrypted in sequence.
##%   - Each part MUST be encrypted using the same cipher instance for each part.
##% - CompleteMultipartUpload MAY be implemented by the S3EC.
##%   - CompleteMultipartUpload MUST complete the multipart upload.
##% - AbortMultipartUpload MAY be implemented by the S3EC.
##%   - AbortMultipartUpload MUST abort the multipart upload.
##%
##% The S3EC may provide implementations for the following S3EC-specific operation(s):
##%
##% - ReEncryptInstructionFile MAY be implemented by the S3EC.
##%   - ReEncryptInstructionFile MUST decrypt the instruction file's encrypted data key for the given object using the client's CMM.
##%   - ReEncryptInstructionFile MUST re-encrypt the plaintext data key with a provided keyring.
##= ../specification/s3-encryption/client.md#required-api-operations
##= type=exception
##= reason=the ruby client does not support the delete operation, this would be a bending change
##% - DeleteObject MUST be implemented by the S3EC.
##%   - DeleteObject MUST delete the given object key.
##%   - DeleteObject MUST delete the associated instruction file using the default instruction file suffix.
##% - DeleteObjects MUST be implemented by the S3EC.
##%   - DeleteObjects MUST delete each of the given objects.
##%   - DeleteObjects MUST delete each of the corresponding instruction files using the default instruction file suffix.
