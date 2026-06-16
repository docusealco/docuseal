# frozen_string_literal: true

# Confines a token-bootstrapped embed session (see EmbedBuilderController) to
# the single template it was issued for.
#
# A valid first-party DocuSeal session is necessary but not sufficient: the
# session may only reach its own template (by id, or by the immutable
# external_id for the /new -> create -> edit redirect) plus the create +
# builder-support paths the editor needs. Listing / enumeration / other
# templates / submissions / the JSON template API are refused even with a
# valid session, so one embedder can't browse another's documents in the
# shared DocuSeal account. Fails closed.
#
# The path rules mirror the allow-list the embedding app previously enforced
# at the edge via Caddy `forward_auth`; moving them in-process lets the embed
# drop the cross-origin cookie + gate machinery entirely.
module EmbedScoped
  extend ActiveSupport::Concern

  SESSION_KEY = 'embed_scope'
  SESSION_TTL = 2.hours

  TEMPLATE_PATH = %r{\A/templates/(\d+)(?:[/?]|\z)}

  # Paths an embed session may hit regardless of which template it owns: the
  # create/upload flow, the signing/asset surfaces, and the few endpoints the
  # builder's own browser code calls. None expose another account's templates.
  UNSCOPED_ALLOW = [
    %r{\A/new(?:[/?]|\z)},
    %r{\A/templates/new(?:[/?]|\z)},
    %r{\A/templates_uploads?(?:[/?]|\z)},
    %r{\A/(?:s|d|p|e)(?:[/?]|\z)},
    %r{\A/(?:preview|file|blobs_proxy|submit_form)/},
    %r{\A/verify_pdf_signature(?:[/?]|\z)},
    %r{\A/api/(?:attachments|submitter_email_clicks|submitter_form_views)(?:[/?]|\z)}
  ].freeze

  included do
    before_action :enforce_embed_scope!
  end

  private

  def enforce_embed_scope!
    scope = session[SESSION_KEY]
    return if scope.blank?

    if embed_scope_expired?(scope)
      reset_session

      return redirect_to(new_user_session_path)
    end

    head(:forbidden) unless embed_path_authorized?(request.path, scope)
  end

  def embed_scope_expired?(scope)
    exp = scope['exp']

    exp.present? && exp.to_i <= Time.now.to_i
  end

  def embed_path_authorized?(path, scope)
    if (match = TEMPLATE_PATH.match(path))
      return embed_template_in_scope?(match[1].to_i, scope)
    end

    UNSCOPED_ALLOW.any? { |re| re.match?(path) }
  end

  # A specific /templates/:id is in scope when the session names that template
  # directly, or when the template's immutable external_id matches the one the
  # token was issued for (covers /new -> create -> redirect to /templates/:id).
  def embed_template_in_scope?(id, scope)
    return true if scope['template_id'].present? && scope['template_id'].to_i == id

    external_id = scope['external_id']
    return false if external_id.blank?

    Template.where(id:).pick(:external_id) == external_id
  end
end
