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

require 'hexapdf/type/annotations/markup_annotation'

module HexaPDF
  module Type
    module Annotations

      # Text annotations are "sticky notes" attached to a point in a PDF document. They act as if
      # the NoZoom and NoRotate flags were always set.
      #
      # See: PDF2.0 s12.5.6.4, HexaPDF::Type::MarkupAnnotation
      class Text < MarkupAnnotation

        define_field :Subtype,    type: Symbol, required: true, default: :Text
        define_field :Open,       type: Boolean, default: false
        define_field :Name,       type: Symbol, default: :Note
        define_field :State,      type: String, version: '1.5',
          allowed_values: %w[Marked Unmarked Accepted Rejected Cancelled Completed None]
        define_field :StateModel, type: String, allowed_values: ['Review', 'Marked'], version: '1.5'

        private

        STATE_TO_STATE_MODEL = { # :nodoc:
          "Marked" => "Marked", "Unmarked" => "Marked",
          "Accepted" => "Review", "Rejected" => "Review", "Cancelled" => "Review",
          "Completed" => "Review", "None" => "Review"
        }

        def perform_validation #:nodoc:
          super

          if key?(:State) && !key?(:StateModel)
            state_model = STATE_TO_STATE_MODEL[self[:State]]
            yield("/StateModel required if /State set", !state_model.nil?)
            self[:StateModel] = state_model
          elsif key?(:State) && STATE_TO_STATE_MODEL[self[:State]] != self[:StateModel]
            yield("/State and /StateModel don't agree", false)
          end
        end

      end

    end
  end
end
