# frozen_string_literal: true

class EmbedScriptsController < ActionController::Metal
  DUMMY_SCRIPT = <<~JAVASCRIPT
    const DummyBuilder = class extends HTMLElement {
      connectedCallback() {
        this.innerHTML = `
          <div style="text-align: center; padding: 20px; font-family: Arial, sans-serif;">
            <h2>Embedded components not loaded</h2>
            <p>The embed assets could not be served from this WaboSign instance. Check that the host is reachable and that the embed script is being served from the same origin.</p>
          </div>
        `;
      }
    };

    const DummyForm = class extends DummyBuilder {};

    if (!window.customElements.get('wabosign-builder')) {
      window.customElements.define('docuseal-builder', DummyBuilder);
    }

    if (!window.customElements.get('wabosign-form')) {
      window.customElements.define('docuseal-form', DummyForm);
    }
  JAVASCRIPT

  def show
    headers['Content-Type'] = 'application/javascript'

    self.response_body = DUMMY_SCRIPT

    self.status = 200
  end
end
