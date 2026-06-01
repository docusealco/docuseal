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

require 'set'
require 'hexapdf/error'
require 'hexapdf/dictionary'
require 'hexapdf/stream'
require 'hexapdf/type/page_tree_node'
require 'hexapdf/content'
require 'hexapdf/content/transformation_matrix'

module HexaPDF
  module Type

    # Represents a page of a PDF document.
    #
    # A page object contains the meta information for a page. Most of the fields are independent
    # from the page's content like the /Dur field. However, some of them (like /Resources or
    # /UserUnit) influence how or if the page's content can be rendered correctly.
    #
    # A number of field values can also be inherited: /Resources, /MediaBox, /CropBox, /Rotate.
    # Field inheritance means that if a field is not set on the page object itself, the value is
    # taken from the nearest page tree ancestor that has this value set.
    #
    # See: PDF2.0 s7.7.3.3, s7.7.3.4, Pages
    class Page < Dictionary

      # The predefined paper sizes in points (1/72 inch):
      #
      # * ISO sizes: A0x4, A0x2, A0-A10, B0-B10, C0-C10
      # * Letter, Legal, Ledger, Tabloid, Executive
      PAPER_SIZE = {
        A0x4: [0, 0, 4767.874016, 6740.787402].freeze,
        A0x2: [0, 0, 3370.393701, 4767.874016].freeze,
        A0: [0, 0, 2383.937008, 3370.393701].freeze,
        A1: [0, 0, 1683.779528, 2383.937008].freeze,
        A2: [0, 0, 1190.551181, 1683.779528].freeze,
        A3: [0, 0, 841.889764, 1190.551181].freeze,
        A4: [0, 0, 595.275591, 841.889764].freeze,
        A5: [0, 0, 419.527559, 595.275591].freeze,
        A6: [0, 0, 297.637795, 419.527559].freeze,
        A7: [0, 0, 209.76378, 297.637795].freeze,
        A8: [0, 0, 147.401575, 209.76378].freeze,
        A9: [0, 0, 104.88189, 147.401575].freeze,
        A10: [0, 0, 73.700787, 104.88189].freeze,
        B0: [0, 0, 2834.645669, 4008.188976].freeze,
        B1: [0, 0, 2004.094488, 2834.645669].freeze,
        B2: [0, 0, 1417.322835, 2004.094488].freeze,
        B3: [0, 0, 1000.629921, 1417.322835].freeze,
        B4: [0, 0, 708.661417, 1000.629921].freeze,
        B5: [0, 0, 498.897638, 708.661417].freeze,
        B6: [0, 0, 354.330709, 498.897638].freeze,
        B7: [0, 0, 249.448819, 354.330709].freeze,
        B8: [0, 0, 175.748031, 249.448819].freeze,
        B9: [0, 0, 124.724409, 175.748031].freeze,
        B10: [0, 0, 87.874016, 124.724409].freeze,
        C0: [0, 0, 2599.370079, 3676.535433].freeze,
        C1: [0, 0, 1836.850394, 2599.370079].freeze,
        C2: [0, 0, 1298.267717, 1836.850394].freeze,
        C3: [0, 0, 918.425197, 1298.267717].freeze,
        C4: [0, 0, 649.133858, 918.425197].freeze,
        C5: [0, 0, 459.212598, 649.133858].freeze,
        C6: [0, 0, 323.149606, 459.212598].freeze,
        C7: [0, 0, 229.606299, 323.149606].freeze,
        C8: [0, 0, 161.574803, 229.606299].freeze,
        C9: [0, 0, 113.385827, 161.574803].freeze,
        C10: [0, 0, 79.370079, 113.385827].freeze,
        Letter: [0, 0, 612, 792].freeze,
        Legal: [0, 0, 612, 1008].freeze,
        Ledger: [0, 0, 792, 1224].freeze,
        Tabloid: [0, 0, 1224, 792].freeze,
        Executive: [0, 0, 522, 756].freeze,
      }.freeze

      # Returns the media box for the given paper size or array.
      #
      # If an array is specified, it needs to contain exactly four numbers. The +orientation+
      # argument is not used in this case.
      #
      # See PAPER_SIZE for the defined paper sizes.
      def self.media_box(paper_size, orientation: :portrait)
        return paper_size if paper_size.kind_of?(Array) && paper_size.size == 4 &&
          paper_size.all?(Numeric)

        unless PAPER_SIZE.key?(paper_size)
          raise HexaPDF::Error, "Invalid paper size specified: #{paper_size}"
        end

        media_box = PAPER_SIZE[paper_size].dup
        media_box[2], media_box[3] = media_box[3], media_box[2] if orientation == :landscape
        media_box
      end

      # The inheritable fields.
      INHERITABLE_FIELDS = [:Resources, :MediaBox, :CropBox, :Rotate].freeze

      define_type :Page

      define_field :Type,                 type: Symbol, required: true, default: type
      define_field :Parent,               type: :Pages, required: true, indirect: true
      define_field :LastModified,         type: PDFDate, version: '1.3'
      define_field :Resources,            type: :XXResources
      define_field :MediaBox,             type: Rectangle
      define_field :CropBox,              type: Rectangle
      define_field :BleedBox,             type: Rectangle, version: '1.3'
      define_field :TrimBox,              type: Rectangle, version: '1.3'
      define_field :ArtBox,               type: Rectangle, version: '1.3'
      define_field :BoxColorInfo,         type: Dictionary, version: '1.4'
      define_field :Contents,             type: [Stream, PDFArray]
      define_field :Rotate,               type: Integer, default: 0
      define_field :Group,                type: Dictionary, version: '1.4'
      define_field :Thumb,                type: Stream
      define_field :B,                    type: PDFArray, version: '1.1'
      define_field :Dur,                  type: Numeric, version: '1.1'
      define_field :Trans,                type: Dictionary, version: '1.1'
      define_field :Annots,               type: PDFArray
      define_field :AA,                   type: Dictionary, version: '1.2'
      define_field :Metadata,             type: Stream, version: '1.4'
      define_field :PieceInfo,            type: Dictionary, version: '1.3'
      define_field :StructParents,        type: Integer, version: '1.3'
      define_field :ID,                   type: PDFByteString, version: '1.3'
      define_field :PZ,                   type: Numeric, version: '1.3'
      define_field :SeparationInfo,       type: Dictionary, version: '1.3'
      define_field :Tabs,                 type: Symbol, version: '1.5'
      define_field :TemplateInstantiated, type: Symbol, version: '1.5'
      define_field :PresSteps,            type: Dictionary, version: '1.5'
      define_field :UserUnit,             type: Numeric, version: '1.6'
      define_field :VP,                   type: PDFArray, version: '1.6'
      define_field :AF,                   type: PDFArray, version: '2.0'
      define_field :OutputIntents,        type: PDFArray, version: '2.0'
      define_field :DPart,                type: Dictionary, version: '2.0'

      # Returns +true+ since page objects must always be indirect.
      def must_be_indirect?
        true
      end

      # Returns the value for the entry +name+.
      #
      # If +name+ is an inheritable value and the value has not been set on the page object, its
      # value is retrieved from the ancestor page tree nodes.
      #
      # See: Dictionary#[]
      def [](name)
        if value[name].nil? && INHERITABLE_FIELDS.include?(name)
          node = self
          node = node[:Parent] while node.value[name].nil? && node[:Parent]
          node == self || node.value[name].nil? ? super : node[name]
        else
          super
        end
      end

      # Copies the page's inherited values from the ancestor page tree nodes into a hash and returns
      # the hash.
      #
      # The hash can then be used to update the page itself (e.g. when moving a page from one
      # position to another) or another page (e.g. when importing a page from another document).
      def copy_inherited_values
        INHERITABLE_FIELDS.each_with_object({}) do |name, hash|
          hash[name] = HexaPDF::Object.deep_copy(self[name]) if value[name].nil?
        end
      end

      # :call-seq:
      #   page.box(type = :crop)              -> box
      #   page.box(type = :crop, rectangle)   -> rectangle
      #
      # If no +rectangle+ is given, returns the rectangle defining a certain kind of box for the
      # page. Otherwise sets the value for the given box type to +rectangle+ (an array with four
      # values or a HexaPDF::Rectangle).
      #
      # This method should be used instead of directly accessing any of /MediaBox, /CropBox,
      # /BleedBox, /ArtBox or /TrimBox because it also takes the fallback values into account!
      #
      # The following types are allowed:
      #
      # :media::
      #     The media box defines the boundaries of the medium the page is to be printed on.
      #
      # :crop::
      #     The crop box defines the region to which the contents of the page should be clipped
      #     when it is displayed or printed. The default is the media box.
      #
      # :bleed::
      #     The bleed box defines the region to which the contents of the page should be clipped
      #     when output in a production environment. The default is the crop box.
      #
      # :trim::
      #     The trim box defines the intended dimensions of the page after trimming. The default
      #     value is the crop box.
      #
      # :art::
      #     The art box defines the region of the page's meaningful content as intended by the
      #     author. The default is the crop box.
      #
      # See: PDF2.0 s14.11.2
      def box(type = :crop, rectangle = nil)
        if rectangle
          case type
          when :media, :crop, :bleed, :trim, :art
            self[:"#{type.capitalize}Box"] = rectangle
          else
            raise ArgumentError, "Unsupported page box type provided: #{type}"
          end
        else
          media_box = self[:MediaBox]
          result = case type
                   when :media then media_box
                   when :crop then self[:CropBox] || media_box
                   when :bleed then self[:BleedBox] || self[:CropBox] || media_box
                   when :trim then self[:TrimBox] || self[:CropBox] || media_box
                   when :art then self[:ArtBox] || self[:CropBox] || media_box
                   else
                     raise ArgumentError, "Unsupported page box type provided: #{type}"
                   end
          unless result == media_box
            if result.right < media_box.left || result.left > media_box.right ||
                result.top < media_box.bottom || result.bottom > media_box.top
              result.value = [0, 0, 0, 0]
            else
              result.left = media_box.left if result.left < media_box.left
              result.right = media_box.right if result.right > media_box.right
              result.top = media_box.top if result.top > media_box.top
              result.bottom = media_box.bottom if result.bottom < media_box.bottom
            end
          end
          result
        end
      end

      # Returns the orientation of the specified box (default is the crop box), either :portrait or
      # :landscape.
      def orientation(type = :crop)
        box = self.box(type)
        rotation = self[:Rotate]
        if (box.height > box.width && (rotation == 0 || rotation == 180)) ||
            (box.height < box.width && (rotation == 90 || rotation == 270))
          :portrait
        else
          :landscape
        end
      end

      # Rotates the page +angle+ degrees counterclockwise where +angle+ has to be a multiple of 90.
      #
      # Positive values rotate the page to the left, negative values to the right. If +flatten+ is
      # +true+, the rotation is not done via the page's meta (i.e. the /Rotate key) data but by
      # rotating the canvas itself and all other necessary objects like the various page boxes and
      # annotations.
      #
      # Notes:
      #
      # * The given +angle+ is applied in addition to a possibly already existing rotation
      #   (specified via the /Rotate key) and does not replace it.
      #
      # * Specifying 0 for +angle+ is valid and means that no additional rotation should be applied.
      #   The only meaningful usage of 0 for +angle+ is when +flatten+ is set to +true+ (so that the
      #   /Rotate key is removed and the existing rotation information incorporated into the canvas,
      #   page boxes and annotations).
      #
      # * The /Rotate key of a page object describes the angle in a clockwise orientation but this
      #   method uses counterclockwise rotation to be consistent with other rotation methods (e.g.
      #   HexaPDF::Content::Canvas#rotate).
      def rotate(angle, flatten: false)
        if angle % 90 != 0
          raise ArgumentError, "Page rotation has to be multiple of 90 degrees"
        end

        # /Rotate and therefore cw_angle is angle in clockwise orientation
        cw_angle = (self[:Rotate] - angle) % 360

        if flatten
          delete(:Rotate)
          return if cw_angle == 0

          pbox = box
          matrix = case cw_angle
                   when 90  then Content::TransformationMatrix.new(0, -1, 1, 0, -pbox.bottom, pbox.right)
                   when 180 then Content::TransformationMatrix.new(-1, 0, 0, -1, pbox.right, pbox.top)
                   when 270 then Content::TransformationMatrix.new(0, 1, -1, 0, pbox.top, -pbox.left)
                   end

          rotate_box = lambda do |box|
            llx, lly, urx, ury =
              case cw_angle
              when 90  then [box.right, box.bottom, box.left, box.top]
              when 180 then [box.right, box.top, box.left, box.bottom]
              when 270 then [box.left, box.top, box.right, box.bottom]
              end
            box.value.replace(matrix.evaluate(llx, lly).concat(matrix.evaluate(urx, ury)))
          end

          [:MediaBox, :CropBox, :BleedBox, :TrimBox, :ArtBox].each do |box_name|
            next unless key?(box_name)
            rotate_box.call(self[box_name])
          end

          each_annotation do |annot|
            rotate_box.call(annot[:Rect])
            if (quad_points = annot[:QuadPoints])
              quad_points = quad_points.value if quad_points.respond_to?(:value)
              result = []
              quad_points.each_slice(2) {|x, y| result.concat(matrix.evaluate(x, y)) }
              quad_points.replace(result)
            end
            if (appearance = annot.appearance)
              appearance[:Matrix] = matrix.dup.premultiply(*appearance[:Matrix].value).to_a
            end
            if annot[:Subtype] == :Widget
              app_ch = annot[:MK] ||= document.wrap({}, type: :XXAppearanceCharacteristics)
              app_ch[:R] = (app_ch[:R] + 360 - cw_angle) % 360
            end
          end

          before_contents = document.add({}, stream: " q #{matrix.to_a.join(' ')} cm ")
          after_contents = document.add({}, stream: " Q ")
          self[:Contents] = [before_contents, *self[:Contents], after_contents]
        else
          self[:Rotate] = cw_angle
        end
      end

      # Returns the concatenated stream data from the content streams as binary string.
      #
      # Note: Any modifications done to the returned value *won't* be reflected in any of the
      # streams' data!
      def contents
        Array(self[:Contents]).each_with_object("".b) do |content_stream, content|
          content << " " unless content.empty?
          content << content_stream.stream if content_stream.kind_of?(Stream)
        end
      end

      # Replaces the contents of the page with the given string.
      #
      # This is done by deleting all but the first content stream and reusing this content stream;
      # or by creating a new one if no content stream exists.
      def contents=(data)
        first, *rest = self[:Contents]
        rest.each {|stream| document.delete(stream) }
        if first
          self[:Contents] = first
          document.deref(first).stream = data
        else
          self[:Contents] = document.add({Filter: :FlateDecode}, stream: data)
        end
      end

      # Returns the, possibly inherited, resource dictionary which is automatically created if it
      # doesn't exist.
      def resources
        self[:Resources] ||= document.wrap({}, type: :XXResources)
      end

      # Processes the content streams associated with the page with the given processor object.
      #
      # See: HexaPDF::Content::Processor
      def process_contents(processor)
        self[:Resources] = {} if self[:Resources].nil?
        processor.resources = self[:Resources]
        Content::Parser.parse(contents, processor)
      end

      # Extracts the layouted text from the page.
      #
      # See HexaPDF::Content::SmartTextExtractor.layout_text_runs for the available +options+.
      def extract_text(**options)
        processor = Content::SmartTextExtractor::TextRunProcessor.new
        process_contents(processor)
        box = box(:media)
        Content::SmartTextExtractor.layout_text_runs(processor.text_runs, box.width, box.height,
                                                     **options)
      end

      # Returns the index of the page in the page tree.
      def index
        idx = 0
        node = self
        while (parent_node = node[:Parent])
          parent_node[:Kids].each do |kid|
            break if kid == node
            idx += (kid.type == :Page ? 1 : kid[:Count])
          end
          node = parent_node
        end
        idx
      end

      # Returns the label of the page which is an optional, alternative description of the page
      # index.
      #
      # See HexaPDF::Document::Pages for details.
      def label
        document.pages.page_label(index)
      end

      # Returns all parent nodes of the page up to the root of the page tree.
      #
      # The direct parent is the first node in the array and the root node the last.
      def ancestor_nodes
        parent = self[:Parent]
        result = [parent]
        result << parent while (parent = parent[:Parent])
        result
      end

      # Returns the requested type of canvas for the page.
      #
      # There are potentially three different canvas objects, one for each of the types :underlay,
      # :page, and :overlay. The canvas objects are cached once they are created so that their
      # graphics states are correctly retained without the need for parsing the contents. This also
      # means that on subsequent invocations the graphic states of the canvases might already be
      # changed.
      #
      # type::
      #    Can either be
      #    * :page for getting the canvas for the page itself (only valid for initially empty pages)
      #    * :overlay for getting the canvas for drawing over the page contents
      #    * :underlay for getting the canvas for drawing unter the page contents
      #
      # translate_origin::
      #    Specifies whether the origin should automatically be translated into the lower-left
      #    corner of the crop box.
      #
      #    Note that this argument is only used for the first invocation for every canvas type. So
      #    if a canvas was initially requested with this argument set to false and then with true,
      #    it won't have any effect as the cached canvas is returned.
      #
      #    To check whether the origin has been translated or not, use
      #
      #      canvas.pos(0, 0)
      #
      #    and check whether the result is [0, 0]. If it is, then the origin has not been
      #    translated.
      def canvas(type: :page, translate_origin: true)
        unless [:page, :overlay, :underlay].include?(type)
          raise ArgumentError, "Invalid value for 'type', expected: :page, :underlay or :overlay"
        end
        cache_key = "#{type}_canvas".intern
        return cache(cache_key) if cached?(cache_key)

        if type == :page && key?(:Contents)
          raise HexaPDF::Error, "Cannot get the canvas for a page with contents"
        end

        create_canvas = lambda do
          Content::Canvas.new(self).tap do |canvas|
            next unless translate_origin
            crop_box = box(:crop)
            if crop_box.left != 0 || crop_box.bottom != 0
              canvas.translate(crop_box.left, crop_box.bottom)
            end
          end
        end

        contents = self[:Contents]
        if contents.nil?
          page_canvas = cache(:page_canvas, create_canvas.call)
          self[:Contents] = document.add({Filter: :FlateDecode},
                                         stream: page_canvas.stream_data)
        end

        if type == :overlay || type == :underlay
          underlay_canvas = cache(:underlay_canvas, create_canvas.call)
          overlay_canvas = cache(:overlay_canvas, create_canvas.call)

          stream = HexaPDF::StreamData.new do
            Fiber.yield(" q ")
            fiber = underlay_canvas.stream_data.fiber
            while fiber.alive? && (data = fiber.resume)
              Fiber.yield(data)
            end
            " Q q "
          end
          underlay = document.add({Filter: :FlateDecode}, stream: stream)

          stream = HexaPDF::StreamData.new do
            Fiber.yield(" Q q ")
            fiber = overlay_canvas.stream_data.fiber
            while fiber.alive? && (data = fiber.resume)
              Fiber.yield(data)
            end
            " Q "
          end
          overlay = document.add({Filter: :FlateDecode}, stream: stream)

          self[:Contents] = [underlay, *self[:Contents], overlay]
        end

        cache(cache_key)
      end

      # Creates a Form XObject from the page's dictionary and contents for the given PDF document.
      #
      # If +reference+ is true, the page's contents is referenced when possible to avoid unnecessary
      # decoding/encoding.
      #
      # Note 1: The created Form XObject is *not* added to the document automatically!
      #
      # Note 2: If +reference+ is false and if a canvas is used on this page (see #canvas), this
      # method should only be called once the contents of the page has been fully defined. The
      # reason is that during the copying of the content stream data the contents may be modified to
      # make it a fully valid content stream.
      def to_form_xobject(reference: true)
        first, *rest = self[:Contents]
        stream = if !first
                   nil
                 elsif !reference || !rest.empty? || first.raw_stream.kind_of?(String)
                   contents
                 else
                   first.raw_stream
                 end
        dict = {
          Type: :XObject,
          Subtype: :Form,
          BBox: HexaPDF::Object.deep_copy(box(:crop)),
          Resources: HexaPDF::Object.deep_copy(self[:Resources]),
          Filter: :FlateDecode,
        }
        document.wrap(dict, stream: stream)
      end

      # :call-seq:
      #   page.each_annotation {|annotation| block}    -> page
      #   page.each_annotation                         -> Enumerator
      #
      # Yields each annotation of this page.
      def each_annotation
        return to_enum(__method__) unless block_given?
        Array(self[:Annots]).each do |annotation|
          next unless annotation?(annotation)
          yield(document.wrap(annotation, type: :Annot))
        end
        self
      end

      # Flattens all or the given annotations of the page. Returns an array with all the annotations
      # that couldn't be flattened because they don't have an appearance stream.
      #
      # Flattening means making the appearances of the annotations part of the content stream of the
      # page and deleting the annotations themselves. Invisible and hidden fields are deleted but
      # not rendered into the content stream.
      #
      # If an annotation is a form field widget, only the widget will be deleted but not the form
      # field itself.
      def flatten_annotations(annotations = self[:Annots])
        not_flattened = Array(annotations) || []
        unless self[:Annots].kind_of?(PDFArray)
          return (not_flattened == [annotations] ? [] : not_flattened)
        end

        annotations = if annotations == self[:Annots]
                        not_flattened
                      else
                        not_flattened & self[:Annots]
                      end
        return not_flattened if annotations.empty?

        canvas = self.canvas(type: :overlay)
        if (pos = canvas.pos(0, 0)) != [0, 0]
          canvas.save_graphics_state
          canvas.translate(-pos[0], -pos[1])
        end

        to_delete = Set.new
        not_flattened -= annotations
        annotations.each do |annotation|
          unless annotation?(annotation)
            self[:Annots].delete(annotation)
            next
          end

          annotation = document.wrap(annotation, type: :Annot)
          appearance = annotation.appearance
          if annotation.flagged?(:hidden) || annotation.flagged?(:invisible)
            to_delete << annotation
            next
          elsif !appearance
            not_flattened << annotation
            next
          end

          rect = annotation[:Rect]
          box = appearance.box

          # PDF2.0 12.5.5 algorithm
          # Step 1) Calculate smallest rectangle containing transformed bounding box
          matrix = HexaPDF::Content::TransformationMatrix.new(*appearance[:Matrix].value)
          llx, lly = matrix.evaluate(box.left, box.bottom)
          ulx, uly = matrix.evaluate(box.left, box.top)
          lrx, lry = matrix.evaluate(box.right, box.bottom)
          left, right = [llx, ulx, lrx, lrx + (ulx - llx)].minmax
          bottom, top = [lly, uly, lry, lry + (uly - lly)].minmax

          # Handle degenerate case of the transformed bounding box being a line or point
          if right - left == 0 || top - bottom == 0
            to_delete << annotation
            next
          end

          # Step 2) Fit calculated rectangle to annotation rectangle by translating/scaling

          # The final matrix is composed by translating the bottom-left corner of the transformed
          # bounding box to the bottom-left corner of the annotation rectangle and scaling from the
          # bottom-left corner of the transformed bounding box.
          sx = rect.width.fdiv(right - left)
          sy = rect.height.fdiv(top - bottom)
          tx = rect.left - left + left - left * sx
          ty = rect.bottom - bottom + bottom - bottom * sy

          # Step 3) Premultiply form matrix - done implicitly when drawing the XObject

          canvas.transform(sx, 0, 0, sy, tx, ty) do
            # Use [box.left, box.bottom] to counter default translation in #xobject since that
            # is already taken care of in matrix a
            canvas.xobject(appearance, at: [box.left, box.bottom])
          end
          to_delete << annotation
        end
        canvas.restore_graphics_state unless pos == [0, 0]

        to_delete.each do |annotation|
          if annotation[:Subtype] == :Widget
            annotation.form_field.delete_widget(annotation)
          else
            self[:Annots].delete(annotation)
            document.delete(annotation)
          end
        end

        not_flattened
      end

      private

      # Returns +true+ if the given object seems to be an annotation.
      def annotation?(obj)
        (obj.kind_of?(Hash) || obj.kind_of?(Dictionary)) &&
          obj&.key?(:Subtype) && obj&.key?(:Rect)
      end

      # Ensures that the required inheritable fields are set.
      def perform_validation(&block)
        root_node = document.catalog.pages
        parent_node = self[:Parent]
        parent_node = parent_node[:Parent] while parent_node && parent_node != root_node
        return unless parent_node

        super

        unless self[:Resources]
          yield("Required inheritable page field Resources not set", true)
          resources.validate(&block)
        end

        unless self[:MediaBox]
          yield("Required inheritable page field MediaBox not set", true)
          index = self.index
          box_before = index == 0 ? nil : document.pages[index - 1][:MediaBox]
          box_after = index == document.pages.count - 1 ? nil : document.pages[index + 1]&.[](:MediaBox)
          self[:MediaBox] =
            if box_before && (box_before&.value == box_after&.value || box_after.nil?)
              box_before.dup
            elsif box_after && box_before.nil?
              box_after
            else
              self.class.media_box(document.config['page.default_media_box'],
                                   orientation: document.config['page.default_media_orientation'])
            end
        end
      end

    end

  end
end
