# frozen_string_literal: true

module SubmitterReminders
  module_function

  def next_reminder_at(submitter, reminder_config)
    return nil unless reminder_config&.value.is_a?(Hash)
    return nil if submitter.completed_at? || submitter.declined_at?
    return nil if submitter.submission.archived_at?
    return nil if submitter.template&.archived_at?
    return nil unless submitter.sent_at

    durations = parse_durations(reminder_config.value)
    return nil if durations.empty?

    reminder_events = submitter.submission_events
                              .select { |e| e.event_type.in?(%w[send_reminder_email skip_reminder_email]) }
    reminder_count = reminder_events.size

    duration = case reminder_count
               when 0 then durations[:first]
               when 1 then durations[:second]
               when 2 then durations[:third]
               end

    return nil unless duration

    base_time = if reminder_count == 0
                  submitter.sent_at
                else
                  reminder_events.max_by(&:created_at)&.created_at || submitter.sent_at
                end

    return nil if base_time.nil?

    base_time + duration
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
