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
require 'hexapdf/digital_signature/handler'

module HexaPDF
  module DigitalSignature

    # The signature handler for PKCS#1 based sub-filters, the only being the adbe.x509.rsa_sha1
    # sub-filter.
    #
    # Note that PKCS#1 signatures are deprecated with PDF 2.0.
    #
    # See: PDF2.0 s12.8.3.2
    class PKCS1Handler < Handler

      # Returns the certificate chain.
      def certificate_chain
        return [] unless signature_dict.key?(:Cert)
        [signature_dict[:Cert]].flatten.map {|str| OpenSSL::X509::Certificate.new(str) }
      end

      # Returns the signer certificate (an instance of OpenSSL::X509::Certificate).
      def signer_certificate
        certificate_chain.first
      end

      # Verifies the signature using the provided OpenSSL::X509::Store object.
      def verify(store, allow_self_signed: false)
        result = super

        signer_certificate = self.signer_certificate
        certificate_chain = self.certificate_chain

        if certificate_chain.empty?
          result.log(:error, "No certificates for verification found")
          return result
        end

        signature = OpenSSL::ASN1.decode(signature_dict.contents)
        if signature.tag != OpenSSL::ASN1::OCTET_STRING
          result.log(:error, "PKCS1 signature object invalid, octet string expected")
          return result
        end

        store.verify(signer_certificate, certificate_chain)

        if signer_certificate.public_key.verify(OpenSSL::Digest.new('SHA1'),
                                                signature.value, signature_dict.signed_data)
          result.log(:info, "Signature valid")
        else
          result.log(:error, "Signature verification failed")
        end

        result
      end

    end

  end
end
