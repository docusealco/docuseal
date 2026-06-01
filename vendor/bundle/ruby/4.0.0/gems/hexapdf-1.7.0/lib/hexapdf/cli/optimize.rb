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

    # Optimizes the size of a PDF file.
    class Optimize < Command

      def initialize #:nodoc:
        super('optimize', takes_commands: false)
        short_desc("Optimize the size of a PDF file")
        long_desc(<<~EOF)
          This command uses several optimization strategies to reduce the file size of the PDF file.

          By default, all strategies except page compression are used since page compression may
          take a very long time without much benefit.
        EOF

        @password = nil
        @out_options[:compact] = true
        @out_options[:xref_streams] = :generate
        @out_options[:object_streams] = :generate
        @out_options[:streams] = :compress
        @out_options[:optimize_fonts] = true

        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end

        options.separator("")
        options.separator("Optimization options")
        define_optimization_options
      end

      def execute(in_file, out_file) #:nodoc:
        maybe_raise_on_existing_file(out_file)
        with_document(in_file, password: @password, out_file: out_file) do |doc|
          optimize_page_tree(doc)
          apply_optimization_options(doc)
        end
      end

      private

      # Optimizes the page tree by flattening it and deleting unsed objects.
      def optimize_page_tree(doc)
        page_tree = doc.add({Type: :Pages})
        retained = {page_tree.data => true}
        doc.pages.each do |page|
          page.value.update(page.copy_inherited_values)
          page_tree.add_page(page)
          retained[page.data] = true
        end
        doc.catalog[:Pages] = page_tree

        doc.each do |obj, revision|
          next unless obj.kind_of?(HexaPDF::Dictionary)
          if (obj.type == :Pages || obj.type == :Page) && !retained.key?(obj.data)
            revision.delete(obj)
          end
        end
      end

    end

  end
end
