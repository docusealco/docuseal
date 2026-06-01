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

require 'hexapdf/font/encoding/base'

module HexaPDF
  module Font
    module Encoding

      # The difference encoding uses a base encoding that can be overlayed with additional mappings.
      #
      # See: PDF2.0 s9.6.5.1
      class DifferenceEncoding < Base

        # The base encoding.
        attr_reader :base_encoding

        # Initializes the Differences object with the given base encoding object.
        def initialize(base_encoding)
          super()
          @base_encoding = base_encoding
        end

        # Returns the name for the given code, either from this object, if it contains the code, or
        # from the base encoding.
        def name(code)
          code_to_name[code] || base_encoding.name(code)
        end

        # Returns the code for the given glyph name, either from this object, if a code references
        # the name, or from the base encoding.
        def code(name)
          code_to_name.key(name) || base_encoding.code(name)
        end

      end

    end
  end
end
