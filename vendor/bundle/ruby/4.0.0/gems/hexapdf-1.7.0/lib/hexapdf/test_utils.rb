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

require 'hexapdf/content/processor'

module HexaPDF

  # Contains various helper methods for testing HexaPDF
  module TestUtils

    # Can be used to to record operators parsed from content streams.
    class OperatorRecorder < HexaPDF::Content::Processor

      undef :paint_xobject

      attr_reader :recorded_ops

      def initialize
        super
        operators.clear
        @recorded_ops = []
      end

      def respond_to_missing?(*)
        true
      end

      def method_missing(msg, *params)
        @recorded_ops << (params.empty? ? [msg] : [msg, params])
      end

    end

    # Asserts that the content string contains the operators.
    def assert_operators(content, operators, only_names: false, range: 0..-1)
      processor = OperatorRecorder.new
      HexaPDF::Content::Parser.new.parse(content, processor)
      result = processor.recorded_ops[range]
      result.map!(&:first) if only_names
      assert_equal(operators, result)
    end

    # Asserts that the method +name+ of +object+ gets invoked with the +expected_values+ when
    # executing the block. +expected_values+ should contain arrays of arguments, one array for each
    # invocation of the method.
    def assert_method_invoked(object, name, *expected_values, check_block: false)
      args = []
      block = []
      object.define_singleton_method(name) {|*la, &lb| args << la; block << lb }
      yield
      assert_equal(expected_values, args, "Incorrect arguments for #{object.class}##{name}")
      block.each do |block_arg|
        assert_kind_of(Proc, block_arg, "Missing block for #{object.class}##{name}") if check_block
      end
    ensure
      object.singleton_class.send(:remove_method, name)
    end

    # Creates a fiber that yields the given string in +len+ length parts.
    def feeder(string, len = string.length)
      Fiber.new do
        string = string.b
        until string.empty?
          Fiber.yield(string.slice!(0, len))
        end
      end
    end

    # Collects the result from the HexaPDF::Filter source into a binary string.
    def collector(source)
      str = ''.b
      while source.alive? && (data = source.resume)
        str << data
      end
      str
    end

  end

end

Minitest::Spec.include(HexaPDF::TestUtils)
