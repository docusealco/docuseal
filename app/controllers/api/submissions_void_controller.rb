# frozen_string_literal: true

module Api
  class SubmissionsVoidController < ApiBaseController
    load_and_authorize_resource :submission

    before_action only: :create do
      authorize!(:destroy, @submission)
    end

    def create
      Submissions::Void.call(@submission, user: current_user, reason: params[:reason], request:)

      render json: {
        id: @submission.id,
        status: 'voided',
        voided_at: @submission.voided_at,
        void_reason: @submission.void_reason
      }
    rescue Submissions::Void::ReasonRequiredError, Submissions::Void::NotVoidableError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  end
end
