# frozen_string_literal: true

require "singleton"
require "open3"

module Ferrum
  class Browser
    class Options
      class Base
        include Singleton

        def self.options
          instance
        end

        # @return [String, nil]
        def self.version
          out, = Open3.capture2(instance.detect_path, "--version")
          out.strip
        rescue Errno::ENOENT
          nil
        end

        def to_h
          self.class::DEFAULT_OPTIONS
        end

        def except(*keys)
          to_h.except(*keys)
        end

        def detect_path
          Binary.find(self.class::PLATFORM_PATH[Utils::Platform.platform_name])
        end

        def merge_required(flags, options, user_data_dir)
          raise NotImplementedError
        end

        def merge_default(flags, options)
          raise NotImplementedError
        end
      end
    end
  end
end
