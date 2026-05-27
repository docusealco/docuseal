# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'

module TwitterCldr
  module Resources
    class CollationTriesImporter < Importer

      AUXILIARY_ZIP_FILE = 'CollationAuxiliary.zip'.freeze
      FRACTIONAL_UCA_FILE = 'FractionalUCA_SHORT.txt'.freeze

      FRACTIONAL_UCA_SHORT_CUSTOMIZATION_HEADER = <<~END.freeze
        # Three custom changes are made in this file:
        #
        #   * Lines like '006C | 00B7; [, DB A9, 05]' are unfolded into the full
        #     form - '006C 00B7; [3D, 05, 05][, DB A9, 05]' (in this example,
        #     [3D, 05, 05] is a collation element for 0x006C). Note: This might
        #     break if tailoring is applied to 0x006C because with this rule
        #     unfolded collation element for '006C 00B7' won't be automatically
        #     updated when a collation element for 0x006C is changed.
        #
        #   * SPECIAL FINAL VALUES are commented, because they are unnecessary for
        #     the current implementation and are breaking some UCA tests.

      END

      FRACTIONAL_UCA_SHORT_CUSTOMIZATIONS = {
        '006C | 00B7; [, DB A9, 05]' => '006C 00B7; [3D, 05, 05][, DB A9, 05]',
        '006C | 0387; [, DB A9, 05]' => '006C 0387; [3D, 05, 05][, DB A9, 05]',
        '004C | 00B7; [, DB A9, 05]' => '004C 00B7; [3D, 05, 8F][, DB A9, 05]',
        '004C | 0387; [, DB A9, 05]' => '004C 0387; [3D, 05, 8F][, DB A9, 05]',
      }

      requirement :cldr, '21'
      requirement :uca, '6.1.0', [AUXILIARY_ZIP_FILE]
      requirement :dependency, [TailoringImporter]
      locales TwitterCldr.supported_locales
      ruby_engine :jruby

      private

      def execute
        copy_fractional_uca
        update_default_trie_dump

        params.fetch(:locales).each do |locale|
          update_tailoring_trie_dump(locale)
        end
      end

      private

      def copy_fractional_uca
        zip_path = requirements[:uca].source_path_for(AUXILIARY_ZIP_FILE)
        base_output_path = File.join('resources', 'collation')
        FileUtils.mkdir_p(base_output_path)

        Zip::File.open(zip_path) do |zip|
          output_path = File.join(base_output_path, FRACTIONAL_UCA_FILE)

          File.open(output_path, 'w') do |file|
            fractional_uca_short = zip.read(File.join('CollationAuxiliary', FRACTIONAL_UCA_FILE))

            FRACTIONAL_UCA_SHORT_CUSTOMIZATIONS.each do |existing, replacement|
              fractional_uca_short.gsub!(existing, replacement)
            end

            fractional_uca_short = fractional_uca_short
              .split("\n")
              .map do |line|
                if line.end_with?('# Special final value for reordering token')
                  "##{line}"
                else
                  line
                end
              end
              .join("\n")

            fractional_uca_short = FRACTIONAL_UCA_SHORT_CUSTOMIZATION_HEADER + fractional_uca_short
            file.write(fractional_uca_short)
          end
        end
      end

      def update_default_trie_dump
        save_trie_dump(TwitterCldr::Collation::TrieLoader::DEFAULT_TRIE_LOCALE, default_trie)
      end

      def update_tailoring_trie_dump(locale)
        save_trie_dump(locale, TwitterCldr::Collation::TrieBuilder.load_tailored_trie(locale, default_trie))
      end

      def save_trie_dump(locale, trie)
        path = TwitterCldr::Collation::TrieLoader.dump_path(locale)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, Marshal.dump(trie))
      end

      def default_trie
        @default_trie ||= TwitterCldr::Collation::TrieBuilder.load_default_trie
      end
    end
  end
end
