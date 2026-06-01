# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'hexapdf/font/type1/font_metrics'
require 'hexapdf/error'

module HexaPDF
  module Font
    module Type1

      # Parses files in the AFM file format.
      #
      # Note that this implementation isn't a full AFM parser, only what is needed for parsing the
      # AFM files for the 14 PDF core fonts is implemented. However, if need be it should be
      # adaptable to other AFM files.
      #
      # For information on the AFM file format have a look at Adobe technical note #5004 - Adobe
      # Font Metrics File Format Specification Version 4.1, available at the Adobe website.
      #
      # == How Parsing Works
      #
      # AFM is a line oriented format. Each line consists of one or more values of supported types
      # (string, name, number, integer, array, boolean) which are separated by whitespace characters
      # (space, newline, tab) except for the string type which just uses everything until the end of
      # the line.
      #
      # This parser reads in line by line and the type parsing functions parse a value from the
      # front of the line and then remove the parsed part from the line, including trailing
      # whitespace characters.
      class AFMParser

        # :call-seq:
        #   Parser.parse(filename)       -> font_metrics
        #   Parser.parse(io)             -> font_metrics
        #
        # Parses the IO or file and returns a FontMetrics object.
        def self.parse(source)
          if source.respond_to?(:read)
            new(source).parse
          else
            File.open(source) {|file| new(file).parse }
          end
        end

        # Creates a new parse for the given IO stream.
        def initialize(io)
          @io = io
        end

        # Parses the AFM file and returns a FontMetrics object.
        def parse
          @metrics = FontMetrics.new
          sections = []
          each_line do
            case (command = parse_name)
            when /\AStart/
              sections.push(command)
              case command
              when 'StartCharMetrics' then parse_character_metrics
              when 'StartKernPairs' then parse_kerning_pairs
              end
            when /\AEnd/
              sections.pop
              break if sections.empty? && command == 'EndFontMetrics'
            else
              if sections.empty?
                parse_global_font_information(command.to_sym)
              end
            end
          end

          if @metrics.bounding_box && !@metrics.descender
            @metrics.descender = @metrics.bounding_box[1]
          end
          if @metrics.bounding_box && !@metrics.ascender
            @metrics.ascender = @metrics.bounding_box[3]
          end

          @metrics
        end

        private

        # Parses global font information line for the given +command+ (a symbol).
        #
        # It is assumed that the command name has already been parsed from the line.
        #
        # Note that writing direction metrics are also processed here since the standard 14 core
        # fonts' AFM files don't have an extra StartDirection section.
        def parse_global_font_information(command)
          case command
          when :FontName then @metrics.font_name = parse_string
          when :FullName then @metrics.full_name = parse_string
          when :FamilyName then @metrics.family_name = parse_string
          when :CharacterSet then @metrics.character_set = parse_string
          when :EncodingScheme then @metrics.encoding_scheme = parse_string
          when :Weight then @metrics.weight = parse_string
          when :FontBBox
            @metrics.bounding_box = [parse_number, parse_number, parse_number, parse_number]
          when :CapHeight then @metrics.cap_height = parse_number
          when :XHeight then @metrics.x_height = parse_number
          when :Ascender then @metrics.ascender = parse_number
          when :Descender then @metrics.descender = parse_number
          when :StdHW then @metrics.dominant_horizontal_stem_width = parse_number
          when :StdVW then @metrics.dominant_vertical_stem_width = parse_number
          when :UnderlinePosition then @metrics.underline_position = parse_number
          when :UnderlineThickness then @metrics.underline_thickness = parse_number
          when :ItalicAngle then @metrics.italic_angle = parse_number
          when :IsFixedPitch then @metrics.is_fixed_pitch = parse_boolean
          end
        end

        # Parses the character metrics in a StartCharMetrics section.
        #
        # It is assumed that the StartCharMetrics name has already been parsed from the line.
        def parse_character_metrics
          parse_integer.times do
            read_line
            char = CharacterMetrics.new
            if @line =~ /C (\S+) ; WX (\S+) ; N (\S+) ; B (\S+) (\S+) (\S+) (\S+) ;((?: L \S+ \S+ ;)+)?/
              char.code = $1.to_i
              char.width = $2.to_f
              char.name = $3.to_sym
              char.bbox = [$4.to_i, $5.to_i, $6.to_i, $7.to_i]
              if $8
                @metrics.ligature_pairs[char.name] = {}
                $8.scan(/L (\S+) (\S+)/).each do |name, ligature|
                  @metrics.ligature_pairs[char.name][name.to_sym] = ligature.to_sym
                end
              end
            end
            @metrics.character_metrics[char.name] = char if char.name
            @metrics.character_metrics[char.code] = char if char.code != -1
          end
        end

        # Parses the kerning pairs in a StartKernPairs section.
        #
        # It is assumed that the StartKernPairs name has already been parsed from the line.
        def parse_kerning_pairs
          parse_integer.times do
            read_line
            if @line =~ /KPX (\S+) (\S+) (\S+)/
              (@metrics.kerning_pairs[$1.to_sym] ||= {})[$2.to_sym] = $3.to_i
            end
          end
        end

        # Iterates over all the lines in the IO, yielding every time a line has been read into the
        # internal buffer.
        def each_line
          read_line
          unless parse_name == 'StartFontMetrics'
            raise HexaPDF::Error, "The AFM file has to start with StartFontMetrics, not #{@line}"
          end
          until @io.eof?
            read_line
            yield
          end
        end

        # Reads the next line into the current line variable.
        def read_line
          @line = @io.readline
        end

        # Parses and returns the name at the start of the line, with whitespace stripped.
        def parse_name
          result = @line[/\S+\s*/].to_s
          @line[0, result.size] = ''
          result.strip!
          result
        end

        # Returns the rest of the line, with whitespace stripped.
        def parse_string
          @line.strip!
          line = @line
          @line = ''
          line
        end

        # Parses the integer at the start of the line.
        def parse_integer
          parse_name.to_i
        end

        # Parses the float number at the start of the line.
        def parse_number
          parse_name.to_f
        end

        # Parses the boolean at the start of the line.
        def parse_boolean
          parse_name == 'true'
        end

      end

    end
  end
end
