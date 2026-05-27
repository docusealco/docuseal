const PagyAIWidget = {
  HOST_ID:              'gurubase-chat-widget-container',
  IMG_SELECTOR:         '#chatWindow > div.anteon-header > div > img',
  NAME_SELECTOR:        '#chatWindow > div.anteon-header > div > span',
  DESCRIPTION_SELECTOR: '#chatWindow > div.chat-messages > div > p',
  NEW_IMG_SIZE:         '40px',
  NEW_NAME:             'Ask Pagy AI',
  NEW_DESCRIPTION:      'Pagy AI uses the latest data in the documentation to answer your questions.',
  ICON_URL:             'https://github.com/ddnexus/pagy/blob/master/assets/images/pagy-the-frog.png?raw=true',
  skipTurbo:            true,

  checkAndEdit: function() {
    const hostElement = document.getElementById(this.HOST_ID);
    if (hostElement && hostElement.shadowRoot) {
      const shadowRoot  = hostElement.shadowRoot;
      const img         = shadowRoot.querySelector(this.IMG_SELECTOR);
      const name        = shadowRoot.querySelector(this.NAME_SELECTOR);
      const description = shadowRoot.querySelector(this.DESCRIPTION_SELECTOR);

      if (img) {
        img.style.maxWidth  = this.NEW_IMG_SIZE;
        img.style.maxHeight = this.NEW_IMG_SIZE;
      }
      if (name) {
        name.textContent = this.NEW_NAME;
      }
      if (description) {
        description.textContent = this.NEW_DESCRIPTION;
      }
      return true;
    }
    return false;
  },

  attemptEditing: function() {
    if (this.checkAndEdit()) {
      return;
    }
    setTimeout(() => this.attemptEditing(), 200);
  },

  editChatWidget: function() {
    this.attemptEditing();
  },

  appendWidgetScript: function() {
    const script   = document.createElement('script');
    const hostname = window.location.hostname;

    switch (hostname) {
      case 'ddnexus.github.io':  // remote docs
        script.dataset.widgetId = 'HKtFSPZLGiAXOdBWS4rSAxEkqv8czIbJoQdMEwCqgEc';
        script.dataset.margins  = '{"bottom": "1.48rem", "right": "6rem"}';
        break;
      case 'localhost':  // local docs
        script.dataset.widgetId = 'djgBhRlpdH8b07oj0Gsaerz69Xfs0FXMuUluyOo2iR4';
        script.dataset.margins  = '{"bottom": "1.48rem", "right": "6rem"}';
        break;
      case '127.0.0.1': // apps
        script.dataset.widgetId = '_rXLissYyqe-dJ9vGGGXzmJwavoW0GvuzQPEq5BZjP8';
        break;
      default:
        console.error('Pagy AI - Unknown hostname: ', hostname);
    }
    script.async               = true;
    script.src                 = 'https://widget.gurubase.io/widget.latest.min.js';
    script.id                  = 'guru-widget-id';
    script.dataset.iconUrl     = this.ICON_URL;
    script.dataset.text        = 'Pagy AI';
    script.dataset.bgColor     = '#1f7a1f';
    script.dataset.lightMode   = 'auto';
    script.dataset.tooltipSide = 'bottom';
    document.head.appendChild(script);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  PagyAIWidget.appendWidgetScript();
  PagyAIWidget.editChatWidget();
});

document.addEventListener("turbo:load", () => {
  // skip only the first time (already done by DOMContentLoaded)
  if (PagyAIWidget.skipTurbo) {
    PagyAIWidget.skipTurbo = false;
  } else {
    window.chatWidget = new ChatWidget();
    PagyAIWidget.editChatWidget();
  }
});
