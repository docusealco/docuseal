# frozen_string_literal: true

module Zip
  module NullDecompressor # :nodoc:all
    module_function

    def read(_length = nil, _outbuf = nil)
      nil
    end

    def eof?
      true
    end

    # Alias for compatibility. Remove for version 4.
    alias eof eof?
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
