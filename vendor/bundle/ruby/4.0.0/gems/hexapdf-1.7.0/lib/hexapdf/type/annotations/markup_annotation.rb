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

require 'hexapdf/type/annotation'

module HexaPDF
  module Type
    module Annotations

      # Markup annotations are used to "mark up" a PDF document, most of the available PDF
      # annotations are actually markup annotations.
      #
      # See: PDF2.0 s12.5.6.2, HexaPDF::Type::Annotation
      class MarkupAnnotation < Annotation

        # External data dictionary used by some markup annotation types.
        #
        # See: PDF2.0 s12.5.6.2
        class ExData < Dictionary

          define_type :ExData

          define_field :Type,    type: Symbol, required: true, default: type
          define_field :Subtype, type: Symbol, required: true,
                       allowed_values: [:Markup3D, :'3DM', :MarkupGeo]

        end

        define_field :T,            type: String, version: '1.1'
        define_field :Popup,        type: :Annot, version: '1.3'
        define_field :RC,           type: [Stream, String], version: '1.5'
        define_field :CreationDate, type: PDFDate, version: '1.5'
        define_field :IRT,          type: Dictionary, version: '1.5'
        define_field :Subj,         type: String, version: '1.5'
        define_field :RT,           type: Symbol, default: :R, allowed_values: [:R, :Group],
                                    version: '1.6'
        define_field :IT,           type: Symbol, version: '1.6'
        define_field :ExData,       type: :ExData, version: '1.7'

        private

        def perform_validation #:nodoc:
          super
          if key?(:RT) && !key?(:IRT)
            yield("/IRT required if /RT field is set")
          end
        end

      end

    end
  end
end
