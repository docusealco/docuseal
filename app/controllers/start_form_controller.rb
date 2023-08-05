# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!

  before_action :load_template

  def show
    @submitter = @template.submissions.new.submitters.new(uuid: @template.submitters.first['uuid'])
  end

  def update
    @submitter = Submitter.where(submission: @template.submissions.where(deleted_at: nil))
                          .find_or_initialize_by(email: submitter_params[:email])

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submitter_params[:email])
    else
      @submitter.assign_attributes(
        uuid: @template.submitters.first['uuid'],
        opened_at: Time.current,
        ip: request.remote_ip,
        ua: request.user_agent
      )

      @submitter.submission ||= Submission.new(template: @template, source: :link)

      if @submitter.save
        redirect_to submit_form_path(@submitter.slug)
      else
        render :show
      end
    end
  end

  def completed
    @submitter = Submitter.where(submission: @template.submissions).find_by!(email: params[:email])
  end

  private

  def submitter_params
    params.require(:submitter).permit(:email)
  end

  def load_template
    slug = params[:slug] || params[:start_form_slug]

    @template = Template.find_by!(slug:)
  end
end
