# frozen_string_literal: true

class SubmitterEditFormController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def update
    @submitter = Submitter.find_by!(slug: params[:submitter_slug])

    if @submitter.submission.archived_at? || @submitter.submission.expired? || @submitter.submission.template&.archived_at?
      return redirect_to submit_form_completed_path(@submitter.slug),
                         alert: I18n.t('form_cannot_be_edited')
    end

    unless @submitter.completed_at?
      return redirect_to submit_form_path(@submitter.slug)
    end

    ActiveRecord::Base.transaction do
      @submitter.update!(completed_at: nil, opened_at: nil)
      @submitter.submission_events.where(event_type: 'complete_form').destroy_all
      @submitter.documents.each(&:purge)
    end

    redirect_to submit_form_path(@submitter.slug)
  end
end
