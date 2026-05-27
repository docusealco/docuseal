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

require 'hexapdf/dictionary'
require 'hexapdf/utils/sorted_tree_node'

module HexaPDF

  # Implementation of PDF number trees.
  #
  # Number trees are similar to name trees but use integers as keys instead of strings. See
  # HexaPDF::NameTreeNode for a more detailed explanation.
  #
  # See: PDF2.0 s7.9.7, HexaPDF::NameTreeNode
  class NumberTreeNode < Dictionary

    include Utils::SortedTreeNode

    define_field :Kids,   type: PDFArray
    define_field :Nums,   type: PDFArray
    define_field :Limits, type: PDFArray

    private

    # Defines the dictionary entry name that contains the leaf node entries.
    def leaf_node_container_name
      :Nums
    end

    # Defines the class that is used for the keys in the number tree (Integer).
    def key_type
      Integer
    end

  end

end
