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
require 'net/http'
require 'hexapdf/error'
require 'stringio'

module HexaPDF
  module DigitalSignature
    module Signing

      # This is a signing handler for adding a timestamp signature (a PDF2.0 feature) to a PDF
      # document. It is registered under the :timestamp name.
      #
      # The timestamp is provided by a timestamp authority and establishes the document contents at
      # the time indicated in the timestamp. Timestamping a PDF document is usually done in context
      # of long term validation but can also be done standalone.
      #
      # == Usage
      #
      # It is necessary to provide at least the URL of the timestamp authority server (TSA) via
      # #tsa_url, everything else is optional and uses default values. The TSA server can optionally
      # use HTTP basic authentication.
      #
      # Example:
      #
      #   document.sign("output.pdf", handler: :timestamp, tsa_url: 'https://freetsa.org/tsr')
      class TimestampHandler

        # The URL of the timestamp authority server.
        #
        # This value is required.
        attr_accessor :tsa_url

        # The username for basic authentication to the TSA server.
        #
        # If the username is not set, no basic authentication is done.
        #
        # See: #tsa_password
        attr_accessor :tsa_username

        # The password for basic authentication to the TSA server.
        #
        # See: #tsa_username
        attr_accessor :tsa_password

        # The hash algorithm to use for timestamping. Defaults to SHA512.
        attr_accessor :tsa_hash_algorithm

        # The policy OID to use for timestamping. Defaults to +nil+.
        attr_accessor :tsa_policy_id

        # The size of the serialized signature that should be reserved.
        #
        # If this attribute has not been set, an empty string will be signed using #sign to
        # determine the signature size. Note thtat this will contact the TSA server!
        #
        # The size needs to be at least as big as the final signature, otherwise signing results in
        # an error.
        attr_writer :signature_size

        # The reason for timestamping. If used, will be set on the signature dictionary.
        attr_accessor :reason

        # The timestamping location. If used, will be set on the signature dictionary.
        attr_accessor :location

        # The contact information. If used, will be set on the signature dictionary.
        attr_accessor :contact_info

        # Creates a new TimestampHandler with the given attributes.
        def initialize(**arguments)
          @signature_size = nil
          arguments.each {|name, value| send("#{name}=", value) }
        end

        # Returns the size of the serialized signature that should be reserved.
        def signature_size
          @signature_size || (sign(StringIO.new, [0, 0, 0, 0]).size * 1.5).to_i
        end

        # Finalizes the signature field as well as the signature dictionary before writing.
        def finalize_objects(_signature_field, signature)
          signature.document.version = '2.0'
          signature[:Type] = :DocTimeStamp
          signature[:Filter] = :'Adobe.PPKLite'
          signature[:SubFilter] = :'ETSI.RFC3161'
          signature[:Reason] = reason if reason
          signature[:Location] = location if location
          signature[:ContactInfo] = contact_info if contact_info
        end

        # Returns the DER serialized OpenSSL::PKCS7 structure containing the timestamp token for the
        # given IO byte ranges.
        def sign(io, byte_range)
          hash_algorithm = tsa_hash_algorithm || 'SHA512'
          digest = OpenSSL::Digest.new(hash_algorithm)
          io.pos = byte_range[0]
          digest << io.read(byte_range[1])
          io.pos = byte_range[2]
          digest << io.read(byte_range[3])

          req = OpenSSL::Timestamp::Request.new
          req.algorithm = hash_algorithm
          req.message_imprint = digest.digest
          req.policy_id = tsa_policy_id if tsa_policy_id

          url = URI(tsa_url)
          http_request = Net::HTTP::Post.new(url, 'Content-Type' => 'application/timestamp-query')
          http_request.body = req.to_der
          http_request.basic_auth(tsa_username, tsa_password) if tsa_username
          http_response = Net::HTTP.start(url.hostname, url.port, use_ssl: (url.scheme == 'https')) do |http|
            http.request(http_request)
          end

          if http_response.kind_of?(Net::HTTPOK)
            response = OpenSSL::Timestamp::Response.new(http_response.body)
            if response.status == 0
              response.token.to_der
            else
              raise HexaPDF::Error, "Timestamp token could not be created: #{response.failure_info}"
            end
          elsif http_response.kind_of?(Net::HTTPUnauthorized)
            raise HexaPDF::Error, "Basic authentication to the server failed: #{http_response.body}"
          else
            raise HexaPDF::Error, "Invalid TSA server response: #{http_response.body}"
          end
        end

      end

    end
  end
end
