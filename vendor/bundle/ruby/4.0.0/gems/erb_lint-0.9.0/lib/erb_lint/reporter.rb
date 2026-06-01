# frozen_string_literal: true

require "active_support/core_ext/class"
require "active_support/core_ext/module/delegation"

module ERBLint
  class Reporter
    def self.create_reporter(format, *args)
      reporter_klass = "#{ERBLint::Reporters}::#{format.to_s.camelize}Reporter".constantize
      reporter_klass.new(*args)
    end

    def self.available_format?(format)
      available_formats.include?(format.to_s)
    end

    def self.available_formats
      descendants
        .map(&:to_s)
        .map(&:demodulize)
        .map(&:underscore)
        .map { |klass_name| klass_name.sub("_reporter", "") }
        .sort
    end

    def initialize(stats, autocorrect, show_linter_names = false)
      @stats = stats
      @autocorrect = autocorrect
      @show_linter_names = show_linter_names
    end

    def preview; end

    def show; end

    private

    attr_reader :stats, :autocorrect, :show_linter_names

    delegate :processed_files, to: :stats
  end
end
