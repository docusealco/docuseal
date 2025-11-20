# frozen_string_literal: true

module SigningFormHelper
  module_function

  def draw_canvas
    page.execute_script <<~JS
      const canvas = document.getElementsByTagName('canvas')[0];
      const rect = canvas.getBoundingClientRect();

      const startX = rect.left + 50;
      const startY = rect.top + 100;

      const amplitude = 20;
      const wavelength = 30;
      const length = 300;

      function dispatchPointerEvent(type, x, y) {
        const event = new PointerEvent(type, {
          pointerId: 1,
          pointerType: 'pen',
          isPrimary: true,
          clientX: x,
          clientY: y,
          bubbles: true,
          pressure: 0.5
        });

        canvas.dispatchEvent(event);
      }

      dispatchPointerEvent('pointerdown', startX, startY);

      let x = 0;
      function drawStep() {
        if (x > length) {
          dispatchPointerEvent('pointerup', startX + x, startY);
          return;
        }

        const y = startY + amplitude * Math.sin((x / wavelength) * 2 * Math.PI);
        dispatchPointerEvent('pointermove', startX + x, y);
        x += 5;
        requestAnimationFrame(drawStep);
      }

      drawStep();
    JS

    sleep 0.1
  end

  def field_value(submitter, field_name)
    field = template_field(submitter.template, field_name)

    submitter.values[field['uuid']]
  end

  def template_field(template, field_name)
    template.fields.find { |f| f['name'] == field_name || f['title'] == field_name } || {}
  end
end
