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

require 'geom2d/utils'

module HexaPDF

  # This module contains helper methods for the whole library.
  #
  # Furthermore, it refines Numeric to provide #mm, #cm, and #inch methods.
  module Utils

    refine Numeric do
      # Intrepeting self as millimeters returns the equivalent number of points.
      def mm
        self * 72 / 25.4
      end

      # Intrepeting self as centimeters returns the equivalent number of points.
      def cm
        self * 72 / 2.54
      end

      # Intrepeting self as inches returns the equivalent number of points.
      def inch
        self * 72
      end
    end

    # The precision with which to compare floating point numbers.
    #
    # This is chosen with respect to precision that is used for serializing floating point numbers.
    EPSILON = 1e-6

    # Best effort of setting Geom2D's precision to the one used by HexaPDF.
    ::Geom2D::Utils.precision = EPSILON

    private

    # Compares two floats whether they are equal using the FLOAT_EPSILON precision.
    def float_equal(a, b)
      (a - b).abs < EPSILON
    end

    # Compares two floats like the <=> operator but using the FLOAT_EPSILON precision for detecting
    # whether they are equal.
    def float_compare(a, b)
      (a - b).abs < EPSILON ? 0 : a <=> b
    end

  end
end
