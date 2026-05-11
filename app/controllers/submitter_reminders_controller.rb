# frozen_string_literal: true

class SubmitterRemindersController < ApplicationController
  before_action :load_submitter
  authorize_resource :submitter

  def destroy
    SubmissionEvent.create!(
      submitter: @submitter,
      event_type: 'skip_reminder_email'
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("reminder_row_#{@submitter.id}")
      end
      format.html do
        redirect_back fallback_location: settings_notifications_path,
                      notice: I18n.t('reminder_skipped')
      end
    end
  end

  private

  def load_submitter
    @submitter = current_account.submitters.find(params[:id])
  end
end
