# frozen_string_literal: true

# Redis Configuration for Token Enforcement
# Required for Winston's single-use token system

# Configure Redis connection
$redis = Redis.new(
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }, # For production with SSL
  timeout: 5.0,
  reconnect_attempts: 1
)

# Verify Redis connection
begin
  $redis.ping
  Rails.logger.info '✅ Redis connection established for token enforcement'
rescue Redis::CannotConnectError => e
  Rails.logger.error "❌ Redis connection failed: #{e.message}"
  Rails.logger.warn 'Token single-use enforcement will not work without Redis'
end

# Token cleanup job (daily)
# This removes expired tokens from Redis to prevent memory bloat
module TokenCleanup
  def self.cleanup_expired_tokens
    redis = $redis
    pattern = "invitation_token:*"

    # Find expired tokens (TTL <= 0)
    redis.scan_each(match: pattern) do |key|
      ttl = redis.ttl(key)
      if ttl <= 0
        redis.del(key)
      end
    end
  end
end

# Schedule daily cleanup (if Sidekiq scheduler is available)
if defined?(Sidekiq)
  begin
    require 'sidekiq/scheduler'

    Sidekiq.configure_server do |config|
      config.on(:startup) do
        Sidekiq::Scheduler.every '1d', class: 'TokenCleanupJob', args: []
      end
    end
  rescue LoadError
    # Sidekiq scheduler not available, skip scheduling
    Rails.logger.warn 'Sidekiq scheduler not available, token cleanup scheduling skipped'
  end
end