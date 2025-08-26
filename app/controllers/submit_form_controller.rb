# frozen_string_literal: true

class SubmitFormController < ApplicationController
  include PrefillFieldsHelper

  layout 'form'

  around_action :with_browser_locale, only: %i[show completed success]
  skip_before_action :authenticate_user!
  skip_authorization_check
  skip_before_action :verify_authenticity_token, only: :update

  before_action :load_submitter, only: %i[show update completed]
  before_action :maybe_render_locked_page, only: :show

  CONFIG_KEYS = [].freeze

  def show
    submission = @submitter.submission

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?

    @form_configs = Submitters::FormConfigs.call(@submitter, CONFIG_KEYS)

    return render :awaiting if (@form_configs[:enforce_signing_order] ||
                                submission.template&.preferences&.dig('submitters_order') == 'preserved') &&
                               !Submitters.current_submitter_order?(@submitter)

    Submissions.preload_with_pages(submission)

    Submitters::MaybeUpdateDefaultValues.call(@submitter, current_user)

    # Fetch ATS prefill values if task_assignment_id is provided
    @ats_prefill_values = fetch_ats_prefill_values_if_available

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
    if @submitter.completed_at?
      return render json: { error: I18n.t('form_has_been_completed_already') }, status: :unprocessable_entity
    end

    if @submitter.template&.archived_at? || @submitter.submission.archived_at?
      return render json: { error: I18n.t('form_has_been_archived') }, status: :unprocessable_entity
    end

    if @submitter.submission.expired?
      return render json: { error: I18n.t('form_has_been_expired') }, status: :unprocessable_entity
    end

    if @submitter.declined_at?
      return render json: { error: I18n.t('form_has_been_declined') },
                    status: :unprocessable_entity
    end

    Submitters::SubmitValues.call(@submitter, params, request)

    head :ok
  rescue Submitters::SubmitValues::RequiredFieldError => e
    Rollbar.warning("Required field #{@submitter.id}: #{e.message}") if defined?(Rollbar)

    render json: { field_uuid: e.message }, status: :unprocessable_entity
  rescue Submitters::SubmitValues::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def completed; end

  def success; end

  private

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

  def fetch_ats_prefill_values_if_available
    # ATS passes values directly as Base64-encoded JSON parameters
    return {} if params[:ats_values].blank?

    # Security: Limit input size to prevent DoS attacks (64KB limit)
    if params[:ats_values].bytesize > 65_536
      Rails.logger.warn "ATS prefill values parameter exceeds size limit: #{params[:ats_values].bytesize} bytes"
      return {}
    end

    begin
      decoded_json = Base64.urlsafe_decode64(params[:ats_values])

      # Security: Limit decoded JSON size as well
      if decoded_json.bytesize > 32_768
        Rails.logger.warn "ATS prefill decoded JSON exceeds size limit: #{decoded_json.bytesize} bytes"
        return {}
      end

      ats_values = JSON.parse(decoded_json)

      # Validate that we got a hash
      if ats_values.is_a?(Hash)
        # Audit logging: Log ATS prefill usage for security monitoring
        Rails.logger.info "ATS prefill values processed for submitter: #{@submitter&.slug || 'unknown'}, " \
                          "field_count: #{ats_values.keys.length}, " \
                          "account: #{@submitter&.account&.name || 'unknown'}"
        ats_values
      else
        Rails.logger.warn "ATS prefill values not a hash: #{ats_values.class}"
        {}
      end
    rescue StandardError => e
      Rails.logger.warn "Failed to parse ATS prefill values: #{e.message}"
      {}
    end
  end
end
