# frozen_string_literal: true

class SubmittersRequestChangesController < ApplicationController
  include IframeAuthentication

  skip_before_action :verify_authenticity_token, only: :request_changes
  skip_before_action :authenticate_via_token!, only: :request_changes
  before_action :authenticate_from_referer, only: :request_changes
  before_action :load_submitter

  def request_changes
    if request.get? || request.head?
      render 'submitters_request_changes/request_changes', layout: false if request.xhr?
    else
      return redirect_back(fallback_location: root_path, alert: 'Invalid request') unless can_request_changes?

      ApplicationRecord.transaction do
        @submitter.update!(
          changes_requested_at: Time.current,
          completed_at: nil
        )

        SubmissionEvents.create_with_tracking_data(
          @submitter,
          'request_changes',
          request,
          { reason: params[:reason], requested_by: current_user.id }
        )
      end

      if @submitter.email.present?
        SubmitterMailer.changes_requested_email(@submitter, current_user, params[:reason]).deliver!
      end

      WebhookUrls.for_account_id(@submitter.account_id, 'form.changes_requested').each do |webhook_url|
        SendFormChangesRequestedWebhookRequestJob.perform_async(
          'submitter_id' => @submitter.id,
          'webhook_url_id' => webhook_url.id
        )
      end

      redirect_back(fallback_location: submission_path(@submitter.submission),
                    notice: 'Changes have been requested and the submitter has been notified.')
    end
  end

  private

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:slug])
    authorize! :read, @submitter
  end

  def can_request_changes?
    # Only the template author (manager) can request changes from submitters
    # Only for completed submissions that haven't been declined
    current_user == @submitter.submission.template.author &&
      @submitter.completed_at? &&
      !@submitter.declined_at? &&
      !@submitter.changes_requested_at?
  end
end
