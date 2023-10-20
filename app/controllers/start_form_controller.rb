# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_template

  def show
    @submitter = @template.submissions.new.submitters.new(uuid: @template.submitters.first['uuid'])
  end

  def update
    @submitter = Submitter.new(email: submitter_params[:email])

    if params[:resubmit].blank?
      @submitter = Submitter.where(submission: @template.submissions.where(deleted_at: nil))
                            .find_by(email: submitter_params[:email]) || @submitter
    end

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submitter_params[:email])
    else
      @submitter.assign_attributes(
        uuid: @template.submitters.first['uuid'],
        ip: request.remote_ip,
        ua: request.user_agent
      )

      @submitter.submission ||= Submission.new(template: @template,
                                               template_submitters: @template.submitters,
                                               source: :link)

      if @submitter.save
        redirect_to submit_form_path(@submitter.slug)
      else
        render :show
      end
    end
  end

  def completed
    @submitter = Submitter.where(submission: @template.submissions)
                          .where.not(completed_at: nil)
                          .find_by!(email: params[:email])
  end

  private

  def submitter_params
    params.require(:submitter).permit(:email).tap do |attrs|
      attrs[:email] = Submissions.normalize_email(attrs[:email])
    end
  end

  def load_template
    slug = params[:slug] || params[:start_form_slug]

    @template = Template.find_by!(slug:)
  end
end
