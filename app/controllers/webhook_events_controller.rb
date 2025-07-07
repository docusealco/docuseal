# frozen_string_literal: true

class WebhookEventsController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false, id_param: :webhook_id
  before_action :load_webhook_event

  def show
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
    id_key = WebhookUrls::EVENT_TYPE_ID_KEYS.fetch(@webhook_event.event_type.split('.').first)

    last_attempt_id = @webhook_event.webhook_attempts.maximum(:id)

    WebhookUrls::EVENT_TYPE_TO_JOB_CLASS[@webhook_event.event_type].perform_async(
      id_key => @webhook_event.record_id,
      'webhook_url_id' => @webhook_event.webhook_url_id,
      'event_uuid' => @webhook_event.uuid,
      'attempt' => SendWebhookRequest::MANUAL_ATTEMPT,
      'last_status' => 0
    )

    render turbo_stream: [
      turbo_stream.after(
        params[:button_id],
        helpers.tag.submit_form(
          helpers.button_to('', refresh_settings_webhook_event_path(@webhook_url.id, @webhook_event.uuid),
                            params: { last_attempt_id: }),
          class: 'hidden', data: { interval: 3_000 }
        )
      )
    ]
  end

  def refresh
    return head :ok if @webhook_event.webhook_attempts.maximum(:id) == params[:last_attempt_id].to_i

    render turbo_stream: [
      turbo_stream.replace(helpers.dom_id(@webhook_event),
                           partial: 'event_row',
                           locals: { with_status: true, webhook_url: @webhook_url, webhook_event: @webhook_event }),
      turbo_stream.replace(helpers.dom_id(@webhook_event, :drawer_events),
                           partial: 'drawer_events',
                           locals: { webhook_url: @webhook_url, webhook_event: @webhook_event })
    ]
  end

  private

  def load_webhook_event
    @webhook_event = @webhook_url.webhook_events.find_by!(uuid: params[:id])
  end
end
