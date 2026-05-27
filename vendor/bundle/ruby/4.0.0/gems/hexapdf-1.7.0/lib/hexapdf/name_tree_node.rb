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

  # Implementation of PDF name trees.
  #
  # Name trees are used in a similar fashion as dictionaries, however, the key in a name tree is
  # always a string instead of a symbol. Another difference is that the keys in a name tree are
  # always sorted to allow fast lookup of a specific key.
  #
  # A name tree consists of one or more NameTreeNodes. If there is only one node, it contains all
  # stored associations in the /Names entry. Otherwise the root node needs to have a /Kids entry
  # that points to one or more intermediate or leaf nodes. An intermediate node contains a /Kids
  # entry whereas a leaf node contains a /Names entry.
  #
  # Since this is a complex structure that must follow several restrictions, it is not advised to
  # build a name tree manually. Instead, use the provided convenience methods (see
  # HexaPDF::Utils::SortedTreeNode) to add or retrieve entries. They ensure that the name tree stays
  # valid.
  #
  # See: PDF2.0 s7.9.6
  class NameTreeNode < Dictionary

    include Utils::SortedTreeNode

    define_field :Kids,   type: PDFArray
    define_field :Names,  type: PDFArray
    define_field :Limits, type: PDFArray

    private

    # Defines the dictionary entry name that contains the leaf node entries.
    def leaf_node_container_name
      :Names
    end

    # Defines the class that is used for the keys in the name tree (String).
    def key_type
      String
    end

  end

end
