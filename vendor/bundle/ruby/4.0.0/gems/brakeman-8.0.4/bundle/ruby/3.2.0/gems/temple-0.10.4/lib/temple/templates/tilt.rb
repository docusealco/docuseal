# frozen_string_literal: true
require 'tilt'

module Temple
  module Templates
    class Tilt < ::Tilt::Template
      extend Mixins::Template

      define_options mime_type: 'text/html'

      # Prepare Temple template
      #
      # Called immediately after template data is loaded.
      #
      # @return [void]
      def prepare
        opts = {}.update(self.class.options).update(options).update(file: eval_file)
        metadata[:mime_type] = opts.delete(:mime_type)
        if opts.include?(:outvar)
          opts[:buffer] = opts.delete(:outvar)
          opts[:save_buffer] = true
        end
        @src = self.class.compile(data, opts)
      end

      # A string containing the (Ruby) source code for the template.
      #
      # @param [Hash]   locals Local variables
      # @return [String] Compiled template ruby code
      def precompiled_template(locals = {})
        @src
      end

      def self.register_as(*names)
        ::Tilt.register(self, *names.map(&:to_s))
      end
    end
  end
end
