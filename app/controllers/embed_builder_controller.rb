# frozen_string_literal: true

require 'jwt'

# Token-authenticated entry point for the embedded template builder.
#
# The embedding app mints a short-lived JWT signed HS256 with the account's
# API access token — the same key the JSON API authenticates with — and
# renders `<docuseal-builder data-token="…">`. The self-hosted embed shim
# (`public/js/builder.js`) iframes THIS endpoint, passing the token.
#
# We verify the token against the owner's access token, sign that user in
# (establishing a first-party DocuSeal session inside the iframe), record a
# template-scoped grant in the session (enforced by EmbedScoped), and redirect
# into the regular builder — `/templates/:id/edit` for an existing template, or
# `/new` (download + create from `document_urls`) for a fresh one. The JWT is
# the only credential the embedder handles: no cross-origin cookies, no shared
# admin grant.
class EmbedBuilderController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  # Refuse tokens whose lifetime exceeds this even if `exp` allows more — an
  # embed bootstrap is near-instant, so a long-lived token is pure replay risk.
  MAX_TOKEN_TTL = 10.minutes

  def show
    payload = verified_payload(params[:token].to_s)
    return reject unless payload

    user = User.active.find_by(email: owner_email(payload))
    return reject unless user

    sign_in(user)

    template_id = resolve_template_id(user, payload)

    session[EmbedScoped::SESSION_KEY] = {
      'external_id' => payload['external_id'].presence,
      'template_id' => template_id,
      'exp' => (Time.current + EmbedScoped::SESSION_TTL).to_i
    }.compact

    redirect_to(builder_target(template_id, payload))
  end

  private

  # Read the owner email from the UNVERIFIED payload only to look up which
  # access token should have signed the token, then verify the signature
  # against that key. A token forged for someone else's email fails — the
  # attacker doesn't hold that account's key.
  def verified_payload(token)
    return if token.blank?

    claims = JWT.decode(token, nil, false).first
    return unless claims.is_a?(Hash)

    user = User.active.find_by(email: owner_email(claims))
    return unless user

    payload, = JWT.decode(token, user.access_token.token, true, algorithm: 'HS256', verify_expiration: true)

    payload if fresh_enough?(payload)
  rescue JWT::DecodeError
    nil
  end

  # Require an `exp` claim and cap the accepted lifetime — bounds replay
  # regardless of what the issuer set.
  def fresh_enough?(payload)
    exp = payload['exp']
    return false if exp.blank?

    now = Time.now.to_i

    now <= exp.to_i && (exp.to_i - now) <= MAX_TOKEN_TTL.to_i
  end

  def owner_email(claims)
    claims['user_email'].presence || claims['integration_email'].presence
  end

  # Only an id the signed-in user's account actually owns — never trust the
  # token's template_id blindly.
  def resolve_template_id(user, payload)
    id = payload['template_id']
    return if id.blank?

    user.account.templates.where(id:).pick(:id)
  end

  def builder_target(template_id, payload)
    return edit_template_path(template_id) if template_id

    query = {
      url: payload.dig('document_urls', 0),
      filename: filename_for(payload),
      external_id: payload['external_id'].presence
    }.compact

    "/new?#{query.to_query}"
  end

  def filename_for(payload)
    name = payload['name'].presence || 'Untitled'

    "#{name.gsub(/[^A-Za-z0-9_-]+/, '_')}.pdf"
  end

  def reject
    redirect_to(new_user_session_path, alert: 'Not authorized')
  end
end
