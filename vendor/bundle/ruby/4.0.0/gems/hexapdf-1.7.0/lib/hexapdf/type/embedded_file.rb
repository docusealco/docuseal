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

require 'hexapdf/stream'

module HexaPDF
  module Type

    # Represents an embedded file stream.
    #
    # An embedded file stream contains the data of, and optionally some meta data about, a file
    # that is embedded into the PDF file. Each embedded file is either associated with a certain
    # Type::FileSpecification dictionary or with the document as a whole through the /EmbeddedFiles
    # entry in the document catalog's /Names dictionary.
    #
    # See: PDF2.0 s7.11.4, FileSpecification
    class EmbeddedFile < Stream

      # The type used for the /Mac field of an EmbeddedFile::Parameters dictionary.
      class MacInfo < Dictionary

        define_type :XXEmbeddedFileParametersMacInfo

        define_field :Subtype, type: Integer
        define_field :Creator, type: Integer
        define_field :ResFork, type: Stream

      end

      # The type used for the /Params field of an EmbeddedFileStream.
      class Parameters < Dictionary

        define_type :XXEmbeddedFileParameters

        define_field :Size,         type: Integer
        define_field :CreationDate, type: PDFDate
        define_field :ModDate,      type: PDFDate
        define_field :Mac,          type: :XXEmbeddedFileParametersMacInfo
        define_field :CheckSum,     type: PDFByteString

      end

      define_type :EmbeddedFile

      define_field :Type,    type: Symbol, default: type, version: '1.3'
      define_field :Subtype, type: Symbol
      define_field :Params,  type: :XXEmbeddedFileParameters

    end

  end
end
