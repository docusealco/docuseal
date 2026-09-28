# frozen_string_literal: true

module Submitters
  module AuthorizedForForm
    Unauthorized = Class.new(StandardError)

    module_function

    def call(submitter, current_user, request, with_order: false)
      pass_email_2fa?(submitter, request) &&
        pass_link_2fa?(submitter, current_user, request) &&
        (!with_order || pass_submitters_order?(submitter))
    end

    def pass_submitters_order?(submitter)
      return false unless submitter

      submission = submitter.submission

      return true if submission.submitters_order_random?
      return true if (submission.template_submitters || submission.template.submitters).size < 2
      return true if submission.template&.preferences&.dig('submitters_order') != 'preserved' &&
                     !AccountConfig.exists?(account_id: submitter.account_id,
                                            key: AccountConfig::ENFORCE_SIGNING_ORDER_KEY, value: true)

      Submitters.current_submitter_order?(submitter)
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
