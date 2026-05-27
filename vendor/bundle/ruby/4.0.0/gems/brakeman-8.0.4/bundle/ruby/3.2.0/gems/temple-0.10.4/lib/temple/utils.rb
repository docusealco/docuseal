# frozen_string_literal: true
begin
  require 'cgi/escape'
rescue LoadError
end

module Temple
  # @api public
  module Utils
    extend self

    # Returns an escaped copy of `html`.
    # Strings which are declared as html_safe are not escaped.
    #
    # @param html [String] The string to escape
    # @return [String] The escaped string
    def escape_html_safe(html)
      s = html.to_s
      s.html_safe? || html.html_safe? ? s : escape_html(s)
    end

    if defined?(CGI.escapeHTML)
      # Returns an escaped copy of `html`.
      #
      # @param html [String] The string to escape
      # @return [String] The escaped string
      def escape_html(html)
        CGI.escapeHTML(html.to_s)
      end
    else
      # Used by escape_html
      # @api private
      ESCAPE_HTML = {
        '&'  => '&amp;',
        '"'  => '&quot;',
        '\'' => '&#39;',
        '<'  => '&lt;',
        '>'  => '&gt;'
      }.freeze

      ESCAPE_HTML_PATTERN = Regexp.union(*ESCAPE_HTML.keys)

      # Returns an escaped copy of `html`.
      #
      # @param html [String] The string to escape
      # @return [String] The escaped string
      def escape_html(html)
        html.to_s.gsub(ESCAPE_HTML_PATTERN, ESCAPE_HTML)
      end
    end

    # Generate unique variable name
    #
    # @param prefix [String] Variable name prefix
    # @return [String] Variable name
    def unique_name(prefix = nil)
      @unique_name ||= 0
      prefix ||= (@unique_prefix ||= self.class.name.gsub('::'.freeze, '_'.freeze).downcase)
      "_#{prefix}#{@unique_name += 1}"
    end

    # Check if expression is empty
    #
    # @param exp [Array] Temple expression
    # @return true if expression is empty
    def empty_exp?(exp)
      case exp[0]
      when :multi
        exp[1..-1].all? {|e| empty_exp?(e) }
      when :newline
        true
      else
        false
      end
    end

    def indent_dynamic(text, indent_next, indent, pre_tags = nil)
      text = text.to_s
      safe = text.respond_to?(:html_safe?) && text.html_safe?
      return text if pre_tags && text =~ pre_tags

      level = text.scan(/^\s*/).map(&:size).min
      text = text.gsub(/(?!\A)^\s{#{level}}/, '') if level > 0

      text = text.sub(/\A\s*\n?/, "\n".freeze) if indent_next
      text = text.gsub("\n".freeze, indent)

      safe ? text.html_safe : text
    end
  end
end
