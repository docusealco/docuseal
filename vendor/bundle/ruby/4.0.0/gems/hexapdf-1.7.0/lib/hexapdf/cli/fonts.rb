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
require 'hexapdf/cli/command'

module HexaPDF
  module CLI

    # Lists fonts from a PDF file.
    #
    # See: HexaPDF::Type::Font
    class Fonts < Command

      def initialize #:nodoc:
        super('fonts', takes_commands: false)
        short_desc("List fonts from a PDF file")
        long_desc(<<~EOF)
          Lists the fonts used in the PDF with additional information, sorted by page number.
        EOF
        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end
        options.on("-i", "--pages PAGES", "The subset of pages that should be looked at") do |pages|
          @pages = pages
        end

        @password = nil
        @pages = nil
      end

      def execute(pdf) #:nodoc:
        with_document(pdf, password: @password) do |doc|
          printf("%5s %-40s %-12s %-10s %-3s %-3s %8s %9s\n",
                 "page", "name", "type", "encoding", "emb", "sub", "size", "oid")
          puts("-" * 97)
          each_font(doc) do |pindex, font|
            font_type = case font[:Subtype]
                        when :Type1
                          if font.embedded? && font[:FontDescriptor][:FontFile3]
                            "Type 1C"
                          else
                            "Type 1"
                          end
                        when :Type3 then "Type 3"
                        when :TrueType then "TrueType"
                        when :Type0
                          if font.descendant_font[:Subtype] == :CIDFontType0
                            "CID CFF"
                          else
                            "CID TrueType"
                          end
                        else
                          "Unknown"
                        end
            encoding = font[:Encoding]
            encoding = if encoding.kind_of?(Symbol)
                         encoding.to_s.sub(/Encoding/, '')
                       elsif encoding.kind_of?(Dictionary) &&
                           [:Type1, :Type3, :TrueType].include?(font[:Subtype])
                         "Custom"
                       else
                         "Built-in"
                       end
            size = human_readable_file_size(font.embedded? ? font.font_file[:Length] : 0)
            embedded = (font.embedded? ? "yes" : "no")
            subset = (font[:BaseFont].match?(/\A[A-Z]{6}\+/) ? "yes" : "no")
            printf("%5s %-40s %-12s %-10s %-3s %-3s %8s %9s\n",
                   pindex, font[:BaseFont], font_type, encoding,
                   embedded, subset, size, "#{font.oid},#{font.gen}")
          end
        end
      end

      private

      # Iterates over all fonts by page.
      def each_font(doc) # :yields: obj, index, page_index
        if @pages
          pages = parse_pages_specification(@pages, doc.pages.count).each_with_object({}) do |(i, _), h|
            h[i] = true
          end
        end
        seen = {}

        doc.pages.each_with_index do |page, pindex|
          next if pages && !pages[pindex]
          font_proc = lambda do |_, font|
            next if seen[font]
            yield(pindex + 1, font)
            seen[font] = true
          end
          page.resources[:Font]&.each(&font_proc)
          page.resources[:XObject]&.each do |_, xobj|
            next unless xobj[:Subtype] == :Form
            xobj.resources[:Font]&.each(&font_proc)
          end
          page.each_annotation do |annotation|
            appearance = annotation.appearance
            next unless appearance
            appearance.resources[:Font]&.each(&font_proc)
          end

          seen.clear if pages
        end
      end

    end

  end
end
