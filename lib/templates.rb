# frozen_string_literal: true

module Templates
  EXPIRATION_DURATIONS = {
    one_day: 1.day,
    two_days: 2.days,
    three_days: 3.days,
    four_days: 4.days,
    five_days: 5.days,
    six_days: 6.days,
    seven_days: 7.days,
    eight_days: 8.days,
    nine_days: 9.days,
    ten_days: 10.days,
    two_weeks: 14.days,
    three_weeks: 21.days,
    four_weeks: 28.days,
    one_month: 1.month,
    two_months: 2.months,
    three_months: 3.months
  }.with_indifferent_access.freeze

  module_function

  def build_field_areas_index(fields)
    hash = {}

    fields.each do |field|
      (field['areas'] || []).each do |area|
        hash[area['attachment_uuid']] ||= {}
        acc = (hash[area['attachment_uuid']][area['page']] ||= [])

        acc << [area, field]
      end
    end

    hash
  end

  def search(current_user, templates, keyword)
    if Docuseal.fulltext_search?(current_user)
      fulltext_search(current_user, templates, keyword)
    else
      plain_search(templates, keyword)
    end
  end

  def plain_search(templates, keyword)
    return templates if keyword.blank?

    templates.where(Template.arel_table[:name].lower.matches("%#{keyword.downcase}%"))
  end

  def fulltext_search(current_user, templates, keyword)
    return templates if keyword.blank?

    templates.where(
      id: SearchEntry.where(record_type: 'Template')
                     .where(account_id: current_user.account_id)
                     .where(*SearchEntries.build_tsquery(keyword))
                     .select(:record_id)
    )
  end

  def filter_undefined_submitters(template_submitters)
    template_submitters.to_a.select do |item|
      item['invite_by_uuid'].blank? && item['optional_invite_by_uuid'].blank? &&
        item['linked_to_uuid'].blank? && item['is_requester'].blank? && item['email'].blank?
    end
  end

  def build_default_expire_at(template)
    default_expire_at_duration = template.preferences['default_expire_at_duration'].presence
    default_expire_at = template.preferences['default_expire_at'].presence

    return if default_expire_at_duration.blank?

    if default_expire_at_duration == 'specified_date' && default_expire_at.present?
      Time.zone.parse(default_expire_at)
    elsif EXPIRATION_DURATIONS[default_expire_at_duration]
      Time.current + EXPIRATION_DURATIONS[default_expire_at_duration]
    end
  end
end
