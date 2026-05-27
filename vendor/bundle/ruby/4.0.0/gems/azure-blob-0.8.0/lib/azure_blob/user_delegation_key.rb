require_relative "http"

module AzureBlob
  class UserDelegationKey # :nodoc:
    EXPIRATION = 25200 # 7 hours
    EXPIRATION_BUFFER = 3600 # 1 hours
    def initialize(account_name:, signer:)
      @uri = URI.parse(
        "#{signer.host}/?restype=service&comp=userdelegationkey"
      )

      @signer = signer

      refresh
    end

    def to_s
      refresh
      user_delegation_key
    end

    def refresh
      return unless expired?
      now = Time.now.utc


      start = now.iso8601
      @expiration = (now + EXPIRATION)
      expiry = @expiration.iso8601

      content = <<-XML.gsub!(/[[:space:]]+/, " ").strip!
        <?xml version="1.0" encoding="utf-8"?>
        <KeyInfo>
            <Start>#{start}</Start>
            <Expiry>#{expiry}</Expiry>
        </KeyInfo>
      XML

      response  = Http.new(uri, signer:).post(content)

      doc = REXML::Document.new(response)

      @signed_oid  = doc.get_elements("/UserDelegationKey/SignedOid").first.get_text.to_s
      @signed_tid = doc.get_elements("/UserDelegationKey/SignedTid").first.get_text.to_s
      @signed_start = doc.get_elements("/UserDelegationKey/SignedStart").first.get_text.to_s
      @signed_expiry = doc.get_elements("/UserDelegationKey/SignedExpiry").first.get_text.to_s
      @signed_service = doc.get_elements("/UserDelegationKey/SignedService").first.get_text.to_s
      @signed_version = doc.get_elements("/UserDelegationKey/SignedVersion").first.get_text.to_s
      @user_delegation_key = Base64.decode64(doc.get_elements("/UserDelegationKey/Value").first.get_text.to_s)
    end

    attr_reader :signed_oid,
      :signed_tid,
      :signed_start,
      :signed_expiry,
      :signed_service,
      :signed_version,
      :user_delegation_key

    private

    def expired?
      expiration.nil? || Time.now >= (expiration - EXPIRATION_BUFFER)
    end

    attr_reader :uri, :user_delegation_key, :signer, :expiration
  end
end
