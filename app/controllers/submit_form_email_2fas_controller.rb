# frozen_string_literal: true

class SubmitFormEmail2fasController < ApplicationController
  around_action :with_browser_locale

  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter

  def create
    RateLimit.call("verify-2fa-code-#{@submitter.id}", limit: 2, ttl: 45.seconds, enabled: true)
    RateLimit.call("verify-2fa-code-1h-#{@submitter.id}", limit: 10, ttl: 1.hour, enabled: true)
    RateLimit.call("verify-2fa-code-1d-#{@submitter.id}", limit: 20, ttl: 1.day, enabled: true)

    value = [@submitter.email.downcase.strip, @submitter.slug].join(':')

    if EmailVerificationCodes.verify(params[:one_time_code].to_s.gsub(/\D/, ''), value)
      SubmissionEvents.create_with_tracking_data(@submitter, 'email_verified', request, { email: @submitter.email })

      cookies.encrypted[:email_2fa_slug] =
        { value: @submitter.slug, expires: Submitters::StartForm::COOKIES_TTL.from_now,
          **Submitters::StartForm::COOKIES_DEFAULTS }

      redirect_to submit_form_path(@submitter.slug)
    else
      redirect_to submit_form_path(@submitter.slug, status: :error), alert: I18n.t(:invalid_code)
    end
  rescue RateLimit::LimitApproached
    redirect_to submit_form_path(@submitter.slug, status: :error), alert: I18n.t(:too_many_attempts)
  end

  def update
    if @submitter.submission_events.where(event_type: 'send_2fa_email').exists?(created_at: 15.seconds.ago..)
      return redirect_to submit_form_path(@submitter.slug, status: :error), alert: I18n.t(:rate_limit_exceeded)
    end

    RateLimit.call("send-email-code-#{@submitter.id}", limit: 2, ttl: 45.seconds, enabled: true)

    if Docuseal.multitenant? && Submitters.email_bounced_recently?(@submitter.email)
      Rollbar.warning("Bounced OTP email for submitter: #{@submitter.id}") if defined?(Rollbar)

      return redirect_to submit_form_path(@submitter.slug, status: :error), alert: I18n.t(:verification_email_bounced)
    end

    SendSubmitterVerificationEmailJob.perform_async('submitter_id' => @submitter.id, 'locale' => I18n.locale.to_s)

    redir_params = params[:resend] ? { alert: I18n.t(:code_has_been_resent) } : {}

    redirect_to submit_form_path(@submitter.slug, status: :sent), **redir_params
  rescue RateLimit::LimitApproached
    redirect_to submit_form_path(@submitter.slug, status: :error), alert: I18n.t(:too_many_attempts)
  end

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:submitter_slug])
  end
end
