# frozen_string_literal: true

# == Schema Information
#
# Table name: security_events
#
#  id          :bigint           not null, primary key
#  user_id     :bigint
#  event_type  :string           not null
#  ip_address  :string           not null
#  details     :jsonb            not null, default: {}
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_security_events_on_user_id       (user_id)
#  index_security_events_on_event_type    (event_type)
#  index_security_events_on_created_at    (created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class SecurityEvent < ApplicationRecord
  belongs_to :user, optional: true

  # Event types
  EVENT_TYPES = %w[
    unauthorized_institution_access
    insufficient_privileges
    token_validation_failure
    rate_limit_exceeded
    invitation_accepted
    super_admin_demoted
  ].freeze

  # Validations
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :ip_address, presence: true

  # CRITICAL METHOD: Security event logging
  def self.log(event_type, user = nil, details = {})
    # Extract IP from details or use default
    ip_address = details[:ip_address] || '0.0.0.0'

    # Clean details (remove sensitive data)
    clean_details = details.except(:ip_address, :password, :token, :raw_token)

    create!(
      user: user,
      event_type: event_type,
      ip_address: ip_address,
      details: clean_details
    )
  end

  # Alert threshold checking
  def self.alert_threshold_exceeded?(event_type, threshold:, time_window: 1.hour)
    count = where(event_type: event_type)
             .where('created_at > ?', time_window.ago)
             .count

    count >= threshold
  end

  # Get recent security events for monitoring
  def self.recent(limit: 100)
    order(created_at: :desc).limit(limit)
  end

  # Filter by time range
  def self.between(start_time, end_time)
    where(created_at: start_time..end_time)
  end

  # Export for audit
  def self.export_csv(start_date: nil, end_date: nil, event_types: nil)
    scope = all
    scope = scope.between(start_date, end_date) if start_date && end_date
    scope = scope.where(event_type: event_types) if event_types.present?

    CSV.generate do |csv|
      csv << %w[id user_email event_type ip_address details created_at]
      scope.find_each do |event|
        csv << [
          event.id,
          event.user&.email,
          event.event_type,
          event.ip_address,
          event.details.to_json,
          event.created_at.iso8601
        ]
      end
    end
  end

  # Human-readable description
  def description
    case event_type
    when 'unauthorized_institution_access'
      "User attempted to access institution they don't have permission for"
    when 'insufficient_privileges'
      "User attempted action without required role"
    when 'token_validation_failure'
      "Invitation token validation failed"
    when 'rate_limit_exceeded'
      "Rate limit exceeded for invitation attempts"
    when 'invitation_accepted'
      "Admin invitation successfully accepted"
    when 'super_admin_demoted'
      "Super admin role removed from user"
    else
      "Unknown security event"
    end
  end
end