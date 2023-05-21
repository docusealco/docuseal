# frozen_string_literal: true

ActionView::Base.field_error_proc = proc do |html_tag, instance|
  next html_tag if html_tag.starts_with?('<label')

  errors = Array(instance.error_message).join(', ')

  field_name =
    instance.object.class.human_attribute_name(instance.instance_variable_get(:@method_name).to_s)

  result = html_tag
  result += ApplicationController.helpers.tag.div("#{field_name} #{errors}") if errors.present?

  result
end
