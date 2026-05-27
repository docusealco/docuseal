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
require 'hexapdf/error'

module HexaPDF
  class Document

    # This class provides methods for creating and managing the destinations of a PDF file.
    #
    # A destination describes a particular view of a PDF document, consisting of the page, the view
    # location and a magnification factor. See Destination for details.
    #
    # Such destinations may be directly specified where needed, e.g. for link annotations, or they
    # may be named and later referenced through the name. This class allows to create destinations
    # with or without a name.
    #
    # See: PDF2.0 s12.3.2
    class Destinations

      # Wraps an explicit destination array to allow easy access to query its properties.
      #
      # A *destination array* has the form
      #
      #   [page, type, *arguments]
      #
      # where +page+ is either a page object or a page number (in case of a destination to a page in
      # a remote PDF document), +type+ is the destination type (see below) and +arguments+ are the
      # required arguments for the specific type of destination.
      #
      # == Destination Types
      #
      # There are eight different types of destinations, each taking different arguments. The
      # arguments are marked up in the list below and are in the correct order for use in the
      # destination array. The first name in the list is the PDF internal name, the second one the
      # explicit, more descriptive one used by HexaPDF (though the PDF internal name can also be
      # used):
      #
      # :XYZ, :xyz::
      #     Display the page with the given (+left+, +top+) coordinate at the upper-left corner of
      #     the window and the specified magnification (+zoom+) factor. A +nil+ value for any
      #     argument means not changing it from the current value.
      #
      # :Fit, :fit_page::
      #     Display the page so that it fits horizontally and vertically within the window.
      #
      # :FitH, :fit_page_horizontal::
      #     Display the page so that it fits horizontally within the window, with the given +top+
      #     coordinate being at the top of the window. A +nil+ value for +top+ means not changing it
      #     from the current value.
      #
      # :FitV, :fit_page_vertical::
      #     Display the page so that it fits vertically within the window, with the given +left+
      #     coordinate being at the left of the window. A +nil+ value for +left+ means not changing
      #     it from the current value.
      #
      # :FitR, :fit_rectangle::
      #     Display the page so that the rectangle specified by (+left+, +bottom+)-(+right+, +top+)
      #     fits horizontally and vertically within the window.
      #
      # :FitB, :fit_bounding_box::
      #     Display the page so that its bounding box fits horizontally and vertically within the
      #     window.
      #
      # :FitBH, :fit_bounding_box_horizontal::
      #     Display the page so that its bounding box fits horizontally within the window, with the
      #     given +top+ coordinate being at the top of the window. A +nil+ value for +top+ means not
      #     changing it from the current value.
      #
      # :FitBV, :fit_bounding_box_vertical::
      #     Display the page so that its bounding box fits vertically within the window, with the
      #     given +left+ coordinate being at the left of the window. A +nil+ value for +left+ means
      #     not changing it from the current value.
      class Destination

        TYPE_MAPPING = { #:nodoc:
          XYZ: :xyz,
          Fit: :fit_page,
          FitH: :fit_page_horizontal,
          FitV: :fit_page_vertical,
          FitR: :fit_rectangle,
          FitB: :fit_bounding_box,
          FitBH: :fit_bounding_box_horizontal,
          FitBV: :fit_bounding_box_vertical,
        }

        REVERSE_TYPE_MAPPING = Hash[*TYPE_MAPPING.flatten.reverse] #:nodoc:

        # Returns +true+ if the destination is valid.
        def self.valid?(destination)
          TYPE_MAPPING.key?(destination[1]) &&
            (destination[0].kind_of?(Integer) || destination[0]&.type == :Page) &&
            destination[2..-1].all? {|item| item.nil? || item.kind_of?(Numeric) }
        end

        # Creates a new Destination for the given +destination+ specification which may be an
        # explicit destination array or a dictionary with a /D entry (as allowed for a named
        # destination).
        def initialize(destination)
          @destination = if destination.kind_of?(HexaPDF::Dictionary) || destination.kind_of?(Hash)
                           destination[:D]
                         else
                           destination
                         end
        end

        # Returns +true+ if the destination references a destination in a remote document.
        def remote?
          @destination[0].kind_of?(Numeric)
        end

        # Returns the referenced page.
        #
        # The return value is either a page object or, in case of a destination to a remote
        # document, a page number.
        def page
          @destination[0]
        end

        # Returns the type of destination.
        def type
          TYPE_MAPPING[@destination[1]]
        end

        # Returns the argument +left+ if used by the destination, raises an error otherwise.
        def left
          case type
          when :xyz, :fit_page_vertical, :fit_rectangle, :fit_bounding_box_vertical
            @destination[2]
          else
            raise HexaPDF::Error, "No such argument for destination type #{type}"
          end
        end

        # Returns the argument +top+ if used by the destination, raises an error otherwise.
        def top
          case type
          when :xyz
            @destination[3]
          when :fit_page_horizontal, :fit_bounding_box_horizontal
            @destination[2]
          when :fit_rectangle
            @destination[5]
          else
            raise HexaPDF::Error, "No such argument for destination type #{type}"
          end
        end

        # Returns the argument +right+ if used by the destination, raises an error otherwise.
        def right
          case type
          when :fit_rectangle
            @destination[4]
          else
            raise HexaPDF::Error, "No such argument for destination type #{type}"
          end
        end

        # Returns the argument +bottom+ if used by the destination, raises an error otherwise.
        def bottom
          case type
          when :fit_rectangle
            @destination[3]
          else
            raise HexaPDF::Error, "No such argument for destination type #{type}"
          end
        end

        # Returns the argument +zoom+ if used by the destination, raises an error otherwise.
        def zoom
          case type
          when :xyz
            @destination[4]
          else
            raise HexaPDF::Error, "No such argument for destination type #{type}"
          end
        end

        # Returns +true+ if the destination is valid.
        def valid?
          self.class.valid?(@destination)
        end

        # Returns the wrapped destination array.
        def value
          @destination
        end

      end

      include Enumerable

      # Creates a new Destinations object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # :call-seq:
      #   destinations.use_or_create(name)           -> name
      #   destinations.use_or_create(destination)    -> destination
      #   destinations.use_or_create(page)           -> destination
      #   destinations.use_or_create(type:, page, **options)           -> destination
      #
      # Uses the given destination name/array or creates a destination array based on the given
      # arguments.
      #
      # This is the main utility method for other parts of HexaPDF for getting a valid destination
      # array based on various different types of the given arguments:
      #
      # String::
      #
      #     If a string is provided, it is assumed to be a named destination. If the named
      #     destination exists, the destination itself is returned. Otherwise an error is raised.
      #
      # Array::
      #
      #     If a valid destination array is provided, it is returned. Otherwise an error is raised.
      #
      # Page dictionary::
      #
      #     If the value is a valid page dictionary object, a fit to page (#create_fit_page)
      #     destination array is created and returned.
      #
      # Integer::
      #
      #     If the value is an integer, it is interpreted as a zero-based page index and a fit to
      #     page (#create_fit_page) destination array is created and returned.
      #
      # Hash containing at least :type and :page::
      #
      #     If the value is a hash, the :type key specifies the type of the destination that should
      #     be created and the :page key the target page. Which other keys are allowed depends on
      #     the destination type, so see the various create_XXX methods. Uses #create to do the job.
      def use_or_create(value)
        case value
        when String
          if self[value]
            value
          else
            raise HexaPDF::Error, "Named destination '#{value}' doesn't exist"
          end
        when Array
          raise HexaPDF::Error, "Invalid destination array" unless Destination.new(value).valid?
          value
        when HexaPDF::Dictionary
          if value.type != :Page
            raise HexaPDF::Error, "Invalid dictionary type '#{value.type}' given, needs to be a page"
          end
          create_fit_page(value)
        when Integer
          if value < 0 || value >= @document.pages.count
            raise ArgumentError, "Page index #{value} out of bounds"
          end
          create_fit_page(@document.pages[value])
        when Hash
          type = value.delete(:type) { raise ArgumentError, "Missing keyword argument :type" }
          page = value.delete(:page) { raise ArgumentError, "Missing keyword argument :page" }
          create(type, page, **value)
        else
          raise ArgumentError, "Invalid argument type '#{value.class}'"
        end
      end

      # :call-seq:
      #   destinations.create(type, page, **options)      -> dest or name
      #
      # Creates a new destination array with the given +type+ (see Destination for all available
      # type names; PDF internal type names are also allowed) and +page+ by calling the respective
      # +create_type+ method.
      def create(type, page, **options)
        send("create_#{Destination::TYPE_MAPPING.fetch(type, type)}", page, **options)
      end

      # :call-seq:
      #   destinations.create_xyz(page, left: nil, top: nil, zoom: nil)            -> dest
      #   destinations.create_xyz(page, name: nil, left: nil, top: nil, zoom: nil) -> name
      #
      # Creates a new xyz destination array for the given arguments and returns it or, in case
      # a name is given, the name.
      #
      # The arguments +page+, +left+, +top+ and +zoom+ are described in detail in the Destination
      # class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_xyz(page, name: nil, left: nil, top: nil, zoom: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:xyz), left, top, zoom]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_page(page)            -> dest
      #   destinations.create_fit_page(page, name: nil) -> name
      #
      # Creates a new fit to page destination array for the given arguments and returns it or, in
      # case a name is given, the name.
      #
      # The argument +page+ is described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_page(page, name: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_page)]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_page_horizontal(page, top: nil)            -> dest
      #   destinations.create_fit_page_horizontal(page, name: nil, top: nil) -> name
      #
      # Creates a new fit page horizontal destination array for the given arguments and returns it
      # or, in case a name is given, the name.
      #
      # The arguments +page and +top+ are described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_page_horizontal(page, name: nil, top: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_page_horizontal), top]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_page_vertical(page, left: nil)            -> dest
      #   destinations.create_fit_page_vertical(page, name: nil, left: nil) -> name
      #
      # Creates a new fit page vertical destination array for the given arguments and returns it or,
      # in case a name is given, the name.
      #
      # The arguments +page and +left+ are described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_page_vertical(page, name: nil, left: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_page_vertical), left]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_rectangle(page, left:, bottom:, right:, top:)            -> dest
      #   destinations.create_fit_rectangle(page, name: nil, left:, bottom:, right:, top:) -> name
      #
      # Creates a new fit to rectangle destination array for the given arguments and returns it or,
      # in case a name is given, the name.
      #
      # The arguments +page+, +left+, +bottom+, +right+ and +top+ are described in detail in the
      # Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_rectangle(page, left:, bottom:, right:, top:, name: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_rectangle),
                       left, bottom, right, top]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_bounding_box(page)            -> dest
      #   destinations.create_fit_bounding_box(page, name: nil) -> name
      #
      # Creates a new fit to bounding box destination array for the given arguments and returns it
      # or, in case a name is given, the name.
      #
      # The argument +page+ is described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_bounding_box(page, name: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_bounding_box)]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_bounding_box_horizontal(page, top: nil)            -> dest
      #   destinations.create_fit_bounding_box_horizontal(page, name: nil, top: nil) -> name
      #
      # Creates a new fit bounding box horizontal destination array for the given arguments and
      # returns it or, in case a name is given, the name.
      #
      # The arguments +page and +top+ are described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_bounding_box_horizontal(page, name: nil, top: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_bounding_box_horizontal), top]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.create_fit_bounding_box_vertical(page, left: nil)            -> dest
      #   destinations.create_fit_bounding_box_vertical(page, name: nil, left: nil) -> name
      #
      # Creates a new fit bounding box vertical destination array for the given arguments and
      # returns it or, in case a name is given, the name.
      #
      # The arguments +page and +left+ are described in detail in the Destination class description.
      #
      # If the argument +name+ is given, the created destination array is added to the destinations
      # name tree under that name for reuse later, overwriting an existing entry if there is one.
      def create_fit_bounding_box_vertical(page, name: nil, left: nil)
        destination = [page, Destination::REVERSE_TYPE_MAPPING.fetch(:fit_bounding_box_vertical), left]
        name ? (add(name, destination); name) : destination
      end

      # :call-seq:
      #   destinations.add(name, destination)
      #
      # Adds the given +destination+ under +name+ (a String) to the destinations name tree.
      #
      # If the name does already exist, an error is raised.
      def add(name, destination)
        destinations.add_entry(name, destination)
      end

      # :call-seq:
      #   destinations.delete(name)    -> destination
      #
      # Deletes the destination specified via +name+ (a String) from the destinations name tree and
      # returns it or +nil+ if no destination was registered under that name.
      def delete(name)
        destinations.delete_entry(name)
      end

      # :call-seq:
      #   destinations.resolve(string_name)    -> destination or nil
      #   destinations.resolve(symbol_name)    -> destination or nil
      #   destinations.resolve(dest_array)     -> destination or nil
      #
      # Resolves the given value to a valid destination object, if possible, or otherwise returns
      # +nil+.
      #
      # * If the given value is a string, it is treated as a destination name and looked up in the
      #   destination name tree.
      #
      # * If the given value is a symbol, it is treated as an old-style destination name and looked
      #   up in the destination dictionary.
      #
      # * If the given value is an array, it is treated as a destination array itself.
      def resolve(value)
        result = case value
                 when String
                   destinations.find_entry(value)
                 when PDFArray
                   value.value
                 when Array
                   value
                 when Symbol
                   @document.catalog[:Dests]&.[](value)
                 end
        result = Destination.new(result) if result
        result&.valid? ? result : nil
      end

      # :call-seq:
      #   destinations[name]    -> destination
      #
      # Returns the destination registered under the given +name+ (a String) or +nil+ if no
      # destination was registered under that name.
      def [](name)
        destinations.find_entry(name)
      end

      # :call-seq:
      #   destinations.each {|name, dest| block }  -> destinations
      #   destinations.each                        -> Enumerator
      #
      # Iterates over all named destinations of the PDF, yielding the name and the destination
      #  wrapped into a Destination object.
      def each
        return to_enum(__method__) unless block_given?

        destinations.each_entry do |name, dest|
          yield(name, Destination.new(dest))
        end

        self
      end

      private

      # Returns the root of the destinations name tree.
      def destinations
        @document.catalog.names.destinations
      end

    end

  end
end
