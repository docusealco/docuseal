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
require 'hexapdf/serializer'
require 'hexapdf/content/parser'
require 'hexapdf/content/operator'
require 'hexapdf/type/xref_stream'
require 'hexapdf/type/object_stream'
require 'hexapdf/font/true_type'

module HexaPDF
  module Task

    # Task for creating a PDF/A compliant document.
    #
    # It automatically
    #
    # * prevents the Standard 14 PDF fonts to be used.
    # * adds an appropriate output intent if none is set.
    # * adds the necessary PDF/A metadata properties.
    #
    # Additionally, it applies fixes to the document so that the structures and content of
    # non-conforming PDFs are corrected. See ::call for more information on the available fixes.
    #
    # Note that you should use a PDF/A validation tool like veraPDF (https://verapdf.org/) to ensure
    # that the resulting files confirm to the PDF/A specification because not all documents can be
    # fixed at the moment.
    module PDFA

      # Performs the necessary tasks to make the document PDF/A compatible.
      #
      # +level+::
      #     Specifies the PDF/A conformance level that should be used. Can be one of the following
      #     strings: 2b, 2u, 3b, 3u.
      #
      # +fixes+::
      #     Specifies the fixes that should be applied when converting a non-conforming PDF. If a
      #     document is created with HexaPDF but also includes parts of loaded documents, this
      #     argument hast to be set to +:all+.
      #
      #     Can be +:default+ (which is also the default value), +:all+ or an array with one or more
      #     fix names.
      #
      #     +:default+:: Applies all fixes if the document was loaded from a file. Otherwise applies
      #         only those fixes necessary for files created with HexaPDF.
      #
      #     +:all+: Applies all available fixes.
      #
      #     +:glyph_widths+:: Corrects mismatching width information in fonts.
      def self.call(doc, level: '3u', fixes: :default)
        unless level.match?(/\A[23][bu]\z/)
          raise ArgumentError, "The given PDF/A conformance level '#{level}' is not supported"
        end
        doc.config['font_loader'].delete('HexaPDF::FontLoader::Standard14')
        doc.register_listener(:complete_objects) do
          part, conformance = level.chars
          doc.metadata.property('pdfaid', 'part', part)
          doc.metadata.property('pdfaid', 'conformance', conformance.upcase)
          add_srgb_icc_output_intent(doc) unless doc.catalog.key?(:OutputIntents)

          fixes = if fixes == :all || (fixes == :default && doc.revisions.parser)
                    ALL_FIXES
                  elsif fixes == :default
                    ALL_FIXES - FIXES_FOR_LOADED_DOCUMENTS
                  else
                    fixes
                  end
          fixes.each {|fix| send(fix, doc) }
        end
      end

      SRGB_ICC = 'sRGB2014.icc' # :nodoc:

      def self.add_srgb_icc_output_intent(doc) # :nodoc:
        icc = doc.add({N: 3}, stream: File.binread(File.join(HexaPDF.data_dir, SRGB_ICC)))
        doc.catalog[:OutputIntents] = [
          doc.add({S: :GTS_PDFA1, OutputConditionIdentifier: SRGB_ICC, Info: SRGB_ICC,
                   RegistryName: 'https://www.color.org', DestOutputProfile: icc}),
        ]
      end

      ALL_FIXES = [:fix_glyph_widths] # :nodoc:

      FIXES_FOR_LOADED_DOCUMENTS = [:fix_glyph_widths] # :nodoc:

      # Makes the glyph widths stored in the embedded fonts the same as the ones specified in the
      # PDF font data structures.
      #
      # Note: Currently only handles Type 2 CIDFonts.
      def self.fix_glyph_widths(doc) # :nodoc:
        # Step 1: Collect all CIDs together with their respective fonts
        processor = CIDCollector.new
        doc.pages.each do |page|
          page.process_contents(processor)
          page.each_annotation do |annotation|
            next unless (appearance = annotation.appearance)
            appearance.process_contents(processor, original_resources: page.resources)
          end
        end

        # Step 2: Process all found fonts
        processor.map.each do |font_object, all_cids|
          next if all_cids.empty?
          font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font_object.font_file.stream))
          cid_to_gid = cid_to_gid_mapping(font_object)

          # Process all found CIDs by comparing their width with the ones defined in the font and
          # correcting the font if necessary.
          raw_hmtx = font[:hmtx].raw_data
          width_conversion_factor = 1000.0 / font[:head].units_per_em
          all_cids.each do |cid|
            cid_width = font_object.width(cid)
            gid = cid_to_gid[cid]
            gid_width = font[:hmtx][gid].advance_width * width_conversion_factor
            next if (cid_width - gid_width).abs.round <= 1
            raw_hmtx[4 * gid, 2] = [(cid_width / width_conversion_factor).round].pack('n')
          end

          font_object.font_file.stream = font.build('hmtx' => raw_hmtx)
        end
      end

      # Processes the contents of a stream and collects the CIDs for each composite font.
      class CIDCollector < HexaPDF::Content::Processor

        # The mapping from the composite font's descendant font to the set of used CIDs.
        attr_reader :map

        def initialize(*) # :nodoc:
          super
          @map = Hash.new {|h, k| h[k] = Set.new }
        end

        def show_text(data) # :nodoc:
          font = graphics_state.font
          return unless font[:Subtype] == :Type0 && font.descendant_font[:Subtype] == :CIDFontType2

          Array(data).each do |item|
            next if item.kind_of?(Numeric)
            @map[font.descendant_font].merge(font.decode(item))
          end
        end
        alias show_text_with_positioning show_text

      end

      # Returns an object responding to #[] that maps CIDs to GIDs for Type 2 CIDFonts.
      def self.cid_to_gid_mapping(font)
        if font[:CIDToGIDMap] == :Identity
          proc {|cid| cid }
        else
          font[:CIDToGIDMap].stream.unpack('n*')
        end
      end
      private_class_method :cid_to_gid_mapping

    end

  end
end
