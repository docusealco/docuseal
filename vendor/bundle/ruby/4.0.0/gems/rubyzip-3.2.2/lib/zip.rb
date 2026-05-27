# frozen_string_literal: true

require 'English'
require 'delegate'
require 'singleton'
require 'tempfile'
require 'fileutils'
require 'stringio'
require 'zlib'
require 'zip/version'
require 'zip/constants'
require 'zip/dos_time'
require 'zip/ioextras'
require 'rbconfig'
require 'zip/entry'
require 'zip/extra_field'
require 'zip/entry_set'
require 'zip/central_directory'
require 'zip/file'
require 'zip/input_stream'
require 'zip/output_stream'
require 'zip/decompressor'
require 'zip/compressor'
require 'zip/null_decompressor'
require 'zip/null_compressor'
require 'zip/null_input_stream'
require 'zip/pass_thru_compressor'
require 'zip/pass_thru_decompressor'
require 'zip/crypto/decrypted_io'
require 'zip/crypto/encryption'
require 'zip/crypto/null_encryption'
require 'zip/crypto/traditional_encryption'
require 'zip/crypto/aes_encryption'
require 'zip/inflater'
require 'zip/deflater'
require 'zip/streamable_stream'
require 'zip/streamable_directory'
require 'zip/errors'

# Rubyzip is a ruby module for reading and writing zip files.
#
# The main entry points are File, InputStream and OutputStream. For a
# file/directory interface in the style of the standard ruby ::File and
# ::Dir APIs then `require 'zip/filesystem'` and see FileSystem.
module Zip
  extend self

  attr_accessor :unicode_names,
                :on_exists_proc,
                :continue_on_exists_proc,
                :sort_entries,
                :default_compression,
                :write_zip64_support,
                :warn_invalid_date,
                :case_insensitive_match,
                :force_entry_names_encoding,
                :validate_entry_sizes

  DEFAULT_RESTORE_OPTIONS = {
    restore_ownership:   false,
    restore_permissions: true,
    restore_times:       true
  }.freeze # :nodoc:

  # :nodoc:
  # Remove this when JRuby#3962 is fixed.
  ZLIB_FLUSHING_STRATEGY = defined?(JRUBY_VERSION) ? Zlib::SYNC_FLUSH : Zlib::NO_FLUSH

  def reset! # :nodoc:
    @_ran_once = false
    @unicode_names = false
    @on_exists_proc = false
    @continue_on_exists_proc = false
    @sort_entries = false
    @default_compression = Zlib::DEFAULT_COMPRESSION
    @write_zip64_support = true
    @warn_invalid_date = true
    @case_insensitive_match = false
    @force_entry_names_encoding = nil
    @validate_entry_sizes = true
  end

  # Set options for RubyZip in one block.
  def setup
    yield self unless @_ran_once
    @_ran_once = true
  end

  reset!
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
