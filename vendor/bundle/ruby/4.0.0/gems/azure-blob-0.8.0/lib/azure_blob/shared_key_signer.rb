# frozen_string_literal: true

require "base64"
require "openssl"
require_relative "canonicalized_headers"
require_relative "canonicalized_resource"

module AzureBlob
  class SharedKeySigner # :nodoc:
    def initialize(account_name:, access_key:, host:)
      @account_name = account_name
      @access_key = Base64.decode64(access_key)
      @host = host
      @remove_prefix = @host.end_with?("/#{@account_name}")
    end

    def authorization_header(uri:, verb:, headers: {})
      canonicalized_headers = CanonicalizedHeaders.new(headers)
      canonicalized_resource = CanonicalizedResource.new(uri, account_name)

      to_sign = [
        verb,
        *sanitize_headers(headers).fetch_values(
          :"Content-Encoding",
          :"Content-Language",
          :"Content-Length",
          :"Content-MD5",
          :"Content-Type",
          :"Date",
          :"If-Modified-Since",
          :"If-Match",
          :"If-None-Match",
          :"If-Unmodified-Since",
          :"Range"
        ) { nil },
        canonicalized_headers,
        canonicalized_resource,
      ].join("\n")

      "SharedKey #{account_name}:#{sign(to_sign)}"
    end

    def sas_token(uri, options = {})
      if remove_prefix
        uri = uri.clone
        uri.path = uri.path.delete_prefix("/#{account_name}")
      end

      to_sign = [
        options[:permissions],
        options[:start],
        options[:expiry],
        CanonicalizedResource.new(uri, account_name, url_safe: false, service_name: :blob),
        options[:identifier],
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
        SAS::Fields::Version => SAS::Version,
        SAS::Fields::Expiry => options[:expiry],
        SAS::Fields::Resource => SAS::Resources::Blob,
        SAS::Fields::Disposition => options[:content_disposition],
        SAS::Fields::Type => options[:content_type],
        SAS::Fields::Signature => sign(to_sign),
      }.reject { |_, value| value.nil? }

      URI.encode_www_form(**query)
    end

    private

    def sign(body)
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", access_key, body))
    end

    def sanitize_headers(headers)
      headers = headers.dup
      headers[:"Content-Length"] = nil if headers[:"Content-Length"].to_i == 0
      headers
    end

    module SAS # :nodoc:
      Version = "2024-05-04"
      module Fields # :nodoc:
        Permissions = :sp
        Version = :sv
        Expiry = :se
        Resource = :sr
        Signature = :sig
        Disposition = :rscd
        Type = :rsct
      end
      module Resources # :nodoc:
        Blob = :b
      end
    end

    attr_reader :access_key, :account_name, :remove_prefix
  end
end
