# frozen_string_literal: true

class SubmissionsPreviewController < ApplicationController
  around_action :with_browser_locale
  skip_before_action :authenticate_user!
  skip_authorization_check

  prepend_before_action :maybe_redirect_com, only: %i[show completed]

  TTL = 40.minutes

  def show
    submitter = Submitter.find_signed(params[:sig], purpose: :download_completed) if params[:sig].present?

    signature_valid =
      if submitter && submitter.submission.slug == params[:slug]
        @submission = submitter.submission

        true
      end

    @submission ||= Submission.find_by!(slug: params[:slug])

    raise ActionController::RoutingError, I18n.t('not_found') if @submission.account.archived_at?

    if !@submission.submitters.all?(&:completed_at?) && !signature_valid &&
       (!current_user || !current_ability.can?(:read, @submission))
      raise ActionController::RoutingError, I18n.t('not_found')
    end

    if !submission_valid_ttl?(@submission) && !signature_valid
      Rollbar.info("TTL: #{@submission.id}") if defined?(Rollbar)

      return redirect_to submissions_preview_completed_path(@submission.slug)
    end

    @submission = Submissions.preload_with_pages(@submission)

    render 'submissions/show', layout: 'plain'
  end

  def completed
    @submission = Submission.find_by!(slug: params[:submissions_preview_slug])
    @template = @submission.template

    render :completed, layout: 'form'
  end

  private

  def submission_valid_ttl?(submission)
    return true if current_user && current_user.account.submissions.exists?(id: submission.id)

    last_submitter = submission.submitters.select(&:completed_at?).max_by(&:completed_at)

    last_submitter && last_submitter.completed_at > TTL.ago
  end
end
