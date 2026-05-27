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

require 'hexapdf/cli/command'

module HexaPDF
  module CLI

    # Shows the space usage of various parts of a PDF file.
    class Usage < Command

      # Modifies the HexaPDF::PDFData class to store the size information
      module PDFDataExtension

        # Used to store the size of the indirect object.
        attr_accessor :size

        # Used to store the size of the object inside the object stream.
        attr_accessor :size_in_object_stream

      end

      # Modifies HexaPDF::Parser to retrieve space used by indirect objects.
      module ParserExtension

        # :nodoc:
        def initialize(*)
          super
          @last_size = nil
        end

        # :nodoc:
        def load_object(xref_entry)
          super.tap do |obj|
            if xref_entry.type == :compressed
              obj.data.size_in_object_stream = @last_size
            elsif xref_entry.type == :in_use
              obj.data.size = @last_size
            end
            @last_size = nil
          end
        end

        # :nodoc:
        def parse_indirect_object(offset = nil)
          real_offset = (offset ? @header_offset + offset : @tokenizer.pos)
          result = super
          @last_size = @tokenizer.pos - real_offset
          result
        end

        # :nodoc:
        def load_compressed_object(xref_entry)
          result = super
          offsets = @object_stream_data[xref_entry.objstm].instance_variable_get(:@offsets)
          @last_size = if xref_entry.pos == offsets.size - 1
                         @object_stream_data[xref_entry.objstm].instance_variable_get(:@tokenizer).
                           io.size - offsets[xref_entry.pos]
                       else
                         offsets[xref_entry.pos + 1] - offsets[xref_entry.pos]
                       end
          result
        end

      end

      def initialize #:nodoc:
        super('usage', takes_commands: false)
        short_desc("Show space usage of various parts of a PDF file")
        long_desc(<<~EOF)
          This command displays some usage statistics of the PDF file, i.e. which parts take which
          approximate space in the file.

          Each statistic line shows the space used followed by the number of indirect objects in
          parentheses. If some of those objects are in object streams, that number is displayed
          after a slash.
        EOF

        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end

        @password = nil
      end

      def execute(file) #:nodoc:
        HexaPDF::Parser.prepend(ParserExtension)
        HexaPDF::PDFData.prepend(PDFDataExtension)

        with_document(file, password: @password) do |doc|
          # Prepare cache of outline items
          outline_item_cache = {}
          if doc.catalog.key?(:Outlines)
            doc.outline.each_item {|item| outline_item_cache[item] = true }
            outline_item_cache[doc.outline] = true
          end

          doc.revisions.each.with_index do |rev, index|
            sum = count = 0
            categories = {
              Content: [],
              Files: [],
              Fonts: [],
              Images: [],
              Metadata: [],
              ObjectStreams: [],
              Outline: [],
              XObjects: [],
            }
            puts if index > 0
            puts "Usage information for revision #{index + 1}" if doc.revisions.count > 1
            rev.each do |obj|
              if command_parser.verbosity_info?
                print "(#{obj.oid},#{obj.gen}): #{obj.data.size.to_i}"
                print " (#{obj.data.size_in_object_stream})" if obj.data.size.nil?
                puts
              end
              next unless obj.kind_of?(HexaPDF::Dictionary)

              case obj.type
              when :Page
                Array(obj[:Contents]).each do |content|
                  categories[:Content] << content if object_in_rev?(content, rev)
                end
              when :Font
                categories[:Fonts] << obj
              when :FontDescriptor
                categories[:Fonts] << obj
                [:FontFile, :FontFile2, :FontFile3].each do |name|
                  categories[:Fonts] << obj[name] if object_in_rev?(obj[name], rev)
                end
              when :Metadata
                categories[:Metadata] << obj
              when :Filespec
                categories[:Files] << obj
                categories[:Files] << obj.embedded_file_stream if obj.embedded_file?
              when :ObjStm
                categories[:ObjectStreams] << obj
              else
                if obj[:Subtype] == :Image
                  categories[:Images] << obj
                elsif obj[:Subtype] == :Form
                  categories[:XObjects] << obj
                end
              end
              sum += obj.data.size if obj.data.size
              count += 1
            end

            # Populate Outline category
            outline_item_cache.reject! do |obj, _val|
              object_in_rev?(obj, rev) && categories[:Outline] << obj
            end

            categories.each do |name, data|
              next if data.empty?
              object_stream_count = 0
              category_sum = data.sum do |o|
                object_stream_count += 1 unless o.data.size
                o.data.size.to_i
              end
              object_stream_count = object_stream_count > 0 ? "/#{object_stream_count}" : ''
              size = human_readable_file_size(category_sum)
              puts "#{name.to_s.ljust(15)} #{size.rjust(8)} (#{data.count}#{object_stream_count})"
            end
            puts "#{'Total'.ljust(15)} #{human_readable_file_size(sum).rjust(8)} (#{count})"
          end
        end
      end

      private

      # Returns +true+ if the +obj+ is in the given +rev+.
      def object_in_rev?(obj, rev)
        obj && rev.object(obj) == obj
      end

    end

  end
end
