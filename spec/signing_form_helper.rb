# frozen_string_literal: true

module SigningFormHelper
  module_function

  def draw_canvas
    page.find('canvas').click([], { x: 150, y: 100 })
    page.execute_script <<~JS
      const canvas = document.getElementsByTagName('canvas')[0];
      const ctx = canvas.getContext('2d');

      ctx.beginPath();
      ctx.moveTo(150, 100);
      ctx.lineTo(450, 100);
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(150, 100);
      ctx.lineTo(150, 150);
      ctx.stroke();
    JS
    sleep 1
  end

  def field_value(submitter, field_name)
    field = template_field(submitter.template, field_name)

    submitter.values[field['uuid']]
  end

  def template_field(template, field_name)
    template.fields.find { |f| f['name'] == field_name || f['title'] == field_name } || {}
  end
end
