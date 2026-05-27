# frozen_string_literal: true
module Haml
  class Ambles < Temple::Filter
    define_options :preamble, :postamble

    def initialize(*)
      super
      @preamble = options[:preamble]
      @postamble = options[:postamble]
    end

    def call(ast)
      ret = [:multi]
      ret << [:static, @preamble] if @preamble
      ret << ast
      ret << [:static, @postamble] if @postamble
      ret
    end
  end
end
