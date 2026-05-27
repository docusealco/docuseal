# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    # author Chris Kempson
    # base16 default dark
    # https://github.com/chriskempson/base16-default-schemes
    class Base16 < CSSTheme
      name 'base16'

      palette base00: "#181818"
      palette base01: "#282828"
      palette base02: "#383838"
      palette base03: "#585858"
      palette base04: "#b8b8b8"
      palette base05: "#d8d8d8"
      palette base06: "#e8e8e8"
      palette base07: "#f8f8f8"
      palette base08: "#ab4642"
      palette base09: "#dc9656"
      palette base0A: "#f7ca88"
      palette base0B: "#a1b56c"
      palette base0C: "#86c1b9"
      palette base0D: "#7cafc2"
      palette base0E: "#ba8baf"
      palette base0F: "#a16946"

      extend HasModes

      def self.light!
        mode :dark # indicate that there is a dark variant
        mode! :light
      end

      def self.dark!
        mode :light # indicate that there is a light variant
        mode! :dark
      end

      def self.make_dark!
        style Text, :fg => :base05, :bg => :base00
      end

      def self.make_light!
        style Text, :fg => :base02
      end

      light!

      style Error, :fg => :base00, :bg => :base08
      style Comment, :fg => :base03

      style Comment::Preproc,
            Name::Tag, :fg => :base0A

      style Operator,
            Punctuation, :fg => :base05

      style Generic::Inserted, :fg => :base0B
      style Generic::Deleted, :fg => :base08
      style Generic::Heading, :fg => :base0D, :bg => :base00, :bold => true

      style Generic::Emph, :italic => true
      style Generic::EmphStrong, :italic => true, :bold => true
      style Generic::Strong, :bold => true

      style Keyword, :fg => :base0E
      style Keyword::Constant,
            Keyword::Type, :fg => :base09

      style Keyword::Declaration, :fg => :base09

      style Literal::String, :fg => :base0B
      style Literal::String::Affix, :fg => :base0E
      style Literal::String::Regex, :fg => :base0C

      style Literal::String::Interpol,
            Literal::String::Escape, :fg => :base0F

      style Name::Namespace,
            Name::Class,
            Name::Constant, :fg => :base0A

      style Name::Attribute, :fg => :base0D

      style Literal::Number,
            Literal::String::Symbol, :fg => :base0B

      class Solarized < Base16
        name 'base16.solarized'
        light!
        # author "Ethan Schoonover (http://ethanschoonover.com/solarized)"

        palette base00: "#002b36"
        palette base01: "#073642"
        palette base02: "#586e75"
        palette base03: "#657b83"
        palette base04: "#839496"
        palette base05: "#93a1a1"
        palette base06: "#eee8d5"
        palette base07: "#fdf6e3"
        palette base08: "#dc322f"
        palette base09: "#cb4b16"
        palette base0A: "#b58900"
        palette base0B: "#859900"
        palette base0C: "#2aa198"
        palette base0D: "#268bd2"
        palette base0E: "#6c71c4"
        palette base0F: "#d33682"
      end

      class Monokai < Base16
        name 'base16.monokai'
        dark!

        # author "Wimer Hazenberg (http://www.monokai.nl)"
        palette base00: "#272822"
        palette base01: "#383830"
        palette base02: "#49483e"
        palette base03: "#75715e"
        palette base04: "#a59f85"
        palette base05: "#f8f8f2"
        palette base06: "#f5f4f1"
        palette base07: "#f9f8f5"
        palette base08: "#f92672"
        palette base09: "#fd971f"
        palette base0A: "#f4bf75"
        palette base0B: "#a6e22e"
        palette base0C: "#a1efe4"
        palette base0D: "#66d9ef"
        palette base0E: "#ae81ff"
        palette base0F: "#cc6633"
      end
    end
  end
end
