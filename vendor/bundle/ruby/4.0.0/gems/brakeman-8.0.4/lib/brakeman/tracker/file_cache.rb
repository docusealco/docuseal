module Brakeman
  class FileCache
    def initialize(file_list = nil)
      @file_list = file_list || {
        controller: {},
        initializer: {},
        lib: {},
        model: {},
        template: {},
      }
    end

    def controllers
      @file_list[:controller]
    end

    def initializers
      @file_list[:initializer]
    end

    def libs
      @file_list[:lib]
    end

    def models
      @file_list[:model]
    end

    def templates
      @file_list[:template]
    end

    def add_file(astfile, type)
      raise "Unknown type: #{type}" unless valid_type? type
      @file_list[type][astfile.path] = astfile
    end

    def valid_type?(type)
      @file_list.key? type
    end

    def cached? path
      @file_list.any? do |name, list|
        list[path]
      end
    end

    def delete path
      @file_list.each do |name, list|
        list.delete path
      end
    end

    def diff other
      @file_list.each do |name, list|
        other_list = other.send(:"#{name}s")

        if list == other_list
          next
        else
          puts "-- #{name} --"
          puts "Old: #{other_list.keys - list.keys}"
          puts "New: #{list.keys - other_list.keys}"
        end
      end
    end

    def dup
      copy_file_list = @file_list.map do |name, list|
        copy_list = list.map do |path, astfile|
          copy_astfile = astfile.dup
          copy_astfile.ast = copy_astfile.ast.deep_clone

          [path, copy_astfile]
        end.to_h

        [name, copy_list]
      end.to_h

      FileCache.new(copy_file_list)
    end
  end
end
