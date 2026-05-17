# frozen_string_literal: true

# Clerk SDK config — secret_key falls back to ENV['CLERK_SECRET_KEY'].
# The Rack middleware is auto-mounted when the SDK is required, which
# reads the __session cookie set by accounts.bloombilt.com on the apex
# .bloombilt.com domain and exposes the verified user via the `clerk`
# helper in controllers that include Clerk::Authenticatable.
Clerk.configure do |c|
  c.logger = Rails.logger
end
