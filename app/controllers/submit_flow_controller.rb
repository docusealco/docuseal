# frozen_string_literal: true

class SubmitFlowController < ApplicationController
  layout 'flow'

  skip_before_action :authenticate_user!

  def show
    @submission = Submission.preload(flow: { documents_attachments: { preview_images_attachments: :blob } })
                            .find_by!(slug: params[:slug])

    return redirect_to submit_flow_completed_path(@submission.slug) if @submission.completed_at?
  end

  def update
    submission = Submission.find_by!(slug: params[:slug])
    submission.values.merge!(params[:values].to_unsafe_h)
    submission.completed_at = Time.current if params[:completed] == 'true'

    submission.save

    head :ok
  end

  def completed
    @submission = Submission.find_by!(slug: params[:submit_flow_slug])
  end
end
