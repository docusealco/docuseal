# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  around_action :with_browser_locale, only: %i[show completed]
  before_action :maybe_redirect_com, only: %i[show completed]
  before_action :load_template

  def show
    @submitter = @template.submissions.new(account_id: @template.account_id)
                          .submitters.new(uuid: (filter_undefined_submitters(@template).first ||
                                                 @template.submitters.first)['uuid'])
  end

  def update
    return redirect_to start_form_path(@template.slug) if @template.archived_at?

    @submitter = find_or_initialize_submitter(@template, submitter_params)

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submitter_params[:email])
    else
      if filter_undefined_submitters(@template).size > 1 && @submitter.new_record?
        @error_message = I18n.t('not_found')

        return render :show
      end

      if (is_new_record = @submitter.new_record?)
        assign_submission_attributes(@submitter, @template)

        Submissions::AssignDefinedSubmitters.call(@submitter.submission)
      end

      if @submitter.save
        if is_new_record
          WebhookUrls.for_account_id(@submitter.account_id, 'submission.created').each do |webhook_url|
            SendSubmissionCreatedWebhookRequestJob.perform_async('submission_id' => @submitter.submission_id,
                                                                 'webhook_url_id' => webhook_url.id)
          end
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
      uuid: (filter_undefined_submitters(template).first || @template.submitters.first)['uuid'],
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
                                            submitters: [submitter],
                                            source: :link)

    submitter.account_id = submitter.submission.account_id

    submitter
  end

  def filter_undefined_submitters(template)
    Templates.filter_undefined_submitters(template)
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
