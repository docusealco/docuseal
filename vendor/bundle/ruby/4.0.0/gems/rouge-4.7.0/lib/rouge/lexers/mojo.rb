# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'python.rb'
    
    class Mojo < Python
      title "Mojo"
      desc "The Mojo programming language (modular.com)"
      tag 'mojo'
      aliases 'mojo'
      filenames '*.mojo', '*.🔥'
      mimetypes 'text/x-mojo', 'application/x-mojo'

      def self.detect?(text)
        return true if text.shebang?(/mojow?(?:[23](?:\.\d+)?)?/)
      end

      def self.keywords
        @keywords ||= super + %w(
          fn self alias out read mut owned ref var
          struct trait raises with in match case
        )
      end

      def self.builtins
        @builtins ||= super + %w(
          __mlir_attr __mlir_type __mlir_op parameter alwaysinline
          register_passable
        )
      end
    end
  end
end
