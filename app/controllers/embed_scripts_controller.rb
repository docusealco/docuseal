# frozen_string_literal: true

class EmbedScriptsController < ActionController::Metal
  EMBED_SCRIPT = <<~JAVASCRIPT
    const buildIframe = (element) => {
      const iframe = document.createElement('iframe');
      const src = element.dataset.src || element.getAttribute('src');

      if (!src) return;

      const url = new URL(src, window.location.href);

      ['email', 'name', 'phone', 'role', 'token', 'preview', 'externalId', 'completedRedirectUrl'].forEach((key) => {
        const value = element.dataset[key];

        if (value) url.searchParams.set(key.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`), value);
      });

      iframe.src = url.toString();
      iframe.style.width = element.dataset.width || '100%';
      iframe.style.height = element.dataset.height || '700px';
      iframe.style.border = element.dataset.border || '0';
      iframe.allow = element.dataset.allow || 'clipboard-write; fullscreen';
      iframe.title = element.dataset.title || 'DocuSeal';

      element.innerHTML = '';
      element.appendChild(iframe);
    };

    const EmbeddedBuilder = class extends HTMLElement {
      connectedCallback() {
        buildIframe(this);
      }
    };

    const EmbeddedForm = class extends EmbeddedBuilder {};

    if (!window.customElements.get('docuseal-builder')) {
      window.customElements.define('docuseal-builder', EmbeddedBuilder);
    }

    if (!window.customElements.get('docuseal-form')) {
      window.customElements.define('docuseal-form', EmbeddedForm);
    }
  JAVASCRIPT

  def show
    headers['Content-Type'] = 'application/javascript'

    self.response_body = EMBED_SCRIPT

    self.status = 200
  end
end
