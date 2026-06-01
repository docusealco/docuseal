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
require 'digest/md5'

module HexaPDF
  module Type

    # Represents the PDF file trailer.
    #
    # The file trailer is the starting point for the PDF's object tree. It links to the Catalog
    # (the main PDF document structure) and the Info dictionary and holds the information
    # necessary for encrypting the PDF document.
    #
    # Since a PDF document can contain multiple revisions, each revision needs to have its own
    # file trailer (see HexaPDF::Revision#trailer).
    #
    # When cross-reference streams are used the information that is normally stored in the file
    # trailer is stored directly in the cross-reference stream dictionary. However, a
    # HexaPDF::Revision object's trailer dictionary is always of this type. Only when a
    # cross-reference stream is written is the trailer integrated into the stream's dictionary.
    #
    # See: PDF2.0 s7.5.5, s14.4; XRefStream
    class Trailer < Dictionary

      define_type :XXTrailer

      define_field :Size,    type: Integer, indirect: false # will be auto-set when written
      define_field :Prev,    type: Integer
      define_field :Root,    type: :Catalog, indirect: true
      define_field :Encrypt, type: Dictionary
      define_field :Info,    type: :XXInfo, indirect: true
      define_field :ID,      type: PDFArray
      define_field :XRefStm, type: Integer, version: '1.5'

      # Returns the document's Catalog (see Type::Catalog), creating it if needed.
      def catalog
        self[:Root] ||= document.add({Type: :Catalog}, type: :Catalog)
      end

      # Returns the document's information dictionary (see Type::Info), creating it if needed.
      def info
        self[:Info] ||= document.add({}, type: :XXInfo)
      end

      # Sets the /ID field to an array of two copies of a random string and returns this array.
      #
      # See: PDF2.0 14.4
      def set_random_id
        value[:ID] = [Digest::MD5.digest(rand.to_s)] * 2
      end

      # Updates the second part of the /ID field (the first part should always be the same for a
      # PDF file, the second part should change with each write).
      def update_id
        if self[:ID].kind_of?(PDFArray)
          value[:ID][1] = Digest::MD5.digest(rand.to_s)
        else
          set_random_id
        end
      end

      private

      # Validates the trailer.
      def perform_validation(&block)
        super
        unless value[:ID]
          msg = if value[:Encrypt]
                  "ID field is required when an Encrypt dictionary is present"
                else
                  "ID field should always be set"
                end
          yield(msg, true)
          set_random_id
        end

        unless value[:Root]
          yield("A PDF document must have a Catalog dictionary", true)
          catalog.validate(&block)
        end

        if value[:Encrypt] && (!document.security_handler ||
                               !document.security_handler.encryption_key_valid?)
          yield("Encryption key doesn't match encryption dictionary", false)
        end
      end

    end

  end
end
