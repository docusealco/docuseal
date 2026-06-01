# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'nokogiri'

module TwitterCldr
  module Resources

    class TransformsImporter < Importer

      IGNORED_TRANSFORMS = [
        # This transform appears to be broken. Two of its rules that deal with separator
        # characters don't make sense to me:
        #
        # "[:Separator:]* > ' ';"
        # "$space = [:Separator:]*;"
        #
        # Why would zero characters be replaced with a space? And why would zero characters
        # be considered a separator?
        #
        # More importantly, the algorithm in this library works with every other transform,
        # provisional and otherwise, except this one. Something's amiss with these rules.
        # ICU probably works because they, once again, fixed the rules but neglected to
        # upstream them into CLDR.
        #
        { source: 'ug', target: 'Latin' }
      ]

      requirement :cldr, Versions.cldr_version
      output_path 'shared/transforms'
      ruby_engine :mri

      private

      def execute
        transform_id_map = {}

        FileUtils.mkdir_p(output_path)

        each_transform_file do |transform_file|
          transform_data =
            parse_transform_data(File.read(transform_file))
              .reject do |transform_datum|
                ignored_transform?(transform_datum)
              end

          next if transform_data.empty?

          output_file = File.join(output_path, "#{File.basename(transform_file).chomp('.xml')}.yml")
          transform_id_map.merge!(map_aliases(transform_data, output_file))
          write_transform_data(transform_data, output_file)
        end

        write_transform_id_map(transform_id_map)
      end

      def ignored_transform?(transform_data)
        IGNORED_TRANSFORMS.any? do |ignored_transform|
          ignored_transform[:source] == transform_data[:source] &&
            ignored_transform[:target] == transform_data[:target]
        end
      end

      def map_aliases(transform_data, path)
        filename = File.basename(path).chomp('.yml')

        aliases = transform_data.flat_map do |transform_datum|
          (transform_datum[:aliases] || []) + [
            join_transform_id(
              transform_datum[:source],
              transform_datum[:target],
              transform_datum[:variant]
            )
          ]
        end

        aliases.uniq.each_with_object({}) do |aliass, ret|
          ret[aliass] = filename
        end
      end

      def join_transform_id(source, target, variant)
        TwitterCldr::Transforms::TransformId.join(source, target, variant)
      end

      def normalize_transform_id(id_str)
        TwitterCldr::Transforms::TransformId.parse(id_str).to_s
      end

      def write_transform_data(transform_data, path)
        File.open(path, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(transforms: transform_data),
              use_natural_symbols: true
            )
          )
        end
      end

      def write_transform_id_map(transform_id_map)
        File.open(File.join(output_path, 'transform_id_map.yml'), 'w+') do |output|
          output.write(YAML.dump(transform_id_map))
        end
      end

      def parse_transform_data(transform_data)
        doc = Nokogiri.XML(transform_data)

        doc.xpath('supplementalData/transforms/transform').map do |transform_node|
          {
            source: transform_node.attribute('source').value,
            target: transform_node.attribute('target').value,
            aliases: get_aliases(transform_node),
            variant: get_variant(transform_node),
            direction: transform_node.attribute('direction').value,
            rules: rules(transform_node)
          }
        end
      end

      def get_aliases(node)
        if attrib = node.attribute('alias')
          attrib.value.split(' ')
        end
      end

      def get_variant(node)
        if attrib = node.attribute('variant')
          attrib.value
        end
      end

      def rules(transform_node)
        transform_node.xpath('tRule').flat_map do |rule_node|
          rule_node.content
            .split("\n")
            .reject { |line| line.start_with?('#') }
            .map { |line| line.sub(/#.*$/, '').strip }
            .join("\n")
            .split(/;$/)
            .map(&:strip)
            .reject(&:empty?)
            .map do |rule_text|
              "#{fix_rule(rule_text)} ;"
            end
        end
      end

      def fix_rule(rule)
        rule.
          gsub("←", '<').
          gsub("→", '>').
          gsub("↔", '<>').
          gsub("\n", " ")
      end

      def each_transform_file(&block)
        Dir.glob(File.join(transforms_path, '*.xml')).each(&block)
      end

      def transforms_path
        File.join(requirements[:cldr].common_path, 'transforms')
      end

      def output_path
        params.fetch(:output_path)
      end

    end

  end
end
