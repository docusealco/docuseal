# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    class UnicodeDataImporter < Importer

      BLOCKS_FILE           = 'ucd/Blocks.txt'
      UNICODE_DATA_FILE     = 'ucd/UnicodeData.txt'
      CASEFOLDING_DATA_FILE = 'ucd/CaseFolding.txt'

      requirement :unicode, Versions.unicode_version, [BLOCKS_FILE, UNICODE_DATA_FILE, CASEFOLDING_DATA_FILE]
      output_path 'unicode_data'
      ruby_engine :mri

      def execute
        blocks           = import_blocks
        unicode_data     = import_unicode_data(blocks)
        casefolding_data = import_casefolding_data

        STDOUT.write('Writing data to disk... ')

        FileUtils.mkdir_p(output_path)

        File.open(File.join(output_path, 'blocks.yml'), 'w') do |output|
          YAML.dump(blocks, output)
        end

        FileUtils.mkdir_p(File.join(output_path, 'blocks'))

        unicode_data.each do |block_name, code_points|
          File.open(File.join(output_path, 'blocks', "#{block_name}.yml"), 'w') do |output|
            YAML.dump(code_points, output)
          end
        end

        File.open(File.join(output_path, 'casefolding.yml'), 'w') do |output|
          YAML.dump(casefolding_data, output)
        end

        puts 'done'
      end

      private

      def output_path
        params.fetch(:output_path)
      end

      def import_blocks
        STDOUT.write('Importing blocks... ')
        blocks = {}

        File.open(blocks_file) do |input|
          input.each_line do |line|
            next unless line =~ /^([0-9A-F]+)\.\.([0-9A-F]+);(.+)$/

            range = ($1.hex..$2.hex)
            name  = block_name($3)

            blocks[name.to_sym] = range
          end
        end

        puts 'done'
        blocks
      end

      def parse_file(file, &block)
        UnicodeFileParser.parse_standard_file(file, &block)
      end

      def import_unicode_data(blocks)
        STDOUT.write('Importing Unicode data... ')
        unicode_data = Hash.new do |hash, key|
          hash[key] = Hash.new { |h, k| h[k] = {} }
        end

        parse_file(unicode_data_file) do |data|
          data[0] = data[0].hex
          unicode_data[find_block(blocks, data[0]).first][data[0]] = data
        end

        puts 'done'
        unicode_data
      end

      def import_casefolding_data
        STDOUT.write('Importing casefolding data... ')

        casefolding_data = parse_file(casefold_data_file).map do |data|
          {
            source: data[0].hex,
            target: data[2].split(" ").map(&:hex),
            status: data[1]
          }
        end

        puts 'done'
        casefolding_data
      end

      def casefold_data_file
        requirements[:unicode].source_path_for(CASEFOLDING_DATA_FILE)
      end

      def unicode_data_file
        requirements[:unicode].source_path_for(UNICODE_DATA_FILE)
      end

      def blocks_file
        requirements[:unicode].source_path_for(BLOCKS_FILE)
      end

      def find_block(blocks, code_point)
        blocks.detect { |_, range| range.include?(code_point) }
      end

      def block_name(string)
        string.strip.downcase.gsub(/[\s-]/, '_')
      end

    end

  end
end
