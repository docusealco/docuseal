# frozen_string_literal: true

ActionView::Base.field_error_proc = proc do |html_tag, instance|
  next html_tag if html_tag.starts_with?('<label')

  errors = Array(instance.error_message).join(', ')

  field_name =
    instance.object.class.human_attribute_name(instance.instance_variable_get(:@method_name).to_s)

  parsed_html_tag = Nokogiri::HTML::DocumentFragment.parse(html_tag)
  parsed_html_tag.children.add_class 'input-error'
  html_tag = parsed_html_tag.to_s.html_safe

  result = html_tag
  result += ApplicationController.helpers.tag.label(ApplicationController.render(partial: 'shared/field_error', locals: { message: "#{field_name} #{errors}" }), class: 'label') if errors.present?

  result
end
