# frozen_string_literal: true

require 'pathname'

require_relative 'constants'
require_relative 'dirtyable'

module Zip
  # Zip::Entry represents an entry in a Zip archive.
  class Entry
    include Dirtyable

    # Constant used to specify that the entry is stored (i.e., not compressed).
    STORED   = ::Zip::COMPRESSION_METHOD_STORE

    # Constant used to specify that the entry is deflated (i.e., compressed).
    DEFLATED = ::Zip::COMPRESSION_METHOD_DEFLATE

    # Language encoding flag (EFS) bit
    EFS = 0b100000000000 # :nodoc:

    # Compression level flags (used as part of the gp flags).
    COMPRESSION_LEVEL_SUPERFAST_GPFLAG = 0b110 # :nodoc:
    COMPRESSION_LEVEL_FAST_GPFLAG = 0b100      # :nodoc:
    COMPRESSION_LEVEL_MAX_GPFLAG = 0b010       # :nodoc:

    attr_accessor :comment, :compressed_size, :follow_symlinks, :name,
                  :restore_ownership, :restore_permissions, :restore_times,
                  :unix_gid, :unix_perms, :unix_uid

    attr_accessor :crc, :external_file_attributes, :fstype, :gp_flags,
                  :internal_file_attributes, :local_header_offset # :nodoc:

    attr_reader :extra, :compression_level, :filepath # :nodoc:

    attr_writer :size # :nodoc:

    mark_dirty :comment=, :compressed_size=, :external_file_attributes=,
               :fstype=, :gp_flags=, :name=, :size=,
               :unix_gid=, :unix_perms=, :unix_uid=

    def set_default_vars_values # :nodoc:
      @local_header_offset      = 0
      @local_header_size        = nil # not known until local entry is created or read
      @internal_file_attributes = 1
      @external_file_attributes = 0
      @header_signature         = ::Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE

      @version_needed_to_extract = VERSION_NEEDED_TO_EXTRACT
      @version                   = VERSION_MADE_BY

      @ftype           = nil          # unspecified or unknown
      @filepath        = nil
      @gp_flags        = 0
      if ::Zip.unicode_names
        @gp_flags |= EFS
        @version = 63
      end
      @follow_symlinks = false

      @restore_times       = DEFAULT_RESTORE_OPTIONS[:restore_times]
      @restore_permissions = DEFAULT_RESTORE_OPTIONS[:restore_permissions]
      @restore_ownership   = DEFAULT_RESTORE_OPTIONS[:restore_ownership]
      # BUG: need an extra field to support uid/gid's
      @unix_uid            = nil
      @unix_gid            = nil
      @unix_perms          = nil
    end

    def check_name(name) # :nodoc:
      raise EntryNameError, name if name.start_with?('/')
      raise EntryNameError if name.length > 65_535
    end

    # Create a new Zip::Entry.
    def initialize(
      zipfile = '', name = '',
      comment: '', size: nil, compressed_size: 0, crc: 0,
      compression_method: DEFLATED,
      compression_level: ::Zip.default_compression,
      time: ::Zip::DOSTime.now, extra: ::Zip::ExtraField.new
    )
      super()
      @name = name
      check_name(@name)

      set_default_vars_values
      @fstype = ::Zip::RUNNING_ON_WINDOWS ? ::Zip::FSTYPE_FAT : ::Zip::FSTYPE_UNIX

      @zipfile            = zipfile
      @comment            = comment || ''
      @compression_method = compression_method || DEFLATED
      @compression_level  = compression_level || ::Zip.default_compression
      @compressed_size    = compressed_size || 0
      @crc                = crc || 0
      @size               = size
      @time               = case time
                            when ::Zip::DOSTime
                              time
                            when Time
                              ::Zip::DOSTime.from_time(time)
                            else
                              ::Zip::DOSTime.now
                            end
      @extra              =
        extra.kind_of?(ExtraField) ? extra : ExtraField.new(extra.to_s)

      set_compression_level_flags
    end

    # Is this entry encrypted?
    def encrypted?
      gp_flags & 1 == 1
    end

    def incomplete? # :nodoc:
      (gp_flags & 8 == 8) && (crc == 0 || size == 0 || compressed_size == 0)
    end

    # The uncompressed size of the entry.
    def size
      @size || 0
    end

    # Get a timestamp component of this entry.
    #
    # Returns modification time by default.
    def time(component: :mtime)
      time =
        if @extra[:universaltime]
          @extra[:universaltime].send(component)
        elsif @extra[:ntfs]
          @extra[:ntfs].send(component)
        end

      # Standard time field in central directory has local time
      # under archive creator. Then, we can't get timezone.
      time || (@time if component == :mtime)
    end

    alias mtime time

    # Get the last access time of this entry, if available.
    def atime
      time(component: :atime)
    end

    # Get the creation time of this entry, if available.
    def ctime
      time(component: :ctime)
    end

    # Set a timestamp component of this entry.
    #
    # Sets modification time by default.
    def time=(value, component: :mtime)
      @dirty = true
      unless @extra.member?(:universaltime) || @extra.member?(:ntfs)
        @extra.create(:universaltime)
      end

      value = DOSTime.from_time(value)
      comp = "#{component}=" unless component.to_s.end_with?('=')
      (@extra[:universaltime] || @extra[:ntfs]).send(comp, value)
      @time = value if component == :mtime
    end

    alias mtime= time=

    # Set the last access time of this entry.
    def atime=(value)
      send(:time=, value, component: :atime)
    end

    # Set the creation time of this entry.
    def ctime=(value)
      send(:time=, value, component: :ctime)
    end

    # Does this entry return time fields with accurate timezone information?
    def absolute_time?
      @extra.member?(:universaltime) || @extra.member?(:ntfs)
    end

    # Return the compression method for this entry.
    #
    # Returns STORED if the entry is a directory or if the compression
    # level is 0.
    def compression_method
      return STORED if ftype == :directory || @compression_level == 0

      @compression_method
    end

    # Set the compression method for this entry.
    def compression_method=(method)
      @dirty = true
      @compression_method = (ftype == :directory ? STORED : method)
    end

    # Does this entry use the ZIP64 extensions?
    def zip64?
      !@extra[:zip64].nil?
    end

    # Is this entry encrypted with AES encryption?
    def aes?
      !@extra[:aes].nil?
    end

    def file_type_is?(type) # :nodoc:
      ftype == type
    end

    def ftype # :nodoc:
      @ftype ||= name_is_directory? ? :directory : :file
    end

    # Dynamic checkers
    %w[directory file symlink].each do |k|
      define_method :"#{k}?" do
        file_type_is?(k.to_sym)
      end
    end

    def name_is_directory? # :nodoc:
      @name.end_with?('/')
    end

    # Is the name a relative path, free of `..` patterns that could lead to
    # path traversal attacks? This does NOT handle symlinks; if the path
    # contains symlinks, this check is NOT enough to guarantee safety.
    def name_safe? # :nodoc:
      cleanpath = Pathname.new(@name).cleanpath
      return false unless cleanpath.relative?

      root = ::File::SEPARATOR
      naive = Regexp.escape(::File.join(root, cleanpath.to_s))
      # Allow for Windows drive mappings at the root.
      ::File.absolute_path(cleanpath.to_s, root).match?(/([A-Z]:)?#{naive}/i)
    end

    def local_entry_offset # :nodoc:
      local_header_offset + @local_header_size
    end

    def name_size # :nodoc:
      @name ? @name.bytesize : 0
    end

    def extra_size # :nodoc:
      @extra ? @extra.local_size : 0
    end

    def comment_size # :nodoc:
      @comment ? @comment.bytesize : 0
    end

    def calculate_local_header_size # :nodoc:
      LOCAL_ENTRY_STATIC_HEADER_LENGTH + name_size + extra_size
    end

    # check before rewriting an entry (after file sizes are known)
    # that we didn't change the header size (and thus clobber file data or something)
    def verify_local_header_size! # :nodoc:
      return if @local_header_size.nil?

      new_size = calculate_local_header_size
      return unless @local_header_size != new_size

      raise Error,
            "Local header size changed (#{@local_header_size} -> #{new_size})"
    end

    def cdir_header_size # :nodoc:
      CDIR_ENTRY_STATIC_HEADER_LENGTH + name_size +
        (@extra ? @extra.c_dir_size : 0) + comment_size
    end

    def next_header_offset # :nodoc:
      local_entry_offset + compressed_size
    end

    # Extracts this entry to a file at `entry_path`, with
    # `destination_directory` as the base location in the filesystem.
    #
    # NB: The caller is responsible for making sure `destination_directory` is
    # safe, if it is passed.
    def extract(entry_path = @name, destination_directory: '.', &block)
      dest_dir = ::File.absolute_path(destination_directory || '.')
      extract_path = ::File.absolute_path(::File.join(dest_dir, entry_path))

      unless extract_path.start_with?(dest_dir)
        warn "WARNING: skipped extracting '#{@name}' to '#{extract_path}' as unsafe."
        return self
      end

      block ||= proc { ::Zip.on_exists_proc }

      raise "unknown file type #{inspect}" unless directory? || file? || symlink?

      __send__(:"create_#{ftype}", extract_path, &block)
      self
    end

    def to_s # :nodoc:
      @name
    end

    class << self
      def read_c_dir_entry(io) # :nodoc:
        path = if io.respond_to?(:path)
                 io.path
               else
                 io
               end
        entry = new(path)
        entry.read_c_dir_entry(io)
        entry
      rescue Error
        nil
      end

      def read_local_entry(io) # :nodoc:
        entry = new(io)
        entry.read_local_entry(io)
        entry
      rescue SplitArchiveError
        raise
      rescue Error
        nil
      end
    end

    def unpack_local_entry(buf) # :nodoc:
      @header_signature,
        @version,
        @fstype,
        @gp_flags,
        @compression_method,
        @last_mod_time,
        @last_mod_date,
        @crc,
        @compressed_size,
        @size,
        @name_length,
        @extra_length = buf.unpack('VCCvvvvVVVvv')
    end

    def read_local_entry(io) # :nodoc:
      @dirty = false # No changes at this point.
      current_offset = io.tell

      read_local_header_fields(io)

      if @header_signature == SPLIT_FILE_SIGNATURE
        raise SplitArchiveError if current_offset.zero?

        # Rewind, skipping the data descriptor, then try to read the local header again.
        current_offset += 16
        io.seek(current_offset)
        read_local_header_fields(io)
      end

      unless @header_signature == LOCAL_ENTRY_SIGNATURE
        raise Error, "Zip local header magic not found at location '#{current_offset}'"
      end

      @local_header_offset = current_offset

      set_time(@last_mod_date, @last_mod_time)

      @name = io.read(@name_length)
      if ::Zip.force_entry_names_encoding
        @name.force_encoding(::Zip.force_entry_names_encoding)
      end
      @name.tr!('\\', '/') # Normalise filepath separators after encoding set.

      # We need to do this here because `initialize` has so many side-effects.
      # :-(
      @ftype = name_is_directory? ? :directory : :file

      extra = io.read(@extra_length)
      if extra && extra.bytesize != @extra_length
        raise ::Zip::Error, 'Truncated local zip entry header'
      end

      read_extra_field(extra, local: true)
      parse_zip64_extra(true)
      parse_aes_extra
      @local_header_size = calculate_local_header_size
    end

    def pack_local_entry # :nodoc:
      zip64 = @extra[:zip64]
      [::Zip::LOCAL_ENTRY_SIGNATURE,
       @version_needed_to_extract, # version needed to extract
       @gp_flags, # @gp_flags
       compression_method,
       @time.to_binary_dos_time, # @last_mod_time
       @time.to_binary_dos_date, # @last_mod_date
       @crc,
       zip64 && zip64.compressed_size ? 0xFFFFFFFF : @compressed_size,
       zip64 && zip64.original_size ? 0xFFFFFFFF : (@size || 0),
       name_size,
       @extra ? @extra.local_size : 0].pack('VvvvvvVVVvv')
    end

    def write_local_entry(io, suppress_extra_fields: false, rewrite: false) # :nodoc:
      prep_local_zip64_extra

      # If we are rewriting the local header, then we verify that we haven't changed
      # its size. At this point we have to keep extra fields if they are present.
      if rewrite
        verify_local_header_size!
      elsif suppress_extra_fields
        @extra.suppress_fields!(suppress_extra_fields)
      end

      @local_header_offset = io.tell

      io << pack_local_entry

      io << @name
      io << @extra.to_local_bin if @extra
      @local_header_size = io.tell - @local_header_offset
    end

    def unpack_c_dir_entry(buf) # :nodoc:
      @header_signature,
        @version, # version of encoding software
        @fstype, # filesystem type
        @version_needed_to_extract,
        @gp_flags,
        @compression_method,
        @last_mod_time,
        @last_mod_date,
        @crc,
        @compressed_size,
        @size,
        @name_length,
        @extra_length,
        @comment_length,
        _, # diskNumberStart
        @internal_file_attributes,
        @external_file_attributes,
        @local_header_offset = buf.unpack('VCCvvvvvVVVvvvvvVV')
    end

    def set_ftype_from_c_dir_entry # :nodoc:
      @ftype = case @fstype
               when ::Zip::FSTYPE_UNIX
                 @unix_perms = (@external_file_attributes >> 16) & 0o7777
                 case (@external_file_attributes >> 28)
                 when ::Zip::FILE_TYPE_DIR
                   :directory
                 when ::Zip::FILE_TYPE_FILE
                   :file
                 when ::Zip::FILE_TYPE_SYMLINK
                   :symlink
                 else
                   # Best case guess for whether it is a file or not.
                   # Otherwise this would be set to unknown and that
                   # entry would never be able to be extracted.
                   if name_is_directory?
                     :directory
                   else
                     :file
                   end
                 end
               else
                 if name_is_directory?
                   :directory
                 else
                   :file
                 end
               end
    end

    def check_c_dir_entry_static_header_length(buf) # :nodoc:
      return unless buf.nil? || buf.bytesize != ::Zip::CDIR_ENTRY_STATIC_HEADER_LENGTH

      raise Error, 'Premature end of file. Not enough data for zip cdir entry header'
    end

    def check_c_dir_entry_signature # :nodoc:
      return if @header_signature == ::Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE

      raise Error, "Zip local header magic not found at location '#{local_header_offset}'"
    end

    def check_c_dir_entry_comment_size # :nodoc:
      return if @comment && @comment.bytesize == @comment_length

      raise ::Zip::Error, 'Truncated cdir zip entry header'
    end

    def read_extra_field(buf, local: false) # :nodoc:
      if @extra.kind_of?(::Zip::ExtraField)
        @extra.merge(buf, local: local) if buf
      else
        @extra = ::Zip::ExtraField.new(buf, local: local)
      end
    end

    def read_c_dir_entry(io) # :nodoc:
      @dirty = false # No changes at this point.
      static_sized_fields_buf = io.read(::Zip::CDIR_ENTRY_STATIC_HEADER_LENGTH)
      check_c_dir_entry_static_header_length(static_sized_fields_buf)
      unpack_c_dir_entry(static_sized_fields_buf)
      check_c_dir_entry_signature
      set_time(@last_mod_date, @last_mod_time)

      @name = io.read(@name_length)
      if ::Zip.force_entry_names_encoding
        @name.force_encoding(::Zip.force_entry_names_encoding)
      end
      @name.tr!('\\', '/') # Normalise filepath separators after encoding set.

      read_extra_field(io.read(@extra_length))
      @comment = io.read(@comment_length)
      check_c_dir_entry_comment_size
      set_ftype_from_c_dir_entry
      parse_zip64_extra(false)
      parse_aes_extra
    end

    def file_stat(path) # :nodoc:
      if @follow_symlinks
        ::File.stat(path)
      else
        ::File.lstat(path)
      end
    end

    def get_extra_attributes_from_path(path) # :nodoc:
      stat = file_stat(path)
      @time = DOSTime.from_time(stat.mtime)
      return if ::Zip::RUNNING_ON_WINDOWS

      @unix_uid   = stat.uid
      @unix_gid   = stat.gid
      @unix_perms = stat.mode & 0o7777
    end

    # rubocop:disable Style/GuardClause
    def set_unix_attributes_on_path(dest_path) # :nodoc:
      # Ignore setuid/setgid bits by default. Honour if @restore_ownership.
      unix_perms_mask = (@restore_ownership ? 0o7777 : 0o1777)
      if @restore_permissions && @unix_perms
        ::FileUtils.chmod(@unix_perms & unix_perms_mask, dest_path)
      end
      if @restore_ownership && @unix_uid && @unix_gid && ::Process.egid == 0
        ::FileUtils.chown(@unix_uid, @unix_gid, dest_path)
      end
    end
    # rubocop:enable Style/GuardClause

    def set_extra_attributes_on_path(dest_path) # :nodoc:
      return unless file? || directory?

      case @fstype
      when ::Zip::FSTYPE_UNIX
        set_unix_attributes_on_path(dest_path)
      end

      # Restore the timestamp on a file. This will either have come from the
      # original source file that was copied into the archive, or from the
      # creation date of the archive if there was no original source file.
      ::FileUtils.touch(dest_path, mtime: time) if @restore_times
    end

    def pack_c_dir_entry # :nodoc:
      zip64 = @extra[:zip64]
      [
        @header_signature,
        @version, # version of encoding software
        @fstype, # filesystem type
        @version_needed_to_extract, # @versionNeededToExtract
        @gp_flags, # @gp_flags
        compression_method,
        @time.to_binary_dos_time, # @last_mod_time
        @time.to_binary_dos_date, # @last_mod_date
        @crc,
        zip64 && zip64.compressed_size ? 0xFFFFFFFF : @compressed_size,
        zip64 && zip64.original_size ? 0xFFFFFFFF : (@size || 0),
        name_size,
        @extra ? @extra.c_dir_size : 0,
        comment_size,
        zip64 && zip64.disk_start_number ? 0xFFFF : 0, # disk number start
        @internal_file_attributes, # file type (binary=0, text=1)
        @external_file_attributes, # native filesystem attributes
        zip64 && zip64.relative_header_offset ? 0xFFFFFFFF : @local_header_offset
      ].pack('VCCvvvvvVVVvvvvvVV')
    end

    def write_c_dir_entry(io, suppress_extra_fields: false) # :nodoc:
      prep_cdir_zip64_extra

      case @fstype
      when ::Zip::FSTYPE_UNIX
        ft = case ftype
             when :file
               @unix_perms ||= 0o644
               ::Zip::FILE_TYPE_FILE
             when :directory
               @unix_perms ||= 0o755
               ::Zip::FILE_TYPE_DIR
             when :symlink
               @unix_perms ||= 0o755
               ::Zip::FILE_TYPE_SYMLINK
             end

        unless ft.nil?
          @external_file_attributes = ((ft << 12) | (@unix_perms & 0o7777)) << 16
        end
      end

      @extra.suppress_fields!(suppress_extra_fields) if suppress_extra_fields
      io << pack_c_dir_entry

      io << @name
      io << (@extra ? @extra.to_c_dir_bin : '')
      io << @comment
    end

    def ==(other) # :nodoc:
      return false unless other.class == self.class

      # Compares contents of local entry and exposed fields
      %w[compression_method crc compressed_size size name extra filepath time].all? do |k|
        other.__send__(k.to_sym) == __send__(k.to_sym)
      end
    end

    def <=>(other) # :nodoc:
      to_s <=> other.to_s
    end

    # Returns an IO like object for the given ZipEntry.
    # Warning: may behave weird with symlinks.
    def get_input_stream(&block)
      if ftype == :directory
        yield ::Zip::NullInputStream if block
        ::Zip::NullInputStream
      elsif @filepath
        case ftype
        when :file
          ::File.open(@filepath, 'rb', &block)
        when :symlink
          linkpath = ::File.readlink(@filepath)
          stringio = ::StringIO.new(linkpath)
          yield(stringio) if block
          stringio
        else
          raise "unknown @file_type #{ftype}"
        end
      else
        zis = ::Zip::InputStream.new(@zipfile, offset: local_header_offset)
        zis.instance_variable_set(:@complete_entry, self)
        zis.get_next_entry
        if block
          begin
            yield(zis)
          ensure
            zis.close
          end
        else
          zis
        end
      end
    end

    def gather_fileinfo_from_srcpath(src_path) # :nodoc:
      stat   = file_stat(src_path)
      @ftype = case stat.ftype
               when 'file'
                 if name_is_directory?
                   raise ArgumentError,
                         "entry name '#{@name}' indicates a directory entry, but " \
                         "'#{src_path}' is not a directory"
                 end
                 :file
               when 'directory'
                 @name += '/' unless name_is_directory?
                 :directory
               when 'link'
                 if name_is_directory?
                   raise ArgumentError,
                         "entry name '#{@name}' indicates a directory entry, but " \
                         "'#{src_path}' is not a directory"
                 end
                 :symlink
               else
                 raise "unknown file type: #{src_path.inspect} #{stat.inspect}"
               end

      @filepath = src_path
      @size = stat.size
      get_extra_attributes_from_path(@filepath)
    end

    def write_to_zip_output_stream(zip_output_stream) # :nodoc:
      if ftype == :directory
        zip_output_stream.put_next_entry(self)
      elsif @filepath
        zip_output_stream.put_next_entry(self)
        get_input_stream do |is|
          ::Zip::IOExtras.copy_stream(zip_output_stream, is)
        end
      else
        zip_output_stream.copy_raw_entry(self)
      end
    end

    def parent_as_string # :nodoc:
      entry_name  = name.chomp('/')
      slash_index = entry_name.rindex('/')
      slash_index ? entry_name.slice(0, slash_index + 1) : nil
    end

    def get_raw_input_stream(&block) # :nodoc:
      if @zipfile.respond_to?(:seek) && @zipfile.respond_to?(:read)
        yield @zipfile
      else
        ::File.open(@zipfile, 'rb', &block)
      end
    end

    def clean_up # :nodoc:
      @dirty = false # Any changes are written at this point.
    end

    private

    def read_local_header_fields(io) # :nodoc:
      static_sized_fields_buf = io.read(::Zip::LOCAL_ENTRY_STATIC_HEADER_LENGTH) || ''

      unless static_sized_fields_buf.bytesize == ::Zip::LOCAL_ENTRY_STATIC_HEADER_LENGTH
        raise Error, 'Premature end of file. Not enough data for zip entry local header'
      end

      unpack_local_entry(static_sized_fields_buf)
    end

    def set_time(binary_dos_date, binary_dos_time)
      @time = ::Zip::DOSTime.parse_binary_dos_format(binary_dos_date, binary_dos_time)
    rescue ArgumentError
      warn 'WARNING: invalid date/time in zip entry.' if ::Zip.warn_invalid_date
    end

    def create_file(dest_path, _continue_on_exists_proc = proc { Zip.continue_on_exists_proc })
      if ::File.exist?(dest_path) && !yield(self, dest_path)
        raise ::Zip::DestinationExistsError, dest_path
      end

      ::File.open(dest_path, 'wb') do |os|
        get_input_stream do |is|
          bytes_written = 0
          warned = false
          buf = +''
          while (buf = is.sysread(::Zip::Decompressor::CHUNK_SIZE, buf))
            os << buf
            bytes_written += buf.bytesize
            next unless bytes_written > size && !warned

            error = ::Zip::EntrySizeError.new(self)
            raise error if ::Zip.validate_entry_sizes

            warn "WARNING: #{error.message}"
            warned = true
          end
        end
      end

      set_extra_attributes_on_path(dest_path)
    end

    def create_directory(dest_path)
      return if ::File.directory?(dest_path)

      if ::File.exist?(dest_path)
        raise ::Zip::DestinationExistsError, dest_path unless block_given? && yield(self, dest_path)

        ::FileUtils.rm_f dest_path
      end

      ::FileUtils.mkdir_p(dest_path)
      set_extra_attributes_on_path(dest_path)
    end

    # BUG: create_symlink() does not use &block
    def create_symlink(dest_path)
      # TODO: Symlinks pose security challenges. Symlink support temporarily
      # removed in view of https://github.com/rubyzip/rubyzip/issues/369 .
      warn "WARNING: skipped symlink '#{dest_path}'."
    end

    # apply missing data from the zip64 extra information field, if present
    # (required when file sizes exceed 2**32, but can be used for all files)
    def parse_zip64_extra(for_local_header) # :nodoc:
      return unless zip64?

      if for_local_header
        @size, @compressed_size = @extra[:zip64].parse(@size, @compressed_size)
      else
        @size, @compressed_size, @local_header_offset = @extra[:zip64].parse(
          @size, @compressed_size, @local_header_offset
        )
      end
    end

    def parse_aes_extra # :nodoc:
      return unless aes?

      if @extra[:aes].vendor_id != 'AE'
        raise Error, "Unsupported encryption method #{@extra[:aes].vendor_id}"
      end

      unless ::Zip::AESEncryption::VERSIONS.include? @extra[:aes].vendor_version
        raise Error, "Unsupported encryption style #{@extra[:aes].vendor_version}"
      end

      @compression_method = @extra[:aes].compression_method if ftype != :directory
    end

    # For DEFLATED compression *only*: set the general purpose flags 1 and 2 to
    # indicate compression level. This seems to be mainly cosmetic but they are
    # generally set by other tools - including in docx files. It is these flags
    # that are used by commandline tools (and elsewhere) to give an indication
    # of how compressed a file is. See the PKWARE APPNOTE for more information:
    # https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
    #
    # It's safe to simply OR these flags here as compression_level is read only.
    def set_compression_level_flags
      return unless compression_method == DEFLATED

      case @compression_level
      when 1
        @gp_flags |= COMPRESSION_LEVEL_SUPERFAST_GPFLAG
      when 2
        @gp_flags |= COMPRESSION_LEVEL_FAST_GPFLAG
      when 8, 9
        @gp_flags |= COMPRESSION_LEVEL_MAX_GPFLAG
      end
    end

    # rubocop:disable Style/GuardClause
    def prep_local_zip64_extra
      return unless ::Zip.write_zip64_support
      return if (!zip64? && @size && @size < 0xFFFFFFFF) || !file?

      # Might not know size here, so need ZIP64 just in case.
      # If we already have a ZIP64 extra (placeholder) then we must fill it in.
      if zip64? || @size.nil? || @size >= 0xFFFFFFFF || @compressed_size >= 0xFFFFFFFF
        @version_needed_to_extract = VERSION_NEEDED_TO_EXTRACT_ZIP64
        zip64 = @extra[:zip64] || @extra.create(:zip64)

        # Local header always includes size and compressed size.
        zip64.original_size = @size || 0
        zip64.compressed_size = @compressed_size
      end
    end

    def prep_cdir_zip64_extra
      return unless ::Zip.write_zip64_support

      if (@size && @size >= 0xFFFFFFFF) || @compressed_size >= 0xFFFFFFFF ||
         @local_header_offset >= 0xFFFFFFFF
        @version_needed_to_extract = VERSION_NEEDED_TO_EXTRACT_ZIP64
        zip64 = @extra[:zip64] || @extra.create(:zip64)

        # Central directory entry entries include whichever fields are necessary.
        zip64.original_size = @size if @size && @size >= 0xFFFFFFFF
        zip64.compressed_size = @compressed_size if @compressed_size >= 0xFFFFFFFF
        zip64.relative_header_offset = @local_header_offset if @local_header_offset >= 0xFFFFFFFF
      end
    end
    # rubocop:enable Style/GuardClause
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
