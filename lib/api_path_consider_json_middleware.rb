# frozen_string_literal: true

class ApiPathConsiderJsonMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'].starts_with?('/api') &&
       (!env['PATH_INFO'].ends_with?('/documents') || env['REQUEST_METHOD'] != 'POST') &&
       !env['PATH_INFO'].ends_with?('/attachments') &&
       # Internal template provisioning accepts multipart PDF uploads — let Rack
       # parse the multipart body instead of forcing application/json.
       !(env['PATH_INFO'].ends_with?('/internal/templates') && env['REQUEST_METHOD'] == 'POST') &&
       !env['PATH_INFO'].ends_with?('/submitter_sms_clicks') &&
       !env['PATH_INFO'].ends_with?('/submitter_email_clicks')
      env['CONTENT_TYPE'] = 'application/json'
    end

    @app.call(env)
  end
end
