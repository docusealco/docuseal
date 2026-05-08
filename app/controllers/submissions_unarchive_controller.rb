# frozen_string_literal: true

class SubmissionsUnarchiveController < ApplicationController
  load_and_authorize_resource :submission

  def create
    if @submission.voided_at?
      return redirect_to submission_path(@submission),
                         alert: I18n.t('voided_submission_cannot_be_unarchived')
    end

    @submission.update!(archived_at: nil)

    redirect_to submission_path(@submission), notice: I18n.t('submission_has_been_unarchived')
  end
end
