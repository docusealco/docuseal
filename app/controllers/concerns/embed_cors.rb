# frozen_string_literal: true

module EmbedCors
  extend ActiveSupport::Concern

  private

  def set_embed_cors_headers
    allowed_origin = embed_cors_allowed_origin

    headers.delete('Access-Control-Allow-Origin')

    return if allowed_origin.blank?

    headers['Access-Control-Allow-Origin'] = allowed_origin
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Max-Age'] = '1728000'
    headers['Vary'] = [headers['Vary'], 'Origin'].compact_blank.join(', ') unless allowed_origin == '*'
  end

  def embed_cors_allowed_origin
    origin = normalized_embed_origin(request.headers['Origin'])

    return '*' if origin.blank?

    account_origins = configured_embed_origins_for_account(embed_cors_account)

    return origin if account_origins.include?(origin)
    return if account_origins.present?

    configured_origins = configured_embed_origins

    return origin if configured_origins.include?(origin)
    return if configured_origins.present?

    '*'
  end

  def configured_embed_origins_for_account(account)
    normalize_embed_origins(
      account&.account_configs&.find_by(key: AccountConfig::EMBED_ALLOWED_ORIGINS_KEY)&.value
    )
  end

  def configured_embed_origins
    normalize_embed_origins(
      AccountConfig.where(key: AccountConfig::EMBED_ALLOWED_ORIGINS_KEY).map(&:value).flatten
    )
  end

  def normalize_embed_origins(value)
    Array.wrap(value).filter_map { |origin| normalized_embed_origin(origin) }.uniq
  end

  def normalized_embed_origin(origin)
    return if origin.blank?

    uri = Addressable::URI.parse(origin.to_s.strip)

    return unless uri.scheme.in?(%w[http https]) && uri.host.present?

    uri.path = nil
    uri.query = nil
    uri.fragment = nil
    uri.to_s.delete_suffix('/')
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def embed_cors_account
    return @embed_cors_account if defined?(@embed_cors_account)

    current_account if respond_to?(:current_account, true)
  end
end
