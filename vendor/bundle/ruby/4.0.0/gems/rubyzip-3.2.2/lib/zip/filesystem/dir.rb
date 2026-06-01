# frozen_string_literal: true

module Zip
  module FileSystem
    class Dir # :nodoc:all
      def initialize(mapped_zip)
        @mapped_zip = mapped_zip
      end

      attr_writer :file

      def new(directory_name)
        DirectoryIterator.new(entries(directory_name))
      end

      def open(directory_name)
        dir_iter = new(directory_name)
        if block_given?
          begin
            yield(dir_iter)
            return nil
          ensure
            dir_iter.close
          end
        end
        dir_iter
      end

      def pwd
        @mapped_zip.pwd
      end
      alias getwd pwd

      def chdir(directory_name)
        unless @file.stat(directory_name).directory?
          raise Errno::EINVAL, "Invalid argument - #{directory_name}"
        end

        @mapped_zip.pwd = @file.expand_path(directory_name)
      end

      def entries(directory_name)
        entries = []
        foreach(directory_name) { |e| entries << e }
        entries
      end

      def glob(...)
        @mapped_zip.glob(...)
      end

      def foreach(directory_name)
        unless @file.stat(directory_name).directory?
          raise Errno::ENOTDIR, directory_name
        end

        path = @file.expand_path(directory_name)
        path << '/' unless path.end_with?('/')
        path = Regexp.escape(path)
        subdir_entry_regex = Regexp.new("^#{path}([^/]+)$")
        @mapped_zip.each do |filename|
          match = subdir_entry_regex.match(filename)
          yield(match[1]) unless match.nil?
        end
      end

      def delete(entry_name)
        unless @file.stat(entry_name).directory?
          raise Errno::EINVAL, "Invalid argument - #{entry_name}"
        end

        @mapped_zip.remove(entry_name)
      end
      alias rmdir delete
      alias unlink delete

      def mkdir(entry_name, permissions = 0o755)
        @mapped_zip.mkdir(entry_name, permissions)
      end

      def chroot(*_args)
        raise NotImplementedError, 'The chroot() function is not implemented'
      end
    end
  end
end
