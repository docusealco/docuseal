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
require 'hexapdf/dictionary'
require 'hexapdf/error'

module HexaPDF
  module DigitalSignature

    # Represents a digital signature that is used to authenticate a user and the contents of the
    # document.
    #
    # == Signature Verification
    #
    # Verification of signatures is a complex topic and what counts as completely verified may
    # differ from use-case to use-case. Therefore HexaPDF provides as much diagnostic information as
    # possible so that the user can decide whether a signature is valid.
    #
    # By defining a custom signature handler based on BaseHandler or CMSHandler one is able to also
    # customize the signature verification.
    #
    # See: PDF2.0 s12.8.1, HexaPDF::Type::AcroForm::SignatureField
    class Signature < Dictionary

      # Represents a transform parameters dictionary.
      #
      # The allowed fields depend on the transform method, so not all fields are available all the
      # time.
      #
      # See: PDF2.0 s12.8.2.2, s12.8.2.3, s12.8.2.4
      class TransformParams < Dictionary

        define_type :TransformParams

        define_field :Type, type: Symbol, default: type

        # For DocMDP, also used by UR
        define_field :P, type: [Integer, Boolean]
        define_field :V, type: Symbol, allowed_values: [:'1.2', :'2.2']

        # For UR
        define_field :Document,  type: PDFArray
        define_field :Msg,       type: String
        define_field :Annots,    type: PDFArray, version: '1.5'
        define_field :Form,      type: PDFArray, version: '1.5'
        define_field :Signature, type: PDFArray
        define_field :EF,        type: PDFArray, version: '1.6'

        # For FieldMDP
        define_field :Action, type: Symbol, allowed_values: [:All, :Include, :Exclude]
        define_field :Fields, type: PDFArray

        private

        # All values allowed for the /Annots field
        FIELD_ANNOTS_ALLOWED_VALUES = [:Create, :Delete, :Modify, :Copy, :Import, :Online, :SummaryView]

        # All values allowed for the /Form field
        FIELD_FORM_ALLOWED_VALUES = [:Add, :Delete, :Fillin, :Import, :Export, :SubmitStandalone,
                                     :SpawnTemplate, :BarcodePlaintext, :Online]

        # All values allowed for the /EF field
        FIELD_EF_ALLOWED_VALUES = [:Create, :Delete, :Modify, :Import]

        def perform_validation #:nodoc:
          super
          # We need to perform the checks here since the values are arrays and not single elements
          if (annots = self[:Annots]) && !(annots = annots.value - FIELD_ANNOTS_ALLOWED_VALUES).empty?
            yield("Field /Annots contains invalid entries: #{annots.join(', ')}", true)
            value[:Annots].value -= annots
          end
          if (form = self[:Form]) && !(form = form.value - FIELD_FORM_ALLOWED_VALUES).empty?
            yield("Field /Form contains invalid entries: #{form.join(', ')}", true)
            value[:Form].value -= form
          end
          if (ef = self[:EF]) && !(ef = ef.value - FIELD_EF_ALLOWED_VALUES).empty?
            yield("Field /EF contains invalid entries: #{ef.join(', ')}", true)
            value[:EF].value -= ef
          end
        end

      end

      # Represents a signature reference dictionary.
      #
      # See: PDF2.0 s12.8.1, HexaPDF::DigitalSignature::Signature
      class SignatureReference < Dictionary

        define_type :SigRef

        define_field :Type,            type: Symbol, default: type
        define_field :TransformMethod, type: Symbol, required: true,
          allowed_values: [:DocMDP, :UR, :FieldMDP]
        define_field :TransformParams, type: :TransformParams
        define_field :Data,            type: ::Object
        define_field :DigestMethod,    type: Symbol, version: '1.5',
          allowed_values: [:MD5, :SHA1, :SHA256, :SHA384, :SHA512, :RIPEMD160]

        private

        def perform_validation #:nodoc:
          super
          if self[:TransformMethod] == :FieldMDP && !key?(:Data)
            yield("Field /Data is required when /TransformMethod is /FieldMDP")
          end
        end

      end

      define_field :Type,          type: Symbol, default: :Sig,
        allowed_values: [:Sig, :DocTimeStamp]
      define_field :Filter,        type: Symbol
      define_field :SubFilter,     type: Symbol
      define_field :Contents,      type: PDFByteString
      define_field :Cert,          type: [PDFArray, PDFByteString]
      define_field :ByteRange,     type: PDFArray
      define_field :Reference,     type: PDFArray
      define_field :Changes,       type: PDFArray
      define_field :Name,          type: String
      define_field :M,             type: PDFDate
      define_field :Location,      type: String
      define_field :Reason,        type: String
      define_field :ContactInfo,   type: String
      define_field :R,             type: Integer
      define_field :V,             type: Integer, default: 0, version: '1.5'
      define_field :Prop_Build,    type: Dictionary, version: '1.5'
      define_field :Prop_AuthTime, type: Integer, version: '1.5'
      define_field :Prop_AuthType, type: Symbol, version: '1.5',
        allowed_values: [:PIN, :Password, :Fingerprint]

      # Returns the name of the person or authority that signed the document.
      def signer_name
        signature_handler.signer_name
      end

      # Returns the time of the signing.
      def signing_time
        signature_handler.signing_time
      end

      # Returns the reason for the signing.
      def signing_reason
        self[:Reason]
      end

      # Returns the location of the signing.
      def signing_location
        self[:Location]
      end

      # Returns the signature type based on the /SubFilter.
      def signature_type
        self[:SubFilter].to_s
      end

      # Returns the signature handler for this signature based on the /SubFilter entry.
      def signature_handler
        cache(:signature_handler) do
          handler_class = document.config.constantize('signature.sub_filter_map', self[:SubFilter]) do
            raise HexaPDF::Error, "No or unknown signature handler set: #{self[:SubFilter]}"
          end
          handler_class.new(self)
        end
      end

      # Returns the raw signature value.
      def contents
        self[:Contents]
      end

      # Returns the signed data as indicated by the /ByteRange entry as binary string.
      def signed_data
        unless document.revisions.parser
          raise HexaPDF::Error, "Can't load signed data without existing PDF file"
        end
        io = document.revisions.parser.io
        data = ''.b
        self[:ByteRange]&.each_slice(2) do |offset, length|
          io.pos = offset
          data << io.read(length).to_s
        end
        data
      end

      # Returns a VerificationResult object with the verification information.
      def verify(default_paths: true, trusted_certs: [], allow_self_signed: false)
        store = OpenSSL::X509::Store.new
        store.set_default_paths if default_paths
        store.purpose = OpenSSL::X509::PURPOSE_SMIME_SIGN
        trusted_certs.each {|cert| store.add_cert(cert) }
        signature_handler.verify(store, allow_self_signed: allow_self_signed)
      end

      private

      def perform_validation #:nodoc:
        if (self[:SubFilter] == :'ETSI.CAdES.detached' || self[:SubFilter] == :'ETSI.RFC3161') &&
            document.version < '2.0'
          yield("Signature handler needs at least PDF version 2.0", true)
          document.version = '2.0'
        end
      end

    end

  end
end
