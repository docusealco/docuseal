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

require 'hexapdf/type/action'

module HexaPDF
  module Type
    module Actions

      # A Launch action dictionary launches an application, opens a document or prints a document.
      #
      # See: PDF2.0 s12.6.4.6
      class Launch < Action

        # The type used for the /Win field of a Launch action dictionary.
        class WinParameters < Dictionary

          define_type :XXLaunchActionWinParameters

          define_field :F, type: PDFByteString, required: true
          define_field :D, type: PDFByteString
          define_field :O, type: String, default: 'open', allowed_values: ['open', 'print']
          define_field :P, type: PDFByteString

        end

        define_field :S,         type: Symbol, required: true, default: :Launch
        define_field :F,         type: :Filespec
        define_field :Win,       type: :XXLaunchActionWinParameters
        define_field :Mac,       type: ::Object, version: '2.0'
        define_field :Unix,      type: ::Object, version: '2.0'
        define_field :NewWindow, type: Boolean, version: '1.2'

        private

        def perform_validation #:nodoc:
          super
          unless key?(:Win) || key?(:Mac) || key?(:Unix) || key?(:F)
            yield("Launch action key /F required if /Win, /Mac and /Unix are absent")
          end
        end

      end

    end
  end
end
