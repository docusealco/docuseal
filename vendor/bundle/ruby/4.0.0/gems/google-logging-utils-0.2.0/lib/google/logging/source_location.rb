# frozen_string_literal: true

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Google
  module Logging
    ##
    # An object representing a source location as used by Google Logging.
    #
    class SourceLocation
      ##
      # Returns a SourceLocation corresponding to the caller.
      # This basically walks the stack trace backwards until it finds the
      # first entry not in the `google/logging/message.rb` source file or in
      # any of the other files optionally listed.
      #
      # @param locations [Array<Thread::Backtrace::Location>] The caller stack
      #     to search. Optional; defaults to the current stack.
      # @param extra_depth [Integer] Optional extra steps backwards to walk.
      #     Defaults to 0.
      # @param omit_files [Array<String,Regexp>] File paths to omit.
      # @return [SourceLocation,nil] The SourceLocation, or nil if none found.
      #
      def self.for_caller locations: nil, extra_depth: 0, omit_files: nil
        in_file = true
        omit_files = [__FILE__] + Array(omit_files)
        (locations || self.caller_locations).each do |loc|
          if in_file
            next if omit_files.any? { |pat| pat === loc.absolute_path }
            in_file = false
          end
          extra_depth -= 1
          next unless extra_depth.negative?
          return new file: loc.path, line: loc.lineno.to_s, function: loc.base_label
        end
        nil
      end

      ##
      # Low-level constructor.
      #
      # @param file [String] Path to the source file.
      # @param line [String] Line number as a string.
      # @param function [String] Name of the calling function.
      #
      def initialize file:, line:, function:
        @file = file.to_s
        @line = line.to_s
        @function = function.to_s
      end

      # @return [String] Path to the source file.
      attr_reader :file

      # @return [String] Line number as a string.
      attr_reader :line

      # @return [String] Name of the calling function.
      attr_reader :function

      # @private
      def to_h
        {
          file: @file,
          line: @line,
          function: @function
        }
      end

      # @private
      def == other
        return false unless other.is_a? SourceLocation
        file == other.file && line == other.line && function == other.function
      end
      alias eql? ==

      # @private
      def hash
        [file, line, function].hash
      end
    end
  end
end
