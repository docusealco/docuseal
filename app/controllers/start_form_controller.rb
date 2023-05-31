# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!

  before_action :load_template

  def show
    @submission = @template.submissions.new
  end

  def update
    @submission = @template.submissions.find_or_initialize_by(
      deleted_at: nil, **submission_params
    )

    if @submission.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submission_params[:email])
    else
      @submission.assign_attributes(
        opened_at: Time.current,
        ip: request.remote_ip,
        ua: request.user_agent
      )

      if @submission.save
        redirect_to submit_form_path(@submission.slug)
      else
        render :show
      end
    end
  end

  def completed
    @submission = @template.submissions.find_by(email: params[:email])
  end

  private

  def submission_params
    params.require(:submission).permit(:email)
  end

  def load_template
    slug = params[:slug] || params[:start_template_slug]

    @template = Template.find_by!(slug:)
  end
end
