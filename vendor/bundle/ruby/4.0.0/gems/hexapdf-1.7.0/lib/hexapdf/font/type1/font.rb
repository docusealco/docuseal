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

require 'forwardable'
require 'set'
require 'hexapdf/font/type1'
require 'hexapdf/font/encoding'

module HexaPDF
  module Font
    module Type1

      # Represents a Type1 font.
      #
      # This class abstracts from the specifics of the Type1 font and allows working with it in a
      # standardized way.
      #
      # The following method calls are forwarded to the contained FontMetrics object:
      #
      # * font_name
      # * full_name
      # * family_name
      # * weight
      # * weight_class
      # * font_bbox
      # * italic_angle
      # * ascender
      # * descender
      # * cap_height
      # * x_height
      # * horizontal_dominant_width
      # * vertical_dominant_width
      class Font

        extend Forwardable

        # Creates a Type1 font object from an AFM source.
        def self.from_afm(source)
          new(AFMParser.parse(source))
        end

        # The associated FontMetrics object.
        attr_reader :metrics

        def_delegators :@metrics, :font_name, :full_name, :family_name
        def_delegators :@metrics, :weight, :weight_class, :bounding_box, :italic_angle
        def_delegators :@metrics, :ascender, :descender, :cap_height, :x_height
        def_delegators :@metrics, :dominant_horizontal_stem_width, :dominant_vertical_stem_width
        def_delegators :@metrics, :underline_thickness

        # Creates a new Type1 font object with the given font metrics.
        def initialize(metrics)
          @metrics = metrics
        end

        # Returns the built-in encoding of the font.
        def encoding
          @encoding ||=
            if @metrics.encoding_scheme == 'AdobeStandardEncoding'
              Encoding.for_name(:StandardEncoding)
            elsif font_name == 'ZapfDingbats' || font_name == 'Symbol'
              Encoding.for_name(:"#{font_name}Encoding")
            else
              encoding = Encoding::Base.new
              @metrics.character_metrics.each do |key, char_metric|
                next unless key.kind_of?(Integer) && key >= 0
                encoding.code_to_name[key] = char_metric.name
              end
              encoding
            end
        end

        # :call-seq:
        #   font.width(glyph_name)        ->  width or nil
        #   font.width(glyph_code)        ->  width or nil
        #
        # Returns the width of the glyph which can either be specified by glyph name or by an
        # integer that is interpreted according to the built-in encoding.
        #
        # If there is no glyph found for the name or code, +nil+ is returned.
        def width(glyph)
          (metric = @metrics.character_metrics[glyph]) && metric.width
        end

        # Returns the name/id of the missing glyph, i.e. .notdef.
        def missing_glyph_id
          :'.notdef'
        end

        # Returns a set of features this font supports.
        #
        # For Type1 fonts, the features that may be available :kern and :liga.
        def features
          @features ||= Set.new.tap do |set|
            set << :kern unless metrics.kerning_pairs.empty?
            set << :liga unless metrics.ligature_pairs.empty?
          end
        end

        # Returns the distance from the baseline to the top of the underline.
        def underline_position
          @metrics.underline_position + @metrics.underline_thickness / 2.0
        end

        # Returns the distance from the baseline to the top of the strikeout line.
        def strikeout_position
          # We use the suggested value from the OpenType spec.
          225
        end

        # Returns the thickness of the strikeout line.
        def strikeout_thickness
          # The OpenType spec suggests the width of an em-dash or 50, so we use that as
          # approximation since the AFM files don't contain this information.
          if (bbox = @metrics.character_metrics[:emdash]&.bbox)
            bbox[3] - bbox[1]
          else
            50
          end
        end

      end

    end
  end
end
