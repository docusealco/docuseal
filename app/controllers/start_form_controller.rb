# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  around_action :with_browser_locale, only: %i[show completed]
  before_action :load_template

  def show
    @submitter = @template.submissions.new(account_id: @template.account_id)
                          .submitters.new(uuid: @template.submitters.first['uuid'])
  end

  def update
    return redirect_to start_form_path(@template.slug) if @template.archived_at?

    @submitter = find_or_initialize_submitter(@template, submitter_params)

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submitter_params[:email])
    else
      if @template.submitters.to_a.size > 2 && @submitter.new_record?
        @error_message = 'Not found'

        return render :show
      end

      assign_submission_attributes(@submitter, @template) if @submitter.new_record?

      is_new_record = @submitter.new_record?

      if @submitter.save
        if is_new_record
          SendSubmissionCreatedWebhookRequestJob.perform_async({ 'submission_id' => @submitter.submission.id })
        end

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

  def find_or_initialize_submitter(template, submitter_params)
    Submitter.where(submission: template.submissions.where(expire_at: Time.current..)
                                        .or(template.submissions.where(expire_at: nil)).where(archived_at: nil))
             .order(id: :desc)
             .where(declined_at: nil)
             .then { |rel| params[:resubmit].present? ? rel.where(completed_at: nil) : rel }
             .find_or_initialize_by(**submitter_params.compact_blank)
  end

  def assign_submission_attributes(submitter, template)
    resubmit_submitter =
      (Submitter.where(submission: template.submissions).find_by(slug: params[:resubmit]) if params[:resubmit].present?)

    submitter.assign_attributes(
      uuid: template.submitters.first['uuid'],
      ip: request.remote_ip,
      ua: request.user_agent,
      values: resubmit_submitter&.preferences&.fetch('default_values', nil) || {},
      preferences: resubmit_submitter&.preferences.presence || { 'send_email' => true },
      metadata: resubmit_submitter&.metadata.presence || {}
    )

    if submitter.values.present?
      resubmit_submitter.attachments.each do |attachment|
        submitter.attachments << attachment.dup if submitter.values.value?(attachment.uuid)
      end
    end

    submitter.submission ||= Submission.new(template:,
                                            account_id: template.account_id,
                                            template_submitters: template.submitters,
                                            source: :link)

    maybe_assign_default_second_submitter(submitter.submission)

    submitter.account_id = submitter.submission.account_id

    submitter
  end

  def maybe_assign_default_second_submitter(submission)
    return unless submission.new_record?
    return if submission.template.submitters.to_a.size != 2

    submission.submitters_order = 'preserved'
    submission.submitters.new(
      account_id: submission.account_id,
      uuid: submission.template.submitters.second['uuid'],
      email: submission.template.author.email
    )
  end

  def submitter_params
    params.require(:submitter).permit(:email, :phone, :name).tap do |attrs|
      attrs[:email] = Submissions.normalize_email(attrs[:email])
    end
  end

  def load_template
    slug = params[:slug] || params[:start_form_slug]

    @template = Template.find_by!(slug:)
  end
end
