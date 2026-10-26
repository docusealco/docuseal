# frozen_string_literal: true

module Submitters
  module GenerateFontImage
    WIDTH = 3000
    HEIGHT = 160
    SHEAR = 0.25

    FONTS = {
      'Dancing Script Regular' => '/fonts/DancingScript-Regular.otf',
      'Go Noto Kurrent-Regular Regular' => '/fonts/GoNotoKurrent-Regular.ttf'
    }.freeze

    FONT_ALIASES = {
      'initials' => 'Go Noto Kurrent-Regular Regular',
      'signature' => 'Dancing Script Regular'
    }.freeze

    module_function

    def call(text, font: nil)
      font = FONT_ALIASES[font] || font

      text = ERB::Util.html_escape(text)

      text_image = Vips::Image.text(text, font:, fontfile: FONTS[font],
                                          width: WIDTH, height: HEIGHT, wrap: :none)

      text_image = text_image.affine([1, -SHEAR, 0, 1], background: [0])

      text_image = text_image.crop(*text_image.find_trim(background: [0], threshold: 0))

      text_mask = Vips::Image.black(text_image.width, text_image.height)

      image = text_mask.bandjoin(text_image).copy(interpretation: :b_w)

      [image.write_to_buffer('.png'), image.width, image.height]
    end
  end
end
