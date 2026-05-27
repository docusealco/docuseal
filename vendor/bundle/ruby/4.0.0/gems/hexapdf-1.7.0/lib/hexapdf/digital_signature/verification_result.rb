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

module HexaPDF
  module DigitalSignature

    # Holds the result of verifying a signature.
    class VerificationResult

      MESSAGE_SORT_MAP = { # :nodoc:
        info: {warning: 1, error: 1, info: 0},
        warning: {info: -1, error: 1, warning: 0},
        error: {info: -1, warning: -1, error: 0},
      }

      # This structure represents a single status message, containing the type (:info, :warning, or
      # :error) and the content of the message.
      Message = Struct.new(:type, :content) do
        def <=>(other)
          MESSAGE_SORT_MAP[type][other.type]
        end
      end

      # An array with all result messages.
      attr_reader :messages

      # Creates an empty result object.
      def initialize
        @messages = []
      end

      # Returns +true+ if there are no error messages.
      def success?
        @messages.none? {|message| message.type == :error }
      end

      # Returns +true+ if there is at least one error message.
      def failure?
        !success?
      end

      # Adds a new message of the given type to this result object.
      #
      # +type+:: One of :info, :warning or :error.
      #
      # +content+:: The log message.
      def log(type, content)
        @messages << Message.new(type, content)
      end

    end

  end
end
