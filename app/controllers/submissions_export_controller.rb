# frozen_string_literal: true

class SubmissionsExportController < ApplicationController
  load_and_authorize_resource :template
  load_and_authorize_resource :submission, through: :template, parent: false, only: :index

  def index
    submissions = @submissions.active
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
end
