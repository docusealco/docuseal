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

require 'cmdparse'
require 'hexapdf/cli/info'
require 'hexapdf/cli/files'
require 'hexapdf/cli/inspect'
require 'hexapdf/cli/modify'
require 'hexapdf/cli/merge'
require 'hexapdf/cli/optimize'
require 'hexapdf/cli/images'
require 'hexapdf/cli/batch'
require 'hexapdf/cli/split'
require 'hexapdf/cli/watermark'
require 'hexapdf/cli/image2pdf'
require 'hexapdf/cli/form'
require 'hexapdf/cli/fonts'
require 'hexapdf/cli/usage'
require 'hexapdf/cli/debug_info'
require 'hexapdf/version'
require 'hexapdf/document'

module HexaPDF

  # Contains the code for the +hexapdf+ binary. The binary uses the cmdparse library
  # (http://cmdparse.gettalong.org) for the command suite support.
  module CLI

    # Runs the CLI application.
    def self.run(args = ARGV)
      Application.new.parse(args)
    rescue Errno::ENOENT => e
      path = e.message.scan(/(?<= - ).*?$/).first
      $stderr.puts "Problem encountered: No such file - #{path}"
    rescue StandardError => e
      $stderr.puts "Problem encountered: #{e.message}"
      unless e.kind_of?(HexaPDF::Error)
        $stderr.puts "Backtrace (last 10 lines):"
        $stderr.puts e.backtrace[0, 10]
        $stderr.puts
        $stderr.puts "--> The problem might indicate a faulty PDF or a bug in HexaPDF."
        $stderr.puts "--> Please report this at"
        $stderr.puts "-->"
        $stderr.puts "-->     https://github.com/gettalong/hexapdf/issues"
        $stderr.puts "-->"
        $stderr.puts "--> and include the information above as well as the output of running"
        $stderr.puts "--> the following command on the input PDF:"
        $stderr.puts "-->"
        $stderr.puts "-->     hexapdf info --check INPUT.PDF"
        $stderr.puts "-->"
        $stderr.puts "--> If possible, please also provide the input PDF."
        $stderr.puts "--> Thanks!"
      end
      exit(1)
    end

    # The CmdParse::CommandParser class that is used for running the CLI application.
    class Application < CmdParse::CommandParser

      # Verbosity level for no output
      VERBOSITY_QUIET = 0

      # Verbosity level for warning output
      VERBOSITY_WARNING = 1

      # Verbosity level for informational output
      VERBOSITY_INFO = 2

      # Specifies whether an operation should be forced. For example, if an existing file should be
      # overwritten.
      attr_reader :force

      # Specifies whether strict parsing and validation should be used.
      attr_reader :strict

      def initialize #:nodoc:
        super(handle_exceptions: :no_help)
        main_command.options.program_name = "hexapdf"
        main_command.options.version = HexaPDF::VERSION
        main_command.extend(Command::Extensions)
        main_command.define_singleton_method(:usage_commands) { "COMMAND" }
        add_command(HexaPDF::CLI::Info.new)
        add_command(HexaPDF::CLI::Files.new)
        add_command(HexaPDF::CLI::Images.new)
        add_command(HexaPDF::CLI::Inspect.new)
        add_command(HexaPDF::CLI::Modify.new)
        add_command(HexaPDF::CLI::Optimize.new)
        add_command(HexaPDF::CLI::Merge.new)
        add_command(HexaPDF::CLI::Batch.new)
        add_command(HexaPDF::CLI::Split.new)
        add_command(HexaPDF::CLI::Watermark.new)
        add_command(HexaPDF::CLI::Image2PDF.new)
        add_command(HexaPDF::CLI::Form.new)
        add_command(HexaPDF::CLI::Fonts.new)
        add_command(HexaPDF::CLI::Usage.new)
        add_command(HexaPDF::CLI::DebugInfo.new)
        add_command(CmdParse::HelpCommand.new)
        version_command = CmdParse::VersionCommand.new(add_switches: false)
        add_command(version_command)
        main_options.on_tail("--version", "Show hexapdf version") { version_command.execute }

        @force = false
        @verbosity = VERBOSITY_WARNING
        @strict = false
        global_options.on("--[no-]force", "Force overwriting existing files. Default: false") do |f|
          @force = f
        end
        global_options.on("--strict", "Enable strict parsing and validation") do |s|
          @strict = s
        end
        global_options.on("--verbose", "-v", "Verbose output") do
          @verbosity += 1
        end
        global_options.on("--quiet", "-q", "Suppress any output") do
          @verbosity = VERBOSITY_QUIET
        end
      end

      # Returns +true+ if the verbosity level warning is enabled.
      def verbosity_warning?
        @verbosity >= VERBOSITY_WARNING
      end

      # Returns +true+ if the verbosity level info is enabled.
      def verbosity_info?
        @verbosity >= VERBOSITY_INFO
      end

      def parse(argv = ARGV) #:nodoc:
        ARGV.unshift('help') if ARGV.empty?
        super
      end

    end

  end

end
