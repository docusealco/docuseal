# frozen_string_literal: true

module Api
  class ToolsController < ApiBaseController
    skip_authorization_check

    def merge
      files = params[:files] || []

      return render json: { error: 'Files are required' }, status: :unprocessable_entity if files.blank?
      return render json: { error: 'At least 2 files are required' }, status: :unprocessable_entity if files.size < 2

      render json: {
        data: Base64.encode64(PdfUtils.merge(files.map { |base64| StringIO.new(Base64.decode64(base64)) }).string)
      }
    end
  end
end
