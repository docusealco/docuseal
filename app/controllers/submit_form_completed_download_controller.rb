# frozen_string_literal: true

class SubmitFormCompletedDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  TTL = 40.minutes
  FILES_TTL = 5.minutes

  def index
    @submitter = Submitter.find_signed(params[:sig], purpose: :download_completed) if params[:sig].present?

    signature_valid = @submitter&.slug == submitter_slug

    @submitter = Submitter.find_by!(slug: submitter_slug) unless signature_valid

    unless completed_submitter?(@submitter)
      Rollbar.error("Not completed: #{@submitter.id}") if defined?(Rollbar)

      return head :not_found
    end

    Submissions::EnsureResultGenerated.call(@submitter) if @submitter.completed_at?

    last_submitter = @submitter.submission.submitters.completed.order(:completed_at).last

    return head :not_found unless last_submitter

    Submissions::EnsureResultGenerated.call(last_submitter)

    if !signature_valid && !current_user_submitter?(last_submitter)
      unless Submitters::AuthorizedForForm.call(@submitter, current_user, request, with_order: true)
        return head :not_found
      end

      if last_submitter.completed_at < TTL.ago
        Rollbar.info("TTL: #{last_submitter.id}") if defined?(Rollbar)

        return head :not_found
      end
    end

    if params[:combined] == 'true'
      respond_with_combined(last_submitter)
    else
      render json: Submitters.build_document_urls(last_submitter)
    end
  end

  private

  def submitter_slug
    params[:submit_form_slug] || params[:submitter_slug]
  end

  def respond_with_combined(submitter)
    url = Submitters.build_combined_url(submitter)

    if url
      render json: [url]
    else
      head :not_found
    end
  end

  def completed_submitter?(submitter)
    submitter.completed_at? || (submitter.viewer? && submitter.submission.completed_at?)
  end

  def current_user_submitter?(submitter)
    current_user && current_ability.can?(:read, submitter)
  end
end
