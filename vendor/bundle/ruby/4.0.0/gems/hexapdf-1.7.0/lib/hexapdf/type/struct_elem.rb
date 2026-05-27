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

module HexaPDF
  module Type

    # Represents a structure element.
    #
    # See: PDF2.0 s14.7.2
    class StructElem < Dictionary

      define_type :StructElem

      define_field :Type,             type: Symbol, default: type
      define_field :S,                type: Symbol, required: true
      define_field :P,                type: Dictionary, required: true, indirect: true
      define_field :ID,               type: PDFByteString
      define_field :Ref,              type: PDFArray, version: '2.0'
      define_field :Pg,               type: Dictionary, indirect: true
      define_field :K,                type: [Dictionary, PDFArray, Integer]
      define_field :A,                type: [Stream, Dictionary, PDFArray]
      define_field :C,                type: [Symbol, PDFArray]
      define_field :R,                type: Integer, default: 0
      define_field :T,                type: String
      define_field :Lang,             type: String
      define_field :Alt,              type: String
      define_field :E,                type: String
      define_field :ActualText,       type: String, version: '1.4'
      define_field :AF,               type: PDFArray, version: '2.0'
      define_field :NS,               type: Dictionary, version: '2.0'
      define_field :PhoneticAlphabet, type: Symbol, version: '2.0', default: :ipa
      define_field :Phoneme,          type: String, version: '2.0'

    end

  end
end
