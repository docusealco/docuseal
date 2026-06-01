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

    # Splits a PDF file, putting each page into a separate file.
    class Split < Command

      def initialize #:nodoc:
        super('split', takes_commands: false)
        short_desc("Split a PDF file")
        long_desc(<<~EOF)
          The default strategy is to split a PDF into individual pages, i.e. splitting is done by
          page number. It is also possible to split by page size where pages with the same page size
          get put into the same output PDF.

          If no OUTPUT_SPEC is specified, the resulting PDF files are named <PDF>_0001.pdf,
          <PDF>_0002.pdf, ... when splitting by page number and <PDF>_A4.pdf, <PDF>_Letter.pdf, ...
          when splitting by page size.

          To specify a custom name, provide the OUTPUT_SPEC argument. It can contain a printf-style
          format definition like '%04d' to specify the place where the page number should be
          inserted. In case of splitting by page size, the place of the format defintion is replaced
          with the name of the page size, e.g. A4 or Letter.

          The optimization and encryption options are applied to each created output file.
        EOF

        options.on("--strategy STRATEGY", "-s", [:page_number, :page_size], "Defines how the PDF " \
                   "file should be split: page_number or page_size (default: page_number)") do |s|
          @strategy = s
        end
        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end
        define_optimization_options
        define_encryption_options

        @password = nil
        @strategy = :page_number
      end

      def execute(pdf, output_spec = pdf.sub(/\.pdf$/i, '_%04d.pdf')) #:nodoc:
        with_document(pdf, password: @password) do |doc|
          if @strategy == :page_number
            split_by_page_number(doc, output_spec)
          else
            split_by_page_size(doc, output_spec)
          end
        end
      end

      private

      # Splits the document into individual pages.
      def split_by_page_number(doc, output_spec)
        doc.pages.each_with_index do |page, index|
          output_file = sprintf(output_spec, index + 1)
          maybe_raise_on_existing_file(output_file)
          out = HexaPDF::Document.new
          out.pages.add(out.import(page))
          apply_encryption_options(out)
          apply_optimization_options(out)
          write_document(out, output_file)
        end
      end

      # Splits the document into files based on the page sizes.
      def split_by_page_size(doc, output_spec)
        output_spec = output_spec.sub(/%.*?[a-zA-Z]/, '%s')
        out_files = Hash.new do |hash, key|
          output_file = sprintf(output_spec, key)
          maybe_raise_on_existing_file(output_file)
          out = HexaPDF::Document.new
          out.config['output_file'] = output_file
          hash[key] = out
        end

        doc.pages.each do |page|
          out = out_files[page_size_name(page.box.value)]
          out.pages.add(out.import(page))
        end

        out_files.each_value do |out|
          apply_encryption_options(out)
          apply_optimization_options(out)
          write_document(out, out.config['output_file'])
        end
      end

      # Tries to retrieve a page size name based on the given page box. If this is not possible, the
      # returned page size name consists of width x height.
      def page_size_name(box)
        @page_name_cache ||= {}
        return @page_name_cache[box] if @page_name_cache.key?(box)

        paper_size = HexaPDF::Type::Page::PAPER_SIZE.find do |_name, paper_box|
          paper_box.each_with_index.all? {|entry, index| (entry - paper_box[index]).abs < 5 }
        end

        @page_name_cache[box] =
          paper_size ? paper_size[0] : sprintf("%.0fx%.0f", *box.values_at(2, 3))
      end

    end

  end
end
