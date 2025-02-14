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

  def index; end
end
