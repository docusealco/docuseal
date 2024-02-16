# frozen_string_literal: true

module Submitters
  module GenerateFontImage
    WIDTH = 3000
    HEIGHT = 160

    FONTS = {
      'Dancing Script Regular' => '/fonts/DancingScript-Regular.otf',
      'Go Noto Kurrent-Bold Bold' => '/fonts/GoNotoKurrent-Bold.ttf'
    }.freeze

    FONT_ALIASES = {
      'initials' => 'Go Noto Kurrent-Bold Bold',
      'signature' => 'Dancing Script Regular'
    }.freeze

    module_function

    def call(text, font: nil)
      font = FONT_ALIASES[font] || font

      text_image = Vips::Image.text(text, font:, fontfile: FONTS[font],
                                          width: WIDTH, height: HEIGHT, wrap: :none)

      text_mask = Vips::Image.black(text_image.width, text_image.height)

      text_mask.bandjoin(text_image).copy(interpretation: :b_w).write_to_buffer('.png')
    end
  end
end
