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

require 'hexapdf/data_dir'

module HexaPDF
  module Font
    module Encoding

      # Provides access to and mapping functionality for the Adobe Glyph List.
      #
      # The Adobe Glyph List is used for mapping glyph names to Unicode values. The mapping itself
      # is not a one-to-one mapping because some glyphs are mapped to the same Unicode sequence,
      # e.g. the glyph name for 'A' and the glyph name for 'small capital A'.
      #
      # Since a reverse mapping is needed for converting UTF-8 strings to glyph names when encoding
      # text, this (not unique) reverse mapping is also available. However, only the first occurence
      # of a particular Unicode string is reverse-mapped.
      #
      # See:
      # * https://github.com/adobe-type-tools/agl-aglfn
      # * https://github.com/adobe-type-tools/agl-specification
      class GlyphList

        # Creates and returns the single GlyphList instance.
        def self.new
          @instance ||= super
        end

        # See #name_to_unicode
        def self.name_to_unicode(name, zapf_dingbats: false)
          new.name_to_unicode(name, zapf_dingbats: zapf_dingbats)
        end

        # See #unicode_to_name
        def self.unicode_to_name(unicode, zapf_dingbats: false)
          new.unicode_to_name(unicode, zapf_dingbats: zapf_dingbats)
        end

        def initialize #:nodoc:
          load
        end

        # Maps the given name to a string by following the Adobe Glyph Specification. Returns +nil+
        # if the name has no correct mapping.
        #
        # If this method is invoked when dealing with the ZapfDingbats font, the +zapf_dingbats+
        # option needs to be set to +true+.
        #
        # Assumes that the name is a Symbol and that it includes just one component (no
        # underscores)!
        def name_to_unicode(name, zapf_dingbats: false)
          if zapf_dingbats && @zapf_name_to_uni.key?(name)
            @zapf_name_to_uni[name]
          elsif @standard_name_to_uni.key?(name)
            @standard_name_to_uni[name]
          else
            name = name.to_s
            if name =~ /\Auni([0-9A-F]{4})\Z/ || name =~ /\Au([0-9A-F]{4,6})\Z/
              +'' << $1.hex
            end
          end
        end

        # Maps the given Unicode codepoint/string to a name in the Adobe Glyph List, or to .notdef
        # if there is no mapping.
        #
        # If this method is invoked when dealing with the ZapfDingbats font, the +zapf_dingbats+
        # option needs to be set to +true+.
        def unicode_to_name(unicode, zapf_dingbats: false)
          if zapf_dingbats
            @zapf_uni_to_name.fetch(unicode, :'.notdef')
          else
            @standard_uni_to_name.fetch(unicode, :'.notdef')
          end
        end

        private

        # Loads the needed Adobe Glyph List files.
        def load
          @standard_name_to_uni, @standard_uni_to_name =
            load_file(File.join(HexaPDF.data_dir, 'encoding', 'glyphlist.txt'))
          @zapf_name_to_uni, @zapf_uni_to_name =
            load_file(File.join(HexaPDF.data_dir, 'encoding', 'zapfdingbats.txt'))
        end

        # Loads an Adobe Glyph List from the specified file and returns the name-to-unicode and
        # unicode-to-name mappings.
        #
        # Regarding the mappings:
        #
        # * The name-to-unicode mapping maps a name (Symbol) to an UTF-8 string consisting of one or
        #   more characters.
        #
        # * The unicode-to-name mapping is *not* unique! It only uses the first occurence of a
        #   Unicode sequence.
        def load_file(file)
          name2uni = {}
          uni2name = {}
          File.open(file, 'rb:UTF-8') do |f|
            25.times { f.gets } # Skip comments
            while (line = f.gets)
              name, codes = line.split(';', 2)
              name = name.to_sym
              name2uni[name] = codes.chomp!
              uni2name[codes] = name unless uni2name.key?(codes)
            end
          end
          [name2uni.freeze, uni2name.freeze]
        end

      end

    end
  end
end
