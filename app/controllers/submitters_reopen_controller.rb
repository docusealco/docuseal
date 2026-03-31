# frozen_string_literal: true

class SubmittersReopenController < ApplicationController
  before_action :load_and_authorize_submitter

  def update
    ActiveRecord::Base.transaction do
      @submitter.update!(completed_at: nil, opened_at: nil)

      @submitter.submission_events.where(event_type: 'complete_form').destroy_all

      @submitter.documents.each(&:purge)

      # Clear stale LockEvents so EnsureResultGenerated regenerates on next completion
      LockEvent.where(key: "result_attachments:#{@submitter.id}").delete_all
      LockEvent.where(key: "combined_document:#{@submitter.id}").delete_all
      LockEvent.where(key: "audit_trail:#{@submitter.submission_id}").delete_all

      # Purge stale combined document and audit trail
      @submitter.submission.combined_document.purge if @submitter.submission.combined_document.attached?
      @submitter.submission.audit_trail.purge if @submitter.submission.audit_trail.attached?

      SubmissionEvent.create!(
        submitter: @submitter,
        event_type: :admin_reopen_form,
        data: { user_id: current_user.id, user_email: current_user.email }
      )
    end

    if @submitter.email.present?
      SendSubmitterInvitationEmailJob.perform_async('submitter_id' => @submitter.id)
    end

    redirect_to submission_path(@submitter.submission),
                notice: I18n.t('submission_has_been_reopened')
  end

  private

  def load_and_authorize_submitter
    @submitter = Submitter.find(params[:id])
    authorize! :update, @submitter.submission
  end
end
