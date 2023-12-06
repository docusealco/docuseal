# frozen_string_literal: true

class SubmissionsPreviewController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  PRELOAD_ALL_PAGES_AMOUNT = 200

  def show
    @submission = Submission.find_by!(slug: params[:slug])

    ActiveRecord::Associations::Preloader.new(
      records: [@submission],
      associations: [:template, { template_schema_documents: :blob }]
    ).call

    total_pages =
      @submission.template_schema_documents.sum { |e| e.metadata.dig('pdf', 'number_of_pages').to_i }

    if total_pages < PRELOAD_ALL_PAGES_AMOUNT
      ActiveRecord::Associations::Preloader.new(
        records: @submission.template_schema_documents,
        associations: [:blob, { preview_secured_images_attachments: :blob }]
      ).call
    end

    render 'submissions/show', layout: 'plain'
  end
end
