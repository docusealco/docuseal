# frozen_string_literal: true

require 'fileutils'
require 'forwardable'

require_relative 'file_split'

module Zip
  # Zip::File is modeled after java.util.zip.ZipFile from the Java SDK.
  # The most important methods are those for accessing information about
  # the entries in
  # the archive and methods such as `get_input_stream` and
  # `get_output_stream` for reading from and writing entries to the
  # archive. The class includes a few convenience methods such as
  # `extract` for extracting entries to the filesystem, and `remove`,
  # `replace`, `rename` and `mkdir` for making simple modifications to
  # the archive.
  #
  # Modifications to a zip archive are not committed until `commit` or
  # `close` is called. The method `open` accepts a block following
  # the pattern from ::File.open offering a simple way to
  # automatically close the archive when the block returns.
  #
  # The following example opens zip archive `my.zip`
  # (creating it if it doesn't exist) and adds an entry
  # `first.txt` and a directory entry `a_dir`
  # to it.
  #
  # ```
  # require 'zip'
  #
  # Zip::File.open('my.zip', create: true) do |zipfile|
  #   zipfile.get_output_stream('first.txt') { |f| f.puts 'Hello from Zip::File' }
  #   zipfile.mkdir('a_dir')
  # end
  # ```
  #
  # The next example reopens `my.zip`, writes the contents of
  # `first.txt` to standard out and deletes the entry from
  # the archive.
  #
  # ```
  # require 'zip'
  #
  # Zip::File.open('my.zip', create: true) do |zipfile|
  #   puts zipfile.read('first.txt')
  #   zipfile.remove('first.txt')
  # end
  #
  # Zip::FileSystem offers an alternative API that emulates ruby's
  # interface for accessing the filesystem, ie. the ::File and ::Dir classes.
  class File
    include Enumerable
    extend Forwardable
    extend FileSplit

    IO_METHODS = [:tell, :seek, :read, :eof, :close].freeze # :nodoc:

    # The name of this zip archive.
    attr_reader :name

    # default -> false.
    attr_accessor :restore_ownership

    # default -> true.
    attr_accessor :restore_permissions

    # default -> true.
    attr_accessor :restore_times

    def_delegators :@cdir, :comment, :comment=, :each, :entries, :glob, :size

    # Opens a zip archive. Pass create: true to create
    # a new archive if it doesn't exist already.
    def initialize(path_or_io, create: false, buffer: false,
                   restore_ownership: DEFAULT_RESTORE_OPTIONS[:restore_ownership],
                   restore_permissions: DEFAULT_RESTORE_OPTIONS[:restore_permissions],
                   restore_times: DEFAULT_RESTORE_OPTIONS[:restore_times],
                   compression_level: ::Zip.default_compression,
                   suppress_extra_fields: false)
      super()

      @name    = path_or_io.respond_to?(:path) ? path_or_io.path : path_or_io
      @create  = create ? true : false # allow any truthy value to mean true

      initialize_cdir(path_or_io, buffer: buffer)

      @restore_ownership     = restore_ownership
      @restore_permissions   = restore_permissions
      @restore_times         = restore_times
      @compression_level     = compression_level
      @suppress_extra_fields = suppress_extra_fields
    end

    class << self
      # Similar to ::new. If a block is passed the Zip::File object is passed
      # to the block and is automatically closed afterwards, just as with
      # ruby's builtin File::open method.
      def open(file_name, create: false,
               restore_ownership: DEFAULT_RESTORE_OPTIONS[:restore_ownership],
               restore_permissions: DEFAULT_RESTORE_OPTIONS[:restore_permissions],
               restore_times: DEFAULT_RESTORE_OPTIONS[:restore_times],
               compression_level: ::Zip.default_compression,
               suppress_extra_fields: false)
        zf = ::Zip::File.new(file_name, create:                create,
                                        restore_ownership:     restore_ownership,
                                        restore_permissions:   restore_permissions,
                                        restore_times:         restore_times,
                                        compression_level:     compression_level,
                                        suppress_extra_fields: suppress_extra_fields)

        return zf unless block_given?

        begin
          yield zf
        ensure
          zf.close
        end
      end

      # Like #open, but reads zip archive contents from a String or open IO
      # stream, and outputs data to a buffer.
      # (This can be used to extract data from a
      # downloaded zip archive without first saving it to disk.)
      def open_buffer(io = ::StringIO.new, create: false,
                      restore_ownership: DEFAULT_RESTORE_OPTIONS[:restore_ownership],
                      restore_permissions: DEFAULT_RESTORE_OPTIONS[:restore_permissions],
                      restore_times: DEFAULT_RESTORE_OPTIONS[:restore_times],
                      compression_level: ::Zip.default_compression,
                      suppress_extra_fields: false)
        unless IO_METHODS.map { |method| io.respond_to?(method) }.all? || io.kind_of?(String)
          raise 'Zip::File.open_buffer expects a String or IO-like argument' \
                "(responds to #{IO_METHODS.join(', ')}). Found: #{io.class}"
        end

        io = ::StringIO.new(io) if io.kind_of?(::String)

        zf = ::Zip::File.new(io, create: create, buffer: true,
                                 restore_ownership:     restore_ownership,
                                 restore_permissions:   restore_permissions,
                                 restore_times:         restore_times,
                                 compression_level:     compression_level,
                                 suppress_extra_fields: suppress_extra_fields)

        return zf unless block_given?

        yield zf

        begin
          zf.write_buffer(io)
        rescue IOError => e
          raise unless e.message == 'not opened for writing'
        end
      end

      # Iterates over the contents of the ZipFile. This is more efficient
      # than using a ZipInputStream since this methods simply iterates
      # through the entries in the central directory structure in the archive
      # whereas ZipInputStream jumps through the entire archive accessing the
      # local entry headers (which contain the same information as the
      # central directory).
      def foreach(zip_file_name, &block)
        ::Zip::File.open(zip_file_name) do |zip_file|
          zip_file.each(&block)
        end
      end

      # Count the entries in a zip archive without reading the whole set of
      # entry data into memory.
      def count_entries(path_or_io)
        cdir = ::Zip::CentralDirectory.new

        if path_or_io.kind_of?(String)
          ::File.open(path_or_io, 'rb') do |f|
            cdir.count_entries(f)
          end
        else
          cdir.count_entries(path_or_io)
        end
      end
    end

    # Returns an input stream to the specified entry. If a block is passed
    # the stream object is passed to the block and the stream is automatically
    # closed afterwards just as with ruby's builtin File.open method.
    def get_input_stream(entry, &a_proc)
      get_entry(entry).get_input_stream(&a_proc)
    end

    # Returns an output stream to the specified entry. If entry is not an instance
    # of Zip::Entry, a new Zip::Entry will be initialized using the arguments
    # specified. If a block is passed the stream object is passed to the block and
    # the stream is automatically closed afterwards just as with ruby's builtin
    # File.open method.
    def get_output_stream(entry, permissions: nil, comment: nil,
                          extra: nil, compressed_size: nil, crc: nil,
                          compression_method: nil, compression_level: nil,
                          size: nil, time: nil, &a_proc)
      new_entry =
        if entry.kind_of?(Entry)
          entry
        else
          Entry.new(
            @name, entry.to_s, comment: comment, extra: extra,
            compressed_size: compressed_size, crc: crc, size: size,
            compression_method: compression_method,
            compression_level: compression_level, time: time
          )
        end
      if new_entry.directory?
        raise ArgumentError,
              "cannot open stream to directory entry - '#{new_entry}'"
      end
      new_entry.unix_perms = permissions
      zip_streamable_entry = StreamableStream.new(new_entry)
      @cdir << zip_streamable_entry
      zip_streamable_entry.get_output_stream(&a_proc)
    end

    # Returns the name of the zip archive
    def to_s
      @name
    end

    # Returns a string containing the contents of the specified entry
    def read(entry)
      get_input_stream(entry, &:read)
    end

    # Convenience method for adding the contents of a file to the archive
    def add(entry, src_path, &continue_on_exists_proc)
      continue_on_exists_proc ||= proc { ::Zip.continue_on_exists_proc }
      check_entry_exists(entry, continue_on_exists_proc, 'add')
      new_entry = if entry.kind_of?(::Zip::Entry)
                    entry
                  else
                    ::Zip::Entry.new(
                      @name, entry.to_s,
                      compression_level: @compression_level
                    )
                  end
      new_entry.gather_fileinfo_from_srcpath(src_path)
      @cdir << new_entry
    end

    # Convenience method for adding the contents of a file to the archive
    # in Stored format (uncompressed)
    def add_stored(entry, src_path, &continue_on_exists_proc)
      entry = ::Zip::Entry.new(
        @name, entry.to_s, compression_method: ::Zip::Entry::STORED
      )
      add(entry, src_path, &continue_on_exists_proc)
    end

    # Removes the specified entry.
    def remove(entry)
      @cdir.delete(get_entry(entry))
    end

    # Renames the specified entry.
    def rename(entry, new_name, &continue_on_exists_proc)
      found_entry = get_entry(entry)
      check_entry_exists(new_name, continue_on_exists_proc, 'rename')
      @cdir.delete(found_entry)
      found_entry.name = new_name
      @cdir << found_entry
    end

    # Replaces the specified entry with the contents of src_path (from
    # the file system).
    def replace(entry, src_path)
      check_file(src_path)
      remove(entry)
      add(entry, src_path)
    end

    # Extracts `entry` to a file at `entry_path`, with `destination_directory`
    # as the base location in the filesystem.
    #
    # NB: The caller is responsible for making sure `destination_directory` is
    # safe, if it is passed.
    def extract(entry, entry_path = nil, destination_directory: '.', &block)
      block ||= proc { ::Zip.on_exists_proc }
      found_entry = get_entry(entry)
      entry_path ||= found_entry.name
      found_entry.extract(entry_path, destination_directory: destination_directory, &block)
    end

    # Commits changes that has been made since the previous commit to
    # the zip archive.
    def commit
      return if name.kind_of?(StringIO) || !commit_required?

      on_success_replace do |tmp_file|
        ::Zip::OutputStream.open(tmp_file, suppress_extra_fields: @suppress_extra_fields) do |zos|
          @cdir.each do |e|
            e.write_to_zip_output_stream(zos)
            e.clean_up
          end
          zos.comment = comment
        end
        true
      end
      initialize_cdir(@name)
    end

    # Write buffer write changes to buffer and return
    def write_buffer(io = ::StringIO.new)
      return io unless commit_required?

      ::Zip::OutputStream.write_buffer(io, suppress_extra_fields: @suppress_extra_fields) do |zos|
        @cdir.each { |e| e.write_to_zip_output_stream(zos) }
        zos.comment = comment
      end
    end

    # Closes the zip file committing any changes that has been made.
    def close
      commit
    end

    # Returns true if any changes has been made to this archive since
    # the previous commit
    def commit_required?
      return true if @create || @cdir.dirty?

      @cdir.each do |e|
        return true if e.dirty?
      end

      false
    end

    # Searches for entry with the specified name. Returns nil if
    # no entry is found. See also get_entry
    def find_entry(entry_name)
      selected_entry = @cdir.find_entry(entry_name)
      return if selected_entry.nil?

      selected_entry.restore_ownership   = @restore_ownership
      selected_entry.restore_permissions = @restore_permissions
      selected_entry.restore_times       = @restore_times
      selected_entry
    end

    # Searches for an entry just as find_entry, but throws Errno::ENOENT
    # if no entry is found.
    def get_entry(entry)
      selected_entry = find_entry(entry)
      raise Errno::ENOENT, entry if selected_entry.nil?

      selected_entry
    end

    # Creates a directory
    def mkdir(entry_name, permission = 0o755)
      raise Errno::EEXIST, "File exists - #{entry_name}" if find_entry(entry_name)

      entry_name = entry_name.dup.to_s
      entry_name << '/' unless entry_name.end_with?('/')
      @cdir << ::Zip::StreamableDirectory.new(@name, entry_name, nil, permission)
    end

    private

    def initialize_cdir(path_or_io, buffer: false)
      @cdir = ::Zip::CentralDirectory.new

      if ::File.size?(@name.to_s)
        # There is a file, which exists, that is associated with this zip.
        @create = false
        @file_permissions = ::File.stat(@name).mode

        if buffer
          # https://github.com/rubyzip/rubyzip/issues/119
          path_or_io.binmode if path_or_io.respond_to?(:binmode)
          @cdir.read_from_stream(path_or_io)
        else
          ::File.open(@name, 'rb') do |f|
            @cdir.read_from_stream(f)
          end
        end
      elsif buffer && path_or_io.size > 0
        # This zip is probably a non-empty StringIO.
        @create = false
        @cdir.read_from_stream(path_or_io)
      elsif !@create && ::File.empty?(@name)
        # A file exists, but it is empty, and we've said we're
        # NOT creating a new zip.
        raise Error, "File #{@name} has zero size. Did you mean to pass the create flag?"
      elsif !@create
        # If we get here, and we're not creating a new zip, then
        # everything is wrong.
        raise Error, "File #{@name} not found"
      end
    end

    def check_entry_exists(entry_name, continue_on_exists_proc, proc_name)
      return unless @cdir.include?(entry_name)

      continue_on_exists_proc ||= proc { Zip.continue_on_exists_proc }
      raise ::Zip::EntryExistsError.new proc_name, entry_name unless continue_on_exists_proc.call

      remove get_entry(entry_name)
    end

    def check_file(path)
      raise Errno::ENOENT, path unless ::File.readable?(path)
    end

    def on_success_replace
      dirname, basename = ::File.split(name)
      ::Dir::Tmpname.create(basename, dirname) do |tmp_filename|
        if yield tmp_filename
          ::File.rename(tmp_filename, name)
          ::File.chmod(@file_permissions, name) unless @create
        end
      ensure
        FileUtils.rm_f(tmp_filename)
      end
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
