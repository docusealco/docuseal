module MultiXML
  # Helpers for normalizing the options hash passed to {MultiXML.parse}
  #
  # Lives in its own module (rather than inside {ParseSupport}, which is
  # mixed into MultiXML's singleton class) so ``self`` inside these
  # methods is ``OptionsNormalization`` rather than ``MultiXML``. That
  # separation is what lets mutation testing distinguish
  # ``MultiXML.warn_deprecation_once(...)`` from
  # ``self.warn_deprecation_once(...)``.
  #
  # @api private
  module OptionsNormalization
    # Translate the deprecated ``:symbolize_keys`` option to ``:symbolize_names``
    #
    # Matches Ruby stdlib's ``JSON.parse`` and sister library MultiJSON
    # naming. Emits a one-time deprecation warning on first encounter
    # of ``:symbolize_keys``. When both names appear together (unusual
    # — only possible if the caller explicitly set both), the canonical
    # ``:symbolize_names`` value wins and ``:symbolize_keys`` is
    # silently dropped.
    #
    # @api private
    # @param options [Hash] options layer to normalize
    # @return [Hash] hash with ``:symbolize_keys`` translated, or the
    #   original hash when no translation is needed
    # @example
    #   MultiXML::OptionsNormalization.normalize_symbolize_option(symbolize_keys: true)
    def self.normalize_symbolize_option(options)
      return options unless options.key?(:symbolize_keys)

      MultiXML.warn_deprecation_once(:symbolize_keys_option,
        "The :symbolize_keys option is deprecated and will be removed in v1.0. Use :symbolize_names instead.")

      new_opts = options.dup
      legacy_value = new_opts.delete(:symbolize_keys)
      new_opts[:symbolize_names] = legacy_value unless new_opts.key?(:symbolize_names)
      new_opts
    end
  end
end
