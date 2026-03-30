# frozen_string_literal: true

class SubmittersReopenController < ApplicationController
  before_action :load_and_authorize_submitter

  def update
    ActiveRecord::Base.transaction do
      @submitter.update!(completed_at: nil, opened_at: nil)

      @submitter.submission_events.where(event_type: 'complete_form').destroy_all

      @submitter.documents.each(&:purge)

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
