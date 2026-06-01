# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

module Geom2D

  # Contains utility methods and classes.
  module Utils

    autoload(:SortedList, 'geom2d/utils/sorted_list')

    # The precision when comparing two floats, defaults to 1e-10.
    singleton_class.send(:attr_accessor, :precision)
    self.precision = 1e-10

    private

    # Compares two float whether they are equal using the set precision.
    def float_equal(a, b)
      (a - b).abs < Utils.precision
    end

    # Compares two floats like the <=> operator but using the set precision for detecting whether
    # they are equal.
    def float_compare(a, b)
      result = a - b
      (result.abs < Utils.precision ? 0 : a <=> b)
    end

  end

end
