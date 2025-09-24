# frozen_string_literal: true

class CspController < ActionController::API
  FILTER_REPORT_REGEXP = /extension|sandbox/i

  SANITIZE_REGEXP = %r{(/[sdep]/)(\w{5})[^/"]+}

  def create
    data = request.raw_post.gsub(SANITIZE_REGEXP, '\1\2')

    Rails.logger.warn(data) if Rails.env.development?

    Rollbar.warning('CSP', data:) if defined?(Rollbar) && !data.match?(FILTER_REPORT_REGEXP)
  end
end
