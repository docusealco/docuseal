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

    # Lists or extracts embedded files from a PDF file or attaches them.
    #
    # See: HexaPDF::Type::EmbeddedFile
    class Files < Command

      def initialize #:nodoc:
        super('files', takes_commands: false)
        short_desc("List and extract embedded files from a PDF or attach files")
        long_desc(<<~EOF)
          If neither the option --attach nor the option --extract is given, the available
          files are listed with their names and indices. The --extract option can then be
          used to extract one or more files. Or the --attach option can be used to attach
          files to the PDF.
        EOF

        options.on("--attach FILE", "-a FILE", String,
                   "The file that should be attached. Can be used multiple times.") do |file|
          @attach_files << [file, nil]
        end
        options.on("--description DESC", "-d DESC", String,
                   "Adds a description to the last file to be attached.") do |description|
          @attach_files[-1][1] = description
        end
        options.on("--extract [a,b,c,...]", "-e [a,b,c,...]", Array,
                   "The indices of the files that should be extracted. Use 0 or no argument to " \
                   "extract all files.") do |indices|
          @indices = (indices ? indices.map(&:to_i) : [0])
        end
        options.on("--[no-]search", "-s", "Search the whole PDF instead of the " \
                   "standard locations (default: false)") do |search|
          @search = search
        end
        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end

        @attach_files = []
        @indices = []
        @password = nil
        @search = false
      end

      def execute(pdf, output = nil) #:nodoc:
        if @indices.empty? && !@attach_files.empty?
          raise Error, "Missing output file" unless output
          maybe_raise_on_existing_file(output)
        end
        with_document(pdf, password: @password, out_file: output) do |doc|
          if @indices.empty? && @attach_files.empty?
            list_files(doc)
          elsif !@indices.empty? && !@attach_files.empty?
            raise Error, "Use either --attach or --extract but not both"
          elsif !@attach_files.empty?
            attach_files(doc)
          else
            extract_files(doc)
          end
        end
      end

      private

      # Outputs the list of files embedded in the given PDF document.
      def list_files(doc)
        each_file(doc) do |obj, index|
          $stdout.write(sprintf("%4i: %s", index + 1, obj.path))
          ef_stream = obj.embedded_file_stream
          if (params = ef_stream[:Params]) && !params.empty?
            data = []
            data << "size: #{params[:Size]}" if params.key?(:Size)
            data << "md5: #{params[:CheckSum].unpack1('H*')}" if params.key?(:CheckSum)
            data << "ctime: #{params[:CreationDate]}" if params.key?(:CreationDate)
            data << "mtime: #{params[:ModDate]}" if params.key?(:ModDate)
            $stdout.write(" (#{data.join(', ')})")
          end
          $stdout.puts
          $stdout.puts("      #{obj[:Desc]}") if obj[:Desc] && !obj[:Desc].empty?
        end
      end

      # Extracts the files with the given indices.
      def extract_files(doc)
        each_file(doc) do |obj, index|
          next unless @indices.include?(index + 1) || @indices.include?(0)
          maybe_raise_on_existing_file(obj.path)
          puts "Extracting #{obj.path}..." if command_parser.verbosity_info?
          File.open(obj.path, 'wb') do |file|
            fiber = obj.embedded_file_stream.stream_decoder
            while fiber.alive? && (data = fiber.resume)
              file << data
            end
          end
        end
      end

      # Attaches the files given on the CLI to the document.
      def attach_files(doc)
        @attach_files.each {|file, desc| doc.files.add(file, description: desc) }
      end

      # Iterates over all embedded files.
      def each_file(doc, &block) # :yields: obj, index
        doc.files.each(search: @search).select(&:embedded_file?).each_with_index(&block)
      end

    end

  end
end
