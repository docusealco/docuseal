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

    # Creates debugging information for adding to an issue.
    class DebugInfo < Command

      def initialize #:nodoc:
        super('debug-info', takes_commands: false)
        short_desc("Create debug information for a PDF file")
        long_desc(<<~EOF)
          Creates debug information for a possibly malformed PDF file that can be attached to an
          issue.

          Two files are created: anonymized-FILE where all strings are replaced with zeroes and
          debug_info.txt with additional debug information.
        EOF

        options.on("--password PASSWORD", "-p", String,
                   "The password for decryption. Use - for reading from standard input.") do |pwd|
          @password = (pwd == '-' ? read_password : pwd)
        end

        @password = nil
      end

      def execute(file) #:nodoc:
        output_name = "anonymized-#{file}"
        puts "Creating anonymized file '#{output_name}'"
        data = File.binread(file)
        data.gsub!(/(>>\s*stream\s*)(.*?)(\s*endstream)/m) {|m| "#{$1}#{'0' * $2.length}#{$3}" }
        data.gsub!(/([^<]<)([0-9A-Fa-f#{Tokenizer::WHITESPACE}]*?)>/m) {|m| "#{$1}#{'0' * $2.length}>" }
        data.gsub!(/\((.*?)\)/m) {|m| "(#{'0' * $1.length})" }
        File.binwrite(output_name, data)

        debug_info = +''
        puts "Collecting debug information in debug_info.txt"
        begin
          output = capture_output { HexaPDF::CLI::Application.new.parse(['info', '--check', file]) }
          debug_info << "Output:\n"<< output
        rescue
          debug_info << "Error collecting info: #{$!.message}\n"
        end
        File.write('debug_info.txt', debug_info)
      end

      private

      def capture_output
        stdout, stderr = $stdout, $stderr
        $stdout = $stderr = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout, $stderr = stdout, stderr
      end

    end

  end
end
