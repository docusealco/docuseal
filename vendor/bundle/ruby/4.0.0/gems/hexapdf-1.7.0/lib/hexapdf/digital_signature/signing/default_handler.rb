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
require 'hexapdf/error'
require 'hexapdf/version'
require 'stringio'

module HexaPDF
  module DigitalSignature
    module Signing

      # This is the default signing handler which provides the ability to sign a document with the
      # adbe.pkcs7.detached or ETSI.CAdES.detached algorithms. It is registered under the :default
      # name.
      #
      # == Usage
      #
      # The signing handler is used by default by all methods that need a signing handler. Therefore
      # it is usually only necessary to provide the actual attribute values.
      #
      #
      # == CMS and PAdES Signatures
      #
      # The handler supports the older standard of CMS signatures as well as the newer PAdES
      # signatures specified in PDF 2.0. By default, CMS signatures are created but this can be
      # changed by setting #signature_type to :pades.
      #
      # When creating PAdES signatures the following two PAdES baseline signatures are supported:
      # B-B and B-T. The difference between those two is that a timestamp handler was defined for
      # B-T compatibility.
      #
      #
      # == Signing Modes - Internal, External, External/Asynchronous
      #
      # This handler provides two ways to create the CMS signed-data structure required by
      # Signatures#add:
      #
      # * By providing the signing certificate together with the signing key and the certificate
      #   chain, HexaPDF itself does the signing *internally*. It is the preferred way if all the
      #   needed information is available.
      #
      #   Assign the respective data to the #certificate, #key and #certificate_chain attributes.
      #
      # * By using an *external signing mechanism*, a callable object assigned to #external_signing.
      #   Here the actual signing happens "outside" of HexaPDF, for example, in custom code or even
      #   asynchronously. This is needed in case the signing key is not directly available but only
      #   an interface to it (e.g. when dealing with a HSM).
      #
      #   Depending on whether #certificate is set the signing happens differently:
      #
      #   * If #certificate is not set, the callable object is used instead of #sign, so it needs to
      #     accept the same arguments as #sign and needs to return a complete, DER-serialized CMS
      #     signed data object.
      #
      #   * If #certificate is set, the CMS signed data object is created by HexaPDF. The
      #     callable #external_signing object is called with the used digest algorithm and the
      #     already digested data which needs to be signed (but *not* digested) and the signature
      #     returned.
      #
      #   If the signing process needs to be *asynchronous*, make sure to set the #signature_size
      #   appropriately, return an empty string during signing and later use
      #   Signatures.embed_signature to embed the actual signature.
      #
      #
      # == Optional Data
      #
      # Besides the required data, some optional attributes can also be specified:
      #
      # * Reason, location and contact information
      # * Making the signature a certification signature by applying the DocMDP transform method and
      #   a DoCMDP permission
      #
      #
      # == Examples
      #
      #   # Signing using certificate + key
      #   document.sign("output.pdf", certificate: my_cert, key: my_key,
      #                 certificate_chain: my_chain)
      #
      #   # Signing using an external mechanism without certificate set
      #   signing_proc = lambda do |io, byte_range|
      #     io.pos = byte_range[0]
      #     data = io.read(byte_range[1])
      #     io.pos = byte_range[2]
      #     data << io.read(byte_range[3])
      #     signing_service.pkcs7_sign(data).to_der
      #   end
      #   document.sign("output.pdf", signature_size: 10_000, external_signing: signing_proc)
      #
      #   # Signing using external mechanism with certificate set
      #   signing_proc = lambda do |digest_method, hash|
      #     signing_service.sign_raw(digest_method, hash)
      #   end
      #   document.sign("output.pdf", certificate: my_cert, certificate_chain: my_chain,
      #                 external_signing: signing_proc)
      #
      #
      # == Implementing a Signing Handler
      #
      # This class also serves as an example on how to create a custom handler: The public methods
      # #signature_size, #finalize_objects and #sign are used by the digital signature algorithm.
      # See their descriptions for details.
      #
      # Once a custom signing handler has been created, it can be registered under the
      # 'signature.signing_handler' configuration option for easy use. It has to take keyword
      # arguments in its initialize method to be compatible with the Signatures#handler method.
      class DefaultHandler

        # The certificate with which to sign the PDF.
        #
        # If the certificate is provided, HexaPDF creates the signature object. Otherwise the
        # #external_signing callable object has to create it.
        #
        # See the class documentation section "Signing Modes" on how #certificate, #key and
        # #external_signing play together.
        attr_accessor :certificate

        # The private key for the #certificate.
        #
        # If the key is provided, HexaPDF does the signing. Otherwise the #external_signing callable
        # object has to sign the data.
        #
        # See the class documentation section "Signing Modes" on how #certificate, #key and
        # #external_signing play together.
        attr_accessor :key

        # The certificate chain that should be embedded in the PDF; usually contains all
        # certificates up to the root certificate.
        attr_accessor :certificate_chain

        # The digest algorithm that should be used when creating the signature.
        #
        # See SignedDataCreator#digest_algorithm for the default value (if nothing is set) and for
        # the allowed values.
        attr_accessor :digest_algorithm

        # The timestamp handler that should be used for timestamping the signature.
        #
        # If this attribute is set, a timestamp token is embedded into the CMS object.
        attr_accessor :timestamp_handler

        # A callable object for custom signing mechanisms.
        #
        # The callable object has two different uses depending on whether #certificate is set:
        #
        # * If #certificate is not set, it fulfills the same role as the #sign method and needs to
        #   conform to that interface.
        #
        # * If #certificate is set and #key is not, it is just used for signing. Here it needs to
        #   accept the used digest algorithm and the already digested data as arguments and return
        #   the signature.
        #
        # Also dee the class documentation section "Signing Modes" on how #certificate, #key and
        # #external_signing play together.
        attr_accessor :external_signing

        # The reason for signing. If used, will be set on the signature dictionary.
        attr_accessor :reason

        # The signing location. If used, will be set on the signature dictionary.
        attr_accessor :location

        # The contact information. If used, will be set on the signature dictionary.
        attr_accessor :contact_info

        # The custom signing time.
        #
        # The signing time is usually the time when signing actually happens. This is also what
        # HexaPDF uses. If it is known that signing happened at a different point in time, that time
        # can be provided using this accessor.
        attr_accessor :signing_time

        # The size of the serialized signature that should be reserved.
        #
        # If this attribute is not set, an empty string will be signed using #sign to determine the
        # signature size.
        #
        # The size needs to be at least as big as the final signature, otherwise signing results in
        # an error.
        attr_writer :signature_size

        # The type of signature to be written (i.e. the value of the /SubFilter key).
        #
        # The value can either be :cms (the default; uses a detached CMS signature) or :pades
        # (uses an ETSI CAdES compatible signature).
        attr_accessor :signature_type

        # The DocMDP permissions that should be set on the document.
        #
        # See #doc_mdp_permissions=
        attr_reader :doc_mdp_permissions

        # Creates a new DefaultHandler instance with the given attributes.
        def initialize(**arguments)
          @signature_size = nil
          @signature_type = :cms
          arguments.each {|name, value| send("#{name}=", value) }
        end

        # Sets the DocMDP permissions that should be applied to the document.
        #
        # Valid values for +permissions+ are:
        #
        # +nil+::
        #     Don't set any DocMDP permissions (default).
        #
        # +:no_changes+ or 1::
        #     No changes whatsoever are allowed.
        #
        # +:form_filling+ or 2::
        #     Only filling in forms and signing are allowed.
        #
        # +:form_filling_and_annotations+ or 3::
        #     Only filling in forms, signing and annotation creation/deletion/modification are
        #     allowed.
        def doc_mdp_permissions=(permissions)
          case permissions
          when :no_changes, 1 then @doc_mdp_permissions = 1
          when :form_filling, 2 then @doc_mdp_permissions = 2
          when :form_filling_and_annotations, 3 then @doc_mdp_permissions = 3
          when nil then @doc_mdp_permissions = nil
          else
            raise ArgumentError, "Invalid permissions value '#{permissions.inspect}'"
          end
        end

        # Returns the size of the serialized signature that should be reserved.
        #
        # If a custom size is set using #signature_size=, it used. Otherwise the size is determined
        # by using #sign to sign an empty string.
        def signature_size
          @signature_size || sign(StringIO.new, [0, 0, 0, 0]).size + 5
        end

        # Finalizes the signature field as well as the signature dictionary before writing.
        def finalize_objects(_signature_field, signature)
          signature[:Filter] = :'Adobe.PPKLite'
          signature[:SubFilter] = (signature_type == :pades ? :'ETSI.CAdES.detached' : :'adbe.pkcs7.detached')
          signature[:M] = self.signing_time ||= Time.now
          signature[:Reason] = reason if reason
          signature[:Location] = location if location
          signature[:ContactInfo] = contact_info if contact_info
          signature[:Prop_Build] = {App: {Name: :HexaPDF, REx: HexaPDF::VERSION}}
          signature.document.version = '2.0' if signature_type == :pades

          if doc_mdp_permissions
            doc = signature.document
            if doc.signatures.count > 1
              raise HexaPDF::Error, "Can set DocMDP access permissions only on first signature"
            end
            params = doc.add({Type: :TransformParams, V: :'1.2', P: doc_mdp_permissions})
            sigref = doc.add({Type: :SigRef, TransformMethod: :DocMDP, TransformParams: params})
            signature[:Reference] = [sigref]
            (doc.catalog[:Perms] ||= {})[:DocMDP] = signature
          end
        end

        # Returns the DER serialized CMS signed data object containing the signature for the given
        # IO byte ranges.
        #
        # The +byte_range+ argument is an array containing four numbers [offset1, length1, offset2,
        # length2]. The offset numbers are byte positions in the +io+ argument and the to-be-signed
        # data can be determined by reading length bytes at the offsets.
        def sign(io, byte_range)
          if certificate
            io.pos = byte_range[0]
            data = io.read(byte_range[1])
            io.pos = byte_range[2]
            data << io.read(byte_range[3])
            SignedDataCreator.create(data,
                                     type: signature_type,
                                     certificate: certificate, key: key,
                                     digest_algorithm: digest_algorithm,
                                     signing_time: signing_time,
                                     timestamp_handler: timestamp_handler,
                                     certificates: certificate_chain, &external_signing).to_der
          else
            external_signing.call(io, byte_range)
          end
        end

      end

    end
  end
end
