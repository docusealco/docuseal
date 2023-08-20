# frozen_string_literal: true

class SubmissionsExportController < ApplicationController
  before_action :load_template

  def index
    submissions = @template.submissions.active
                           .preload(submitters: { documents_attachments: :blob,
                                                  attachments_attachments: :blob })
                           .order(id: :asc)

    if params[:format] == 'csv'
      send_data Submissions::GenerateExportFiles.call(submissions, format: params[:format]),
                filename: "#{@template.name}.csv"
    elsif params[:format] == 'xlsx'
      send_data Submissions::GenerateExportFiles.call(submissions, format: params[:format]),
                filename: "#{@template.name}.xlsx"
    end
  end

  def new; end

  private

  def load_template
    @template = current_account.templates.find(params[:template_id])
  end
end
