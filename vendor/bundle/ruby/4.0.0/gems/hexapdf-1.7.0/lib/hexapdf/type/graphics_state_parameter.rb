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

require 'hexapdf/dictionary'
require 'hexapdf/content/graphics_state'

module HexaPDF
  module Type

    # Represents a graphics state parameter dictionary.
    #
    # This dictionary can be used to define most graphics state parameters that are available.
    # Some parameters can only be set by an operator, some only by the dictionary but most by
    # both.
    #
    # See: PDF2.0 s8.4.5, s8.1
    class GraphicsStateParameter < Dictionary

      define_type :ExtGState

      define_field :Type,          type: Symbol, default: type
      define_field :LW,            type: Numeric, version: "1.3"
      define_field :LC,            type: Integer, version: "1.3"
      define_field :LJ,            type: Integer, version: "1.3"
      define_field :ML,            type: Numeric, version: "1.3"
      define_field :D,             type: PDFArray, version: "1.3"
      define_field :RI,            type: Symbol, version: "1.3",
                   allowed_values: [HexaPDF::Content::RenderingIntent::ABSOLUTE_COLORIMETRIC,
                                    HexaPDF::Content::RenderingIntent::RELATIVE_COLORIMETRIC,
                                    HexaPDF::Content::RenderingIntent::SATURATION,
                                    HexaPDF::Content::RenderingIntent::PERCEPTUAL]
      define_field :OP,            type: Boolean
      define_field :op,            type: Boolean, version: "1.3"
      define_field :OPM,           type: Integer, version: "1.3"
      define_field :Font,          type: PDFArray, version: "1.3"
      define_field :BG,            type: [Dictionary, Stream]
      define_field :BG2,           type: [Dictionary, Stream, Symbol], version: "1.3"
      define_field :UCR,           type: [Dictionary, Stream]
      define_field :UCR2,          type: [Dictionary, Stream, Symbol], version: "1.3"
      define_field :TR,            type: [Dictionary, Stream, PDFArray, Symbol]
      define_field :TR2,           type: [Dictionary, Stream, PDFArray, Symbol], version: "1.3"
      define_field :HT,            type: [Dictionary, Stream, Symbol]
      define_field :FL,            type: Numeric, version: "1.3"
      define_field :SM,            type: Numeric, version: "1.3"
      define_field :SA,            type: Boolean
      define_field :BM,            type: [Symbol, PDFArray], version: "1.4"
      define_field :SMask,         type: [Dictionary, Symbol], version: "1.4"
      define_field :CA,            type: Numeric, version: "1.4"
      define_field :ca,            type: Numeric, version: "1.4"
      define_field :AIS,           type: Boolean, version: "1.4"
      define_field :TK,            type: Boolean, version: "1.4"
      define_field :UseBlackPtComp, type: Symbol, version: "2.0",
                   allowed_values: [:OFF, :ON, :Default]
      define_field :HTO,           type: PDFArray, version: "2.0"

    end

  end
end
