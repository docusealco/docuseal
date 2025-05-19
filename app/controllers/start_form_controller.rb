# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  around_action :with_browser_locale, only: %i[show completed]
  before_action :maybe_redirect_com, only: %i[show completed]
  before_action :load_template

  def show
    raise ActionController::RoutingError, I18n.t('not_found') if @template.preferences['require_phone_2fa'] == true

    @submitter = @template.submissions.new(account_id: @template.account_id)
                          .submitters.new(account_id: @template.account_id,
                                          uuid: (filter_undefined_submitters(@template).first ||
                                                 @template.submitters.first)['uuid'])
  end

  def update
    return redirect_to start_form_path(@template.slug) if @template.archived_at?

    @submitter = find_or_initialize_submitter(@template, submitter_params)

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, email: submitter_params[:email])
    else
      if filter_undefined_submitters(@template).size > 1 && @submitter.new_record?
        @error_message = multiple_submitters_error_message

        return render :show
      end

      if (is_new_record = @submitter.new_record?)
        assign_submission_attributes(@submitter, @template)

        Submissions::AssignDefinedSubmitters.call(@submitter.submission)
      else
        @submitter.assign_attributes(ip: request.remote_ip, ua: request.user_agent)
      end

      if @submitter.save
        if is_new_record
          enqueue_submission_create_webhooks(@submitter)

          if @submitter.submission.expire_at?
            ProcessSubmissionExpiredJob.perform_at(@submitter.submission.expire_at,
                                                   'submission_id' => @submitter.submission_id)
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

  def enqueue_submission_create_webhooks(submitter)
    WebhookUrls.for_account_id(submitter.account_id, 'submission.created').each do |webhook_url|
      SendSubmissionCreatedWebhookRequestJob.perform_async('submission_id' => submitter.submission_id,
                                                           'webhook_url_id' => webhook_url.id)
    end
  end

  def find_or_initialize_submitter(template, submitter_params)
    Submitter.where(submission: template.submissions.where(expire_at: Time.current..)
                                        .or(template.submissions.where(expire_at: nil)).where(archived_at: nil))
             .order(id: :desc)
             .where(declined_at: nil)
             .where(external_id: nil)
             .where(ip: [nil, request.remote_ip])
             .then { |rel| params[:resubmit].present? ? rel.where(completed_at: nil) : rel }
             .find_or_initialize_by(email: submitter_params[:email], **submitter_params.compact_blank)
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
                                            expire_at: Templates.build_default_expire_at(template),
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

  def multiple_submitters_error_message
    if current_user&.account_id == @template.account_id
      helpers.t('this_submission_has_multiple_signers_which_prevents_the_use_of_a_sharing_link_html')
    else
      I18n.t('not_found')
    end
  end
end
