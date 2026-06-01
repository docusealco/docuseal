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

require 'hexapdf/utils/math_helpers'

module HexaPDF
  module Content

    # A TransformationMatrix is a matrix used in PDF graphics operations to specify the
    # relationship between different coordinate systems.
    #
    # All matrix operations modify the matrix in place. So if the original matrix should be
    # preserved, duplicate it before the operation.
    #
    # It is important to note that the matrix transforms from the new coordinate system to the
    # untransformed coordinate system. This means that after the transformation all coordinates
    # are specified in the new, transformed coordinate system and to get the untransformed
    # coordinates the matrix needs to be applied.
    #
    # Although all operations are done in 2D space the transformation matrix is a 3x3 matrix
    # because homogeneous coordinates are used. This, however, also means that only six entries
    # are actually used that are named like in the following graphic:
    #
    #   a b 0
    #   c d 0
    #   e f 1
    #
    # Here is a simple transformation matrix to translate all coordinates by 5 units horizontally
    # and 10 units vertically:
    #
    #   1  0 0
    #   0  1 0
    #   5 10 1
    #
    # Details and some examples can be found in the PDF reference.
    #
    # See: PDF2.0 s8.3
    class TransformationMatrix

      include HexaPDF::Utils::MathHelpers

      # The value at the position (1,1) in the matrix.
      attr_reader :a

      # The value at the position (1,2) in the matrix.
      attr_reader :b

      # The value at the position (2,1) in the matrix.
      attr_reader :c

      # The value at the position (2,2) in the matrix.
      attr_reader :d

      # The value at the position (3,1) in the matrix.
      attr_reader :e

      # The value at the position (3,2) in the matrix.
      attr_reader :f

      # Initializes the transformation matrix with the given values.
      def initialize(a = 1, b = 0, c = 0, d = 1, e = 0, f = 0)
        @a = a
        @b = b
        @c = c
        @d = d
        @e = e
        @f = f
      end

      # Returns the untransformed coordinates of the given point.
      def evaluate(x, y)
        [@a * x + @c * y + @e, @b * x + @d * y + @f]
      end

      # Translates this matrix by +x+ units horizontally and +y+ units vertically and returns it.
      #
      # This is equal to premultiply(1, 0, 0, 1, x, y).
      def translate(x, y)
        @e = x * @a + y * @c + @e
        @f = x * @b + y * @d + @f
        self
      end

      # Scales this matrix by +sx+ units horizontally and +y+ units vertically and returns it.
      #
      # This is equal to premultiply(sx, 0, 0, sy, 0, 0).
      def scale(sx, sy)
        @a = sx * @a
        @b = sx * @b
        @c = sy * @c
        @d = sy * @d
        self
      end

      # Rotates this matrix by an angle of +q+ degrees and returns it.
      #
      # This equal to premultiply(cos(rad(q)), sin(rad(q)), -sin(rad(q)), cos(rad(q)), x, y).
      def rotate(q)
        cq = Math.cos(deg_to_rad(q))
        sq = Math.sin(deg_to_rad(q))
        premultiply(cq, sq, -sq, cq, 0, 0)
      end

      # Skews this matrix by an angle of +a+ degrees for the x axis and by an angle of +b+ degrees
      # for the y axis and returns it.
      #
      # This is equal to premultiply(1, tan(rad(a)), tan(rad(b)), 1, x, y).
      def skew(a, b)
        premultiply(1, Math.tan(deg_to_rad(a)), Math.tan(deg_to_rad(b)), 1, 0, 0)
      end

      # Transforms this matrix by premultiplying it with the given one (ie. given*this) and
      # returns it.
      def premultiply(a, b, c, d, e, f)
        a1 = a * @a + b * @c
        b1 = a * @b + b * @d
        c1 = c * @a + d * @c
        d1 = c * @b + d * @d
        @e = e * @a + f * @c + @e
        @f = e * @b + f * @d + @f
        @a = a1
        @b = b1
        @c = c1
        @d = d1
        self
      end

      # Returns +true+ if the other object is a transformation matrix with the same values.
      def ==(other)
        other.kind_of?(self.class) && @a == other.a && @b == other.b && @c == other.c &&
          @d == other.d && @e == other.e && @f == other.f
      end

      # Creates an array [a, b, c, d, e, f] from the transformation matrix.
      def to_a
        [@a, @b, @c, @d, @e, @f]
      end

    end

  end
end
