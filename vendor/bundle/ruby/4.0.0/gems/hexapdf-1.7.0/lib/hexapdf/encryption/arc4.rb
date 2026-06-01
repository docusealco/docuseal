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
  module Encryption

    # Common interface for ARC4 algorithms
    #
    # This module defines the common interface that is used by the security handlers to encrypt or
    # decrypt data with ARC4. It has to be *prepended* by any ARC4 algorithm class.
    #
    # See the ClassMethods module for available class level methods of ARC4 algorithms.
    #
    # == Implementing an ARC4 Class
    #
    # An ARC4 class needs to define at least the following methods:
    #
    # initialize(key)::
    #   Initializes the ARC4 algorithm with the given key.
    #
    # process(data)::
    #   Processes the data and returns the encrypted/decrypted data. Since the ARC4 algorithm is
    #   symmetric in regards to its inner workings, the same method can be used for encryption and
    #   decryption.
    module ARC4

      # Convenience methods for decryption and encryption that operate according to the PDF
      # specification.
      #
      # These methods will be available on the class object that prepends the ARC4 module.
      module ClassMethods

        # Encrypts the given +data+ with the +key+.
        #
        # See: PDF2.0 s7.6.3
        def encrypt(key, data, &_block)
          new(key).process(data)
        end
        alias decrypt encrypt

        # Returns a Fiber object that encrypts the data from the given source fiber with the
        # +key+.
        def encryption_fiber(key, source, &_block)
          Fiber.new do
            algorithm = new(key)
            while source.alive? && (data = source.resume)
              Fiber.yield(algorithm.process(data)) unless data.empty?
            end
          end
        end
        alias decryption_fiber encryption_fiber

      end

      # Automatically extends the klass with the necessary class level methods.
      def self.prepended(klass) # :nodoc:
        klass.extend(ClassMethods)
      end

    end

  end
end
