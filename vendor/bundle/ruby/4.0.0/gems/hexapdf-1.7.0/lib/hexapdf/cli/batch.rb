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
require 'shellwords'

module HexaPDF
  module CLI

    # Execute the same command for multiple input files.
    class Batch < Command

      def initialize #:nodoc:
        super('batch', takes_commands: false)
        short_desc("Execute a single command on multiple files")
        long_desc(<<~EOF)
          This command allows executing a single command for multiple input files, thereby reducing
          the overall execution time.

          The first argument is used as a hexapdf command line (but without the binary name) and
          the rest as input files. The specified command will be executed for each input file, with
          {} being replaced by the file name.
        EOF
      end

      def execute(command, *files) #:nodoc:
        args = Shellwords.split(command)
        files.each do |file|
          HexaPDF::CLI::Application.new.parse(args.map {|a| a.gsub(/{}/, file) })
        rescue StandardError
          if command_parser.verbosity_warning?
            $stderr.puts "Error processing '#{file}': #{$!.message}"
          end
        end
      end

    end

  end
end
