# frozen_string_literal: true
module Haml
  module Helpers
    def self.preserve(input)
      s = input.to_s.chomp("\n")
      s.gsub!(/\n/, '&#x000A;')
      s.delete!("\r")
      s
    end

    def preserve(input)
      Helpers.preserve(input)
    end
  end
end
