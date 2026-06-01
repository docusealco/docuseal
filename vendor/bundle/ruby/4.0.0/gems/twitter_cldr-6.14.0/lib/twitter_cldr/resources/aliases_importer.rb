# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'nokogiri'

module TwitterCldr
  module Resources

    class AliasesImporter < Importer
      # only these aliases will be imported
      ALIAS_TAGS = %w(languageAlias territoryAlias zoneAlias)

      requirement :cldr, Versions.cldr_version
      output_path 'shared/'
      ruby_engine :mri

      def execute
        output_file = File.join(output_path, 'aliases.yml')
        FileUtils.mkdir_p(output_path)

        File.open(output_file, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(aliases: aliases),
              use_natural_symbols: true
            )
          )
        end
      end

      private

      def aliases
        ALIAS_TAGS.inject({}) do |ret, alias_tag|
          ret[alias_tag.sub('Alias', '')] = alias_for(alias_tag)
          ret
        end
      end

      def alias_for(alias_tag)
        doc.xpath("//alias/#{alias_tag}").inject({}) do |ret, alias_data|
          if replacement_attr = alias_data.attribute('replacement')
            replacement = replacement_attr.value

            if replacement.include?(' ')
              replacement = replacement.split(' ')
            end

            type = alias_data.attribute('type').value
            reason = alias_data.attribute('reason').value

            ret[reason] ||= {}
            ret[reason][type] = replacement
          end

          ret
        end
      end

      def doc
        @doc ||= Nokogiri.XML(File.read(supplemental_metadata_path))
      end

      def supplemental_metadata_path
        File.join(
          requirements[:cldr].common_path,
          'supplemental',
          'supplementalMetadata.xml'
        )
      end

      def output_path
        params.fetch(:output_path)
      end
    end

  end
end
