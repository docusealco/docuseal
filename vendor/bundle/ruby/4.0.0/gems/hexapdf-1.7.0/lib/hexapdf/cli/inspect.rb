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

    # Shows the internal structure of a PDF file.
    class Inspect < Command

      # Outputs the content of a page in a nicer form.
      class ContentProcessor < HexaPDF::Content::Processor

        # :nodoc:
        def initialize(*)
          super
          @indent = 0
          @serializer = HexaPDF::Serializer.new
        end

        # :nodoc:
        def paint_xobject(name)
          puts "#{indent}paint_xobject #{@serializer.serialize(name)}"
          @indent += 1
          super
          @indent -= 1
        end

        # :nodoc:
        def method_missing(operator, *operands)
          case operator
          when :save_graphics_state, :begin_text, :begin_marked_content
            puts "#{indent}#{operator}"
            @indent += 1
          when :restore_graphics_state, :end_text, :end_marked_content
            @indent -= 1
            puts "#{indent}#{operator}"
          when :show_text, :show_text_with_positioning
            puts "#{indent}text> #{decode_text(*operands)}"
          else
            puts "#{indent}#{operator} #{operands.map {|op| @serializer.serialize(op) }.join(' ')}"
            @indent += 1 if operator == :begin_marked_content_with_property_list
          end
        end

        # :nodoc:
        def respond_to_missing?(*)
          true
        end

        private

        # Returns the current indentation string.
        def indent
          '  ' * @indent
        end

      end

      def initialize #:nodoc:
        super('inspect', takes_commands: false)
        short_desc("Dig into the internal structure of a PDF file")
        long_desc(<<~EOF)
          Inspects a PDF file for debugging or testing purposes. This command is useful when one
          needs to inspect the internal object structure or a stream of a PDF file. A PDF object is
          always shown in the PDF syntax.

          If no arguments are given, the interactive mode is started. Otherwise the arguments are
          interpreted as interactive mode commands and executed. It is possible to specify more than
          one command in this way by separating them with semicolons, or whitespace in case the
          number of command arguments is fixed.

        EOF

        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end

        @password = nil
        @serializer = HexaPDF::Serializer.new
      end

      def execute(file, *commands) #:nodoc:
        with_document(file, password: @password) do |doc|
          doc.config['font.on_missing_unicode_mapping'] = lambda do |code, font|
            $stderr.puts("No Unicode mapping for code point #{code} in font #{font[:BaseFont]}, " \
                         "using the Unicode replacement character")
            "\u{FFFD}"
          end
          @doc = doc
          if commands.empty?
            begin
              require 'reline'
              Reline.completion_proc = RELINE_COMPLETION_PROC
              Reline.completion_append_character = " "
            rescue LoadError
              if command_parser.verbosity_info?
                $stderr.puts("Library reline not available, history and line editing not available")
              end
            end
            while true
              input = read_input
              (puts; break) unless input
              commands = input.scan(/(["'])(.+?)\1|(\S+)/).map {|a| a[1] || a[2] }
              break if execute_commands(commands)
            end
          else
            execute_commands(commands)
          end
        end
      end

      private

      COMMAND_LIST = %w[object recursive stream raw-stream xref catalog trailer pages # :nodoc:
                        page-count search quit help]
      RELINE_COMPLETION_PROC = proc do |s| # :nodoc:
        if s.empty?
          COMMAND_DESCRIPTIONS.map {|cmd, desc| cmd.ljust(35) << desc }
        else
          COMMAND_LIST.grep(/^#{Regexp.escape(s)}/)
        end
      end

      # Returns one line of input, using Reline if available.
      def read_input
        if Object.const_defined?("Reline")
          Reline.readline("cmd> ", true)
        else
          print "cmd> "
          $stdin.gets
        end
      end

      def execute_commands(data) #:nodoc:
        data.map! {|item| item == ";" ? nil : item }
        until data.empty?
          command = data.shift || next
          case command
          when /^\d+(,\d+)?$/, 'o', 'object'
            arg = (command.start_with?('o') ? data.shift : command)
            obj = pdf_object_from_string_reference(arg) rescue $stderr.puts($!.message)
            if obj&.data&.stream && command_parser.verbosity_info?
              $stderr.puts("Note: Object also has stream data")
            end
            serialize(obj.value, recursive: false) if obj

          when 'r', 'recursive'
            obj = if (obj = data.shift)
                    pdf_object_from_string_reference(obj) rescue $stderr.puts($!.message)
                  else
                    @doc.trailer
                  end
            serialize(obj.value, recursive: true) if obj

          when 's', 'stream', 'raw', 'raw-stream', 'sd'
            if (obj = pdf_object_from_string_reference(data.shift) rescue $stderr.puts($!.message)) &&
                obj.kind_of?(HexaPDF::Stream)
              if command == 'sd'
                if obj.respond_to?(:process_contents)
                  obj.process_contents(ContentProcessor.new)
                else
                  $stderr.puts("Error: The object is not a Form XObject or page")
                end
              else
                source = (command.start_with?('raw') ? obj.stream_source : obj.stream_decoder)
                while source.alive? && (stream_data = source.resume)
                  $stdout.write(stream_data)
                end
              end
            elsif command_parser.verbosity_info?
              $stderr.puts("Note: Object has no stream data")
            end

          when 'x', 'xref'
            if (obj = pdf_object_from_string_reference(data.shift) rescue $stderr.puts($!.message))
              @doc.revisions.reverse_each do |rev|
                if (xref = rev.xref(obj))
                  puts xref
                  break
                end
              end
            end

          when 'c', 'catalog'
            serialize(@doc.catalog.value, recursive: false)

          when 't', 'trailer'
            serialize(@doc.trailer.value, recursive: false)

          when 'p', 'pages'
            begin
              pages = parse_pages_specification(data.shift || '1-e', @doc.pages.count)
            rescue StandardError => e
              $stderr.puts("Error: #{e}")
              next
            end
            page_list = @doc.pages.to_a
            pages.each do |index, _|
              page = page_list[index]
              str = +"page #{index + 1} (#{page.oid},#{page.gen}): "
              str << Array(page[:Contents]).map {|c| "#{c.oid},#{c.gen}" }.join(" ")
              puts str
            end

          when 'po', 'ps', 'psd'
            page_number_str = data.shift
            unless page_number_str
              $stderr.puts("Error: Missing PAGE argument to #{command}")
              next
            end
            page_number = parse_pages_specification(page_number_str, @doc.pages.count).first&.first
            unless page_number
              $stderr.puts("Error: Invalid page number #{page_number_str}")
              next
            end
            page = @doc.pages[page_number]
            case command
            when 'ps'
              $stdout.write(page.contents)
            when 'psd'
              page.process_contents(ContentProcessor.new)
            else
              puts "#{page.oid} #{page.gen} obj"
              serialize(page.value, recursive: false)
              puts "endobj"
            end

          when 'pc', 'page-count'
            puts @doc.pages.count

          when 'search'
            regexp = data.shift
            unless regexp
              $stderr.puts("Error: Missing argument regexp")
              next
            end
            re = Regexp.new(regexp, Regexp::IGNORECASE)
            @doc.each do |object|
              if @serializer.serialize(object.value).match?(re)
                puts "#{object.oid} #{object.gen} obj"
                serialize(object.value, recursive: false)
                puts "endobj"
              end
            end

          when 'rev', 'revision'
            if (rev_index = data.shift)
              rev_index = rev_index.to_i - 1
              if rev_index < 0 || rev_index >= @doc.revisions.count
                $stderr.puts("Error: Invalid revision number specified")
                next
              end
              length = 0
              revision_information do |_, index, _, _, end_offset|
                length = end_offset if index == rev_index
              end
              IO.copy_stream(@doc.revisions.parser.io, $stdout, length, 0)
            else
              puts "Document has #{@doc.revisions.count} revision#{@doc.revisions.count == 1 ? '' : 's'}"
              if @doc.revisions.parser.reconstructed? && @doc.revisions.count == 1 &&
                 @doc.revisions.current == @doc.revisions.parser.reconstructed_revision
                puts "Document cross-reference table has been reconstructed"
              end
              revision_information do |rev, index, count, signature, end_offset|
                type = if rev.trailer[:XRefStm]
                         "xref table + stream"
                       elsif rev.trailer[:Type] == :XRef
                         "xref stream"
                       else
                         "xref table"
                       end
                puts "Revision #{index + 1}"
                puts "  Type      : #{type}"
                puts "  Objects   : #{count}"
                puts "  Size      : #{rev.trailer[:Size]}"
                puts "  Signed    : yes" if signature
                puts "  Byte range: 0-#{end_offset}"
              end
            end

          when 'q', 'quit'
            return true

          when 'h', 'help'
            puts COMMAND_DESCRIPTIONS.map {|cmd, desc| cmd.ljust(35) << desc }.join("\n")

          else
            if command
              $stderr.puts("Error: Unknown command '#{command}' - enter 'h' for a list of commands")
            end
          end
        end

        false
      end

      # Resolves the PDF object from the given string reference and returns it.
      def pdf_object_from_string_reference(str)
        if str.nil?
          raise Error, "Error: Missing argument object identifier OID[,GEN]"
        elsif !str.match?(/^\d+(,\d+)?$/)
          raise Error, "Error: Invalid argument: Must be of form OID[,GEN], not '#{str}'"
        elsif !(obj = @doc.object(pdf_reference_from_string(str)))
          raise Error, "Error: No object with the given object identifier '#{str}' found"
        else
          obj
        end
      end

      # Parses the given string of the format "oid[,gen]" and returns a PDF reference object.
      def pdf_reference_from_string(str)
        oid, gen = str.split(",").map(&:to_i)
        HexaPDF::Reference.new(oid, gen || 0)
      end

      # Prints the serialized value to the standard output. If +recursive+ is +true+, then the whole
      # object tree is printed, with object references to already printed objects replaced by
      # specially generated PDF references.
      def serialize(val, recursive: true, seen: {}, indent: 0) #:nodoc:
        case val
        when Hash
          puts "<<"
          (recursive ? val.sort : val).each do |k, v|
            next if v.nil? || (v.respond_to?(:null?) && v.null?)
            print '%s%s ' % ['  ' * (indent + 1), @serializer.serialize_symbol(k)]
            serialize(v, recursive: recursive, seen: seen, indent: indent + 1)
            puts
          end
          print "#{'  ' * indent}>>"
        when Array
          print "["
          val.each do |v|
            serialize(v, recursive: recursive, seen: seen, indent: indent)
            print " "
          end
          print "]"
        when HexaPDF::Reference
          serialize(@doc.object(val), recursive: recursive, seen: seen, indent: indent)
        when HexaPDF::Object
          if !recursive
            if val.indirect?
              print "#{val.oid} #{val.gen} R"
            else
              serialize(val.value, recursive: recursive, seen: seen, indent: indent)
            end
          elsif val.nil? || seen.key?(val.data)
            print "{ref #{seen[val.data]}}"
          else
            seen[val.data] = (val.type == :Page ? "page #{val.index + 1}" : seen.length + 1)
            print "{obj #{seen[val.data]}} "
            serialize(val.value, recursive: recursive, seen: seen, indent: indent)
          end
        else
          print @serializer.serialize(val)
        end
        puts if indent == 0
      end

      # Yields information about the document's revisions.
      #
      # Returns an array of arrays that include the following information:
      #
      # - The revision object itself
      # - The index of the revision in terms of all revisions of the document
      # - The number of objects in the revision
      # - The signature dictionary if this revision was signed
      # - The byte offset from the start of the file to the end of the revision
      def revision_information
        signatures = @doc.signatures.to_h do |sig|
          [@doc.revisions.find {|rev| rev.object(sig) == sig }, sig]
        end
        io = @doc.revisions.parser.io

        io.seek(0, IO::SEEK_END)
        startxrefs = @doc.revisions.map {|rev| rev.trailer[:Prev].to_i } <<
                     @doc.revisions.parser.startxref_offset <<
                     io.pos
        startxrefs.sort!
        startxrefs.shift

        @doc.revisions.each_with_index.map do |rev, index|
          end_index = 0
          sig = signatures[rev]
          if sig
            end_index = sig[:ByteRange][-2] + sig[:ByteRange][-1]
          elsif rev != @doc.revisions.parser.reconstructed_revision
            io.seek(startxrefs[index], IO::SEEK_SET)
            buffer = ''.b
            while io.pos < startxrefs[index + 1]
              buffer << io.read(1_000)
              if (buffer_index = buffer.index(/(?:\n|\r\n?)\s*%%EOF\s*(?:\n|\r\n?)?/))
                end_index = io.pos - buffer.size + buffer_index + $~[0].size
                break
              end
              buffer = buffer[-20..-1]
            end
          end
          yield(rev, index, rev.each.count, sig, end_index)
        end
      end

      COMMAND_DESCRIPTIONS = [ #:nodoc:
        ["OID[,GEN] | o[bject] OID[,GEN]", "Print object"],
        ["r[ecursive] OID[,GEN]", "Print object recursively"],
        ["s[tream] OID[,GEN]", "Print filtered stream"],
        ["sd OID[,GEN]", "Print the decoded stream of a Form XObject or page"],
        ["raw[-stream] OID[,GEN]", "Print raw stream"],
        ["rev[ision] [NUMBER]", "Print or extract revision"],
        ["x[ref] OID[,GEN]", "Print the cross-reference entry"],
        ["c[atalog]", "Print the catalog dictionary"],
        ["t[railer]", "Print the trailer dictionary"],
        ["p[ages] [RANGE]",  "Print information about pages"],
        ["po PAGE", "Print the page object"],
        ["ps PAGE", "Print the content stream of the page"],
        ["psd PAGE", "Print the decoded content stream of the page"],
        ["pc | page-count", "Print the number of pages"],
        ["search REGEXP", "Print objects matching the pattern"],
        ["h[elp]", "Show the help"],
        ["q[uit]", "Quit"],
      ]

      def help_long_desc #:nodoc:
        output = super
        summary_width = command_parser.main_options.summary_width
        data = <<~HELP
          If a command or an argument is OID[,GEN], object and generation numbers are expected. The
          generation number defaults to 0 if not given. The available commands are:
        HELP
        content = format(data, indent: 0,
                         width: command_parser.help_line_width - command_parser.help_indent)
        content << "\n\n"
        COMMAND_DESCRIPTIONS.each do |cmd, desc|
          content << format(cmd.ljust(summary_width + 1) << desc,
                            width: command_parser.help_line_width - command_parser.help_indent,
                            indent: summary_width + 1, indent_first_line: false) << "\n"
        end
        output << cond_format_help_section("Interactive Mode Commands", content, preformatted: true)
      end

      def usage_arguments #:nodoc:
        "FILE [[CMD [ARGS]]...]"
      end

    end

  end
end
