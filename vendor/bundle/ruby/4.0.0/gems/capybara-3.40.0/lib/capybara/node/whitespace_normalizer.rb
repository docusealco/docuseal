# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # {Capybara::Node::WhitespaceNormalizer} provides methods that
    # help to normalize the spacing of text content inside of
    # {Capybara::Node::Element}s by removing various unicode
    # spacing and directional markings.
    #
    module WhitespaceNormalizer
      # Unicode for NBSP, or &nbsp;
      NON_BREAKING_SPACE = "\u00a0"
      LINE_SEPERATOR = "\u2028"
      PARAGRAPH_SEPERATOR = "\u2029"

      # All spaces except for NBSP
      BREAKING_SPACES = "[[:space:]&&[^#{NON_BREAKING_SPACE}]]".freeze

      # Whitespace we want to substitute with plain spaces
      SQUEEZED_SPACES = " \n\f\t\v#{LINE_SEPERATOR}#{PARAGRAPH_SEPERATOR}".freeze

      # Any whitespace at the front of text
      LEADING_SPACES = /\A#{BREAKING_SPACES}+/

      # Any whitespace at the end of text
      TRAILING_SPACES = /#{BREAKING_SPACES}+\z/

      # "Invisible" space character
      ZERO_WIDTH_SPACE = "\u200b"

      # Signifies text is read left to right
      LEFT_TO_RIGHT_MARK = "\u200e"

      # Signifies text is read right to left
      RIGHT_TO_LEFT_MARK = "\u200f"

      # Characters we want to truncate from text
      REMOVED_CHARACTERS = [ZERO_WIDTH_SPACE, LEFT_TO_RIGHT_MARK, RIGHT_TO_LEFT_MARK].join

      # Matches multiple empty lines
      EMPTY_LINES = /[\ \n]*\n[\ \n]*/

      ##
      #
      # Normalizes the spacing of a node's text to be similar to
      # what matchers might expect.
      #
      # @param text [String]
      # @return [String]
      #
      def normalize_spacing(text)
        text
          .delete(REMOVED_CHARACTERS)
          .tr(SQUEEZED_SPACES, ' ')
          .squeeze(' ')
          .sub(LEADING_SPACES, '')
          .sub(TRAILING_SPACES, '')
          .tr(NON_BREAKING_SPACE, ' ')
      end

      ##
      #
      # Variant on {Capybara::Node::Normalizer#normalize_spacing} that
      # targets the whitespace of visible elements only.
      #
      # @param text [String]
      # @return [String]
      #
      def normalize_visible_spacing(text)
        text
          .squeeze(' ')
          .gsub(EMPTY_LINES, "\n")
          .sub(LEADING_SPACES, '')
          .sub(TRAILING_SPACES, '')
          .tr(NON_BREAKING_SPACE, ' ')
      end
    end
  end
end
