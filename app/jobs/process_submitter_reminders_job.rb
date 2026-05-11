# frozen_string_literal: true

class ProcessSubmitterRemindersJob
  include Sidekiq::Job

  sidekiq_options queue: :recurrent

  def perform
    AccountConfig.where(key: AccountConfig::SUBMITTER_REMINDERS).find_each do |config|
      process_account_reminders(config)
    end

    reschedule!
  end

  private

  def reschedule!
    require 'sidekiq/api'

    Sidekiq::ScheduledSet.new
      .select { |j| j.klass == 'ProcessSubmitterRemindersJob' }
      .each(&:delete)

    ProcessSubmitterRemindersJob.perform_in(1.hour)
  end

  def process_account_reminders(config)
    durations = parse_durations(config.value)
    return if durations.empty?

    pending_submitters = Submitter
      .joins(:submission)
      .where(account_id: config.account_id)
      .where.not(sent_at: nil)
      .where(completed_at: nil, declined_at: nil)
      .where.not(email: [nil, ''])
      .where(submissions: { archived_at: nil })

    pending_submitters.find_each do |submitter|
      next if submitter.template&.archived_at?

      send_reminder_if_due(submitter, durations)
    end
  end

  def send_reminder_if_due(submitter, durations)
    reminder_count = submitter.submission_events.where(event_type: %w[send_reminder_email skip_reminder_email]).count

    duration = case reminder_count
               when 0 then durations[:first]
               when 1 then durations[:second]
               when 2 then durations[:third]
               else return
               end

    return unless duration

    base_time = if reminder_count == 0
                  submitter.sent_at
                else
                  submitter.submission_events
                    .where(event_type: %w[send_reminder_email skip_reminder_email])
                    .order(:created_at)
                    .last&.created_at || submitter.sent_at
                end

    return if base_time.nil?
    return unless Time.current >= base_time + duration

    SendSubmitterReminderEmailJob.perform_async('submitter_id' => submitter.id)
  end

  def parse_durations(value)
    return {} unless value.is_a?(Hash)

    result = {}
    result[:first] = duration_to_seconds(value['first_duration']) if value['first_duration'].present?
    result[:second] = duration_to_seconds(value['second_duration']) if value['second_duration'].present?
    result[:third] = duration_to_seconds(value['third_duration']) if value['third_duration'].present?
    result
  end

  def duration_to_seconds(key)
    case key
    when 'one_hour' then 1.hour
    when 'two_hours' then 2.hours
    when 'four_hours' then 4.hours
    when 'eight_hours' then 8.hours
    when 'twelve_hours' then 12.hours
    when 'twenty_four_hours' then 24.hours
    when 'two_days' then 2.days
    when 'three_days' then 3.days
    when 'four_days' then 4.days
    when 'five_days' then 5.days
    when 'six_days' then 6.days
    when 'seven_days' then 7.days
    when 'eight_days' then 8.days
    when 'fifteen_days' then 15.days
    when 'twenty_one_days' then 21.days
    when 'thirty_days' then 30.days
    end
  end
end
