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

require 'hexapdf/digital_signature/verification_result'

module HexaPDF
  module DigitalSignature

    # The base signature handler providing common functionality.
    #
    # Specific signature handlers need to override methods if necessary and implement the needed
    # ones that don't have a default implementation.
    class Handler

      # The signature dictionary used by the handler.
      attr_reader :signature_dict

      # Creates a new signature handler for the given signature dictionary.
      def initialize(signature_dict)
        @signature_dict = signature_dict
      end

      # Returns the common name of the signer (/Name field of the signature dictionary).
      def signer_name
        @signature_dict[:Name]
      end

      # Returns the time of signing (/M field of the signature dictionary).
      def signing_time
        @signature_dict[:M]
      end

      # Returns the certificate chain.
      #
      # Needs to be implemented by specific handlers.
      def certificate_chain
        raise "Needs to be implemented by specific handlers"
      end

      # Returns the certificate used for signing.
      #
      # Needs to be implemented by specific handlers.
      def signer_certificate
        raise "Needs to be implemented by specific handlers"
      end

      # Verifies general signature properties and prepares the provided OpenSSL::X509::Store
      # object for use by concrete implementations.
      #
      # Needs to be called by specific handlers.
      def verify(store, allow_self_signed: false)
        result = VerificationResult.new
        check_certified_signature(result)
        verify_signing_time(result)
        store.verify_callback =
          store_verification_callback(result, allow_self_signed: allow_self_signed)
        result
      end

      protected

      # Verifies that the signing time was within the validity period of the signer certificate.
      def verify_signing_time(result)
        time = signing_time
        cert = signer_certificate
        if time && cert && (time < cert.not_before || time > cert.not_after)
          result.log(:error, "Signer certificate not valid at signing time")
        end
      end

      DOCMDP_PERMS_MESSAGE_MAP = { # :nodoc:
        1 => "No changes allowed",
        2 => "Form filling and signing allowed",
        3 => "Form filling, signing and annotation manipulation allowed",
      }

      # Sets an informational message on +result+ whether the signature is a certified signature.
      def check_certified_signature(result)
        sigref = signature_dict[:Reference]&.find {|ref| ref[:TransformMethod] == :DocMDP }
        if sigref && signature_dict.document.catalog[:Perms]&.[](:DocMDP) == signature_dict
          perms = sigref[:TransformParams]&.[](:P) || 2
          result.log(:info, "Certified signature (#{DOCMDP_PERMS_MESSAGE_MAP[perms]})")
        end
      end

      # Returns the block that should be used as the OpenSSL::X509::Store verification callback.
      #
      # +result+:: The VerificationResult object that should be updated if problems are found.
      #
      # +allow_self_signed+:: Specifies whether self-signed certificates are allowed.
      def store_verification_callback(result, allow_self_signed: false)
        lambda do |_success, context|
          if context.error == OpenSSL::X509::V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT ||
              context.error == OpenSSL::X509::V_ERR_SELF_SIGNED_CERT_IN_CHAIN
            result.log(allow_self_signed ? :info : :error, "Self-signed certificate found")
          end

          true
        end
      end

    end

  end
end
