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

    # Outputs various bits of information about PDF files:
    #
    # * The entries in the trailers /Info dictionary
    # * Encryption information from the trailers /Encrypt dictionary
    # * The number of pages
    # * The used PDF version
    #
    # See: HexaPDF::Type::Info, HexaPDF::Encryption::SecurityHandler
    class Info < Command

      def initialize #:nodoc:
        super('info', takes_commands: false)
        short_desc("Show document information")
        long_desc(<<~EOF)
          This command extracts information from the Info dictionary of a PDF file as well
          as some other useful information like the used PDF version and encryption information.

          If the --check option is specified, the PDF file will also be checked for parse and
          validation errors. And if the process doesn't abort, HexaPDF is still able to handle the
          file by correcting the errors.
        EOF
        options.on("--check", "-c", "Check the PDF file for parse errors and validity") do |check|
          @check_file = check
        end
        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end
        @password = nil
        @auto_decrypt = true
        @check_file = false
      end

      def execute(file) #:nodoc:
        output_info(file)
      end

      private

      INFO_KEYS = [:Title, :Author, :Subject, :Keywords, :Creator, :Producer, #:nodoc:
                   :CreationDate, :ModDate].freeze

      COLUMN_WIDTH = 20 #:nodoc:

      def output_info(file) # :nodoc:
        options = pdf_options(@password)
        options[:config]['document.auto_decrypt'] = @auto_decrypt
        HexaPDF::Document.open(file, **options) do |doc|
          if @check_file
            indirect_object = nil
            validation_block = lambda do |msg, correctable, object|
              object = indirect_object unless object.indirect? || object.type == :XXTrailer
              object_type = if object.type == :XXTrailer
                              'trailer'
                            elsif !object.type.to_s.start_with?("XX")
                              "object type #{object.type} (#{object.oid},#{object.gen})"
                            else
                              "object (#{object.oid},#{object.gen})"
                            end
              object_type = "sub-object of #{object_type}" if object == indirect_object
              puts "WARNING: Validation error for #{object_type}: #{msg} " \
                "#{correctable ? '(correctable)' : ''}"
            end
            doc.trailer.validate(auto_correct: true, &validation_block)
            doc.each(only_loaded: false) do |obj|
              indirect_object = obj
              obj.validate(auto_correct: true, &validation_block)
              if obj.data.stream
                begin
                  obj.stream
                rescue StandardError
                  puts "ERROR: Stream of object (#{obj.oid},#{obj.gen}) invalid: #{$!.message}"
                end
              end
            end
          end

          output_line("File name", file)
          output_line("File size", File.stat(file).size.to_s << " bytes")
          @auto_decrypt && INFO_KEYS.each do |name|
            value = doc.trailer.info[name]
            next if !value || (value.kind_of?(String) && value.empty?)
            output_line(name.to_s, doc.trailer.info[name].to_s)
          end

          if doc.encrypted? && @auto_decrypt
            details = doc.security_handler.encryption_details
            data = "yes (version: #{details[:version]}, key length: #{details[:key_length]}bits)"
            output_line("Encrypted", data)
            output_line("  Used Password", doc.security_handler.decryption_password_type)
            output_line("  String algorithm", details[:string_algorithm].to_s)
            output_line("  Stream algorithm", details[:stream_algorithm].to_s)
            output_line("  EFF algorithm", details[:embedded_file_algorithm].to_s)
            if doc.security_handler.respond_to?(:permissions)
              output_line("  Permissions", doc.security_handler.permissions.join(", "))
            end
          elsif doc.encrypted?
            output_line("Encrypted", "yes (no or wrong password given)")
          else
            output_line("Encrypted", "no")
          end

          if doc.revisions.parser.linearized?
            output_line("Linearized", "yes")
          end

          signatures = doc.signatures.to_a
          unless signatures.empty?
            nr_sigs = signatures.count
            output_line("Document signed", "yes - #{nr_sigs} signature#{nr_sigs > 1 ? 's' : ''}")
            signatures.each do |signature|
              output_line("  Signer", signature.signer_name)
              output_line("    Signing time", signature.signing_time)
              if (reason = signature.signing_reason)
                output_line("    Reason", reason)
              end
              if (location = signature.signing_location)
                output_line("    Location", location)
              end
              output_line("    Signature type", signature.signature_type)
              signature.verify(allow_self_signed: true).messages.sort.each do |msg|
                output_line("    #{msg.type.capitalize}", msg.content)
              end
            end
          end

          output_line("Pages", doc.pages.count.to_s)
          output_line("Version", doc.version)
          if doc.revisions.parser.reconstructed?
            output_line("Reconstructed", "yes (use --check for details)")
          end
        end
      rescue HexaPDF::EncryptionError
        if @auto_decrypt
          @auto_decrypt = false
          retry
        else
          raise
        end
      rescue HexaPDF::MalformedPDFError => e
        $stderr.puts "Error: PDF file #{file} is damaged and cannot be recovered"
        $stderr.puts "       #{e}"
      end

      # Use custom options if we are checking the PDF file for errors.
      def pdf_options(password)
        if @check_file
          options = {decryption_opts: {password: password}, config: {}}
          HexaPDF::GlobalConfiguration['filter.predictor.strict'] = true
          HexaPDF::GlobalConfiguration['filter.flate.on_error'] = proc { true }
          options[:config]['parser.try_xref_reconstruction'] = true
          options[:config]['parser.on_correctable_error'] = lambda do |_, msg, pos|
            puts "WARNING: Parse error at position #{pos}: #{msg}"
            false
          end
          options[:config]['encryption.on_decryption_error'] = lambda do |obj, msg|
            puts "WARNING: Decryption problem for object (#{obj.oid},#{obj.gen}): #{msg}"
            false
          end
          options
        else
          super
        end
      end

      def output_line(header, text) #:nodoc:
        puts("#{header}:".ljust(COLUMN_WIDTH) << text.to_s)
      end

    end

  end
end
