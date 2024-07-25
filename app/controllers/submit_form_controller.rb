# frozen_string_literal: true

class SubmitFormController < ApplicationController
  layout 'form'

  around_action :with_browser_locale, only: %i[show completed success]
  skip_before_action :authenticate_user!
  skip_authorization_check

  CONFIG_KEYS = [].freeze

  def show
    @submitter = Submitter.find_by!(slug: params[:slug])

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?
    return render :archived if @submitter.submission.template.archived_at? || @submitter.submission.archived_at?

    Submitters.preload_with_pages(@submitter)

    Submitters::MaybeUpdateDefaultValues.call(@submitter, current_user)

    @attachments_index = ActiveStorage::Attachment.where(record: @submitter.submission.submitters, name: :attachments)
                                                  .preload(:blob).index_by(&:uuid)

    @form_configs = Submitters::FormConfigs.call(@submitter, CONFIG_KEYS)

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
    submitter = Submitter.find_by!(slug: params[:slug])

    if submitter.completed_at?
      return render json: { error: 'Form has been completed already.' }, status: :unprocessable_entity
    end

    if submitter.template.archived_at? || submitter.submission.archived_at?
      return render json: { error: 'Form has been archived.' }, status: :unprocessable_entity
    end

    Submitters::SubmitValues.call(submitter, params, request)

    head :ok
  rescue Submitters::SubmitValues::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def completed
    @submitter = Submitter.completed.find_by!(slug: params[:submit_form_slug])
  end

  def success; end
end
