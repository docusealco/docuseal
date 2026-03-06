# frozen_string_literal: true

module Submitters
  module AuthorizedForForm
    Unauthorized = Class.new(StandardError)

    module_function

    def call(submitter, current_user, request)
      pass_email_2fa?(submitter, request) && pass_link_2fa?(submitter, current_user, request)
    end

    def pass_email_2fa?(submitter, request)
      return false unless submitter

      return true if submitter.submission.template&.preferences&.dig('require_email_2fa') != true &&
                     submitter.preferences['require_email_2fa'] != true
      return true if request.cookie_jar.encrypted[:email_2fa_slug] == submitter.slug

      token = request.params[:two_factor_token].presence || request.headers['x-two-factor-token'].presence

      return true if token.present? &&
                     Submitter.signed_id_verifier.verified(token, purpose: :email_two_factor) == submitter.slug

      false
    end

    def pass_link_2fa?(submitter, current_user, request)
      return false unless submitter

      return true if submitter.submission.source != 'link'
      return true unless submitter.submission.template&.preferences&.dig('shared_link_2fa') == true
      return true if request.cookie_jar.encrypted[:email_2fa_slug] == submitter.slug
      return true if submitter.email == current_user&.email && current_user&.account_id == submitter.account_id

      if (token = request.params[:two_factor_token].presence || request.headers['x-two-factor-token'].presence)
        link_2fa_key = [submitter.email.downcase.squish, submitter.submission.template.slug].join(':')

        return true if Submitter.signed_id_verifier.verified(token, purpose: :email_two_factor) == link_2fa_key
      end

      false
    end
  end
end
