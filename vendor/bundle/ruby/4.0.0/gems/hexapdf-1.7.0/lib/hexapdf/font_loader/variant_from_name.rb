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

require 'hexapdf/font/true_type_wrapper'
require 'hexapdf/font_loader/from_file'

module HexaPDF
  module FontLoader

    # This module translates font names like 'Helvetica bold' into the arguments 'Helvetica' and
    # {variant: :bold}.
    #
    # This eases the usage of font names where specifying a font variant is not straight-forward.
    # The actual loading of the font is deferred to Document::Fonts#add.
    #
    # Note that this should be the last entry in the list of font loaders to ensure correct
    # operation.
    module VariantFromName

      # Returns a font wrapper for the given font by splitting the font name into the font name part
      # and variant selector part. If the the resulting font cannot be resolved, +nil+ is returned.
      #
      # A font name should have the form 'Fontname selector' where selector can be 'bold', 'italic'
      # or 'bold_italic', for example 'Helvetica bold'.
      #
      # Note that a supplied :variant keyword argument is ignored!
      def self.call(document, name, recursive_invocation: false, **options)
        return if recursive_invocation
        name, variant = name.split(/ (?=(?:bold|italic|bold_italic)\z)/, 2)
        return if variant.nil?

        options[:variant] = variant.to_sym
        document.fonts.add(name, **options, recursive_invocation: true) rescue nil
      end

    end

  end
end
