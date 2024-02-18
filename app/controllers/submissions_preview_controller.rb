# frozen_string_literal: true

class SubmissionsPreviewController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  PRELOAD_ALL_PAGES_AMOUNT = 200

  TTL = 20.minutes

  def show
    @submission = Submission.find_by!(slug: params[:slug])

    if !@submission.submitters.all?(&:completed_at?) && current_user.blank?
      raise ActionController::RoutingError, 'Not Found'
    end

    unless submission_valid_ttl?(@submission)
      Rollbar.info("TTL: #{@submission.id}") if defined?(Rollbar)

      return redirect_to submissions_preview_completed_path(@submission.slug)
    end

    ActiveRecord::Associations::Preloader.new(
      records: [@submission],
      associations: [:template, { template_schema_documents: :blob }]
    ).call

    total_pages =
      @submission.template_schema_documents.sum { |e| e.metadata.dig('pdf', 'number_of_pages').to_i }

    if total_pages < PRELOAD_ALL_PAGES_AMOUNT
      ActiveRecord::Associations::Preloader.new(
        records: @submission.template_schema_documents,
        associations: [:blob, { preview_images_attachments: :blob }]
      ).call
    end

    render 'submissions/show', layout: 'plain'
  end

  def completed
    @submission = Submission.find_by!(slug: params[:submissions_preview_slug])

    render :completed, layout: 'plain'
  end

  private

  def submission_valid_ttl?(submission)
    return true if current_user && current_user.account.submissions.exists?(id: submission.id)

    last_submitter = submission.submitters.select(&:completed_at?).max_by(&:completed_at)

    last_submitter && last_submitter.completed_at > TTL.ago
  end
end
