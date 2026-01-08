# frozen_string_literal: true

# SecurityAlertJob
# Sends immediate alerts for critical security events
class SecurityAlertJob
  include Sidekiq::Job

  sidekiq_options queue: :critical_security, retry: 3

  def perform(security_event_id)
    event = SecurityEvent.find_by(id: security_event_id)
    return unless event

    # Check if this event type should trigger an alert
    return unless should_alert?(event)

    # Send alert (email, Slack, PagerDuty, etc.)
    # This would integrate with your existing notification system
    send_alert(event)

    # Log that alert was sent
    Rails.logger.info "Security alert sent for event #{event.id}: #{event.event_type}"
  end

  private

  def should_alert?(event)
    # Alert thresholds
    case event.event_type
    when 'unauthorized_institution_access'
      # Any unauthorized access attempt
      true
    when 'rate_limit_exceeded'
      # Rate limit violations
      true
    when 'token_validation_failure'
      # Multiple token failures might indicate attack
      SecurityEvent.alert_threshold_exceeded?('token_validation_failure', threshold: 20, time_window: 1.hour)
    when 'super_admin_demoted'
      # Always alert on super admin changes
      true
    else
      false
    end
  end

  def send_alert(event)
    # Implementation depends on your notification system
    # Examples:
    # - Send email to security team
    # - Post to Slack webhook
    # - Trigger PagerDuty incident
    # - Log to external SIEM

    # For now, log to Rails logger
    Rails.logger.warn <<~ALERT
      [SECURITY ALERT] #{event.event_type.upcase}
      User: #{event.user&.email}
      IP: #{event.ip_address}
      Time: #{event.created_at}
      Details: #{event.details}
    ALERT
  end
end