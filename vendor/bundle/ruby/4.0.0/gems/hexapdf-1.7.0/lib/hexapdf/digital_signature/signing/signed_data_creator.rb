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
require 'hexapdf/error'

module HexaPDF
  module DigitalSignature
    module Signing

      # This class is used for creating a CMS SignedData binary data object, as needed for PDF
      # signing.
      #
      # OpenSSL already provides the ability to access, sign and create such CMS objects but is
      # limited in what it offers in terms of data added to it. Since HexaPDF needs to follow the
      # PDF standard, it needs control over the created structure so as to make it compatible with
      # the various requirements.
      #
      # As the created CMS object is only meant to be used in the context of PDF signing, it also
      # restricts certain things, like allowing only a single signer.
      #
      # Additionally, only RSA signatures are currently supported!
      #
      # See: PDF2.0 s12.8.3.3, PDF2.0 s12.8.3.4, RFC5652, ETSI TS 102 778 Parts 1-4
      class SignedDataCreator

        # Creates a SignedDataCreator, sets the given attributes if they are not nil and then calls
        # #create with the given data, type and block.
        def self.create(data, type: :cms, **attributes, &block)
          instance = new
          attributes.each {|key, value| instance.send("#{key}=", value) unless value.nil? }
          instance.create(data, type: type, &block)
        end

        # The OpenSSL certificate object which is used to sign the data.
        attr_accessor :certificate

        # The OpenSSL key object which is used for signing. Needs to correspond to #certificate.
        #
        # If the key is not set, a block for signing will need to be provided to #sign.
        attr_accessor :key

        # Array of additional OpenSSL certificate objects that should be included.
        #
        # Should include all certificates of the hierarchy of the signing certificate.
        attr_accessor :certificates

        # The digest algorithm that should be used. Defaults to 'sha256'.
        #
        # Allowed values: sha256, sha384, sha512.
        attr_accessor :digest_algorithm

        # The signing time to use instead of Time.now.
        attr_accessor :signing_time

        # The timestamp handler instance that should be used for timestamping.
        attr_accessor :timestamp_handler

        # Creates a new SignedData object.
        def initialize
          @certificate = nil
          @key = nil
          @certificates = []
          @digest_algorithm = 'sha256'
          @timestamp_handler = nil
        end

        # Creates a CMS SignedData binary data object for the given data using the set attributes
        # and returns it in DER-serialized form.
        #
        # If the #key attribute is not set, the digest algorithm and the already digested data to be
        # signed is yielded and the block needs to return the signature.
        #
        # +type+::
        #     The type can either be :cms when creating standard PDF CMS signatures or :pades when
        #     creating PAdES compatible signatures. PAdES signatures are part of PDF 2.0.
        def create(data, type: :cms, &block) # :yield: digest_algorithm, hashed_data
          signed_attrs = create_signed_attrs(data, signing_time: (type == :cms))
          signature = digest_and_sign_data(set(*signed_attrs.value).to_der, &block)
          unsigned_attrs = create_unsigned_attrs(signature)

          signer_info = create_signer_info(signature, signed_attrs, unsigned_attrs)
          signed_data = create_signed_data(signer_info)
          create_content_info(signed_data)
        end

        private

        # Creates the set of signed attributes for the signer information structure.
        def create_signed_attrs(data, ess_cert_hash: 'sha256', signing_time: true)
          signing_time = (self.signing_time || Time.now).utc if signing_time
          set(
            attribute('content-type', oid('id-data')),
            (attribute('id-signingTime', utc_time(signing_time)) if signing_time),
            attribute(
              'message-digest',
              binary(OpenSSL::Digest.digest(@digest_algorithm, data))
            ),
            attribute(
              'id-aa-signingCertificateV2',
              sequence( # SigningCertificateV2, see RFC5035
                sequence( # Seq of ESSCertIDv2
                  sequence( # ESSCertIDv2
                    (sequence( # AlgorithmIdentifier RFC3280 4.1.1.2
                      oid(ess_cert_hash) # algorithm
                    ) unless ess_cert_hash == 'sha256'),
                    binary(OpenSSL::Digest.digest(ess_cert_hash, @certificate.to_der)), # certHash
                    sequence(                                      # issuerSerial
                      sequence(                                    #  issuer
                        implicit(4, sequence(@certificate.issuer)) #   choice 4 directoryName
                      ),
                      integer(@certificate.serial)                 #  serial
                    )
                  )
                )
              )
            )
          )
        end

        # Creates the set of unsigned attributes for the signer information structure.
        def create_unsigned_attrs(signature)
          attrs = set
          if @timestamp_handler
            time_stamp_token = @timestamp_handler.sign(StringIO.new(signature),
                                                       [0, signature.size, 0, 0])
            attrs.value << attribute('id-aa-timeStampToken', time_stamp_token)
          end
          attrs.value.empty? ? nil : attrs
        end

        # Creates a single attribute for use in the (un)signed attributes set.
        def attribute(name, value)
          sequence(
            oid(name), # attrType
            set(value) # attrValues
          )
        end

        # Digests the data and then signs it using the assigned key, or if the key is not available,
        # by yielding to the caller.
        def digest_and_sign_data(data) #:yields: digest_algorithm, hashed_data
          hash = OpenSSL::Digest.digest(@digest_algorithm, data)
          if @key
            @key.sign_raw(@digest_algorithm, hash)
          else
            yield(@digest_algorithm, hash)
          end
        end

        # Creates a signer information structure containing the actual meat of the whole CMS object.
        def create_signer_info(signature, signed_attrs, unsigned_attrs = nil)
          certificate_pkey_algorithm = @certificate.public_key.oid
          signature_algorithm = case certificate_pkey_algorithm
                                when 'rsaEncryption'
                                  sequence(               # signatureAlgorithm
                                    oid('rsaEncryption'), #   algorithmID
                                    null                  #   params
                                  )
                                when 'DSA'
                                  unless @digest_algorithm == 'sha256'
                                    raise HexaPDF::Error, "Only SHA256 supported with DSA"
                                  end
                                  sequence(oid('id-dsa-with-sha256'), null)
                                when 'id-ecPublicKey'
                                  sequence(oid("ecdsa-with-#{@digest_algorithm.upcase}"), null)
                                end

          sequence(
            integer(1),                    # version
            sequence(                      # sid (choice: issuerAndSerialNumber)
              @certificate.issuer,         #   issuer
              integer(@certificate.serial) #   serial
            ),
            sequence(                      # digestAlgorithm
              oid(@digest_algorithm),      #   algorithmID
              null                         #   params
            ),
            implicit(0, signed_attrs),     # signedAttrs 0 implicit
            signature_algorithm,           # signatureAlgorithm
            binary(signature),             # signature
            (implicit(1, unsigned_attrs) if unsigned_attrs) # unsignedAttrs 1 implicit
          )
        end

        # Creates the signed data structure which is the actual content of the CMS object.
        def create_signed_data(signer_info)
          certificates = set(*[@certificate, @certificates].flatten)

          sequence(
            integer(1),                 # version
            set(                        # digestAlgorithms
              sequence(                 #   digestAlgorithm
                oid(@digest_algorithm), #     algorithmID
                null                    #     params
              )
            ),
            sequence(                   # encapContentInfo (detached signature)
              oid('id-data')            #   eContentType
            ),
            implicit(0, certificates),  # certificates 0 implicit
            set(                        # signerInfos
              signer_info               #   signerInfo
            )
          )
        end

        # Creates the content info structure which is the main structure containing everything else.
        def create_content_info(signed_data)
          signed_data.tag = 0
          signed_data.tagging = :EXPLICIT
          signed_data.tag_class = :CONTEXT_SPECIFIC
          sequence(
            oid('id-signedData'), # contentType
            signed_data           # content 0 explicit
          )
        end

        # Changes the given ASN1Data object to use implicit tagging with the given +tag+ and a tag
        # class of :CONTEXT_SPECIFIC.
        def implicit(tag, data)
          data.tag = tag
          data.tagging = :IMPLICIT
          data.tag_class = :CONTEXT_SPECIFIC
          data
        end

        # Creates an ASN.1 set instance.
        def set(*contents, tag: nil, tagging: nil)
          OpenSSL::ASN1::Set.new(contents.compact, *tag, *tagging)
        end

        # Creates an ASN.1 sequence instance.
        def sequence(*contents, tag: nil, tagging: nil)
          OpenSSL::ASN1::Sequence.new(contents.compact, *tag, *tagging)
        end

        # Mapping of ASN.1 object ID names to object ID strings.
        OIDS = {
          'content-type' => '1.2.840.113549.1.9.3',
          'message-digest' => '1.2.840.113549.1.9.4',
          'id-data' => '1.2.840.113549.1.7.1',
          'id-signedData' => '1.2.840.113549.1.7.2',
          'id-signingTime' => '1.2.840.113549.1.9.5',
          'sha256' => '2.16.840.1.101.3.4.2.1',
          'sha384' => '2.16.840.1.101.3.4.2.2',
          'sha512' => '2.16.840.1.101.3.4.2.3',
          'rsaEncryption' => '1.2.840.113549.1.1.1',
          'id-dsa-with-sha1' => '1.2.840.10040.4.3',
          'id-dsa-with-sha256' => '2.16.840.1.101.3.4.3.2',
          'ecdsa-with-SHA1' => '1.2.840.10045.4.1',
          'ecdsa-with-SHA256' => '1.2.840.10045.4.3.2',
          'ecdsa-with-SHA384' => '1.2.840.10045.4.3.3',
          'ecdsa-with-SHA512' => '1.2.840.10045.4.3.4',
          'id-aa-signingCertificate' => '1.2.840.113549.1.9.16.2.12',
          'id-aa-timeStampToken' => '1.2.840.113549.1.9.16.2.14',
          'id-aa-signingCertificateV2' => '1.2.840.113549.1.9.16.2.47',
        }

        # Creates an ASN.1 object ID instance for the given object ID name.
        def oid(name)
          OpenSSL::ASN1::ObjectId.new(OIDS[name])
        end

        # Creates an ASN.1 octet string instance.
        def binary(str)
          OpenSSL::ASN1::OctetString.new(str)
        end

        # Creates an ASN.1 integer instance.
        def integer(int)
          OpenSSL::ASN1::Integer.new(int)
        end

        # Creates an ASN.1 UTC time instance.
        def utc_time(value)
          OpenSSL::ASN1::UTCTime.new(value)
        end

        # Creates an ASN.1 null instance.
        def null
          OpenSSL::ASN1::Null.new(nil)
        end

      end

    end
  end
end
