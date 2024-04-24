# frozen_string_literal: true

class ErrorsController < ActionController::Base
  ENTERPRISE_FEATURE_MESSAGE =
    'This feature is available in Pro Edition: https://www.docuseal.co/pricing'

  ENTERPRISE_PATHS = [
    '/templates/html',
    '/api/templates/html',
    '/templates/pdf',
    '/api/templates/pdf',
    '/templates/doc',
    '/api/templates/doc',
    '/templates/docx',
    '/api/templates/docx'
  ].freeze

  SAFE_ERROR_MESSAGE_CLASSES = [
    ActionDispatch::Http::Parameters::ParseError,
    JSON::ParserError
  ].freeze

  def show
    if request.original_fullpath.in?(ENTERPRISE_PATHS) && error_status_code == 404
      return render json: { status: 404, message: ENTERPRISE_FEATURE_MESSAGE }, status: :not_found
    end

    respond_to do |f|
      f.json do
        set_cors_headers

        exception = request.env['action_dispatch.exception']

        error = exception.message if exception.class.in?(SAFE_ERROR_MESSAGE_CLASSES)

        render json: { status: error_status_code, error: }.compact, status: error_status_code
      end

      f.html { render error_status_code.to_s, status: error_status_code }
    end
  end

  private

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Max-Age'] = '1728000'
    headers['Access-Control-Allow-Credentials'] = true
  end

  def error_status_code
    @error_status_code ||=
      ActionDispatch::ExceptionWrapper.new(request.env,
                                           request.env['action_dispatch.exception']).status_code
  end
end
