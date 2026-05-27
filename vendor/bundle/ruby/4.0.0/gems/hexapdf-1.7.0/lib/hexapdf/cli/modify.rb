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

    # Modifies a PDF file:
    #
    # * Decrypts or encrypts the resulting output PDF file.
    # * Generates or deletes object and cross-reference streams.
    # * Optimizes the output PDF by merging the revisions of a PDF file and removes unused entries.
    #
    # See: HexaPDF::Task::Optimize
    class Modify < Command

      def initialize #:nodoc:
        super('modify', takes_commands: false)
        short_desc("Modify a PDF file")
        long_desc(<<~EOF)
          This command modifies a PDF file. It can be used, for example, to select pages that should
          appear in the output file and/or rotate them. The output file can also be
          encrypted/decrypted and optimized in various ways.
        EOF

        @password = nil
        @pages = '1-e'
        @embed_files = []
        @annotation_mode = nil

        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end
        options.on("-i", "--pages PAGES", "The pages of the input file that should be used " \
                   "(default: 1-e)") do |pages|
          @pages = pages
        end
        options.on("-e", "--embed FILE", String, "Embed the file into the output file (can be " \
                   "used multiple times)") do |file|
          @embed_files << file
        end
        options.on("--annotations MODE", [:remove, :flatten], "Handling of annotations (either " \
                   "remove or flatten)") do |mode|
          @annotation_mode = mode
        end
        define_optimization_options
        define_encryption_options
      end

      def execute(in_file, out_file) #:nodoc:
        maybe_raise_on_existing_file(out_file)
        with_document(in_file, password: @password, out_file: out_file) do |doc|
          arrange_pages(doc) unless @pages == '1-e'
          handle_annotations(doc)
          @embed_files.each {|file| doc.files.add(file, embed: true) }
          apply_encryption_options(doc)
          apply_optimization_options(doc)
        end
      end

      private

      # Arranges the pages of the document as specified with the --pages option.
      def arrange_pages(doc)
        all_pages = doc.pages.to_a
        new_page_tree = doc.add({Type: :Pages})
        parse_pages_specification(@pages, all_pages.length).each do |index, rotation|
          page = all_pages[index]
          page.value.update(page.copy_inherited_values)
          if rotation == :none
            page.delete(:Rotate)
          elsif rotation.kind_of?(Integer)
            page.rotate(rotation)
          end
          new_page_tree.add_page(page)
        end
        doc.catalog[:Pages] = new_page_tree
        remove_unused_pages(doc)
        doc.pages.add unless doc.pages.count > 0
      end

      # Handles the annotations of all selected pages by doing nothing, removing them or flattening
      # them.
      def handle_annotations(doc)
        return unless @annotation_mode

        doc.pages.each do |page|
          if @annotation_mode == :remove
            page.delete(:Annots)
          else
            page.flatten_annotations
          end
        end
      end

    end

  end
end
