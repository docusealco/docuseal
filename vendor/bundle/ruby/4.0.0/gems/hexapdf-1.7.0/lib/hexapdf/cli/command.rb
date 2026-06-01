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

require 'io/console'
require 'cmdparse'
require 'hexapdf/document'
require 'hexapdf/font/true_type'

module HexaPDF
  module CLI

    # Raised when problems occur on the CLI side of things.
    class Error < HexaPDF::Error; end

    # Base class for all hexapdf commands. It provides utility methods needed by the individual
    # commands.
    class Command < CmdParse::Command

      module Extensions #:nodoc:
        def help_banner #:nodoc:
          "hexapdf #{HexaPDF::VERSION} - Versatile PDF Manipulation Tool\n" \
            "Copyright (c) 2014-2025 Thomas Leitner; licensed under the AGPLv3\n\n" \
            "#{format(usage, indent: 7)}\n\n"
        end

        def help #:nodoc:
          super << format("See https://hexapdf.gettalong.org/documentation/hexapdf.1.html " \
                          "for the full manual page with examples.", indent: 0)
        end

      end

      include Extensions

      def initialize(*args, **kwargs, &block) #:nodoc:
        super
        @out_options = {
          compact: true,
          compress_pages: false,
          object_streams: :preserve,
          xref_streams: :preserve,
          streams: :preserve,
          optimize_fonts: false,
          prune_page_resources: false,
          encryption: :preserve,
          enc_user_pwd: nil,
          enc_owner_pwd: nil,
          enc_key_length: 128,
          enc_algorithm: :aes,
          enc_force_v4: false,
          enc_permissions: [],
        }
      end

      protected

      # Creates a HexaPDF::Document instance for the PDF file and yields it.
      #
      # If +out_file+ is given, the document is written to it after yielding.
      def with_document(file, password: nil, out_file: nil, incremental: false) #:yield: document
        if file == out_file
          doc = HexaPDF::Document.open(file, **pdf_options(password))
        else
          file_io = File.open(file, 'rb')
          doc = HexaPDF::Document.new(io: file_io, **pdf_options(password))
        end

        yield(doc)

        write_document(doc, out_file, incremental: incremental)
      ensure
        file_io&.close
      end

      # Returns a hash with HexaPDF::Document options based on the given password and the option
      # switches.
      def pdf_options(password)
        hash = {decryption_opts: {password: password}, config: {}}
        HexaPDF::GlobalConfiguration['filter.predictor.strict'] = command_parser.strict
        HexaPDF::GlobalConfiguration['filter.flate.on_error'] =
          if command_parser.strict
            proc { true }
          else
            proc do |_, error|
              if command_parser.verbosity_info?
                $stderr.puts "Ignoring error in flate encoded stream: #{error}"
              end
              false
            end
          end
        hash[:config]['parser.try_xref_reconstruction'] = !command_parser.strict
        hash[:config]['parser.on_correctable_error'] =
          if command_parser.strict
            proc { true }
          else
            proc do |_, msg, pos|
              if command_parser.verbosity_info?
                msg = MalformedPDFError.new(msg, pos: pos).message
                $stderr.puts "Corrected parsing problem: #{msg}"
              end
              false
            end
          end
        hash[:config]['encryption.on_decryption_error'] =
          if command_parser.strict
            proc { true }
          else
            proc do |obj, msg|
              if command_parser.verbosity_info?
                $stderr.puts "Ignored decryption problem for object (#{ob.oid},#{obj.gen}): #{msg}"
              end
              false
            end
          end
        hash
      end

      # Writes the document to the given file or does nothing if +out_file+ is +nil+.
      def write_document(doc, out_file, incremental: false)
        if out_file
          doc.trailer.update_id
          doc.validate(auto_correct: true) do |msg, correctable, object|
            if command_parser.strict && !correctable
              raise Error, "Validation error for object (#{object.oid},#{object.gen}): #{msg}"
            elsif command_parser.verbosity_info?
              $stderr.puts "#{correctable ? 'Corrected' : 'Ignored'} validation problem " \
                "for object (#{object.oid},#{object.gen}): #{msg}"
            end
          end
          if command_parser.verbosity_info?
            puts "Creating output document #{out_file}"
          end
          doc.write(out_file, validate: false, compact: false, incremental: incremental)
        end
      end

      # Checks whether the given output file exists and ask whether to overwrite the output file if
      # it does. If HexaPDF::CLI#force is set, a possibly existing output file is always overwritten.
      def maybe_raise_on_existing_file(filename)
        if !command_parser.force && File.exist?(filename)
          response = read_from_console("Output file '#{filename}' already exists - overwrite? (y/n)")
          exit(1) unless response =~ /y/i
        end
      end

      # Defines the optimization options.
      #
      # See: #out_options, #apply_optimization_options
      def define_optimization_options
        options.separator("")
        options.separator("Optimization options:")
        options.on("--[no-]compact", "Delete unnecessary PDF objects (default: " \
                   "#{@out_options[:compact]})") do |c|
          @out_options[:compact] = c
        end
        options.on("--object-streams MODE", [:generate, :preserve, :delete],
                   "Handling of object streams (either generate, preserve or delete; " \
                     "default: #{@out_options[:object_streams]})") do |os|
          @out_options[:object_streams] = os
        end
        options.on("--xref-streams MODE", [:generate, :preserve, :delete],
                   "Handling of cross-reference streams (either generate, preserve or delete; " \
                     "default: #{@out_options[:xref_streams]})") do |x|
          @out_options[:xref_streams] = x
        end
        options.on("--streams MODE", [:compress, :preserve, :uncompress],
                   "Handling of stream data (either compress, preserve or uncompress; default: " \
                     "#{@out_options[:streams]})") do |streams|
          @out_options[:streams] = streams
        end
        options.on("--[no-]compress-pages", "Recompress page content streams (may take a long " \
                   "time; default: #{@out_options[:compress_pages]})") do |c|
          @out_options[:compress_pages] = c
        end
        options.on("--[no-]prune-page-resources", "Prunes unused objects from the page resources " \
                   "(may take a long time; default: #{@out_options[:prune_page_resources]})") do |c|
          @out_options[:prune_page_resources] = c
        end
        options.on("--[no-]optimize-fonts", "Optimize embedded font files; " \
                   "default: #{@out_options[:optimize_fonts]})") do |o|
          @out_options[:optimize_fonts] = o
        end
      end

      # Defines the encryption options.
      #
      # See: #out_options, #apply_encryption_options
      def define_encryption_options
        options.separator("")
        options.separator("Encryption options:")
        options.on("--decrypt", "Remove any encryption") do
          @out_options[:encryption] = :remove
        end
        options.on("--encrypt", "Encrypt the output file") do
          @out_options[:encryption] = :add
        end
        options.on("--owner-password PASSWORD", String, "The owner password to be set on the " \
                   "output file (use - for reading from standard input)") do |pwd|
          @out_options[:encryption] = :add
          @out_options[:enc_owner_pwd] = (pwd == '-' ? read_password("Owner password") : pwd)
        end
        options.on("--user-password PASSWORD", String, "The user password to be set on the " \
                   "output file (use - for reading from standard input)") do |pwd|
          @out_options[:encryption] = :add
          @out_options[:enc_user_pwd] = (pwd == '-' ? read_password("User password") : pwd)
        end
        options.on("--algorithm ALGORITHM", [:aes, :arc4],
                   "The encryption algorithm: aes or arc4 (default: " \
                     "#{@out_options[:enc_algorithm]})") do |a|
          @out_options[:encryption] = :add
          @out_options[:enc_algorithm] = a
        end
        options.on("--key-length BITS", Integer,
                   "The encryption key length in bits (default: " \
                     "#{@out_options[:enc_key_length]})") do |i|
          @out_options[:encryption] = :add
          @out_options[:enc_key_length] = i
        end
        options.on("--force-V4",
                   "Force use of encryption version 4 if key length=128 and algorithm=arc4") do
          @out_options[:encryption] = :add
          @out_options[:enc_force_v4] = true
        end
        syms = HexaPDF::Encryption::StandardSecurityHandler::Permissions::SYMBOL_TO_PERMISSION.keys
        options.on("--permissions PERMS", Array,
                   "Comma separated list of permissions to be set on the output file. Possible " \
                     "values: #{syms.join(', ')}") do |perms|
          perms.map! do |perm|
            unless syms.include?(perm.to_sym)
              raise OptionParser::InvalidArgument, "#{perm} (invalid permission name)"
            end
            perm.to_sym
          end
          @out_options[:encryption] = :add
          @out_options[:enc_permissions] = perms
        end
      end

      # Applies the optimization options to the given HexaPDF::Document instance.
      #
      # See: #define_optimization_options
      def apply_optimization_options(doc)
        doc.task(:optimize, compact: @out_options[:compact],
                 object_streams: @out_options[:object_streams],
                 xref_streams: @out_options[:xref_streams],
                 compress_pages: @out_options[:compress_pages],
                 prune_page_resources: @out_options[:prune_page_resources])
        if @out_options[:streams] != :preserve || @out_options[:optimize_fonts]
          doc.each do |obj|
            optimize_stream(obj)
            optimize_font(obj)
          end
        end
      end

      IGNORED_FILTERS = { #:nodoc:
        CCITTFaxDecode: true, JBIG2Decode: true, DCTDecode: true, JPXDecode: true, Crypt: true
      }.freeze

      # Applies the chosen stream mode to the given object.
      def optimize_stream(obj)
        return if @out_options[:streams] == :preserve || !obj.respond_to?(:set_filter) ||
          Array(obj[:Filter]).any? {|f| IGNORED_FILTERS[f] }

        obj.set_filter(@out_options[:streams] == :compress ? :FlateDecode : nil)
      end

      # Optimize the object if it is a font object.
      def optimize_font(obj)
        return unless @out_options[:optimize_fonts] && obj.kind_of?(HexaPDF::Type::Font) &&
          (obj[:Subtype] == :TrueType ||
           (obj[:Subtype] == :Type0 && obj.descendant_font[:Subtype] == :CIDFontType2)) &&
          obj.embedded?

        font = HexaPDF::Font::TrueType::Font.new(StringIO.new(obj.font_file.stream))
        data = HexaPDF::Font::TrueType::Optimizer.build_for_pdf(font)
        obj.font_file.stream = data
        obj.font_file[:Length1] = data.size
      rescue StandardError => e
        if command_parser.verbosity_info?
          $stderr.puts "Error optimizing font object (#{obj.oid},#{obj.gen}): #{e.message}"
        end
      end

      # Applies the encryption related options to the given HexaPDF::Document instance.
      #
      # See: #define_encryption_options
      def apply_encryption_options(doc)
        case @out_options[:encryption]
        when :add
          doc.encrypt(algorithm: @out_options[:enc_algorithm],
                      key_length: @out_options[:enc_key_length],
                      force_v4: @out_options[:enc_force_v4],
                      permissions: @out_options[:enc_permissions],
                      owner_password: @out_options[:enc_owner_pwd],
                      user_password: @out_options[:enc_user_pwd])
        when :remove
          doc.encrypt(name: nil)
        end
      end

      PAGE_NUMBER_SPEC = "(r?[1-9]\\d*|e)" #:nodoc:
      PAGE_MAP = lambda do |result, count|
        if result == 'e'
          count
        elsif result.start_with?('r')
          count - result[1..-1].to_i + 1
        else
          result.to_i
        end
      end
      ROTATE_MAP = {'l' => 90, 'r' => -90, 'd' => 180, 'n' => :none}.freeze #:nodoc:

      # Parses the pages specification string and returns an array of tuples containing a page
      # number and a rotation value (either -90, 90, 180, :none or +nil+ where an integer means
      # adding a rotation by that number of degrees, :none means removing any set rotation value and
      # +nil+ means preserving the set rotation value).
      #
      # The parameter +count+ needs to be the total number of pages in the document.
      #
      # For details on the pages specification see the hexapdf(1) manual page.
      def parse_pages_specification(range, count)
        range.split(',').each_with_object([]) do |str, arr|
          case str
          when /\A#{PAGE_NUMBER_SPEC}(l|r|d|n)?\z/o
            page_num = PAGE_MAP[$1, count]
            next if page_num > count
            arr << [page_num - 1, ROTATE_MAP[$2]]
          when /\A#{PAGE_NUMBER_SPEC}-#{PAGE_NUMBER_SPEC}(?:\/([1-9]\d*))?(l|r|d|n)?\z/o
            start_nr = [PAGE_MAP[$1, count], count].min - 1
            end_nr = [PAGE_MAP[$2, count], count].min - 1
            step = ($3 ? $3.to_i : 1) * (start_nr > end_nr ? -1 : 1)
            rotation = ROTATE_MAP[$4]
            start_nr.step(to: end_nr, by: step) {|n| arr << [n, rotation] }
          else
            raise OptionParser::InvalidArgument, "invalid page range format: #{str.inspect}"
          end
        end
      end

      # Reads a password from the standard input and falls back to the console if needed.
      #
      # The optional argument +prompt+ can be used to customize the prompt when reading from the
      # console.
      def read_password(prompt = "Password")
        if $stdin.tty?
          read_from_console(prompt, noecho: true)
        else
          ($stdin.gets || read_from_console(prompt, noecho: true)).chomp
        end
      end

      # Removes unused pages and page tree nodes from the document.
      def remove_unused_pages(doc)
        retained = doc.pages.each_with_object({}) {|page, h| h[page.data] = true }
        retained[doc.pages.root.data] = true
        doc.each do |obj|
          next unless obj.kind_of?(HexaPDF::Dictionary)
          if (obj.type == :Pages || obj.type == :Page) && !retained.key?(obj.data)
            doc.delete(obj)
          end
        end
      end

      # Returns the human readable file size.
      def human_readable_file_size(size)
        case size
        when 0..9999 then "#{size}B"
        when 10_000..999_999 then "#{(size / 1024.to_f).round(1)}K"
        else "#{(size.to_f / 1024 / 1024).round(1)}M"
        end
      end

      private

      # Displays the given prompt, reads from the console without echo and returns the read string.
      def read_from_console(prompt, noecho: false)
        IO.console.write("#{prompt}: ")
        if noecho
          IO.console.noecho {|io| io.gets.chomp }
          puts
        else
          IO.console.gets.chomp
        end
      end

    end

  end
end
