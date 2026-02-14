# frozen_string_literal: true

class SubmitFormController < ApplicationController
  layout 'form'

  around_action :with_browser_locale, only: %i[show completed success]
  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter, only: %i[show update completed]
  before_action :maybe_render_locked_page, only: :show
  before_action :maybe_require_link_2fa, only: %i[show]

  CONFIG_KEYS = [].freeze

  def show
    submission = @submitter.submission

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?
    return render :email_2fa unless Submitters::AuthorizedForForm.pass_email_2fa?(@submitter, request)

    @form_configs = Submitters::FormConfigs.call(@submitter, CONFIG_KEYS)

    return render :awaiting if (@form_configs[:enforce_signing_order] ||
                                submission.template&.preferences&.dig('submitters_order') == 'preserved') &&
                               !Submitters.current_submitter_order?(@submitter)

    Submissions.preload_with_pages(submission)

    Submitters::MaybeUpdateDefaultValues.call(@submitter, current_user)

    @attachments_index = build_attachments_index(submission)

    return unless @form_configs[:prefill_signature]

    if (user_signature = UserConfigs.load_signature(current_user))
      @signature_attachment = ActiveStorage::Attachment.find_or_create_by!(
        blob_id: user_signature.blob_id,
        name: 'attachments',
        record: @submitter
      )
    end

    @signature_attachment ||=
      Submitters::MaybeAssignDefaultBrowserSignature.call(@submitter, params, cookies, @attachments_index.values)

    @attachments_index[@signature_attachment.uuid] = @signature_attachment if @signature_attachment
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

    Submitters::SubmitValues.call(@submitter, params, request)

    head :ok
  rescue Submitters::SubmitValues::RequiredFieldError => e
    Rollbar.warning("Required field #{@submitter.id}: #{e.message}") if defined?(Rollbar)

    render json: { field_uuid: e.message }, status: :unprocessable_content
  rescue Submitters::SubmitValues::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def completed
    raise ActionController::RoutingError, I18n.t('not_found') if @submitter.account.archived_at?

    return if Submitters::AuthorizedForForm.call(@submitter, current_user, request)

    redirect_to submit_form_path(params[:submit_form_slug])
  end

  def success; end

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

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:slug] || params[:submit_form_slug])
  end

  def build_attachments_index(submission)
    ActiveStorage::Attachment.where(record: submission.submitters, name: :attachments)
                             .preload(:blob).index_by(&:uuid)
  end
end
