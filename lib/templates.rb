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
end
