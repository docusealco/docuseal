# frozen_string_literal: true

module RQRCode
  module Export
    module ANSI
      #
      # Returns a string of the QR code as
      # characters writen with ANSI background set.
      #
      # Options:
      # light: Foreground ("\033[47m")
      # dark: Background ANSI code. ("\033[40m")
      # fill_character: The written character. ('  ')
      # quiet_zone_size: (4)
      #
      def as_ansi(options = {})
        options = {
          light: "\033[47m",
          dark: "\033[40m",
          fill_character: "  ",
          quiet_zone_size: 4
        }.merge(options)

        normal = "\033[m\n"
        light = options.fetch(:light)
        dark = options.fetch(:dark)
        fill_character = options.fetch(:fill_character)
        quiet_zone_size = options.fetch(:quiet_zone_size)
        output = []

        @qrcode.modules.each_index do |c|
          # start row with quiet zone
          row = light + fill_character * quiet_zone_size
          previous_dark = false

          @qrcode.modules.each_index do |r|
            if @qrcode.checked?(c, r)
              if previous_dark != true
                row << dark
                previous_dark = true
              end
            elsif previous_dark != false
              # light
              row << light
              previous_dark = false
            end

            row << fill_character
          end

          # add quiet zone
          if previous_dark != false
            row << light
          end
          row << fill_character * quiet_zone_size

          # always end with reset and newline
          row << normal

          output << row
        end

        # count the row width so we can add quiet zone rows
        width = output.first.scan(fill_character).length

        quiet_row = light + fill_character * width + normal
        quiet_rows = quiet_row * quiet_zone_size

        quiet_rows + output.join + quiet_rows
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::ANSI
