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

require 'hexapdf/type/acro_form/field'
require 'hexapdf/type/acro_form/appearance_generator'

module HexaPDF
  module Type
    module AcroForm

      # AcroForm signature fields represent a digital signature.
      #
      # It serves two purposes: To visually display the signature and to hold the information of the
      # digital signature itself.
      #
      # If the signature should not be visible, the associated widget annotation should have zero
      # width and height; and/or the 'hidden' or 'no_view' flags of the annotation should be set.
      #
      # See: PDF2.0 s12.7.5.5
      class SignatureField < Field

        # A signature field lock dictionary specifies a set of form fields that should be locked
        # once the associated signature field is signed.
        #
        # See: PDF2.0 s12.7.5.5
        class LockDictionary < Dictionary

          define_type :SigFieldLock

          define_field :Type,   type: Symbol, default: type
          define_field :Action, type: Symbol, required: true,
                       allowed_values: [:All, :Include, :Exclude]
          define_field :Fields, type: PDFArray
          define_field :P, type: Numeric, version: '2.0',
                       allowed_values: [1, 2, 3]

          private

          def perform_validation #:nodoc:
            if self[:Action] != :All && !key?(:Fields)
              yield("The /Fields key of the signature lock dictionary is missing")
            end
          end

        end

        # A seed value dictionary contains information that constrains the properties of a signature
        # that is applied to the associated signature field.
        #
        # == Flags
        #
        # If a flag is set it means that the associated entry is a required constraint. Otherwise it
        # is optional.
        #
        # The available flags are: filter, sub_filter, v, reasons, legal_attestation, add_rev_info,
        # digest_method, lock_document and appearance_filter.
        #
        # See: PDF2.0 s12.7.5.5
        class SeedValueDictionary < Dictionary

          extend Utils::BitField

          define_type :SV

          define_field :Type,             type: Symbol, default: type
          define_field :Ff,               type: Integer, default: 0
          define_field :Filter,           type: Symbol
          define_field :SubFilter,        type: PDFArray
          define_field :DigestMethod,     type: PDFArray, version: '1.7'
          define_field :V,                type: Integer
          define_field :Cert,             type: :SVCert
          define_field :Reasons,          type: PDFArray
          define_field :MDP,              type: Dictionary, version: '1.6'
          define_field :TimeStamp,        type: Dictionary, version: '1.6'
          define_field :LegalAttestation, type: PDFArray, version: '1.6'
          define_field :AddRevInfo,       type: Boolean, version: '1.7'
          define_field :LockDocument,     type: Symbol, version: '2.0',
                       allowed_values: [:true, :false, :auto]
          define_field :AppearanceFilter, type: String, version: '2.0'

          ##
          # :method: flags
          #
          # Returns an array of flag names representing the set bit flags.
          #

          ##
          # :method: flagged?
          # :call-seq:
          #   flagged?(flag)
          #
          # Returns +true+ if the given flag is set. The argument can either be the flag name or the
          # bit index.
          #

          ##
          # :method: flag
          # :call-seq:
          #   flag(*flags, clear_existing: false)
          #
          # Sets the given flags, given as flag names or bit indices. If +clear_existing+ is +true+,
          # all prior flags will be cleared.
          #
          bit_field(:flags, {filter: 0, sub_filter: 1, v: 2, reasons: 3, legal_attestation: 4,
                             add_rev_info: 5, digest_method: 6, lock_document: 7,
                             appearance_filter: 8},
                    lister: "flags", getter: "flagged?", setter: "flag", unsetter: "unflag",
                    value_getter: "self[:Ff]", value_setter: "self[:Ff]")

        end

        # A certificate seed value dictionary contains information about the characteristics of the
        # certificate that shall be used when signing.
        #
        # == Flags
        #
        # The flags describe the entries that a signer is required to use.
        #
        # The available flags are: subject, issuer, oid, subject_dn, reserved,  key_usage and url.
        #
        # See: PDF2.0 s12.7.5.5
        class CertificateSeedValueDictionary < Dictionary

          extend Utils::BitField

          define_type :SVCert

          define_field :Type,      type: Symbol, default: type
          define_field :Ff,        type: Integer, default: 0
          define_field :Subject,   type: PDFArray
          define_field :SignaturePolicyOID, type: String, version: '2.0'
          define_field :SignaturePolicyHashValue, type: String, version: '2.0'
          define_field :SignaturePolicyHashAlgorithm, type: Symbol, version: '2.0'
          define_field :SignaturePolicyCommitmentType, type: PDFArray, version: '2.0'
          define_field :SubjectDN, type: PDFArray, version: '1.7'
          define_field :KeyUsage,  type: PDFArray, version: '1.7'
          define_field :Issuer,    type: PDFArray
          define_field :OID,       type: PDFArray
          define_field :URL,       type: String
          define_field :URLType,   type: Symbol, default: :Browser, version: '1.7'

          ##
          # :method: flags
          #
          # Returns an array of flag names representing the set bit flags.
          #

          ##
          # :method: flagged?
          # :call-seq:
          #   flagged?(flag)
          #
          # Returns +true+ if the given flag is set. The argument can either be the flag name or the
          # bit index.
          #

          ##
          # :method: flag
          # :call-seq:
          #   flag(*flags, clear_existing: false)
          #
          # Sets the given flags, given as flag names or bit indices. If +clear_existing+ is +true+,
          # all prior flags will be cleared.
          #
          bit_field(:flags, {subject: 0, issuer: 1, oid: 2, subject_dn: 3, reserved: 4,
                             key_usage: 5, url: 6},
                    lister: "flags", getter: "flagged?", setter: "flag", unsetter: "unflag",
                    value_getter: "self[:Ff]", value_setter: "self[:Ff]")

        end

        define_type :XXAcroFormField

        define_field :Lock, type: :SigFieldLock, indirect: true, version: '1.5'
        define_field :SV, type: :SV, indirect: true, version: '1.5'

        # Returns the associated signature dictionary or +nil+ if the signature is not filled in.
        def field_value
          val = self[:V]
          val.instance_of?(Dictionary) ? document.wrap(val, type: :Sig) : val
        end

        # Sets the signature dictionary as value of this signature field.
        def field_value=(sig_dict)
          self[:V] = sig_dict
        end

        private

        def perform_validation #:nodoc:
          if field_type != :Sig
            yield("Field /FT of AcroForm signature field has to be :Sig", true)
            self[:FT] = :Sig
          end

          super
        end

      end

    end
  end
end
