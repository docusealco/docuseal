# frozen_string_literal: true

module Flows
  module_function

  def build_field_areas_index(flow)
    hash = {}

    flow.fields.each do |field|
      (field['areas'] || []).each do |area|
        hash[area['attachment_uuid']] ||= {}
        acc = (hash[area['attachment_uuid']][area['page']] ||= [])

        acc << { area:, field: }
      end
    end

    hash
  end
end
