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

  # PDF documents can be signed using digital signatures. Such a signature can be used to
  # authenticate the identity of the signer and the contents of the documents.
  #
  # This module contains all code related to digital signatures in PDF:
  #
  # * Signatures provides the convenience interface accessible via Document#signatures.
  # * Signature implements the PDF signature dictionary.
  # * BaseHandler, CMSHandler and PKCS1Handler are used for verifying existing signatures.
  # * The Signing module implements the functionality for creating digital signatures.
  #
  # See: PDF2.0 s12.8
  module DigitalSignature

    autoload(:Signatures, 'hexapdf/digital_signature/signatures')
    autoload(:Signature, "hexapdf/digital_signature/signature")
    autoload(:Handler, 'hexapdf/digital_signature/handler')
    autoload(:CMSHandler, "hexapdf/digital_signature/cms_handler")
    autoload(:PKCS1Handler, "hexapdf/digital_signature/pkcs1_handler")
    autoload(:VerificationResult, 'hexapdf/digital_signature/verification_result')
    autoload(:Signing, 'hexapdf/digital_signature/signing')

  end
end
