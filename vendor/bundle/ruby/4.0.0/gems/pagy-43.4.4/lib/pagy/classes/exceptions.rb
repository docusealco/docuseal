# frozen_string_literal: true

class Pagy
  # Generic option error
  class OptionError < ArgumentError
    attr_reader :pagy, :option, :value

    # Set the options and prepare the message
    def initialize(pagy, option, description, value)
      @pagy   = pagy
      @option = option
      @value  = value

      super("expected :#{@option} #{description}; got #{@value.inspect}")
    end
  end

  # Specific range error
  class RangeError < OptionError; end

  # I18n localization error
  class RailsI18nLoadError < LoadError; end

  # Generic internal error
  class InternalError < StandardError; end
end
