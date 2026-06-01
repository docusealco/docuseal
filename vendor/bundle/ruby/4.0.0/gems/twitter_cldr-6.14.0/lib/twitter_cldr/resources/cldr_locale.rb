# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'

module TwitterCldr
  module Resources

    class CldrLocale
      attr_reader :base_locale, :cldr_requirement

      def initialize(base_locale, cldr_requirement)
        @base_locale = base_locale
        @cldr_requirement = cldr_requirement
      end

      def ancestors
        @ancestors ||= [].tap do |ancestry|
          locale = from_fs(base_locale)
          ancestry << locale

          loop do
            cur = from_fs(ancestry.last)

            if parents = parent_locales[cur]
              ancestry << to_fs(parents)
            elsif I18n::Locale::Tag.tag(cur).self_and_parents.count > 1
              ancestry << I18n::Locale::Tag.tag(cur).self_and_parents.last.to_sym
            else
              parents = TwitterCldr::Shared::Locale
                .parse(cur)
                .permutations

              ancestry.concat(parents - [cur])
              break
            end
          end

          ancestry.select! do |locale|
            File.exist?(File.join(cldr_requirement.common_path, 'main', "#{from_fs(locale)}.xml"))
          end

          ancestry << "root"
          ancestry.freeze
        end
      end

      private

      def to_fs(locale)
        locale.to_s.gsub('_', '-').to_sym
      end

      def from_fs(locale)
        locale.to_s.gsub('-', '_')
      end

      def parent_locales
        @parent_locales ||= supplemental_data.xpath('//parentLocales/parentLocale').each_with_object({}) do |node, ret|
          parent = node.attr('parent')
          locales = node.attr('locales').split(' ')

          locales.each do |locale|
            ret[locale] = parent
          end
        end
      end

      def supplemental_data
        @supplemental_data ||= Nokogiri.XML(
          File.read(File.join(cldr_requirement.common_path, 'supplemental', 'supplementalData.xml'))
        )
      end
    end

  end
end
