# frozen_string_literal: true

class StartFlowController < ApplicationController
  layout 'flow'

  skip_before_action :authenticate_user!

  before_action :load_flow

  def show
    @submission = @flow.submissions.new
  end

  def update
    @submission = @flow.submissions.find_or_initialize_by(
      deleted_at: nil, **submission_params
    )

    if @submission.completed_at?
      redirect_to start_flow_completed_path(@flow.slug, email: submission_params[:email])
    else
      @submission.assign_attributes(
        opened_at: Time.current,
        ip: request.remote_ip,
        ua: request.user_agent
      )

      if @submission.save
        redirect_to submit_flow_path(@submission.slug)
      else
        render :show
      end
    end
  end

  def completed
    @submission = @flow.submissions.find_by(email: params[:email])
  end

  private

  def submission_params
    params.require(:submission).permit(:email)
  end

  def load_flow
    slug = params[:slug] || params[:start_flow_slug]

    @flow = Flow.find_by!(slug:)
  end
end
