# frozen_string_literal: true

class WebhookEventsController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false, only: %i[show resend], id_param: :webhook_id

  def show
    @webhook_event = @webhook_url.webhook_events.find_by!(uuid: params[:id])
    @webhook_attempts = @webhook_event.webhook_attempts.order(created_at: :desc)

    return unless current_ability.can?(:read, @webhook_event.record)

    @data =
      case @webhook_event.event_type
      when 'form.started', 'form.completed', 'form.declined', 'form.viewed'
        Submitters::SerializeForWebhook.call(@webhook_event.record)
      when 'submission.created', 'submission.completed', 'submission.expired'
        Submissions::SerializeForApi.call(@webhook_event.record)
      when 'template.created', 'template.updated'
        Templates::SerializeForApi.call(@webhook_event.record)
      when 'submission.archived'
        @webhook_event.record.as_json(only: %i[id archived_at])
      end
  end

  def resend
    @webhook_event = @webhook_url.webhook_events.find_by!(uuid: params[:id])

    id_key = WebhookUrls::EVENT_TYPE_ID_KEYS.fetch(@webhook_event.event_type.split('.').first)

    WebhookUrls::EVENT_TYPE_TO_JOB_CLASS[@webhook_event.event_type].perform_async(
      id_key => @webhook_event.record_id,
      'webhook_url_id' => @webhook_event.webhook_url_id,
      'event_uuid' => @webhook_event.uuid,
      'attempt' => SendWebhookRequest::MANUAL_ATTEMPT,
      'last_status' => 0
    )

    head :ok
  end
end
