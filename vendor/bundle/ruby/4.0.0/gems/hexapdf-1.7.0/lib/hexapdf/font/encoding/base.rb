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

require 'hexapdf/font/encoding/glyph_list'

module HexaPDF
  module Font
    module Encoding

      # Base for encoding classes that are used for mapping codes in the range of 0 to 255 to glyph
      # names.
      class Base

        # The name of the encoding or +nil+ if the encoding has not been assigned a name.
        attr_reader :encoding_name

        # The hash mapping codes to names.
        attr_reader :code_to_name

        # Creates a new encoding object containing no default mappings.
        def initialize
          @code_to_name = {}
          @unicode_cache = {}
          @encoding_name = nil
        end

        # Returns the name for the given code, or .notdef if no glyph for the code is defined.
        #
        # The returned value is always a Symbol object!
        def name(code)
          @code_to_name.fetch(code, :'.notdef')
        end

        # Returns the Unicode value in UTF-8 for the given code, or +nil+ if the code cannot be
        # mapped.
        #
        # Note that this method caches the result of the Unicode mapping and therefore should only
        # be called after all codes have been defined.
        def unicode(code)
          @unicode_cache[code] ||= GlyphList.name_to_unicode(name(code))
        end

        # Returns the code for the given glyph name (a Symbol) or +nil+ if there is no code for the
        # given glyph name.
        #
        # If multiple codes reference the given glyph name, the first found is always returned.
        def code(name)
          @code_to_name.key(name)
        end

        # Returns the encoding in a compact array form.
        #
        # If the optional +base_encoding+ argument is specified, all codes that have the same value
        # in the base encoding are ignored.
        #
        # The returned array is of the form:
        #
        #   code1 name1 name2 ... code2 name3 name4 ...
        #
        # This means that name1 is associated with code1, name2 with code1 + 1 and so on.
        #
        # See: PDF 2.0 s9.6.5.1
        def to_compact_array(base_encoding: nil)
          result = []
          last_code = -3
          @code_to_name.sort.each do |code, name|
            next if base_encoding&.name(code) == name
            if last_code + 1 == code
              result << name
            else
              result << code << name
            end
            last_code = code
          end
          result
        end

      end

    end
  end
end
