# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized

    class LocalizedHash < LocalizedObject
      def to_yaml(options = {})
        TwitterCldr::Utils::YAML.dump(@base_obj, options)
      end

      def formatter_const
        nil
      end
    end

  end
end