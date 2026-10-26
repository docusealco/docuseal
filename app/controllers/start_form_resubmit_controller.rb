# frozen_string_literal: true

class StartFormResubmitController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  around_action :with_browser_locale
  before_action :load_resubmit_submitter
  before_action :load_template
  before_action :authorize_start!

  def update
    @submitter = find_or_initialize_submitter(@template, @resubmit_submitter)

    if Templates.filter_undefined_submitters(@template.submitters).size > 1 && @submitter.new_record?
      @error_message = multiple_submitters_error_message

      return render 'start_form/show', status: :unprocessable_content
    end

    if (is_new_record = @submitter.new_record?)
      Submitters::StartForm.assign_submission_attributes(
        @submitter, @template,
        ip: request.remote_ip, user_agent: request.user_agent, resubmit_submitter: @resubmit_submitter,
        source: @resubmit_submitter.submission.source_self? ? :self : :link
      )

      Submissions::AssignDefinedSubmitters.call(@submitter.submission)
    else
      @submitter.assign_attributes(ip: request.remote_ip, ua: request.user_agent)
    end

    if @template.preferences['shared_link_2fa'] == true
      handle_require_2fa(@submitter)
    elsif @submitter.save
      Submitters::StartForm.enqueue_new_submitter_jobs(@submitter) if is_new_record

      Submitters::StartForm.assign_start_form_cookie(@submitter, request)

      redirect_to submit_form_path(@submitter.slug)
    else
      render 'start_form/show', status: :unprocessable_content
    end
  end

  private

  def find_or_initialize_submitter(template, resubmit_submitter)
    Submitters::StartForm.build_submitters_scope(template, exclude_completed: true)
                         .find_by(slug: cookies.encrypted[:start_form_slug],
                                  email: resubmit_submitter.email) || Submitter.new
  end

  def load_resubmit_submitter
    @resubmit_submitter = Submitter.find_by(slug: params[:resubmit])

    raise ActiveRecord::RecordNotFound if @resubmit_submitter.blank? ||
                                          !Submitters::StartForm.can_resubmit?(@resubmit_submitter)
  end

  def load_template
    @template = @resubmit_submitter.template
  end

  def authorize_start!
    redirect_to submit_form_path(@resubmit_submitter.slug) if @template.archived_at? || @template.account.archived_at?
  end

  def multiple_submitters_error_message
    if current_user&.account_id == @template.account_id
      helpers.t('this_submission_has_multiple_signers_which_prevents_the_use_of_a_sharing_link_html')
    else
      I18n.t('not_found')
    end
  end

  def handle_require_2fa(submitter)
    if Submitters::StartForm.verify_2fa_and_save_submitter(submitter, request,
                                                           is_new_record: submitter.new_record?)
      redirect_to submit_form_path(submitter.slug)
    else
      Submitters.send_shared_link_email_verification_code(submitter, request:)

      render 'start_form/email_verification'
    end
  rescue Submitters::StartForm::NotSaved
    render 'start_form/show', status: :unprocessable_content
  rescue Submitters::BouncedEmail => e
    @error_message = e.message

    render 'start_form/error', status: :unprocessable_content
  rescue Submitters::UnableToSendCode, Submitters::InvalidOtp => e
    flash.now[:alert] = e.message

    render 'start_form/email_verification'
  rescue RateLimit::LimitApproached
    flash.now[:alert] = I18n.t(:too_many_attempts)

    render 'start_form/email_verification'
  end
end
