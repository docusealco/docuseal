# frozen_string_literal: true

class StartFormSelfController < ApplicationController
  load_resource :template, parent: false

  around_action :with_browser_locale
  before_action :authorize_start!

  def update
    @submitter = Submitters::StartForm.build_submitters_scope(@template, exclude_completed: true, source: :self)
                                      .find_or_initialize_by(email: current_user.email)

    @submitter = Submitter.new(email: current_user.email) if @submitter.persisted? &&
                                                             outdated_template_fields?(@submitter, @template)

    if (is_new_record = @submitter.new_record?)
      @submitter.name = current_user.full_name

      Submitters::StartForm.assign_submission_attributes(
        @submitter, @template, ip: request.remote_ip, user_agent: request.user_agent, source: :self
      )

      Submissions::AssignDefinedSubmitters.call(@submitter.submission)
    else
      @submitter.assign_attributes(ip: request.remote_ip, ua: request.user_agent)
    end

    @submitter.save!

    Submitters::StartForm.enqueue_new_submitter_jobs(@submitter) if is_new_record

    Submitters::StartForm.assign_start_form_cookie(@submitter, request)

    redirect_to submit_form_path(@submitter.slug)
  end

  private

  def outdated_template_fields?(submitter, template)
    template_fields = submitter.submission.template_fields

    template_fields.present? && template_fields != template.fields
  end

  def authorize_start!
    authorize!(:read, @template)

    redirect_to template_path(@template) if @template.archived_at?
  end
end
