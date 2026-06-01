require "base64"
require "openssl"
require "net/http"
require "rexml/document"

require_relative "canonicalized_resource"
require_relative "identity_token"

require_relative "user_delegation_key"

module AzureBlob
  class EntraIdSigner # :nodoc:
    attr_reader :token
    attr_reader :account_name
    attr_reader :host

    def initialize(account_name:, host:, principal_id: nil)
      @token = AzureBlob::IdentityToken.new(principal_id:)
      @account_name = account_name
      @host = host
    end

    def authorization_header(uri:, verb:, headers: {})
      "Bearer #{token}"
    end

    def sas_token(uri, options = {})
      delegation_key.refresh
      to_sign = [
        options[:permissions],
        options[:start],
        options[:expiry],
        CanonicalizedResource.new(uri, account_name, url_safe: false, service_name: :blob),
        delegation_key.signed_oid,
        delegation_key.signed_tid,
        delegation_key.signed_start,
        delegation_key.signed_expiry,
        delegation_key.signed_service,
        delegation_key.signed_version,
        nil,
        nil,
        nil,
        options[:ip],
        options[:protocol],
        SAS::Version,
        SAS::Resources::Blob,
        nil,
        nil,
        nil,
        options[:content_disposition],
        nil,
        nil,
        options[:content_type],
      ].join("\n")

      query = {
        SAS::Fields::Permissions => options[:permissions],
        SAS::Fields::Start => options[:start],
        SAS::Fields::Expiry => options[:expiry],

        SAS::Fields::SignedObjectId => delegation_key.signed_oid,
        SAS::Fields::SignedTenantId => delegation_key.signed_tid,
        SAS::Fields::SignedKeyStartTime => delegation_key.signed_start,
        SAS::Fields::SignedKeyExpiryTime => delegation_key.signed_expiry,
        SAS::Fields::SignedKeyService => delegation_key.signed_service,
        SAS::Fields::Signedkeyversion => delegation_key.signed_version,


        SAS::Fields::SignedIp => options[:ip],
        SAS::Fields::SignedProtocol => options[:protocol],
        SAS::Fields::Version => SAS::Version,
        SAS::Fields::Resource => SAS::Resources::Blob,

        SAS::Fields::Disposition => options[:content_disposition],
        SAS::Fields::Type => options[:content_type],
        SAS::Fields::Signature => sign(to_sign, key: delegation_key.to_s),

      }.reject { |_, value| value.nil? }

      URI.encode_www_form(**query)
    end

    private

    def delegation_key
      @delegation_key ||= UserDelegationKey.new(account_name:, signer: self)
    end

    def sign(body, key:)
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", key, body))
    end

    module SAS # :nodoc:
      Version = "2024-05-04"
      module Fields # :nodoc:
        Permissions = :sp
        Version = :sv
        Start = :st
        Expiry = :se
        Resource = :sr
        Signature = :sig
        Disposition = :rscd
        Type = :rsct
        SignedObjectId = :skoid
        SignedTenantId = :sktid
        SignedKeyStartTime = :skt
        SignedKeyExpiryTime = :ske
        SignedKeyService = :sks
        Signedkeyversion = :skv
        SignedIp = :sip
        SignedProtocol = :spr
      end
      module Resources # :nodoc:
        Blob = :b
      end
    end
  end
end
