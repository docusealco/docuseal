# frozen_string_literal: true

class SubmittersResetSignatureController < ApplicationController
  load_and_authorize_resource :submitter, parent: false

  def update
    authorize!(:update, @submitter)

    if @submitter.completed_at.blank?
      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: I18n.t('signature_has_not_been_completed_yet'))
    end

    # Remove the previously generated signature artifacts.
    @submitter.documents.purge
    @submitter.attachments.purge
    @submitter.preview_documents.purge

    # Re-open the submitter's form so they can sign again from scratch.
    @submitter.update!(completed_at: nil, opened_at: nil, declined_at: nil, values: {})

    # Email the signer a fresh invitation to correct their signature.
    SendSubmitterInvitationEmailJob.perform_async('submitter_id' => @submitter.id)

    @submitter.update!(sent_at: Time.current)

    redirect_back(fallback_location: submission_path(@submitter.submission),
                  notice: I18n.t('correction_request_has_been_sent'))
  end
end
