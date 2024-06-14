# frozen_string_literal: true

class SubmitFormController < ApplicationController
  layout 'form'

  around_action :with_browser_locale, only: %i[show completed success]
  skip_before_action :authenticate_user!
  skip_authorization_check

  PRELOAD_ALL_PAGES_AMOUNT = 200

  def show
    @submitter = Submitter.find_by!(slug: params[:slug])

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?

    ActiveRecord::Associations::Preloader.new(
      records: [@submitter],
      associations: [submission: [:template, { template_schema_documents: :blob }]]
    ).call

    total_pages =
      @submitter.submission.template_schema_documents.sum { |e| e.metadata.dig('pdf', 'number_of_pages').to_i }

    if total_pages < PRELOAD_ALL_PAGES_AMOUNT
      ActiveRecord::Associations::Preloader.new(
        records: @submitter.submission.template_schema_documents,
        associations: [:blob, { preview_images_attachments: :blob }]
      ).call
    end

    Submitters::MaybeUpdateDefaultValues.call(@submitter, current_user)

    @attachments_index = ActiveStorage::Attachment.where(record: @submitter.submission.submitters, name: :attachments)
                                                  .preload(:blob).index_by(&:uuid)

    unless Docuseal.multitenant?
      @signature_attachment = Submitters::MaybeAssignDefaultSignature.call(@submitter, params, @attachments_index)
    end

    render(@submitter.submission.template.archived_at? || @submitter.submission.archived_at? ? :archived : :show)
  end

  def update
    submitter = Submitter.find_by!(slug: params[:slug])

    if submitter.completed_at?
      return render json: { error: 'Form has been completed already.' }, status: :unprocessable_entity
    end

    if submitter.template.archived_at? || submitter.submission.archived_at?
      Rollbar.info("Archived template: #{submitter.template.id}") if defined?(Rollbar)

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
