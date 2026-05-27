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

module HexaPDF
  module Utils

    # A simple least recently used (LRU) cache.
    #
    # The cache relies on the fact that Ruby's Hash class maintains insertion order. So deleting
    # and re-inserting a key-value pair on access moves the key to the last position. When an
    # entry is added and the cache is full, the first entry is removed.
    class LRUCache

      # Creates a new LRUCache that can hold +size+ entries.
      def initialize(size)
        @size = size
        @cache = {}
      end

      # Returns the stored value for +key+ or +nil+ if no value was stored under the key.
      def [](key)
        (val = @cache.delete(key)).nil? ? nil : @cache[key] = val
      end

      # Stores the +value+ under the +key+.
      def []=(key, value)
        @cache.delete(key)
        @cache[key] = value
        @cache.shift if @cache.length > @size
      end

    end

  end
end
