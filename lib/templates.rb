# frozen_string_literal: true

module Templates
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

  def search(templates, keyword)
    return templates if keyword.blank?

    templates.where(Template.arel_table[:name].lower.matches("%#{keyword.downcase}%"))
  end

  def filter_undefined_submitters(template)
    template.submitters.to_a.select do |item|
      item['invite_by_uuid'].blank? && item['linked_to_uuid'].blank? &&
        item['is_requester'].blank? && item['email'].blank?
    end
  end
end
