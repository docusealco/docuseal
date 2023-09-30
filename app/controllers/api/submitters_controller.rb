# frozen_string_literal: true

module Api
  class SubmittersController < ApiBaseController
    load_and_authorize_resource :submitter

    def show
      Submissions::EnsureResultGenerated.call(@submitter) if @submitter.completed_at?

      render json: Submitters::SerializeForApi.call(@submitter, with_template: true, with_events: true)
    end
  end
end
