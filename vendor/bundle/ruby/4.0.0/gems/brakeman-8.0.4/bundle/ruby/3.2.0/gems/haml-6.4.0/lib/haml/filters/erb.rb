# frozen_string_literal: true
module Haml
  class Filters
    class Erb < TiltBase
      def compile(node)
        precompiled_with_tilt(node, 'erb')
      end
    end
  end
end
