# frozen_string_literal: true

module ERBLint
  class Corrector
    attr_reader :processed_source, :offenses, :corrected_content

    def initialize(processed_source, offenses)
      @processed_source = processed_source
      @offenses = offenses
      corrector = RuboCop::Cop::Corrector.new(@processed_source.source_buffer)
      correct!(corrector)
      @corrected_content = corrector.rewrite
    end

    def corrections
      @corrections ||= @offenses.map do |offense|
        offense.linter.autocorrect(@processed_source, offense) if offense.linter.class.support_autocorrect?
      end.compact
    end

    def correct!(corrector)
      corrections.each do |correction|
        correction.call(corrector)
      end
    end
  end
end
