# frozen_string_literal: true

require_relative 'file_stat'

module Zip
  module FileSystem
    # Instances of this class are normally accessed via the accessor
    # Zip::File::file. An instance of File behaves like ruby's
    # builtin File (class) object, except it works on Zip::File entries.
    #
    # The individual methods are not documented due to their
    # similarity with the methods in File
    class File # :nodoc:all
      attr_writer :dir

      def initialize(mapped_zip)
        @mapped_zip = mapped_zip
      end

      def find_entry(filename)
        unless exists?(filename)
          raise Errno::ENOENT, "No such file or directory - #{filename}"
        end

        @mapped_zip.find_entry(filename)
      end

      def unix_mode_cmp(filename, mode)
        e = find_entry(filename)
        e.fstype == FSTYPE_UNIX && (e.external_file_attributes >> 16).anybits?(mode)
      rescue Errno::ENOENT
        false
      end
      private :unix_mode_cmp

      def exists?(filename)
        expand_path(filename) == '/' || !@mapped_zip.find_entry(filename).nil?
      end
      alias exist? exists?

      # Permissions not implemented, so if the file exists it is accessible
      alias owned? exists?
      alias grpowned? exists?

      def readable?(filename)
        unix_mode_cmp(filename, 0o444)
      end
      alias readable_real? readable?

      def writable?(filename)
        unix_mode_cmp(filename, 0o222)
      end
      alias writable_real? writable?

      def executable?(filename)
        unix_mode_cmp(filename, 0o111)
      end
      alias executable_real? executable?

      def setuid?(filename)
        unix_mode_cmp(filename, 0o4000)
      end

      def setgid?(filename)
        unix_mode_cmp(filename, 0o2000)
      end

      def sticky?(filename)
        unix_mode_cmp(filename, 0o1000)
      end

      def umask(*args)
        ::File.umask(*args)
      end

      def truncate(_filename, _len)
        raise StandardError, 'truncate not supported'
      end

      def directory?(filename)
        entry = @mapped_zip.find_entry(filename)
        expand_path(filename) == '/' || (!entry.nil? && entry.directory?)
      end

      def open(filename, mode = 'r', permissions = 0o644, &block)
        mode = mode.tr('b', '') # ignore b option
        case mode
        when 'r'
          @mapped_zip.get_input_stream(filename, &block)
        when 'w'
          @mapped_zip.get_output_stream(filename, permissions, &block)
        else
          raise StandardError, "openmode '#{mode} not supported" unless mode == 'r'
        end
      end

      def new(filename, mode = 'r')
        self.open(filename, mode)
      end

      def size(filename)
        @mapped_zip.get_entry(filename).size
      end

      # Returns nil for not found and nil for directories.
      # We disable the cop here for compatibility with `::File.size?`.
      def size?(filename)
        entry = @mapped_zip.find_entry(filename)
        entry.nil? || entry.directory? ? nil : entry.size # rubocop:disable Style/ReturnNilInPredicateMethodDefinition
      end

      def chown(owner, group, *filenames)
        filenames.each do |filename|
          e = find_entry(filename)
          e.extra.create(:iunix) unless e.extra.member?(:iunix)
          e.extra[:iunix].uid = owner
          e.extra[:iunix].gid = group
        end
        filenames.size
      end

      def chmod(mode, *filenames)
        filenames.each do |filename|
          e = find_entry(filename)
          e.fstype = FSTYPE_UNIX # Force conversion filesystem type to unix.
          e.unix_perms = mode
          e.external_file_attributes = mode << 16
        end
        filenames.size
      end

      def zero?(filename)
        sz = size(filename)
        sz.nil? || sz == 0
      rescue Errno::ENOENT
        false
      end

      def file?(filename)
        entry = @mapped_zip.find_entry(filename)
        !entry.nil? && entry.file?
      end

      def dirname(filename)
        ::File.dirname(filename)
      end

      def basename(filename)
        ::File.basename(filename)
      end

      def split(filename)
        ::File.split(filename)
      end

      def join(*fragments)
        ::File.join(*fragments)
      end

      def utime(modified_time, *filenames)
        filenames.each do |filename|
          find_entry(filename).time = modified_time
        end
      end

      def mtime(filename)
        @mapped_zip.get_entry(filename).mtime
      end

      def atime(filename)
        @mapped_zip.get_entry(filename).atime
      end

      def ctime(filename)
        @mapped_zip.get_entry(filename).ctime
      end

      def pipe?(_filename)
        false
      end

      def blockdev?(_filename)
        false
      end

      def chardev?(_filename)
        false
      end

      def symlink?(filename)
        @mapped_zip.get_entry(filename).symlink?
      end

      def socket?(_filename)
        false
      end

      def ftype(filename)
        @mapped_zip.get_entry(filename).directory? ? 'directory' : 'file'
      end

      def readlink(_filename)
        raise NotImplementedError, 'The readlink() function is not implemented'
      end

      def symlink(_filename, _symlink_name)
        raise NotImplementedError, 'The symlink() function is not implemented'
      end

      def link(_filename, _symlink_name)
        raise NotImplementedError, 'The link() function is not implemented'
      end

      def pipe
        raise NotImplementedError, 'The pipe() function is not implemented'
      end

      def stat(filename)
        raise Errno::ENOENT, filename unless exists?(filename)

        Stat.new(self, filename)
      end

      alias lstat stat

      def readlines(filename)
        self.open(filename, &:readlines)
      end

      def read(filename)
        @mapped_zip.read(filename)
      end

      def popen(*args, &a_proc)
        ::File.popen(*args, &a_proc)
      end

      def foreach(filename, sep = $INPUT_RECORD_SEPARATOR, &a_proc)
        self.open(filename) { |is| is.each_line(sep, &a_proc) }
      end

      def delete(*args)
        args.each do |filename|
          if directory?(filename)
            raise Errno::EISDIR, "Is a directory - \"#{filename}\""
          end

          @mapped_zip.remove(filename)
        end
      end

      def rename(file_to_rename, new_name)
        @mapped_zip.rename(file_to_rename, new_name) { true }
      end

      alias unlink delete

      def expand_path(path)
        @mapped_zip.expand_path(path)
      end
    end
  end
end
