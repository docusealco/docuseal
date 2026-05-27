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

require 'stringio'
require 'hexapdf/stream'
require 'hexapdf/content'

module HexaPDF
  module Type

    # Represents a form XObject of a PDF document.
    #
    # See: PDF2.0 s8.10
    class Form < Stream

      # Represents a group attribute dictionary.
      #
      # See: PDF2.0 s8.10.3
      class Group < Dictionary

        define_type :Group

        define_field :Type, type: Symbol, default: type
        define_field :S,    type: Symbol, required: true

      end

      # Represents a reference dictionary which allows an XObject to refer to content in an embedded
      # or linked PDF document.
      #
      # See: PDF2.0 s8.10.4
      class Reference < Dictionary

        define_type :XXReference

        define_field :F,    type: :Filespec, required: true
        define_field :Page, type: [Integer, String], required: true
        define_field :ID,   type: PDFArray

      end

      define_type :XObject

      define_field :Type,          type: Symbol,       default: type
      define_field :Subtype,       type: Symbol,       required: true, default: :Form
      define_field :FormType,      type: Integer,      default: 1, allowed_values: 1
      define_field :BBox,          type: Rectangle,    required: true
      define_field :Matrix,        type: PDFArray,     default: [1, 0, 0, 1, 0, 0]
      define_field :Resources,     type: :XXResources, version: '1.2'
      define_field :Group,         type: :Group,       version: '1.4'
      define_field :Ref,           type: :XXReference, version: '1.4'
      define_field :Metadata,      type: Stream,       version: '1.4'
      define_field :PieceInfo,     type: Dictionary,   version: '1.3'
      define_field :LastModified,  type: PDFDate,      version: '1.3'
      define_field :StructParent,  type: Integer,      version: '1.3'
      define_field :StructParents, type: Integer,      version: '1.3'
      define_field :OPI,           type: Dictionary,   version: '1.2'
      define_field :OC,            type: Dictionary,   version: '1.5'
      define_field :Name,          type: Symbol
      define_field :AF,            type: PDFArray,     version: '2.0'
      define_field :Measure,       type: Dictionary,   version: '2.0'
      define_field :PtData,        type: Dictionary,   version: '2.0'

      # Returns the path to the PDF file that was used when creating the form object.
      #
      # This value is only set when the form object was created by using the image loading
      # facility (i.e. when treating a single page PDF file as image) and not when the form object
      # was created in any other way (i.e. manually created or already part of a loaded PDF file).
      attr_accessor :source_path

      # Returns the rectangle defining the bounding box of the form.
      def box
        self[:BBox]
      end

      # Returns the width of the bounding box (see #box).
      def width
        box.width
      end

      # Returns the height of the bounding box (see #box).
      def height
        box.height
      end

      # Returns the contents of the form XObject.
      #
      # Note: This is the same as #stream but here for interface compatibility with Page.
      def contents
        stream
      end

      # Replaces the contents of the form XObject with the given string.
      #
      # This also clears the cache to avoid returning invalid objects.
      #
      # Note: This is the same as #stream= but here for interface compatibility with Page.
      def contents=(data)
        self.stream = data
        clear_cache
      end

      # Returns the resource dictionary which is automatically created if it doesn't exist.
      def resources
        self[:Resources] ||= document.wrap({}, type: :XXResources)
      end

      # Processes the content stream of the form XObject with the given processor object.
      #
      # The +original_resources+ argument has to be set to a page's resources if this form XObject
      # is processed as part of this page.
      #
      # See: HexaPDF::Content::Processor
      def process_contents(processor, original_resources: nil)
        form = referenced_content || self
        processor.resources = if form[:Resources]
                                form[:Resources]
                              elsif original_resources
                                original_resources
                              else
                                document.wrap({}, type: :XXResources)
                              end
        Content::Parser.parse(form.contents, processor)
      end

      # Returns the canvas for the form XObject.
      #
      # The canvas object is cached once it is created so that its graphics state is correctly
      # retained without the need for parsing its contents.
      #
      # If the bounding box of the form XObject doesn't have its origin at (0, 0), the canvas origin
      # is translated into the bottom-left corner so that this detail doesn't matter when using the
      # canvas. This means that the canvas' origin is always at the bottom-left corner of the
      # bounding box.
      #
      # *Note* that a canvas can only be retrieved for initially empty form XObjects!
      def canvas(translate: true)
        cache(:canvas) do
          unless stream.empty?
            raise HexaPDF::Error, "Cannot create a canvas for a form XObjects with contents"
          end

          canvas = Content::Canvas.new(self)
          if translate && (box.left != 0 || box.bottom != 0)
            canvas.save_graphics_state.translate(box.left, box.bottom)
          end
          self.stream = canvas.stream_data
          set_filter(:FlateDecode)
          canvas
        end
      end

      # Returns +true+ if the Form XObject is a reference XObject.
      def reference_xobject?
        !self[:Ref].nil?
      end

      # Returns the referenced page as Form XObject, if this Form XObject is a Reference XObject and
      # the referenced page is found. Otherwise returns +nil+.
      def referenced_content
        return unless (ref = self[:Ref])

        doc = if ref[:F].embedded_file?
                HexaPDF::Document.new(io: StringIO.new(ref[:F].embedded_file_stream.stream))
              elsif File.exist?(ref[:F].path)
                HexaPDF::Document.open(ref[:F].path)
              end
        return unless doc

        page = ref[:Page]
        if page.kind_of?(Integer)
          page = doc.pages[page]
        else
          labels = []
          doc.pages.each_labelling_range do |_first_index, count, label|
            count.times {|i| labels << label.construct_label(i) }
          end
          index = labels.index(page)
          page = index && doc.pages[index]
        end
        return unless page

        # See PDF2.0 s8.10.4.3
        print_annots = page.each_annotation.select {|annot| annot.flagged?(:print) }
        page.flatten_annotations(print_annots) unless print_annots.empty?

        obj = page.to_form_xobject
        obj[:BBox] = self[:BBox].dup
        obj[:Matrix] = self[:Matrix].dup
        obj
      rescue StandardError
        nil
      end

    end

  end
end
