# frozen_string_literal: true

class SubmitFormDelegateController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter

  def create
    return redirect_to submit_form_path(@submitter.slug) if @submitter.declined_at? ||
                                                            @submitter.completed_at? ||
                                                            @submitter.submission.archived_at? ||
                                                            @submitter.submission.expired? ||
                                                            @submitter.submission.template&.archived_at? ||
                                                            !Submitters::AuthorizedForForm.call(@submitter,
                                                                                                current_user,
                                                                                                request)

    @submitter.account.account_configs.find_by!(key: AccountConfig::ALLOW_TO_DELEGATE_KEY, value: true)

    email = Submissions.normalize_email(params[:email])

    return redirect_to submit_form_path(@submitter.slug) if email.blank?

    old_slug = @submitter.slug

    ApplicationRecord.transaction do
      @submitter.submitter_versions.create!(slug: old_slug, email: @submitter.email,
                                            name: @submitter.name, phone: @submitter.phone)

      SubmissionEvents.create_with_tracking_data(@submitter, 'delegate_form', request,
                                                 { old_email: @submitter.email, email: })

      @submitter.update!(email:, phone: nil, name: nil, slug: SecureRandom.base58(14))
    end

    SendSubmitterInvitationEmailJob.perform_async('submitter_id' => @submitter.id)

    redirect_to submit_form_delegated_path(old_slug)
  end

  private

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])
  end
end
