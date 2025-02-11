# frozen_string_literal: true

class SubmissionEventsController < ApplicationController
  SUBMISSION_EVENT_ICONS = {
    'view_form' => 'eye',
    'start_form' => 'player_play',
    'complete_form' => 'check',
    'send_email' => 'mail_forward',
    'click_email' => 'hand_click',
    'api_complete_form' => 'check',
    'send_reminder_email' => 'mail_forward',
    'send_2fa_sms' => '2fa',
    'send_sms' => 'send',
    'phone_verified' => 'phone_check',
    'click_sms' => 'hand_click',
    'decline_form' => 'x',
    'start_verification' => 'player_play',
    'complete_verification' => 'check',
    'invite_party' => 'user_plus'
  }.freeze

  load_and_authorize_resource :submission

  # rubocop:disable Metrics
  def index
    submitters = @submission.submitters
    submitters_uuids = (@submission.template_submitters || @submission.template.submitters).pluck('uuid')

    @events_data = @submission.submission_events.sort_by(&:event_timestamp).map do |event|
      submitter = submitters.find { |e| e.id == event.submitter_id }
      submitter_name =
        if event.event_type.include?('sms') || event.event_type.include?('phone')
          event.data['phone'] || submitter.phone
        else
          submitter.name || submitter.email || submitter.phone
        end

      text =
        if event.event_type == 'complete_verification'
          helpers.t('submission_event_names.complete_verification_by_html', provider: event.data['method'],
                                                                            submitter_name:)
        elsif event.event_type == 'invite_party' &&
              (invited_submitter = submitters.find { |e| e.uuid == event.data['uuid'] }) &&
              (name = submission.template_submitters.find { |e| e['uuid'] == event.data['uuid'] }&.dig('name'))
          invited_submitter_name = [invited_submitter.name || invited_submitter.email || invited_submitter.phone,
                                    name].join(' ')
          helpers.t('submission_event_names.invite_party_by_html', invited_submitter_name:,
                                                                   submitter_name:)
        elsif event.event_type.include?('send_')
          helpers.t("submission_event_names.#{event.event_type}_to_html", submitter_name:)
        else
          helpers.t("submission_event_names.#{event.event_type}_by_html", submitter_name:)
        end

      {
        timestamp: event.event_timestamp.in_time_zone(current_account.timezone),
        event_type: event.event_type,
        submitter_index: submitters_uuids.index(submitter.uuid),
        text:
      }
    end
  end
  # rubocop:enable Metrics
end
