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

    # Merges pages from multiple PDF files.
    class Merge < Command

      InputSpec = Struct.new(:file, :pages, :password) #:nodoc:

      def initialize #:nodoc:
        super('merge', takes_commands: false)
        short_desc("Merge multiple PDF files")
        long_desc(<<~EOF)
          This command merges pages from multiple PDFs into one output file which can optionally be
          encrypted/decrypted and optimized in various ways.

          The first input file is the primary input file from which meta data like file information,
          outlines, etc. are taken from. Alternatively, it is possible to start with an empty PDF
          file by using --empty. The order of the files is important as they are used in that order.

          Also note that the --password and --pages options apply to the last preceeding input file.
        EOF

        options.on(/.*/, "Input file, can be specified multiple times") do |file|
          @files << InputSpec.new(file, '1-e')
          throw :prune
        end
        options.on("-p", "--password PASSWORD", String, "The password for decrypting the last " \
                   "specified input file (use - for reading from standard input)") do |pwd|
          raise OptionParser::InvalidArgument, "(No prior input file specified)" if @files.empty?
          pwd = (pwd == '-' ? read_password("#{@files.last.file} password") : pwd)
          @files.last.password = pwd
        end
        options.on("-i", "--pages PAGES", "The pages of the last specified input file that " \
                   "should be used (default: 1-e)") do |pages|
          raise OptionParser::InvalidArgument, "(No prior input file specified)" if @files.empty?
          @files.last.pages = pages
        end
        options.on("-e", "--empty", "Use an empty file as the first input file") do
          @initial_empty = true
        end
        options.on("--[no-]interleave", "Interleave the pages from the input files (default: " \
                   "false)") do |c|
          @interleave = c
        end

        options.separator("")
        options.separator("Output related options")
        define_optimization_options
        define_encryption_options

        @files = []
        @initial_empty = false
        @interleave = false
      end

      def execute #:nodoc:
        if !@initial_empty && @files.empty?
          error = OptionParser::ParseError.new("At least one FILE or --empty is needed")
          error.reason = "Missing argument"
          raise error
        elsif (@initial_empty && @files.empty?) || (!@initial_empty && @files.length < 2)
          error = OptionParser::ParseError.new("Output file is needed")
          error.reason = "Missing argument"
          raise error
        end

        output_file = @files.pop.file
        maybe_raise_on_existing_file(output_file)

        # Create PDF documents for each input file
        cache = {}
        @files.each do |spec|
          cache[spec.file] ||=
            begin
              io = if spec.file == output_file
                     StringIO.new(File.binread(spec.file))
                   else
                     File.open(spec.file)
                   end
              HexaPDF::Document.new(io: io, **pdf_options(spec.password))
            end
          spec.file = cache[spec.file]
        end

        # Assemble pages
        target = (@initial_empty ? HexaPDF::Document.new : @files.first.file)
        page_tree = target.add({Type: :Pages})
        import_pages(page_tree)
        target.catalog[:Pages] = page_tree
        remove_unused_pages(target)
        target.pages.add unless target.pages.count > 0

        apply_encryption_options(target)
        apply_optimization_options(target)

        write_document(target, output_file)
      end

      def usage #:nodoc:
        "Usage: #{command_parser.main_options.program_name} merge [options] {FILE | --empty} " \
          "[FILE]... OUT_FILE"
      end

      private

      # Imports the pages of the document as specified with the --pages option to the given page
      # tree.
      def import_pages(page_tree)
        @files.each do |s|
          page_list = s.file.pages.to_a
          s.pages = parse_pages_specification(s.pages, s.file.pages.count)
          s.pages.each {|arr| arr[0] = page_list[arr[0]] }
        end

        if @interleave
          max_pages_per_file = 0
          all = @files.each_with_index.map do |spec, findex|
            list = []
            spec.pages.each {|index, rotation| list << [spec.file, findex, index, rotation] }
            max_pages_per_file = list.size if list.size > max_pages_per_file
            list
          end
          first, *rest = *all
          first[max_pages_per_file - 1] ||= nil
          first.zip(*rest) do |slice|
            slice.each do |source, findex, page, rotation|
              next unless source
              import_page(page_tree, findex, page, rotation)
            end
          end
        else
          @files.each_with_index do |s, findex|
            s.pages.each {|page, rotation| import_page(page_tree, findex, page, rotation) }
          end
        end
      end

      # Import the page with the given +rotation+ into the page tree.
      def import_page(page_tree, source_index, page, rotation)
        if page_tree.document == page.document
          page.value.update(page.copy_inherited_values)
          page = page.deep_copy unless source_index == 0
        else
          page = page_tree.document.import(page).deep_copy
        end
        if rotation == :none
          page.delete(:Rotate)
        elsif rotation.kind_of?(Integer)
          page.rotate(rotation)
        end
        page_tree.document.add(page)
        page_tree.add_page(page)
      end

    end

  end
end
