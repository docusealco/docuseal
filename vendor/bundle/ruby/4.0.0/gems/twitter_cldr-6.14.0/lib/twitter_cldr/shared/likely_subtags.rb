# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class UnrecognizedSubtagsError < StandardError; end

    class LikelySubtags
      class << self
        def locale_for(locale_text)
          locale = Locale.parse(locale_text)
          lookup(locale)
        end

        private

        # http://unicode.org/reports/tr35/#Likely_Subtags
        #
        # Try each of the following in order (where the fields exist). The
        # notation field³ means field¹ if it exists, otherwise field².
        #
        # 1. Lookup language¹ _ script¹ _ region¹. If in the table, return the
        #    language² _ script² _ region² + variants.
        #
        # 2. Lookup language¹ _ script¹. If in the table, return language² _
        #    script² _ region³ + variants.
        #
        # 3. Lookup language¹ _ region¹. If in the table, return language² _
        #    script³ _ region² + variants.
        #
        # 4. Lookup language¹. If in the table, return language² _ script³ _
        #    region³ + variants.
        #
        # 5. Lookup und_script¹ and return if exists
        #
        def lookup(locale)
          first_lookup(locale) ||
            second_lookup(locale) ||
            third_lookup(locale) ||
            fourth_lookup(locale) ||
            fifth_lookup(locale) ||
            raise(
              UnrecognizedSubtagsError,
              "couldn't find matching subtags for #{locale}"
            )
        end

        def first_lookup(locale)
          if locale.language && locale.script && locale.region
            code = [locale.language, locale.abbreviated_script, locale.region].join('_')

            if replacement = subtags_resource[code.to_sym]
              language2, script2, region2 = Locale.split(replacement)
              Locale.new(language2, script2, region2, locale.variants)
            end
          end
        end

        def second_lookup(locale)
          if locale.language && locale.script
            code = [locale.language, locale.abbreviated_script].join('_')

            if replacement = subtags_resource[code.to_sym]
              language2, script2, region2 = Locale.split(replacement)
              Locale.new(
                language2, script2, locale.region || region2, locale.variants
              )
            end
          end
        end

        def third_lookup(locale)
          if locale.language && locale.region
            code = [locale.language, locale.region].join('_')

            if replacement = subtags_resource[code.to_sym]
              language2, script2, region2 = Locale.split(replacement)
              Locale.new(
                language2, locale.script || script2, region2, locale.variants
              )
            end
          end
        end

        def fourth_lookup(locale)
          if locale.language
            if replacement = subtags_resource[locale.language.to_sym]
              language2, script2, region2 = Locale.split(replacement)
              Locale.new(
                language2,
                locale.script || script2,
                locale.region || region2,
                locale.variants
              )
            end
          end
        end

        def fifth_lookup(locale)
          if locale.script
            code = ['und', locale.abbreviated_script].join('_')

            if replacement = subtags_resource[code.to_sym]
              Locale.parse(replacement)
            end
          end
        end

        def subtags_resource
          @subtags_resource ||=
            TwitterCldr.get_resource('shared', 'likely_subtags')[:subtags]
        end
      end
    end

  end
end
