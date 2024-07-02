# frozen_string_literal: true

class TemplatesFormPreviewController < ApplicationController
  PRELOAD_ALL_PAGES_AMOUNT = 200

  layout 'form'

  load_and_authorize_resource :template

  def show
    @submitter = Submitter.new(uuid: params[:uuid] || @template.submitters.first['uuid'],
                               account: current_account,
                               submission: @template.submissions.new(template_submitters: @template.submitters,
                                                                     account: current_account))

    @submitter.submission.submitters = @template.submitters.map { |item| Submitter.new(uuid: item['uuid']) }

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

    @attachments_index = ActiveStorage::Attachment.where(record: @submitter.submission.submitters, name: :attachments)
                                                  .preload(:blob).index_by(&:uuid)

    @form_configs = Submitters::FormConfigs.call(@submitter)
  end
end
