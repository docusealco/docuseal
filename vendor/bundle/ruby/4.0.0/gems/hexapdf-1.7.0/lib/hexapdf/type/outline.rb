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

module HexaPDF
  module Type

    # Represents the root of the PDF's document outline containing a hierarchy of outline items
    # (sometimes called bookmarks) in a linked list.
    #
    # The document outline usually contains items for the sections of the document, so that clicking
    # on an item opens the page where the section starts (the section header is). Most PDF viewers
    # are able to display the outline to aid in navigation, though not all apply the optional
    # attributes like the text color.
    #
    # The outline dictionary is linked via the /Outlines entry from the Type::Catalog and can
    # directly be accessed via HexaPDF::Document#outline.
    #
    # == Examples
    #
    # Here is an example for creating an outline:
    #
    #   doc = HexaPDF::Document.new
    #   5.times { doc.pages.add }
    #   doc.outline.add_item("Section 1", destination: 0) do |sec1|
    #     sec1.add_item("Page 2", destination: doc.pages[1])
    #     sec1.add_item("Page 3", destination: 2)
    #     sec1.add_item("Section 1.1", text_color: "red", flags: [:bold]) do |sec11|
    #       sec11.add_item("Page 4", destination: 3)
    #     end
    #   end
    #
    # Here is one for copying the complete outline from one PDF to another:
    #
    #   doc = HexaPDF::Document.open(ARGV[0])
    #   target = HexaPDF::Document.new
    #   stack = [target.outline]
    #   doc.outline.each_item do |item, level|
    #     if stack.size < level
    #       stack << stack.last[:Last]
    #     elsif stack.size > level
    #       (stack.size - level).times { stack.pop }
    #     end
    #     stack.last.add_item(target.import(item))
    #   end
    #   # Copying all the pages so that the references work.
    #   doc.pages.each {|page| target.pages << target.import(page) }
    #
    # See: PDF2.0 s12.3.3
    class Outline < Dictionary

      define_type :Outlines

      define_field :Type,  type: Symbol, default: type
      define_field :First, type: :XXOutlineItem, indirect: true
      define_field :Last,  type: :XXOutlineItem, indirect: true
      define_field :Count, type: Integer

      # Adds a new top-level outline item.
      #
      # See OutlineItem#add_item for details on the available options since this method just passes
      # all arguments through to it.
      def add_item(title, **options, &block)
        self[:Count] ||= 0
        self_as_item.add_item(title, **options, &block)
      end

      # :call-seq:
      #   outline.each_item {|item| block }   -> item
      #   outline.each_item                   -> Enumerator
      #
      # Iterates over all items of the outline.
      #
      # The items are yielded in-order, yielding first the item itself and then its descendants.
      def each_item(&block)
        self_as_item.each_item(&block)
      end

      private

      # Represents the outline dictionary as an outline item dictionary to make use of some of its
      # methods.
      def self_as_item
        @self_as_item ||= document.wrap(self, type: :XXOutlineItem)
      end

      # Makes sure the required values are set.
      def perform_validation
        super
        first = self[:First]
        last = self[:Last]
        if (first && !last) || (!first && last)
          yield('Outline dictionary is missing an endpoint reference', true)
          node, dir = first ? [first, :Next] : [last, :Prev]
          node = node[dir] while node[dir]
          self[dir == :Next ? :Last : :First] = node
        elsif !first && !last && self[:Count] && self[:Count] != 0
          yield('Outline dictionary key /Count set but no items exist', true)
          delete(:Count)
        end
      end

    end

  end
end
