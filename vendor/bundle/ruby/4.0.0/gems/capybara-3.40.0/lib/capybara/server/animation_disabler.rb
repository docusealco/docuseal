# frozen_string_literal: true

module Capybara
  class Server
    class AnimationDisabler
      def self.selector_for(css_or_bool)
        case css_or_bool
        when String
          css_or_bool
        when true
          '*'
        else
          raise CapybaraError, 'Capybara.disable_animation supports either a String (the css selector to disable) or a boolean'
        end
      end

      def initialize(app)
        @app = app
        @disable_css_markup = format(DISABLE_CSS_MARKUP_TEMPLATE,
                                     selector: self.class.selector_for(Capybara.disable_animation))
        @disable_js_markup = +DISABLE_JS_MARKUP_TEMPLATE
      end

      def call(env)
        status, headers, body = @app.call(env)
        return [status, headers, body] unless html_content?(headers)

        nonces = directive_nonces(headers).transform_values { |nonce| "nonce=\"#{nonce}\"" if nonce && !nonce.empty? }
        response = Rack::Response.new([], status, headers)

        body.each { |html| response.write insert_disable(html, nonces) }
        body.close if body.respond_to?(:close)

        response.finish
      end

    private

      attr_reader :disable_css_markup, :disable_js_markup

      def html_content?(headers)
        /html/.match?(headers['Content-Type']) # rubocop:todo Performance/StringInclude
      end

      def insert_disable(html, nonces)
        html.sub(%r{(</head>)}, "<style #{nonces['style-src']}>#{disable_css_markup}</style>\\1")
            .sub(%r{(</body>)}, "<script #{nonces['script-src']}>#{disable_js_markup}</script>\\1")
      end

      def directive_nonces(headers)
        headers.fetch('Content-Security-Policy', '')
               .split(';')
               .map(&:split) # rubocop:disable Style/MapToHash
               .to_h do |s|
                 [
                   s[0], s[1..].filter_map do |value|
                     /^'nonce-(?<nonce>.+)'/ =~ value
                     nonce
                   end[0]
                 ]
               end
      end

      DISABLE_CSS_MARKUP_TEMPLATE = <<~CSS
        %<selector>s, %<selector>s::before, %<selector>s::after {
           transition: none !important;
           animation-duration: 0s !important;
           animation-delay: 0s !important;
           scroll-behavior: auto !important;
        }
      CSS

      DISABLE_JS_MARKUP_TEMPLATE = <<~SCRIPT
        //<![CDATA[
          (typeof jQuery !== 'undefined') && (jQuery.fx.off = true);
        //]]>
      SCRIPT
    end
  end
end
