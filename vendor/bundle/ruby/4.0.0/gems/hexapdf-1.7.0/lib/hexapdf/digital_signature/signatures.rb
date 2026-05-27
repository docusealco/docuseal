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

require 'openssl'
require 'stringio'
require 'hexapdf/digital_signature'
require 'hexapdf/error'

module HexaPDF
  module DigitalSignature

    # This class provides methods for interacting with digital signatures of a PDF file. It is used
    # through HexaPDF::Document#signatures.
    class Signatures

      include Enumerable

      # Creates a new Signatures object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # Creates a signing handler with the given attributes and returns it.
      #
      # A signing handler name is mapped to a class via the 'signature.signing_handler'
      # configuration option. The default signing handler is Signing::DefaultHandler.
      def signing_handler(name: :default, **attributes)
        handler = @document.config.constantize('signature.signing_handler', name) do
          raise HexaPDF::Error, "No signing handler named '#{name}' is available"
        end
        handler.new(**attributes)
      end

      # Adds a signature to the document and returns the corresponding signature object.
      #
      # This method will add a new signature to the document and write the updated document to the
      # given file or IO stream. Afterwards the document can't be modified anymore and still retain
      # a correct digital signature. To modify the signed document (e.g. for adding another
      # signature) create a new document based on the given file or IO stream instead.
      #
      # +signature+::
      #     Can either be a signature object (determined via the /Type key), a signature field or
      #     +nil+. Providing a signature object or signature field provides for more control, e.g.:
      #
      #     * Setting values for optional signature object fields like /Reason and /Location.
      #     * (In)directly specifying which signature field should be used.
      #
      #     If a signature object is provided and it is not associated with an AcroForm signature
      #     field, a new signature field is created and added to the main AcroForm object, creating
      #     that if necessary.
      #
      #     If a signature field is provided and it already has a signature object as field value,
      #     that signature object is discarded.
      #
      #     If the signature field doesn't have a widget, a non-visible one is created on the first
      #     page.
      #
      # +handler+::
      #     The signing handler that provides the necessary methods for signing and adjusting the
      #     signature and signature field objects to one's liking, see #signing_handler and
      #     Signing::DefaultHandler.
      #
      # +write_options+::
      #     The key-value pairs of this hash will be passed on to the HexaPDF::Document#write
      #     method. Note that +incremental+ will be automatically set to ensure proper behaviour.
      def add(file_or_io, handler, signature: nil, write_options: {})
        if signature && signature.type != :Sig
          signature_field = signature
          signature = signature_field.field_value
        end
        signature ||= @document.add({Type: :Sig})

        # Prepare AcroForm
        form = @document.acro_form(create: true)
        form.signature_flag(:signatures_exist, :append_only)

        # Prepare signature field
        signature_field ||= form.each_field.find {|field| field.field_value == signature } ||
          form.create_signature_field(generate_field_name)
        signature_field.field_value = signature

        if signature_field.each_widget.to_a.empty?
          signature_field.create_widget(@document.pages[0], Rect: [0, 0, 0, 0])
        end

        # Work-around for Adobe Acrobat to recognize images (https://stackoverflow.com/a/73011571/8203541)
        signature_field.each_widget do |widget|
          next unless (resources = widget.appearance&.resources)
          resources[:XObject]&.each do |_name, entry|
            entry[:Resources] ||= {}
          end
        end

        # Prepare signature object
        handler.finalize_objects(signature_field, signature)
        signature[:ByteRange] = [0, 1_000_000_000_000, 1_000_000_000_000, 1_000_000_000_000]
        signature[:Contents] = '00' * handler.signature_size # twice the size due to hex encoding

        io = if file_or_io.kind_of?(String)
               File.open(file_or_io, 'wb+')
             else
               file_or_io
             end

        # Save the current state so that we can determine the correct /ByteRange value and set the
        # values
        start_xref, section = @document.write(io, incremental: true, **write_options)
        signature_offset, signature_length = Signing.locate_signature_dict(section, start_xref,
                                                                           signature.oid)
        io.pos = signature_offset
        signature_data = io.read(signature_length)

        io.seek(0, IO::SEEK_END)
        file_size = io.pos

        # Calculate the offsets for the /ByteRange
        contents_offset = signature_offset + signature_data.index('Contents(') + 8
        offset2 = contents_offset + signature[:Contents].size + 2 # +2 because of the needed < and >
        length2 = file_size - offset2
        signature[:ByteRange] = [0, contents_offset, offset2, length2]

        # Set the correct /ByteRange value
        signature_data.sub!(/ByteRange\[0 1000000000000 1000000000000 1000000000000\]/) do |match|
          length = match.size
          result = "ByteRange[0 #{contents_offset} #{offset2} #{length2}]"
          result.ljust(length)
        end

        # Now everything besides the /Contents value is correct, so we can read the contents for
        # signing
        io.pos = signature_offset
        io.write(signature_data)
        signature[:Contents] = handler.sign(io, signature[:ByteRange].value)

        # And now replace the /Contents value
        Signing.replace_signature_contents(signature_data, signature[:Contents])
        io.pos = signature_offset
        io.write(signature_data)

        signature
      ensure
        io.close if io && io != file_or_io
      end

      # :call-seq:
      #   signatures.each {|signature| block }   -> signatures
      #   signatures.each                        -> Enumerator
      #
      # Iterates over all signatures in the order they are found in the PDF.
      def each
        return to_enum(__method__) unless block_given?

        return [] unless (form = @document.acro_form)
        form.each_field do |field|
          yield(field.field_value) if field.field_type == :Sig && field.field_value
        end
      end

      # Returns the number of signatures in the PDF document. May be zero if the document has no
      # signatures.
      def count
        each.to_a.size
      end

      private

      # Generates a field name for a signature field.
      def generate_field_name
        index = (@document.acro_form.each_field.
                 map {|field| field.full_field_name.scan(/\ASignature(\d+)/).first&.first.to_i }.
                 max || 0) + 1
        "Signature#{index}"
      end

    end

  end
end
