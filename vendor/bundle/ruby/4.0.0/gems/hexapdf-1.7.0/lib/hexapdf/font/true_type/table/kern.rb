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

require 'hexapdf/font/true_type/table'

module HexaPDF
  module Font
    module TrueType
      class Table

        # The 'kern' table contains kerning values, i.e. values to control inter-character spacing.
        #
        # Restrictions:
        #
        # * Only subtable format 0 is supported, all other subtables are ignored.
        #
        # See: https://www.microsoft.com/typography/otspec/kern.htm
        class Kern < Table

          # A kerning subtable containing the actual information to do kerning.
          class Subtable

            # Creates a new subtable.
            def initialize(pairs:, horizontal:, minimum_values:, cross_stream:)
              @pairs = pairs
              @horizontal = horizontal
              @minimum_values = minimum_values
              @cross_stream = cross_stream
            end

            # Returns the kerning value between the two glyphs, or +nil+ if there is no kerning
            # value.
            def kern(left, right)
              @pairs.fetch(left, nil)&.fetch(right, nil)
            end

            # Returns +true+ if this subtable is used for horizontal kerning.
            def horizontal?
              @horizontal
            end

            # Returns +true+ if this subtable contains minimum values and not kerning values.
            def minimum_values?
              @minimum_values
            end

            # Returns +true+ if this subtable contains cross-stream values, i.e. values that are
            # applied perpendicular to the writing direction.
            def cross_stream?
              @cross_stream
            end

          end

          # The version of the table.
          attr_accessor :version

          # The available subtables, all instances of Subtable.
          attr_reader :subtables

          # Returns the first subtable that supports horizontal non-cross-stream kerning, or +nil+
          # if no such subtable exists.
          def horizontal_kerning_subtable
            @horizontal_kerning_subtable
          end

          private

          def parse_table #:nodoc:
            @version, nr_of_subtables = read_formatted(4, 'nn')
            subtable_parsing_method = :parse_subtable0
            if @version == 1
              @version = Rational(@version << 16 + nr_of_subtables, 65536)
              nr_of_subtables = read_formatted(4, 'N').first
              subtable_parsing_method = :parse_subtable1
            end

            @subtables = []
            send(subtable_parsing_method, nr_of_subtables) do |length, format, options|
              if format == 0
                pairs = Format0.parse(io, length)
                @subtables << Subtable.new(pairs: pairs, **options)
              elsif font.config['font.true_type.unknown_format'] == :raise
                raise HexaPDF::Error, "Unsupported kern subtable format: #{format}"
              else
                io.pos += length
              end
            end
            @horizontal_kerning_subtable = @subtables.find do |t|
              t.horizontal? && !t.minimum_values? && !t.cross_stream?
            end
          end

          # Parses subtables for kern table version 0.
          def parse_subtable0(nr_of_subtables)
            nr_of_subtables.times do
              length, format, coverage = read_formatted(6, 'x2nCC')
              options = {horizontal: (coverage[0] == 1),
                         minimum_values: (coverage[1] == 1),
                         cross_stream: (coverage[2] == 1)}
              yield(length - 6, format, options)
            end
          end

          # Parses subtables for kern table version 1.
          def parse_subtable1(nr_of_subtables)
            nr_of_subtables.times do
              length, coverage, format = read_formatted(8, 'NCC')
              options = {horizontal: (coverage[7] == 0),
                         minimum_values: false,
                         cross_stream: (coverage[6] == 1)}
              yield(length - 8, format, options)
            end
          end

          # 'kern' subtable format 0
          module Format0

            # :call-seq:
            #   Format0.parse(io, length)    -> pairs
            #
            # Parses the format 0 subtable and returns a hash of the form
            #   {left_char: {right_char: kern_value}}
            def self.parse(io, _length)
              number_of_pairs = io.read(8).unpack1('n')
              pairs = Hash.new {|h, k| h[k] = {} }
              io.read(number_of_pairs * 6).unpack('n*').each_slice(3) do |left, right, value|
                pairs[left][right] = (value < 0x8000 ? value : -(value ^ 0xffff) - 1)
              end
              pairs
            end

          end

        end

      end
    end
  end
end
