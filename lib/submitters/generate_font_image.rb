# frozen_string_literal: true

module Submitters
  module GenerateFontImage
    WIDTH = 3000
    HEIGHT = 160

    FONTS = {
      'Dancing Script Regular' => '/fonts/DancingScript-Regular.otf',
      'Great Vibes Regular' => '/fonts/GreatVibes-Regular.ttf',
      'Pacifico Regular' => '/fonts/Pacifico-Regular.ttf',
      'Caveat Regular' => '/fonts/Caveat-Regular.ttf',
      'Homemade Apple Regular' => '/fonts/HomemadeApple-Regular.ttf',
      'Mrs Saint Delafield Regular' => '/fonts/MrsSaintDelafield-Regular.ttf',
      'Shadows Into Light Regular' => '/fonts/ShadowsIntoLight-Regular.ttf',
      'Alex Brush Regular' => '/fonts/AlexBrush-Regular.ttf',
      'Kalam Regular' => '/fonts/Kalam-Regular.ttf',
      'Sacramento Regular' => '/fonts/Sacramento-Regular.ttf',
      'Herr Von Muellerhoff Regular' => '/fonts/HerrVonMuellerhoff-Regular.ttf',
      'Go Noto Kurrent-Bold Bold' => '/fonts/GoNotoKurrent-Bold.ttf'
    }.freeze

    FONT_ALIASES = {
      'initials' => 'Go Noto Kurrent-Bold Bold',
      'signature' => 'Dancing Script Regular',
      'Dancing Script' => 'Dancing Script Regular',
      'Great Vibes' => 'Great Vibes Regular',
      'Pacifico' => 'Pacifico Regular',
      'Caveat' => 'Caveat Regular',
      'Homemade Apple' => 'Homemade Apple Regular',
      'Mrs Saint Delafield' => 'Mrs Saint Delafield Regular',
      'Shadows Into Light' => 'Shadows Into Light Regular',
      'Alex Brush' => 'Alex Brush Regular',
      'Kalam' => 'Kalam Regular',
      'Sacramento' => 'Sacramento Regular',
      'Herr Von Muellerhoff' => 'Herr Von Muellerhoff Regular'
    }.freeze

    module_function

    def call(text, font: nil)
      font = FONT_ALIASES[font] || font

      text = ERB::Util.html_escape(text)

      text_image = Vips::Image.text(text, font:, fontfile: FONTS[font],
                                          width: WIDTH, height: HEIGHT, wrap: :none)

      text_mask = Vips::Image.black(text_image.width, text_image.height)

      text_mask.bandjoin(text_image).copy(interpretation: :b_w).write_to_buffer('.png')
    end
  end
end
