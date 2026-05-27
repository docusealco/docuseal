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

  # == Overview
  #
  # A PDF document may be encrypted so that
  #
  # * certain permissions are respected when the document is opened,
  # * a password must be specified so that a document can be openend, or so that
  # * a password must be specified to remove the restrictions and allow full access.
  #
  # This module contains all encryption and security related code to facilitate PDF encryption.
  #
  # === Working With Encrypted Documents
  #
  # When a PDF document is opened, an encryption password can be specified. This is necessary if a
  # user password is set on the file and optional otherwise (because the default password is
  # automatically tried):
  #
  #   HexaPDF::Document.open(filename, decryption_opts: {password: 'somepassword'}) do |doc|
  #   end
  #
  # To remove the encryption from a PDF document, use the following:
  #
  #   document.encrypt(name: nil)
  #
  # To encrypt a PDF document, use the same method but specify the required encryption options:
  #
  #   document.encrypt(algorithm: :aes, key_length: 256)
  #
  #
  # === Security Handlers
  #
  # Security handlers manage the process of encrypting and decrypting a PDF document. One of the
  # main responsibilities of them is providing the encryption key that is then used by the
  # selected encryption algorithm (see below). However, security handlers may also provide
  # additional information.
  #
  # The Encryption::SecurityHandler is the base class for all such security handlers. It defines the
  # interface and all common code for encrypting and decrypting strings and streams.
  #
  # The PDF specification also defines a password-based standard security handler that
  # additionally allows setting permission information. This security handler is implemented by
  # the Encryption::StandardSecurityHandler class.
  #
  # There is also a certificate-based security handler defined by the PDF specification. However,
  # that handler is not implemented.
  #
  #
  # === Encryption Algorithms
  #
  # PDF security is based on two algorithms with varying key lengths: ARC4 and AES. The ARC4 and
  # AES modules contain code common to their specific algorithm and are adapted to work together
  # with any SecurityHandler.
  #
  # There are at least two versions of each algorithm present:
  #
  # FastAES and FastARC4::
  #   The preferred versions which are based on OpenSSL and therefore rely on the OpenSSL library
  #   and a C extension.
  #
  # RubyAES and RubyARC4::
  #   Pure Ruby implementations of the algorithms which are naturally much slower than the OpenSSL
  #   based ones. However, these implementation can be used on any Ruby implementation.
  #
  # The ARC4 algorithm is deprecated with PDF 2.0 and should not be used when creating new
  # documents.
  #
  # See: PDF2.0 s7.6
  module Encryption

    autoload(:ARC4, 'hexapdf/encryption/arc4')
    autoload(:AES, 'hexapdf/encryption/aes')
    autoload(:FastARC4, "hexapdf/encryption/fast_arc4")
    autoload(:RubyARC4, "hexapdf/encryption/ruby_arc4")
    autoload(:FastAES, "hexapdf/encryption/fast_aes")
    autoload(:RubyAES, "hexapdf/encryption/ruby_aes")
    autoload(:Identity, "hexapdf/encryption/identity")

    autoload(:SecurityHandler, 'hexapdf/encryption/security_handler')
    autoload(:StandardSecurityHandler, 'hexapdf/encryption/standard_security_handler')

  end
end
