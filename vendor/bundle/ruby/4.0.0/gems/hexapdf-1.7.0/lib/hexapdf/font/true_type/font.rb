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
require 'hexapdf/font/true_type/builder'
require 'set'

module HexaPDF
  module Font
    module TrueType

      # Represents a font in the TrueType font file format.
      class Font

        # The default configuration:
        #
        # font.ttf.table_mapping::
        #     The default mapping from table tag as symbol to table class name.
        #
        # font.ttf.unknown_format::
        #     Action to take when encountering unknown subtables. Can either be :ignore
        #     which ignores them or :raise which raises an error.
        DEFAULT_CONFIG = {
          'font.true_type.table_mapping' => {
            head: 'HexaPDF::Font::TrueType::Table::Head',
            cmap: 'HexaPDF::Font::TrueType::Table::Cmap',
            hhea: 'HexaPDF::Font::TrueType::Table::Hhea',
            hmtx: 'HexaPDF::Font::TrueType::Table::Hmtx',
            loca: 'HexaPDF::Font::TrueType::Table::Loca',
            maxp: 'HexaPDF::Font::TrueType::Table::Maxp',
            name: 'HexaPDF::Font::TrueType::Table::Name',
            post: 'HexaPDF::Font::TrueType::Table::Post',
            glyf: 'HexaPDF::Font::TrueType::Table::Glyf',
            'OS/2': 'HexaPDF::Font::TrueType::Table::OS2',
            kern: 'HexaPDF::Font::TrueType::Table::Kern',
          },
          'font.true_type.unknown_format' => :ignore,
        }

        # The IO stream associated with this file.
        attr_reader :io

        # The configuration for the TrueType font.
        attr_reader :config

        # Creates a new TrueType font file object for the given IO object.
        #
        # The +config+ hash can contain configuration options.
        def initialize(io, config: {})
          @io = io
          @config = DEFAULT_CONFIG.merge(config)
          @tables = {}
        end

        # Uses Builder to build a font file for this font.
        #
        # The +table_overrides+ argument can be used to supply mappings from table names (in string
        # form) to raw table data that should override the respective font's tables.
        def build(table_overrides = {})
          tables = directory.table_names.each_with_object({}) do |name, hash|
            hash[name] = self[name.to_sym].raw_data
          end
          tables.merge!(table_overrides)
          Builder.build(tables)
        end

        # Returns the table instance for the given tag (a symbol), or +nil+ if no such table exists.
        def [](tag)
          return @tables[tag] if @tables.key?(tag)

          entry = directory.entry(tag.to_s.b)
          entry ? @tables[tag] = table_class(tag).new(self, entry) : nil
        end

        # Returns the font directory.
        def directory
          @directory ||= Table::Directory.new(self, io ? Table::Directory::SELF_ENTRY : nil)
        end

        # Returns a set of features this font supports.
        #
        # Features that may be available are for example :kern or :liga.
        def features
          @features ||= Set.new.tap do |set|
            set << :kern if self[:kern]&.horizontal_kerning_subtable
          end
        end

        # Returns the PostScript font name.
        def font_name
          self[:name][:postscript_name].preferred_record
        end

        # Returns the full name of the font.
        def full_name
          self[:name][:font_name].preferred_record
        end

        # Returns the family name of the font.
        def family_name
          self[:name][:font_family].preferred_record
        end

        # Returns the weight of the font.
        def weight
          self[:'OS/2'].weight_class || 0
        end

        # Returns the bounding of the font.
        def bounding_box
          self[:head].bbox
        end

        # Returns the cap height of the font.
        def cap_height
          self[:'OS/2'].cap_height
        end

        # Returns the x-height of the font.
        def x_height
          self[:'OS/2'].x_height
        end

        # Returns the ascender of the font.
        def ascender
          self[:'OS/2'].typo_ascender || self[:hhea].ascent
        end

        # Returns the descender of the font.
        def descender
          self[:'OS/2'].typo_descender || self[:hhea].descent
        end

        # Returns the italic angle of the font, in degrees counter-clockwise from the vertical.
        def italic_angle
          self[:post].italic_angle.to_f
        end

        # Returns the dominant width of vertical stems.
        #
        # Note: This attribute does not actually exist in TrueType fonts, so it is estimated based
        # on the #weight.
        def dominant_vertical_stem_width
          weight / 5
        end

        # Returns the distance from the baseline to the top of the underline.
        def underline_position
          self[:post].underline_position
        end

        # Returns the stroke width for the underline.
        def underline_thickness
          self[:post].underline_thickness
        end

        # Returns the distance from the baseline to the top of the strikeout line.
        def strikeout_position
          self[:'OS/2'].strikeout_position
        end

        # Returns the stroke width for the strikeout line.
        def strikeout_thickness
          self[:'OS/2'].strikeout_size
        end

        # Returns th glyph ID of the missing glyph, i.e. 0.
        def missing_glyph_id
          0
        end

        private

        # Returns the class that is used for handling tables of the given tag.
        def table_class(tag)
          k = config['font.true_type.table_mapping'].fetch(tag, 'HexaPDF::Font::TrueType::Table')
          ::Object.const_get(k)
        end

      end

    end
  end
end
