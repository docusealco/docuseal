# frozen_string_literal: true

module EmailMessages
  MIN_BODY_SIZE = 2.kilobytes
  MIN_ASSET_SIZE = 256.bytes
  STYLE_REGEXP = %r{<style[^>]*>.*?</style>(?:\s*<style[^>]*>.*?</style>)*}mi
  BASE64_REGEXP = %r{(data:[^,]*;base64,)([A-Za-z0-9+/=]+)}
  ASSET_REGEXP = Regexp.union(STYLE_REGEXP, BASE64_REGEXP)
  ASSET_PREFIX = '[[asset:'
  PLACEHOLDER_REGEXP = /\[\[asset:(\h{40})\]\]/

  module_function

  def find_or_create_for_account_user(account, user, subject, body)
    subject = I18n.t(:you_are_invited_to_sign_a_document) if subject.blank?

    body, assets = maybe_extract_assets(account, body)

    new_message = account.email_messages.new(author: user, subject:, body:).tap(&:validate)

    message = account.email_messages.find_by(sha1: new_message.sha1)

    message ||= new_message.tap do |m|
      m.save!(validate: false)

      save_new_assets!(account, assets)
    end

    message
  end

  def save_new_assets!(account, assets)
    return if assets.blank?

    existing_assets_sha1 = account.email_message_assets.where(sha1: assets.map(&:sha1)).pluck(:sha1)

    assets.each do |asset|
      asset.save!(validate: false) if existing_assets_sha1.exclude?(asset.sha1)
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  def maybe_extract_assets(account, body)
    return [body, []] if body.blank? || body.bytesize < MIN_BODY_SIZE

    assets_index = {}

    result = body.gsub(ASSET_REGEXP) do
      match = Regexp.last_match
      prefix, data = match[1] ? [match[1], match[2]] : ['', match[0]]

      next match[0] if data.blank? || data.bytesize < MIN_ASSET_SIZE

      asset = account.email_message_assets.new(data:).tap(&:validate)
      assets_index[asset.sha1] = asset

      "#{prefix}#{ASSET_PREFIX}#{asset.sha1}]]"
    end

    [result, assets_index.values]
  end

  def rebuild_body_with_assets(account_id, body)
    shas = body.scan(PLACEHOLDER_REGEXP).flatten.uniq
    data = EmailMessageAsset.where(account_id:, sha1: shas).pluck(:sha1, :data).to_h

    body.gsub(PLACEHOLDER_REGEXP) { data[Regexp.last_match(1)] || Regexp.last_match(0) }
  end
end
