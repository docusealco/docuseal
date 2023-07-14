# frozen_string_literal: true

if defined?(Sidekiq)
  require 'sidekiq/web'

  Sidekiq::Web.use(Rack::Auth::Basic) do |_, password|
    next true if Rails.env.development?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password),
      Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_BASIC_AUTH_PASSWORD'))
    )
  end

  Sidekiq.strict_args!
end
