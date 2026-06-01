# frozen_string_literal: true

require "chunky_png"

# This class creates PNG files.
module RQRCode
  module Export
    module PNG
      # Render the PNG from the QR Code.
      #
      # Options:
      # fill  - Background ChunkyPNG::Color, defaults to 'white'.
      # color - Foreground ChunkyPNG::Color, defaults to 'black'.
      #
      # When option :file is supplied you can use the following ChunkyPNG constraints
      # color_mode  - The color mode to use. Use one of the ChunkyPNG::COLOR_* constants.
      #               (defaults to 'ChunkyPNG::COLOR_GRAYSCALE')
      # bit_depth   - The bit depth to use. This option is only used for indexed images.
      #               (defaults to 1 bit)
      # interlace   - Whether to use interlacing (true or false).
      #               (defaults to ChunkyPNG default)
      # compression - The compression level for Zlib. This can be a value between 0 and 9, or a
      #               Zlib constant like Zlib::BEST_COMPRESSION
      #               (defaults to ChunkyPNG default)
      #
      # There are two sizing algorithms.
      #
      # - Original that can result in blurry and hard to scan images
      # - Google's Chart API inspired sizing that resizes the module size to fit within the given image size.
      #
      # The Googleis one will be used when no options are given or when the new size option is used.
      #
      # *Google*
      # size            - Total size of PNG in pixels. The module size is calculated so it fits.
      #                   (defaults to 120)
      # border_modules  - Width of white border around in modules.
      #                   (defaults to 4).
      #
      #  -- DONT USE border_modules OPTION UNLESS YOU KNOW ABOUT THE QUIET ZONE NEEDS OF QR CODES --
      #
      # *Original*
      # module_px_size  - Image size, in pixels.
      # border          - Border thickness, in pixels
      #
      # It first creates an image where 1px = 1 module, then resizes.
      # Defaults to 120x120 pixels, customizable by option.
      #
      def as_png(options = {})
        default_img_options = {
          bit_depth: 1,
          border_modules: 4,
          color_mode: ChunkyPNG::COLOR_GRAYSCALE,
          color: "black",
          file: false,
          fill: "white",
          module_px_size: 6,
          resize_exactly_to: false,
          resize_gte_to: false,
          size: 120
        }

        googleis = options.length == 0 || !options[:size].nil?
        options = default_img_options.merge(options) # reverse_merge
        fill = ChunkyPNG::Color(*(options[:fill].is_a?(Array) ? options[:fill] : [options[:fill]]))
        color = ChunkyPNG::Color(*(options[:color].is_a?(Array) ? options[:color] : [options[:color]]))
        output_file = options[:file]
        module_px_size = nil
        border_px = nil
        png = nil

        if googleis
          total_image_size = options[:size]
          border_modules = options[:border_modules]

          module_px_size = (total_image_size.to_f / (@qrcode.module_count + 2 * border_modules).to_f).floor.to_i

          img_size = module_px_size * @qrcode.module_count

          remaining = total_image_size - img_size
          border_px = (remaining / 2.0).floor.to_i

          png = ChunkyPNG::Image.new(total_image_size, total_image_size, fill)
        else
          border = options[:border_modules]
          total_border = border * 2
          module_px_size = if options[:resize_gte_to]
            (options[:resize_gte_to].to_f / (@qrcode.module_count + total_border).to_f).ceil.to_i
          else
            options[:module_px_size]
          end
          border_px = border * module_px_size
          total_border_px = border_px * 2
          resize_to = options[:resize_exactly_to]

          img_size = module_px_size * @qrcode.module_count
          total_img_size = img_size + total_border_px

          png = ChunkyPNG::Image.new(total_img_size, total_img_size, fill)
        end

        @qrcode.modules.each_index do |x|
          @qrcode.modules.each_index do |y|
            if @qrcode.checked?(x, y)
              (0...module_px_size).each do |i|
                (0...module_px_size).each do |j|
                  png[(y * module_px_size) + border_px + j, (x * module_px_size) + border_px + i] = color
                end
              end
            end
          end
        end

        if !googleis && resize_to
          png = png.resize(resize_to, resize_to)
        end

        if output_file
          constraints = {
            color_mode: options[:color_mode],
            bit_depth: options[:bit_depth]
          }
          constraints[:interlace] = options[:interlace] if options.has_key?(:interlace)
          constraints[:compression] = options[:compression] if options.has_key?(:compression)
          png.save(output_file, constraints)
        end

        png
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::PNG
