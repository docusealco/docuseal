# frozen_string_literal: true

class Pagy
  # Add configuration methods
  module Configurable
    # Deprecated: Sync the pagy javascript targets. Use sync(:javascripts, ...) instead.
    def sync_javascript(...)
      warn "[PAGY] 'Pagy.sync_javascript(...)' is deprecated: use 'Pagy.sync(:javascript, ...)' instead."
      sync(:javascript, ...)
    end

    # Sync the pagy resource targets.
    def sync(resource, destination, *targets)
      files    = ROOT.join("#{resource}s").glob("{#{targets.join(',')}}")
      unknownn = targets - files.map { |f| f.basename.to_s }
      raise InternalError, "Resource not known: #{unknownn.join(', ')}" if unknownn.any?

      FileUtils.cp(files, destination)
    end

    # Generate the script and style tags to help development
    def dev_tools(wand_scale: 1)
      <<~HTML
        <script id="pagy-ai-widget">
          #{ROOT.join('javascripts/ai_widget.js').read}
        </script>
        <script id="pagy-wand" data-scale="#{wand_scale}">
          #{ROOT.join('javascripts/wand.js').read}
        </script>
        <style id="pagy-wand-default">
          #{ROOT.join('stylesheets/pagy.css').read}
        </style>
      HTML
    end

    # Setup pagy for using the i18n gem
    def translate_with_the_slower_i18n_gem!
      send(:remove_const, :I18n)
      send(:const_set, :I18n, ::I18n)
      ::I18n.load_path += Dir[ROOT.join('locales/*.yml')]
    end
  end
end
