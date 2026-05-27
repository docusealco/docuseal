# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    # This class should be used with JRuby in 1.9 mode

    class BidiTestImporter < Importer
      BIDI_TEST_FILE = 'ucd/BidiTest.txt'  # this file is about 3.4 MB
      OUT_FILE = 'classpath_bidi_test.txt'
      DIRECTIONS = [nil, :LTR, :RTL]

      requirement :unicode, '6.1.0', ['ucd/BidiTest.txt']
      output_path File.join(TwitterCldr::SPEC_DIR, 'bidi')
      ruby_engine :jruby

      def execute
        generate_test
      end

      private

      def before_prepare
        require 'java'
        java_import 'java.lang.Character'
        java_import 'classpath.Bidi'
      end

      def source_file
        requirements[:unicode].source_path_for(BIDI_TEST_FILE)
      end

      def output_file
        File.join(params.fetch(:output_path), File.basename(BIDI_TEST_FILE))
      end

      def generate_test
        run_hash = {}

        File.open(source_file, 'r').each_line do |ln|
          cur_line = ln.strip

          case cur_line[0]
            when '#', '@'
              next
            else
              input, bitset = cur_line.split('; ')

              expand_bitset_str(bitset).each_with_index do |check, index|
                if check
                  types = input.split(" ")
                  direction = get_java_direction(DIRECTIONS[index])
                  bidi = Java::Classpath::Bidi.new(types_to_string(types), direction)
                  levels = types.each_with_index.map { |_, idx| bidi.getLevelAt(idx) }
                  reorder_arr = Java::Classpath::Bidi.reorderVisually(levels.dup, 0, (0...types.size).to_a, 0, types.size).to_a

                  key = "#{levels.join(" ")} | #{reorder_arr.join(" ")}"
                  run_hash[key] ||= {}
                  run_hash[key][input] ||= 0
                  run_hash[key][input] |= (2 ** index)
                end
              end
          end
        end

        File.open(output_file, 'w+') do |out|
          run_hash.each_pair do |levels_and_reorders, inputs|
            levels, reorders = levels_and_reorders.split(' | ')
            out.write("@Levels: #{levels}\n")
            out.write("@Reorder: #{reorders}\n")
            inputs.each_pair do |input, bitset|
              out.write("#{input}; #{bitset}\n")
            end
          end
        end
      end

      def expand_bitset_str(bitset)
        bitset.to_i.to_s(2).rjust(3, '0').chars.to_a.map { |i| i == '1' }.reverse
      end

      def get_java_direction(dir)
        case dir
          when :RTL
            Java::Classpath::Bidi::DIRECTION_RIGHT_TO_LEFT
          when :LTR
            Java::Classpath::Bidi::DIRECTION_LEFT_TO_RIGHT
          else
            Java::Classpath::Bidi::DIRECTION_DEFAULT_LEFT_TO_RIGHT
        end
      end

      def types_to_string(types)
        @utf_map ||= {
          'L'   => "\u0041",
          'LRE' => "\u202a",
          'LRO' => "\u202d",
          'R'   => "\u05be",
          'AL'  => "\u0626",
          'RLE' => "\u202b",
          'RLO' => "\u202e",
          'PDF' => "\u202c",
          'EN'  => "\u0030",
          'ET'  => "\u0023",
          'AN'  => "\u0667",
          'CS'  => "\u002c",
          'NSM' => "\u0300",
          'BN'  => "\u0000",
          'B'   => "\u0085",
          'S'   => "\u0009",
          'WS'  => "\u000c",
          'ON'  => "\u0021"
        }

        # java 1.6 and 1.7 report different representative characters for the "ES" bidi class
        @utf_map['ES'] = (Character.getDirectionality(0x002b) == Character::DIRECTIONALITY_EUROPEAN_NUMBER_SEPARATOR) ? "\u002b" : "\u002f"
        types.inject('') { |ret, type| ret << @utf_map[type]; ret }
      end

    end
  end
end
