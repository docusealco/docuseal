# frozen_string_literal: true

class StartFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_authorization_check

  around_action :with_browser_locale, only: %i[show update completed]
  before_action :maybe_redirect_com, only: %i[show completed]
  before_action :load_template
  before_action :authorize_start!, only: :update

  def show
    if @template.preferences['require_phone_2fa'] || @template.preferences['require_email_2fa']
      raise ActionController::RoutingError, I18n.t('not_found')
    end

    if @template.shared_link?
      @submitter = @template.submissions.new(account_id: @template.account_id)
                            .submitters.new(account_id: @template.account_id,
                                            uuid: Submitters::StartForm.first_submitter_uuid(@template))
      render :email_verification if params[:email_verification]
    else
      Rollbar.warning("Not shared template: #{@template.id}") if defined?(Rollbar)

      return render :private if current_user && current_ability.can?(:read, @template)

      raise ActionController::RoutingError, I18n.t('not_found')
    end
  end

  def update
    @submitter = find_or_initialize_submitter(@template, submitter_params)

    if @submitter.completed_at?
      redirect_to start_form_completed_path(@template.slug, submitter_params.compact_blank)
    else
      if Templates.filter_undefined_submitters(@template.submitters).size > 1 && @submitter.new_record?
        @error_message = multiple_submitters_error_message

        return render :show, status: :unprocessable_content
      end

      if (is_new_record = @submitter.new_record?)
        Submitters::StartForm.assign_submission_attributes(
          @submitter, @template, ip: request.remote_ip, user_agent: request.user_agent
        )

        Submissions::AssignDefinedSubmitters.call(@submitter.submission)
      else
        @submitter.assign_attributes(ip: request.remote_ip, ua: request.user_agent)
      end

      if require_link_2fa?(@template, @submitter)
        handle_require_2fa(@template, @submitter)
      elsif @submitter.errors.blank? && @submitter.save
        Submitters::StartForm.enqueue_new_submitter_jobs(@submitter) if is_new_record

        Submitters::StartForm.assign_start_form_cookie(@submitter, request)

        redirect_to submit_form_path(@submitter.slug)
      else
        render :show, status: :unprocessable_content
      end
    end
  end

  def completed
    return redirect_to start_form_path(@template.slug) if !@template.shared_link? || @template.archived_at?

    submitter_params = params.permit(:name, :email, :phone).tap do |attrs|
      attrs[:email] = Submissions.normalize_email(attrs[:email])
    end

    required_fields = @template.preferences.fetch('link_form_fields', ['email'])

    required_params = required_fields.index_with { |key| submitter_params[key] }

    raise ActionController::RoutingError, I18n.t('not_found') if required_params.any? { |_, v| v.blank? } ||
                                                                 required_params.except('name').compact_blank.blank?

    @submitter = Submitter.where(submission: @template.submissions)
                          .where.not(completed_at: nil)
                          .find_by!(required_params.except('name'))
  end

  private

  def find_or_initialize_submitter(template, submitter_params)
    required_fields = template.preferences.fetch('link_form_fields', ['email'])

    blank_fields = required_fields.select { |key| submitter_params[key].blank? }

    submitter =
      if blank_fields.present?
        Submitter.new(submitter_params)
      else
        Submitters::StartForm.find_or_initialize_submitter(
          template, submitter_params, exclude_completed: params[:resubmit].present?,
                                      request:, current_user:
        )
      end

    blank_fields.each { |key| submitter.errors.add(key.to_sym, :blank) }

    submitter
  end

  def require_link_2fa?(template, submitter)
    return true if template.preferences['shared_link_2fa'] == true
    return false if cookies.encrypted[:start_form_slug] == submitter.slug
    return false if current_user && submitter.email == current_user.email &&
                    current_user.account_id == submitter.account_id

    !submitter.new_record?
  end

  def authorize_start!
    is_archived = @template.archived_at? || @template.account.archived_at?

    return redirect_to start_form_path(@template.slug) if is_archived

    return if @template.shared_link? || (current_user && current_ability.can?(:read, @template))

    Rollbar.warning("Not shared template: #{@template.id}") if defined?(Rollbar)

    redirect_to start_form_path(@template.slug)
  end

  def submitter_params
    params.require(:submitter).permit(:email, :phone, :name).tap do |attrs|
      attrs[:email] = Submissions.normalize_email(attrs[:email])
    end
  end

  def load_template
    @template = Template.find_by!(slug: params[:slug] || params[:start_form_slug])
  end

  def multiple_submitters_error_message
    if current_user&.account_id == @template.account_id
      helpers.t('this_submission_has_multiple_signers_which_prevents_the_use_of_a_sharing_link_html')
    else
      I18n.t('not_found')
    end
  end

  def handle_require_2fa(template, submitter)
    return render :show, status: :unprocessable_content if submitter.errors.present?

    if Submitters::StartForm.verify_2fa_and_save_submitter(submitter, request, is_new_record: submitter.new_record?)
      redirect_to submit_form_path(submitter.slug)
    else
      if defined?(Rollbar) && template.preferences['shared_link_2fa'] != true
        Rollbar.info("2FA link requested: #{submitter.id}")
      end

      Submitters.send_shared_link_email_verification_code(submitter, request:)

      render :email_verification
    end
  rescue Submitters::StartForm::NotSaved
    render :show, status: :unprocessable_content
  rescue Submitters::BouncedEmail => e
    @error_message = e.message

    render :error, status: :unprocessable_content
  rescue Submitters::UnableToSendCode, Submitters::InvalidOtp => e
    redirect_to start_form_path(template.slug, params: submitter_params.merge(email_verification: true)),
                alert: e.message
  rescue RateLimit::LimitApproached
    redirect_to start_form_path(template.slug, params: submitter_params.merge(email_verification: true)),
                alert: I18n.t(:too_many_attempts)
  end
end
