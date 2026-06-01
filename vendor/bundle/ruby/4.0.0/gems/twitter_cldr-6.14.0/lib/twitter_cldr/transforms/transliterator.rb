# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    class Transliterator
      def self.transliterate(text, source_locale, target_locale)
        new(text, source_locale, target_locale).transliterate
      end

      attr_reader :text, :source_locale, :target_locale

      def initialize(text, source_locale, target_locale)
        @text = text
        @source_locale = locale_klass.parse(source_locale)
        @target_locale = locale_klass.parse(target_locale).maximize
      end

      def transliterate
        result = text.dup

        each_source_locale do |source_locale|
          transform_id = TransformId.find(source_locale, target_locale)

          if transform_id
            transformer = Transformer.get(transform_id)
            result = transformer.transform(result)
          end
        end

        result
      end

      private

      def locale_klass
        TwitterCldr::Shared::Locale
      end

      def each_source_locale
        if source_locale.script
          yield source_locale
        else
          scripts.each do |script|
            locale = locale_klass.new(
              source_locale.language, script, source_locale.region
            )

            yield locale.maximize
          end
        end
      end

      def scripts
        @scripts ||=
          TwitterCldr::Utils::ScriptDetector.detect_scripts(text).scripts
      end
    end
  end
end
