# frozen_string_literal: true
module Temple
  module Templates
    class Rails
      extend Mixins::Template

      def call(template, source = nil)
        opts = {}.update(self.class.options).update(file: template.identifier)
        if ActionView::Base.try(:annotate_rendered_view_with_filenames) && template.format == :html
          opts[:preamble] = "<!-- BEGIN #{template.short_identifier} -->\n"
          opts[:postamble] = "<!-- END #{template.short_identifier} -->\n"
        end
        self.class.compile((source || template.source), opts)
      end

      def supports_streaming?
        self.class.options[:streaming]
      end

      def self.register_as(*names)
        raise 'Rails is not loaded - Temple::Templates::Rails cannot be used' unless defined?(::ActionView)
        if ::ActiveSupport::VERSION::MAJOR < 5
          raise "Temple supports only Rails 5 and greater, your Rails version is #{::ActiveSupport::VERSION::STRING}"
        end
        names.each do |name|
          ::ActionView::Template.register_template_handler name.to_sym, new
        end
      end
    end
  end
end
