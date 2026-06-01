module Turbo::RequestIdTracking
  extend ActiveSupport::Concern

  included do
    around_action :turbo_tracking_request_id
  end

  private
    def turbo_tracking_request_id(&block)
      Turbo.with_request_id(request.headers["X-Turbo-Request-Id"], &block)
    end
end
