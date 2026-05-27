# frozen_string_literal: true

require 'ffi'

module Puma
  module JRubyRestart
    extend FFI::Library
    ffi_lib 'c'
    attach_function :chdir, [:string], :int
  end
end
