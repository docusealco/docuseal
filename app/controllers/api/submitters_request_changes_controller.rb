# frozen_string_literal: true

module Api
  class SubmittersRequestChangesController < ApiBaseController
    before_action :load_submitter

    def request_changes
      @submitter.update!(changes_requested_at: Time.current, completed_at: nil) unless @submitter.changes_requested_at?

      render json: Submitters::SerializeForApi.call(@submitter), status: :ok
    end

    private

    def load_submitter
      @submitter = Submitter.find_by!(slug: params[:slug])
      authorize! :read, @submitter
    end
  end
end
