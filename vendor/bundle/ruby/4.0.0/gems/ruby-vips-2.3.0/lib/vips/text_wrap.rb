module Vips
  # Sets the word wrapping style for {Image#text} when used with a
  # maximum width.
  #
  # *   `:char` wrap at character boundaries
  # *   `:word_char` wrap at word boundaries, but fall back to character boundaries if there is not enough space for a full word
  # *   `:none` no wrapping

  class TextWrap < Symbol
  end
end
