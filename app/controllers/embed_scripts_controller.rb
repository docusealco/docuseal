# frozen_string_literal: true

class EmbedScriptsController < ActionController::Metal
  DUMMY_SCRIPT = <<~JAVASCRIPT.freeze
    const DummyBuilder = class extends HTMLElement {
      connectedCallback() {
        this.innerHTML = `
          <div style="text-align: center; padding: 20px; font-family: Arial, sans-serif;">
            <h2>Upgrade to Pro</h2>
            <p>Unlock embedded components by upgrading to Pro</p>
            <div style="margin-top: 40px;">
              <a href="#{Docuseal::CONSOLE_URL}/on_premises" target="_blank" style="padding: 15px 25px; background-color: #222; color: white; text-decoration: none; border-radius: 5px; font-size: 16px; cursor: pointer;">
                Learn More
              </a>
            </div>
          </div>
        `;
      }
    };

    const DummyForm = class extends DummyBuilder {};

    if (!window.customElements.get('docuseal-builder')) {
      window.customElements.define('docuseal-builder', DummyBuilder);
    }

    if (!window.customElements.get('docuseal-form')) {
      window.customElements.define('docuseal-form', DummyForm);
    }
  JAVASCRIPT

  def show
    headers['Content-Type'] = 'application/javascript'

    self.response_body = DUMMY_SCRIPT

    self.status = 200
  end
end
