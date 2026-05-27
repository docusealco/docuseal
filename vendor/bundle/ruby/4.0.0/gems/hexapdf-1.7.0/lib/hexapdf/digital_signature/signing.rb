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

require 'hexapdf/document'

module HexaPDF
  module DigitalSignature

    # This module contains everything related to the signing of a PDF document, i.e. signing
    # handlers and the actual code for signing.
    #
    # * The DefaultHandler is the standard signing handler and should be sufficient for most cases.
    # * The TimestampHandler is used for timestamping purposes.
    # * The SignedDataCreator provides the functionality to create custom CMS signed data objects.
    module Signing

      autoload(:DefaultHandler, 'hexapdf/digital_signature/signing/default_handler')
      autoload(:TimestampHandler, 'hexapdf/digital_signature/signing/timestamp_handler')
      autoload(:SignedDataCreator, 'hexapdf/digital_signature/signing/signed_data_creator')

      # Embeds the given +signature+ into the /Contents value of the newest signature dictionary of
      # the PDF document given by the +io+ argument.
      #
      # This functionality can be used together with the support for external signing (see
      # DefaultHandler and DefaultHandler#external_signing) to implement asynchronous signing.
      #
      # Note: This will, most probably, only work on documents prepared for external signing by
      # HexaPDF and not by other libraries.
      def self.embed_signature(io, signature)
        doc = HexaPDF::Document.new(io: io)
        signature_dict = doc.signatures.find {|sig| doc.revisions.current.object(sig) == sig }
        signature_dict_offset, signature_dict_length = locate_signature_dict(
          doc.revisions.current.xref_section,
          doc.revisions.parser.startxref_offset,
          signature_dict.oid
        )
        io.pos = signature_dict_offset
        signature_data = io.read(signature_dict_length)
        replace_signature_contents(signature_data, signature)
        io.pos = signature_dict_offset
        io.write(signature_data)
      end

      # Uses the information in the given cross-reference section as well as the byte offset of the
      # cross-reference section to calculate the offset and length of the signature dictionary with
      # the given object id.
      def self.locate_signature_dict(xref_section, start_xref_position, signature_oid)
        data = xref_section.map {|oid, _gen, entry| [entry.pos, oid] if entry.in_use? }.compact.sort <<
          [start_xref_position, nil]
        index = data.index {|_pos, oid| oid == signature_oid }
        [data[index][0], data[index + 1][0] - data[index][0]]
      end

      # Replaces the value of the /Contents key in the serialized +signature_data+ with the value of
      # +contents+.
      def self.replace_signature_contents(signature_data, contents)
        signature_data.sub!(/Contents(?:\(.*?\)|<.*?>)/) do |match|
          length = match.size
          result = "Contents<#{contents.unpack1('H*')}"
          if length < result.size
            raise HexaPDF::Error, "The reserved space for the signature was too small " \
              "(#{(length - 10) / 2} vs #{(result.size - 10) / 2}) - use the handlers " \
              "#signature_size method to increase the reserved space"
          end
          "#{result.ljust(length - 1, '0')}>"
        end
      end

    end

  end
end
