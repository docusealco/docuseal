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

require 'hexapdf/type/annotations'

module HexaPDF
  module Type
    module Annotations

      # This module provides a convenience method for getting and setting the border effect for
      # square, circle and polygon annotations.
      #
      # See: PDF2.0 s12.5.4
      module BorderEffect

        # :call-seq:
        #   annot.border_effect         => border_effect
        #   annot.border_effect(type)   => annot
        #
        # Returns the border effect of the annotation when no argument is given. Otherwise sets the
        # border effect of the annotation and returns self.
        #
        # The argument type can have the following values:
        #
        # +:none+:: No border effect is used.
        #
        # +:cloudy+:: The border appears "cloudy" (as a series of convex curved line segments).
        #
        # +:cloudier+:: Like +:cloudy+ but more intense.
        #
        # +:cloudiest+:: Like +:cloudier+ but still more intense.
        def border_effect(type = :UNSET)
          if type == :UNSET
            be = self[:BE]
            if !be || be[:S] != :C
              :none
            else
              case be[:I]
              when 0 then :cloudy
              when 1 then :cloudier
              when 2 then :cloudiest
              else :cloudy
              end
            end
          else
            case type
            when nil, :none
              delete(:BE)
            when :cloudy
              self[:BE] = {S: :C, I: 0}
            when :cloudier
              self[:BE] = {S: :C, I: 1}
            when :cloudiest
              self[:BE] = {S: :C, I: 2}
            else
              raise ArgumentError, "Unknown value #{type} for type argument"
            end
            self
          end
        end

      end

    end
  end
end
