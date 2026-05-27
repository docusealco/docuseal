# frozen_string_literal: true

module Zip
  module FileSystem
    class File # :nodoc:all
      class Stat # :nodoc:all
        class << self
          def delegate_to_fs_file(*methods)
            methods.each do |method|
              class_exec do
                define_method(method) do
                  @zip_fs_file.__send__(method, @entry_name)
                end
              end
            end
          end
        end

        def initialize(zip_fs_file, entry_name)
          @zip_fs_file = zip_fs_file
          @entry_name = entry_name
        end

        def kind_of?(type)
          super || type == ::File::Stat
        end

        delegate_to_fs_file :file?, :directory?, :pipe?, :chardev?, :symlink?,
                            :socket?, :blockdev?, :readable?, :readable_real?, :writable?, :ctime,
                            :writable_real?, :executable?, :executable_real?, :sticky?, :owned?,
                            :grpowned?, :setuid?, :setgid?, :zero?, :size, :size?, :mtime, :atime

        def blocks
          nil
        end

        def gid
          e = find_entry
          if e.extra.member? :iunix
            e.extra[:iunix].gid || 0
          else
            0
          end
        end

        def uid
          e = find_entry
          if e.extra.member? :iunix
            e.extra[:iunix].uid || 0
          else
            0
          end
        end

        def ino
          0
        end

        def dev
          0
        end

        def rdev
          0
        end

        def rdev_major
          0
        end

        def rdev_minor
          0
        end

        def ftype
          if file?
            'file'
          elsif directory?
            'directory'
          else
            raise StandardError, 'Unknown file type'
          end
        end

        def nlink
          1
        end

        def blksize
          nil
        end

        def mode
          e = find_entry
          if e.fstype == FSTYPE_UNIX
            e.external_file_attributes >> 16
          else
            0o100_666 # Equivalent to -rw-rw-rw-.
          end
        end

        private

        def find_entry
          @zip_fs_file.find_entry(@entry_name)
        end
      end
    end
  end
end
