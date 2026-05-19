# frozen_string_literal: true

class SubmissionsUnarchiveController < ApplicationController
  load_and_authorize_resource :submission

  def create
    authorize!(:update, @submission)

    @submission.update!(archived_at: nil)

    redirect_to submission_path(@submission), notice: I18n.t('submission_has_been_unarchived')
  end
end
