# frozen_string_literal: true
module Haml
  class Identity
    def initialize
      @unique_id = 0
    end

    def generate
      @unique_id += 1
      "_haml_compiler#{@unique_id}"
    end
  end
end
