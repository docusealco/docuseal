# frozen_string_literal: true

# InvitationCleanupJob
# Daily cleanup of expired invitations
# Implements Winston's token cleanup requirement
class InvitationCleanupJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform
    # Clean up expired invitations from database
    expired_count = InvitationService.cleanup_expired

    # Clean up expired tokens from Redis
    redis_cleanup_count = cleanup_redis_tokens

    Rails.logger.info "Invitation cleanup: #{expired_count} database records, #{redis_cleanup_count} Redis tokens"

    # Log cleanup event
    if expired_count > 0 || redis_cleanup_count > 0
      SecurityEvent.log(:invitation_cleanup, nil, {
        expired_invitations: expired_count,
        redis_tokens_cleaned: redis_cleanup_count,
        reason: 'Daily maintenance'
      })
    end

    { database: expired_count, redis: redis_cleanup_count }
  end

  private

  def cleanup_redis_tokens
    return 0 unless defined?(Redis.current)

    redis = Redis.current
    pattern = "invitation_token:*"
    count = 0

    redis.scan_each(match: pattern) do |key|
      ttl = redis.ttl(key)
      if ttl <= 0
        redis.del(key)
        count += 1
      end
    end

    count
  end
end