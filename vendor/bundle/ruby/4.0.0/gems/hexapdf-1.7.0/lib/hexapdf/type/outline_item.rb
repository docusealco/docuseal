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
require 'hexapdf/utils/bit_field'
require 'hexapdf/content/color_space'

module HexaPDF
  module Type

    # Represents an outline item dictionary.
    #
    # An item has a title and some optional attributes: the action that is activated when clicking
    # (either a simple destination or an explicit action object), the text color, and flags (whether
    # the text should appear bold and/or italic).
    #
    # Additionally, items may have child items which makes it possible to create a hierarchy of
    # items.
    #
    # If no destination/action is set, the item just acts as kind of a header. It usually only makes
    # sense to do this when the item has children.
    #
    # Outline item dictionaries are connected together in the form of a linked list using the /Next
    # and /Prev keys. Each item may have descendant items. If so, the /First and /Last keys point to
    # respectively the first and last descendant items.
    #
    # Since many dictionary keys need to be kept up-to-date when manipulating the outline item tree,
    # it is not recommended to manually do this but to rely on the provided convenience methods.
    #
    # See: PDF2.0 s12.3.3
    class OutlineItem < Dictionary

      extend Utils::BitField

      define_type :XXOutlineItem

      define_field :Title,  type: String, required: true
      define_field :Parent, type: Dictionary, required: true, indirect: true
      define_field :Prev,   type: :XXOutlineItem, indirect: true
      define_field :Next,   type: :XXOutlineItem, indirect: true
      define_field :First,  type: :XXOutlineItem, indirect: true
      define_field :Last,   type: :XXOutlineItem, indirect: true
      define_field :Count,  type: Integer
      define_field :Dest,   type: [Symbol, PDFByteString, PDFArray]
      define_field :A,      type: :Action, version: '1.1'
      define_field :SE,     type: Dictionary, indirect: true
      define_field :C,      type: PDFArray, default: [0, 0, 0], version: '1.4'
      define_field :F,      type: Integer, default: 0, version: '1.4'

      ##
      # :method: flags
      #
      # Returns an array of flag names representing the set bit flags for /F.
      #
      # The available flags are:
      #
      # :italic or 0:: The text is displayed in italic.
      # :bold or 1:: The text is displayed in bold.
      #

      ##
      # :method: flagged?
      # :call-seq:
      #   flagged?(flag)
      #
      # Returns +true+ if the given flag is set on /F. The argument can either be the flag name or
      # the bit index.
      #
      # See #flags for the list of available flags.
      #

      ##
      # :method: flag
      # :call-seq:
      #   flag(*flags, clear_existing: false)
      #
      # Sets the given flags on /F, given as flag names or bit indices. If +clear_existing+ is
      # +true+, all prior flags will be cleared.
      #
      # See #flags for the list of available flags.
      #

      ##
      # :method: unflag
      # :call-seq:
      #   flag(*flags)
      #
      # Clears the given flags from /F, given as flag names or bit indices.
      #
      # See #flags for the list of available flags.
      #
      bit_field(:flags, {italic: 0, bold: 1},
                lister: "flags", getter: "flagged?", setter: "flag", unsetter: "unflag",
                value_getter: "self[:F]", value_setter: "self[:F]")

      # Returns +true+ since outline items must always be indirect objects.
      def must_be_indirect?
        true
      end

      # :call-seq:
      #   item.title          -> title
      #   item.title(value)   -> title
      #
      # Returns the item's title if no argument is given. Otherwise sets the title to the given
      # value.
      def title(value = nil)
        if value
          self[:Title] = value
        else
          self[:Title]
        end
      end

      # :call-seq:
      #   item.text_color               -> color
      #   item.text_color(color)        -> color
      #
      # Returns the item's text color as HexaPDF::Content::ColorSpace::DeviceRGB::Color object if no
      # argument is given. Otherwise sets the text color, see
      # HexaPDF::Content::ColorSpace.device_color_from_specification for possible +color+ values.
      #
      # Note: The color *has* to be an RGB color.
      def text_color(color = nil)
        if color
          color = HexaPDF::Content::ColorSpace.device_color_from_specification(color)
          unless color.color_space.family == :DeviceRGB
            raise ArgumentError, "The given argument is not a valid RGB color"
          end
          self[:C] = color.components
        else
          Content::ColorSpace.prenormalized_device_color(self[:C])
        end
      end

      # :call-seq:
      #   item.destination             -> destination
      #   item.destination(value)      -> destination
      #
      # Returns the item's destination if no argument is given. Otherwise sets the destination to
      # the given value (see HexaPDF::Document::Destinations#use_or_create for the posssible
      # values).
      #
      # If an action is set, the destination has to be unset; and vice versa. So when setting a
      # destination value, the action is automatically deleted.
      def destination(value = nil)
        if value
          delete(:A)
          self[:Dest] = document.destinations.use_or_create(value)
        else
          self[:Dest]
        end
      end

      # :call-seq:
      #   item.action             -> action
      #   item.action(value)      -> action
      #
      # Returns the item's action if no argument is given. Otherwise sets the action to
      # the given value (needs to be a valid HexaPDF::Type::Action dictionary).
      #
      # If an action is set, the destination has to be unset; and vice versa. So when setting an
      # action value, the destination is automatically deleted.
      def action(value = nil)
        if value
          delete(:Dest)
          self[:A] = value
        else
          self[:A]
        end
      end

      # Returns the outline level this item is one.
      #
      # The level of the items in the main outline dictionary, the root level, is 1.
      #
      # Here is an illustrated example of items contained in a document outline with their
      # associated level:
      #
      #  Outline dictionary          0
      #    Outline item 1            1
      #    |- Sub item 1             2
      #    |- Sub item 2             2
      #       |- Sub sub item 1      3
      #    |- Sub item 3             2
      #    Outline item 2            1
      def level
        count = 0
        temp = self
        count += 1 while (temp = temp[:Parent])
        count
      end

      # Returns the open state of the item.
      #
      # +true+::  If this item is open, i.e. showing its child items.
      # +false+:: If this item is closed, i.e. not showing its child items.
      # +nil+::   If this item doesn't (yet) have any child items.
      def open?
        self[:First] && key?(:Count) && self[:Count] >= 0
      end

      # Returns the destination page if there is any.
      #
      # * If a destination is set, the associated page is returned.
      # * If an action is set and it is a GoTo action, the associated page is returned.
      # * Otherwise +nil+ is returned.
      def destination_page
        dest = self[:Dest]
        dest = action[:D] if !dest && (action = self[:A]) && action[:S] == :GoTo
        document.destinations.resolve(dest)&.page
      end

      # Adds, as child to this item, a new outline item with the given title that performs the
      # provided action on clicking. Returns the newly added item.
      #
      # Alternatively, it is possible to provide an already initialized outline item instead of the
      # title. If so, the only other argument that is used is +position+. Existing fields /Prev,
      # /Next, /First, /Last, /Parent and /Count are deleted from the given item and set
      # appropriately.
      #
      # If neither :destination nor :action is specified, the outline item has no associated action.
      # This is only meaningful if the new item will have children as it then acts just as a
      # container.
      #
      # If a block is specified, the newly created item is yielded.
      #
      # destination::
      #
      #     Specifies the destination that should be activated when clicking on the outline item.
      #     See HexaPDF::Document::Destinations#use_or_create for details. The argument :action
      #     takes precedence if it is also specified,
      #
      # action::
      #
      #     Specifies the action that should be taken when clicking on the outline item. See
      #     HexaPDF::Type::Action for details. If the argument :destination is also specified, the
      #     :action argument takes precedence.
      #
      # position::
      #
      #     The position where the new child item should be inserted. Can either be:
      #
      #     +:first+:: Insert as first item
      #     +:last+:: Insert as last item (default)
      #     Integer:: When non-negative inserts before, otherwise after, the item at the given
      #               zero-based index.
      #
      # open::
      #
      #     Specifies whether the outline item should be open (i.e. one or more children are shown)
      #     or closed. Default: +true+.
      #
      # text_color::
      #
      #     The text color of the outline item text which needs to be a valid RGB color (see
      #     #text_color for details). If not set, the text appears in black.
      #
      # flags::
      #
      #     An array of font variants (possible values are :bold and :italic) to set for the outline
      #     item text, see #flags for detail. Default is to use no variant.
      #
      # Examples:
      #
      #   doc.destinations.add("Title") do |item|                  # no action, just container
      #     item.add("Second subitem", destination: doc.pages[1])  # links to page 2
      #     item.add("First subitem", position: :first, destination: doc.pages[0])
      #   end
      def add_item(title, destination: nil, action: nil, position: :last, open: true,
                   text_color: nil, flags: nil) # :yield: item
        if title.kind_of?(HexaPDF::Object) && title.type == :XXOutlineItem
          item = title
          item.delete(:Prev)
          item.delete(:Next)
          item.delete(:First)
          item.delete(:Last)
          if item[:Count] && item[:Count] >= 0
            item[:Count] = 0
          else
            item.delete(:Count)
          end
          item[:Parent] = self
        else
          item = document.add({Parent: self}, type: :XXOutlineItem)
          item.title(title)
          if action
            item.action(action)
          else
            item.destination(destination)
          end
          item.text_color(text_color) if text_color
          item.flag(*flags) if flags
          item[:Count] = 0 if open # Count=0 means open if items are later added
        end

        unless position == :last || position == :first || position.kind_of?(Integer)
          raise ArgumentError, "position must be :first, :last, or an integer"
        end
        if self[:First]
          case position
          when :last, -1
            item[:Prev] = self[:Last]
            self[:Last][:Next] = item
            self[:Last] = item
          when :first, 0
            item[:Next] = self[:First]
            self[:First][:Prev] = item
            self[:First] = item
          when Integer
            temp, direction = if position > 0
                                [self[:First], :Next]
                              else
                                position = -position - 2
                                [self[:Last], :Prev]
                              end
            position.times { temp &&= temp[direction] }
            raise ArgumentError, "position out of bounds" if temp.nil?
            item[:Prev] = temp[:Prev]
            item[:Next] = temp
            temp[:Prev] = item
            item[:Prev][:Next] = item
          end
        else
          self[:First] = self[:Last] = item
        end

        # Re-calculate /Count entries
        temp = self
        while temp
          if !temp.key?(:Count) || temp[:Count] < 0
            temp[:Count] = (temp[:Count] || 0) - 1
            break
          else
            temp[:Count] += 1
          end
          temp = temp[:Parent]
        end

        yield(item) if block_given?

        item
      end

      # :call-seq:
      #   item.each_item {|descendant_item, level| block }   -> item
      #   item.each_item                                     -> Enumerator
      #
      # Iterates over all descendant items of this one.
      #
      # The descendant items are yielded in-order, yielding first the item itself and then its
      # descendants.
      def each_item(&block)
        return to_enum(__method__) unless block_given?
        return self unless (item = self[:First])

        level = self.level + 1
        while item
          yield(item, level)
          item.each_item(&block)
          item = item[:Next]
        end

        self
      end

      private

      def perform_validation # :nodoc:
        super
        first = self[:First]
        last = self[:Last]
        if (first && !last) || (!first && last)
          yield('Outline item dictionary is missing an endpoint reference', true)
          node, dir = first ? [first, :Next] : [last, :Prev]
          node = node[dir] while node[dir]
          self[dir == :Next ? :Last : :First] = node
        elsif !first && !last && self[:Count] && self[:Count] != 0
          yield('Outline item dictionary key /Count set but no descendants exist', true)
          delete(:Count)
        end

        prev_item = self[:Prev]
        if prev_item && (prev_item_next = prev_item[:Next]) != self
          if prev_item_next
            yield('Outline item /Prev points to item whose /Next points somewhere else', false)
          else
            yield('Outline item /Prev points to item without /Next', true)
            prev_item[:Next] = self
          end
        end

        next_item = self[:Next]
        if next_item && (next_item_prev = next_item[:Prev]) != self
          if next_item_prev
            yield('Outline item /Next points to item whose /Prev points somewhere else', false)
          else
            yield('Outline item /Next points to item without /Prev', true)
            next_item[:Prev] = self
          end
        end
      end

    end

  end
end
