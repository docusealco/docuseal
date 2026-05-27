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

require 'hexapdf/error'

module HexaPDF
  class Document

    # This class provides methods for managing the pages and page labels of a PDF file.
    #
    # For page manipulation it uses the methods of HexaPDF::Type::PageTreeNode underneath but
    # provides a more convenient interface.
    #
    # == Page Labels
    #
    # In addition to page manipulation, the class provides methods for managing the page labels
    # which are alternative descriptions for the pages. In contrast to the page indices which are
    # fixed the page labels can be freely defined.
    #
    # The way this works is that one can assign page label objects (HexaPDF::Type::PageLabel) to
    # page ranges via the /PageLabels number tree in the catalog. The page label objects specify how
    # the pages in their range shall be labeled. See HexaPDF::Type::PageLabel for examples of page
    # labels.
    #
    # To facilitate the easy use of page labels the following methods are provided:
    #
    # * #page_label
    # * #each_labelling_range
    # * #add_labelling_range
    # * #delete_labelling_range
    class Pages

      include Enumerable

      # Creates a new Pages object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # Returns the root of the page tree, a HexaPDF::Type::PageTreeNode object.
      def root
        @document.catalog.pages
      end

      # Creates a page object and returns it *without* adding it to the page tree.
      #
      # +media_box+::
      #     If this argument is +nil+/not specified, the value is taken from the configuration
      #     option 'page.default_media_box'.
      #
      #     If the resulting value is an array with four numbers (specifying the media box), the new
      #     page will have these exact dimensions.
      #
      #     If the value is a symbol, it is taken as a reference to a pre-defined media box in
      #     HexaPDF::Type::Page::PAPER_SIZE. The +orientation+ can then be used to specify the page
      #     orientation.
      #
      # +orientation+::
      #     If this argument is not specified, it is taken from 'page.default_media_orientation'. It
      #     is only used if +media_box+ is a symbol and not an array.
      def create(media_box: nil, orientation: nil)
        media_box ||= @document.config['page.default_media_box']
        orientation ||= @document.config['page.default_media_orientation']
        box = Type::Page.media_box(media_box, orientation: orientation)
        @document.add({Type: :Page, MediaBox: box})
      end

      # :call-seq:
      #   pages.add                               -> new_page
      #   pages.add(page)                         -> page
      #   pages.add(media_box, orientation: nil)  -> new_page
      #
      # Adds the given page or a new empty page at the end and returns it.
      #
      # If called with a page object as argument, that page object is used. Otherwise #create is
      # called with the arguments +media_box+ and +orientation+ to create a new page.
      def add(page = nil, orientation: nil)
        unless page.kind_of?(HexaPDF::Type::Page)
          page = create(media_box: page, orientation: orientation)
        end
        @document.catalog.pages.add_page(page)
      end

      # :call-seq:
      #   pages << page            -> pages
      #
      # Appends the given page at the end and returns the pages object itself to allow chaining.
      def <<(page)
        add(page)
        self
      end

      # Inserts the page or a new empty page at the zero-based index and returns it.
      #
      # Negative indices count backwards from the end, i.e. -1 is the last page. When using
      # negative indices, the page will be inserted after that element. So using an index of -1
      # will insert the page after the last page.
      def insert(index, page = nil)
        @document.catalog.pages.insert_page(index, page)
      end

      # :call-seq:
      #   pages.move(page, to_index)
      #   pages.move(index, to_index)
      #
      # Moves the given page or the page at the position specified by the zero-based index to the
      # +to_index+ position.
      #
      # If the page that should be moved, doesn't exist or is invalid, an error is raised.
      #
      # Negative indices count backwards from the end, i.e. -1 is the last page. When using a
      # negative index, the page will be moved after that element. So using an index of -1 will
      # move the page after the last page.
      def move(page, to_index)
        @document.catalog.pages.move_page(page, to_index)
      end

      # Deletes the given page object from the document's page tree and the document.
      #
      # Also see: HexaPDF::Type::PageTreeNode#delete_page
      def delete(page)
        @document.catalog.pages.delete_page(page)
      end

      # Deletes the page object at the given index from the document's page tree and the document.
      #
      # Also see: HexaPDF::Type::PageTreeNode#delete_page
      def delete_at(index)
        @document.catalog.pages.delete_page(index)
      end

      # Returns the page for the zero-based index, or +nil+ if no such page exists.
      #
      # Negative indices count backwards from the end, i.e. -1 is the last page.
      def [](index)
        @document.catalog.pages.page(index)
      end

      # :call-seq:
      #   pages.each {|page| block }   -> pages
      #   pages.each                   -> Enumerator
      #
      # Iterates over all pages inorder.
      def each(&block)
        @document.catalog.pages.each_page(&block)
      end

      # Returns the number of pages in the PDF document. May be zero if the document has no pages
      # yet.
      def count
        @document.catalog.pages.page_count
      end
      alias size count
      alias length count

      # Returns the constructed page label for the given page index.
      #
      # If no page labels are defined, +nil+ is returned.
      #
      # See HexaPDF::Type::PageLabel for examples.
      def page_label(page_index)
        raise(ArgumentError, 'Page index out of range') if page_index < 0 || page_index >= count
        each_labelling_range do |index, count, label|
          if page_index < index + count
            return label.construct_label(page_index - index)
          end
        end
      end

      # :call-seq:
      #   pages.each_labelling_range {|first_index, count, page_label| block }   -> pages
      #   pages.each_labelling_range                                             -> Enumerator
      #
      # Iterates over all defined labelling ranges inorder, yielding the page index of the first
      # page in the labelling range, the number of pages in the range, and the associated page label
      # object.
      #
      # The last yielded count might be equal or lower than zero in case the document has fewer
      # pages than anticipated by the labelling ranges.
      def each_labelling_range
        return to_enum(__method__) unless block_given?
        return unless @document.catalog.page_labels

        last_start = nil
        last_label = nil
        @document.catalog.page_labels.each_entry do |s1, p1|
          yield(last_start, s1 - last_start, @document.wrap(last_label, type: :PageLabel)) if last_start
          last_start = s1
          last_label = p1
        end
        if last_start
          yield(last_start, count - last_start, @document.wrap(last_label, type: :PageLabel))
        end

        self
      end

      # Adds a new labelling range starting at +start_index+ and returns it.
      #
      # See HexaPDF::Type::PageLabel for information on the arguments +numbering_style+, +prefix+,
      # and +start_number+.
      #
      # If a labelling range already exists for the given +start_index+, its value will be
      # overwritten.
      #
      # If there are no existing labelling ranges and the given +start_index+ isn't 0, a default
      # labelling range using start index 0 and numbering style :decimal is added.
      def add_labelling_range(start_index, numbering_style: nil, prefix: nil, start_number: nil)
        page_label = @document.wrap({}, type: :PageLabel)
        page_label.numbering_style(numbering_style) if numbering_style
        page_label.prefix(prefix) if prefix
        page_label.start_number(start_number) if start_number

        labels = @document.catalog.page_labels(create: true)
        labels.add_entry(start_index, page_label)
        labels.add_entry(0, {S: :D}) unless labels.find_entry(0)

        page_label
      end

      # Deletes the page labelling range starting at +start_index+ and returns the associated page
      # label object.
      #
      # Note: The page label for the range starting at zero can only be deleted last!
      def delete_labelling_range(start_index)
        return unless (labels = @document.catalog.page_labels)
        if start_index == 0 && labels.each_entry.first(2).size == 2
          raise HexaPDF::Error, "Page labelling range starting at 0 must be deleted last"
        end
        page_label = labels.delete_entry(start_index)
        @document.catalog.delete(:PageLabels) if start_index == 0
        page_label
      end

    end

  end
end
