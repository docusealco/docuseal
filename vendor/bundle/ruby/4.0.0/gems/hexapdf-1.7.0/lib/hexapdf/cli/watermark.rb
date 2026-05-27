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

    # Uses one or more pages of one PDF and underlays/overlays it/them onto another.
    class Watermark < Command

      def initialize #:nodoc:
        super('watermark', takes_commands: false)
        short_desc("Put one or more PDF pages onto another PDF")
        long_desc(<<~EOF)
          This command uses one ore more pages from a PDF file and applies them as background or
          stamp on another PDF file.

          If multiple pages are selected from the watermark PDF, the --repeat option can be used to
          specify how they should be applied: 'last' (the default) will only repeat the last
          watermark page whereas 'all' will cyclically repeat all watermark pages.
        EOF

        options.on("-w", "--watermark-file FILE", "The PDF used as watermark") do |watermark_file|
          @watermark_file = watermark_file
        end
        options.on("-i", "--pages PAGES", "The pages of the watermark file that should be used " \
                   "(default: 1)") do |pages|
          @pages = pages
        end
        options.on("-r", "--repeat REPEAT_MODE", [:last, :all],
                   "Specifies how the watermark pages should be repeated. Either last or " \
                     "all (default: last)") do |repeat|
          @repeat = repeat
        end
        options.on("-t", "--type WATERMARK_TYPE", [:background, :stamp],
                   "Specifies how the watermark is applied: background applies it below the page " \
                     "contents and stamp applies it above. Default: background") do |type|
          @type = (type == :background ? :underlay : :overlay)
        end
        options.on("--password PASSWORD", "-p", String,
                   "The password for decrypting the input PDF. Use - for reading from " \
                     "standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end
        define_optimization_options
        define_encryption_options

        @watermark_file = nil
        @pages = "1"
        @repeat = :last
        @type = :underlay
        @password = nil
      end

      def execute(in_file, out_file) #:nodoc:
        maybe_raise_on_existing_file(out_file)
        watermark = HexaPDF::Document.open(@watermark_file)
        indices = page_index_generator(watermark)
        xobject_map = {}
        with_document(in_file, password: @password, out_file: out_file) do |doc|
          doc.pages.each do |page|
            index = indices.next
            xobject = xobject_map[index] ||= doc.import(watermark.pages[index].to_form_xobject)
            pw = page.box.width.to_f
            ph = page.box.height.to_f
            xw = xobject.width.to_f
            xh = xobject.height.to_f
            canvas = page.canvas(type: @type)
            ratio = [pw / xw, ph / xh].min
            xw, xh = xw * ratio, xh * ratio
            x, y = (pw - xw) / 2, (ph - xh) / 2
            canvas.xobject(xobject, at: [x, y], width: xw, height: xh)
          end
        end
      end

      private

      # Returns an Enumerator instance that returns the indices of the watermark pages that should
      # be used.
      def page_index_generator(watermark)
        pages = parse_pages_specification(@pages, watermark.pages.count)
        Enumerator.new do |y|
          loop do
            pages.each {|index, _rotation| y << index }
            if @repeat == :last
              y << pages.last[0] while true
            end
          end
        end
      end

    end

  end
end
