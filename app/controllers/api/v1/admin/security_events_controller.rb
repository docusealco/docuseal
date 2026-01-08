# frozen_string_literal: true

module Api
  module V1
    module Admin
      # SecurityEventsController
      # Handles security event monitoring and audit trail
      # Implements export capability for compliance
      class SecurityEventsController < ApiBaseController
        # Layer 3: Authorization - only super admins can view security events
        before_action :verify_super_admin_access

        # GET /api/v1/admin/security_events
        def index
          # Layer 1: Scoped query
          events = SecurityEvent.all

          # Layer 4: Filtering
          events = events.where(user_id: params[:user_id]) if params[:user_id].present?
          events = events.where(event_type: params[:event_type]) if params[:event_type].present?
          events = events.where('created_at >= ?', params[:from]) if params[:from].present?
          events = events.where('created_at <= ?', params[:to]) if params[:to].present?

          # Pagination
          events = events.order(created_at: :desc)
          @pagy, events = pagy(events, items: params[:limit] || 50)

          render json: {
            events: events.map do |event|
              {
                id: event.id,
                event_type: event.event_type,
                user_email: event.user&.email,
                ip_address: event.ip_address,
                details: event.details,
                created_at: event.created_at,
                description: event.description
              }
            end,
            meta: pagy_meta(@pagy)
          }
        end

        # GET /api/v1/admin/security_events/:id
        def show
          event = SecurityEvent.find_by(id: params[:id])

          unless event
            return render json: { error: 'Security event not found' }, status: :not_found
          end

          render json: {
            id: event.id,
            event_type: event.event_type,
            user: {
              id: event.user&.id,
              email: event.user&.email,
              name: event.user&.full_name
            },
            ip_address: event.ip_address,
            details: event.details,
            created_at: event.created_at,
            description: event.description
          }
        end

        # GET /api/v1/admin/security_events/export
        def export
          # Layer 4: Export capability
          events = SecurityEvent.all

          # Apply filters
          events = events.where(event_type: params[:event_type]) if params[:event_type].present?
          events = events.where('created_at >= ?', params[:from]) if params[:from].present?
          events = events.where('created_at <= ?', params[:to]) if params[:to].present?

          # Generate CSV
          csv_data = events.export_csv(
            start_date: params[:from],
            end_date: params[:to],
            event_types: params[:event_type]&.split(',')
          )

          # Log export event
          log_security_event(:security_events_exported, {
            event_count: events.count,
            filters: params.slice(:event_type, :from, :to)
          })

          send_data csv_data,
            filename: "security_events_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
            type: 'text/csv'
        end

        # GET /api/v1/admin/security_events/alerts
        def alerts
          # Get recent critical events that might indicate attacks
          critical_events = SecurityEvent.where(
            event_type: ['unauthorized_institution_access', 'rate_limit_exceeded', 'token_validation_failure']
          ).where('created_at >= ?', 1.hour.ago)

          # Group by type for summary
          summary = critical_events.group(:event_type).count

          # Check thresholds
          alerts = []
          alerts << { type: 'unauthorized_access', severity: 'high', count: summary['unauthorized_institution_access'] || 0 } if (summary['unauthorized_institution_access'] || 0) >= 5
          alerts << { type: 'rate_limit', severity: 'medium', count: summary['rate_limit_exceeded'] || 0 } if (summary['rate_limit_exceeded'] || 0) >= 10
          alerts << { type: 'token_failures', severity: 'high', count: summary['token_validation_failure'] || 0 } if (summary['token_validation_failure'] || 0) >= 20

          render json: {
            summary: summary,
            alerts: alerts,
            time_range: { from: 1.hour.ago, to: Time.current }
          }
        end

        private

        def verify_super_admin_access
          unless current_user.cohort_super_admin?
            render json: { error: 'Super admin access required' }, status: :forbidden
          end
        end
      end
    end
  end
end