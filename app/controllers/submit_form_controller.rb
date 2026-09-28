# frozen_string_literal: true

class SubmitFormController < ApplicationController
  layout 'form'

  around_action :with_browser_locale, only: %i[show completed success delegated]
  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter, only: %i[show update completed]
  before_action :maybe_redirect_delegated, only: %i[show completed]
  before_action :maybe_render_locked_page, only: :show
  before_action :maybe_require_link_2fa, only: %i[show]

  CONFIG_KEYS = [].freeze

  def show
    submission = @submitter.submission

    return render :email_2fa unless Submitters::AuthorizedForForm.pass_email_2fa?(@submitter, request)

    if @submitter.completed_at? || submission.completed_at?
      return redirect_to submit_form_completed_path(@submitter.slug)
    end

    @form_configs = Submitters::FormConfigs.call(@submitter, CONFIG_KEYS)

    return render :awaiting if (@form_configs[:enforce_signing_order] ||
                                submission.template&.preferences&.dig('submitters_order') == 'preserved') &&
                               !Submitters.current_submitter_order?(@submitter)

    Submissions.preload_with_pages(submission)

    @attachments_index = build_attachments_index(submission)

    if current_user && current_user.email == @submitter.email
      @current_user_data = current_user.as_json(only: %i[first_name last_name], methods: %i[full_name])

      initials = UserConfigs.load_initials(current_user)

      @prefill_initials = Submitters.build_prefill_attachment_data(@submitter, initials) if initials
    end

    return unless @form_configs[:prefill_signature]

    signature = UserConfigs.load_signature(current_user) ||
                Submitters::FindRememberedSignature.call(@submitter, params, cookies)

    @prefill_signature = Submitters.build_prefill_attachment_data(@submitter, signature) if signature
  end

  def update
    unless Submitters::AuthorizedForForm.call(@submitter, current_user, request)
      return render json: { error: I18n.t('verification_required_refresh_the_page_and_pass_2fa') },
                    status: :unprocessable_content
    end

    if @submitter.completed_at?
      return render json: { error: I18n.t('form_has_been_completed_already') }, status: :unprocessable_content
    end

    if @submitter.submission.template&.archived_at? || @submitter.submission.archived_at?
      return render json: { error: I18n.t('form_has_been_archived') }, status: :unprocessable_content
    end

    if @submitter.submission.expired?
      return render json: { error: I18n.t('form_has_been_expired') }, status: :unprocessable_content
    end

    if @submitter.declined_at?
      return render json: { error: I18n.t('form_has_been_declined') },
                    status: :unprocessable_content
    end

    if @submitter.viewer?
      Rollbar.warning("Submit viewer: #{@submitter.id}") if defined?(Rollbar)

      return render json: { error: I18n.t('form_is_view_only') }, status: :unprocessable_content
    end

    Submitters::SubmitValues.call(@submitter, params, request)

    head :ok
  rescue Submitters::SubmitValues::RequiredFieldError => e
    Rollbar.warning("Required field #{@submitter.id}: #{e.message}") if defined?(Rollbar)

    render json: { field_uuid: e.message }, status: :unprocessable_content
  rescue Submitters::SubmitValues::ValidationError => e
    Rollbar.warning("Validation error #{@submitter.id}: #{e.message}") if defined?(Rollbar)

    render json: { error: e.message }, status: :unprocessable_content
  end

  def completed
    raise ActionController::RoutingError, I18n.t('not_found') if @submitter.account.archived_at?

    return if Submitters::AuthorizedForForm.call(@submitter, current_user, request)

    redirect_to submit_form_path(params[:submit_form_slug])
  end

  def success; end

  def delegated
    submitter_version = SubmitterVersion.find_by!(slug: params[:slug] || params[:submit_form_slug])

    @submitter = submitter_version.submitter

    maybe_render_locked_page
  end

  private

  def maybe_require_link_2fa
    return if Submitters::AuthorizedForForm.pass_link_2fa?(@submitter, current_user, request)

    redirect_to start_form_path(@submitter.submission.template.slug)
  end

  def maybe_render_locked_page
    return render :archived if @submitter.submission.template&.archived_at? ||
                               @submitter.submission.archived_at? ||
                               @submitter.account.archived_at?
    return render :expired if @submitter.submission.expired?

    render :declined if @submitter.declined_at?
  end

  def maybe_redirect_delegated
    return if @submitter

    submitter_version = SubmitterVersion.find_by!(slug: params[:slug] || params[:submit_form_slug])

    submitter_version.submitter.submission_events.find_by!(event_type: :delegate_form)

    redirect_to submit_form_delegated_path(submitter_version.slug)
  end

  def load_submitter
    @submitter = Submitter.find_by(slug: params[:slug] || params[:submit_form_slug])
  end

  def build_attachments_index(submission)
    ActiveStorage::Attachment.where(record: submission.submitters, name: :attachments)
                             .preload(:blob).index_by(&:uuid)
  end
end
