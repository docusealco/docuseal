# frozen_string_literal: true
module Haml
  class Whitespace < Temple::Filter
    def on_whitespace
      [:static, "\n"]
    end
  end
end
