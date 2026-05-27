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

module HexaPDF

  # A general error.
  class Error < StandardError; end

  # Raised when the PDF is invalid and can't be read correctly.
  class MalformedPDFError < Error

    # The byte position in the PDF file where the error occured.
    attr_accessor :pos

    # Creates a new malformed PDF error object for the given exception message.
    #
    # The byte position where the error occured can either be given via the +pos+ argument or later
    # via the #pos accessor but must be set before the exception message is retrieved.
    def initialize(message, pos: nil)
      super(message)
      @pos = pos
    end

    def message # :nodoc:
      "PDF malformed around position #{pos}: #{super}"
    end

  end

  # Raised when a filter encounters a problem during decoding or encoding.
  class FilterError < Error; end

  # Raised when a PDF object contains invalid data.
  class InvalidPDFObjectError < Error; end

  # Raised when there are problems while encrypting or decrypting a document.
  class EncryptionError < Error

    # The PDF object that caused the problem. May not be set in case of general problems unrelated
    # to a specific PDF object.
    attr_accessor :pdf_object

    def message # :nodoc:
      pdf_object ? "Object (#{pdf_object.oid},#{pdf_object.gen}): #{super}" : super
    end

  end

  # Raised when the encryption method is not supported.
  class UnsupportedEncryptionError < EncryptionError; end

  # Raised when a font wrapper implementation should encode a missing glyph.
  class MissingGlyphError < Error

    # Returns the glyph object that contains the information about the missing glyph.
    attr_reader :glyph

    # Creates a new MissingGlyphError for the given +glyph+.
    def initialize(glyph)
      @glyph = glyph
    end

    def message # :nodoc:
      str = "No glyph for #{glyph.str.inspect} in font '#{glyph.font_wrapper.wrapped_font.full_name}' " \
            "found. \n\n"
      str << if glyph.font_wrapper.font_type == :Type1
               "The used Type1 font only contains a very limited number of glyphs. TrueType " \
               "fonts usually provide a much wider array of glyphs. Use the configuration option " \
               "'font.map' to register appropriate font files. Also have a look at the " \
               "'font.default' and 'font.fallback' options. "
             else
               "Maybe register another #{glyph.font_wrapper.font_type} font that contains the " \
               "needed glyph and use it as fallback via the configuration option 'font.fallback'."
             end
    end

  end

end
