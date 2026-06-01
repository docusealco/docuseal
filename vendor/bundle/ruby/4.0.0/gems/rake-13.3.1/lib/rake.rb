# frozen_string_literal: true
#--
# Copyright 2003-2010 by Jim Weirich (jim.weirich@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#++

module Rake; end

require_relative "rake/version"

require "rbconfig"
require "fileutils"
require "singleton"
require "monitor"
require "optparse"

require_relative "rake/ext/string"

require_relative "rake/win32"

require_relative "rake/linked_list"
require_relative "rake/cpu_counter"
require_relative "rake/scope"
require_relative "rake/task_argument_error"
require_relative "rake/rule_recursion_overflow_error"
require_relative "rake/rake_module"
require_relative "rake/trace_output"
require_relative "rake/pseudo_status"
require_relative "rake/task_arguments"
require_relative "rake/invocation_chain"
require_relative "rake/task"
require_relative "rake/file_task"
require_relative "rake/file_creation_task"
require_relative "rake/multi_task"
require_relative "rake/dsl_definition"
require_relative "rake/file_utils_ext"
require_relative "rake/file_list"
require_relative "rake/default_loader"
require_relative "rake/early_time"
require_relative "rake/late_time"
require_relative "rake/name_space"
require_relative "rake/task_manager"
require_relative "rake/application"
require_relative "rake/backtrace"

# :stopdoc:
#
# Some top level Constants.

FileList = Rake::FileList
RakeFileUtils = Rake::FileUtilsExt
