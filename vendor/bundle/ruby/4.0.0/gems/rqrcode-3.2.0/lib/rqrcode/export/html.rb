# frozen_string_literal: true

module RQRCode
  module Export
    module HTML
      TABLE_OPEN = "<table>"
      TABLE_CLOSE = "</table>"
      TR_OPEN = "<tr>"
      TR_CLOSE = "</tr>"
      TD_BLACK = '<td class="black"></td>'
      TD_WHITE = '<td class="white"></td>'

      def as_html
        qr = @qrcode
        module_count = qr.module_count

        estimated_size = (module_count * module_count * 26) + (module_count * 9) + 15
        result = String.new(capacity: estimated_size)

        result << TABLE_OPEN
        module_count.times do |row_index|
          result << TR_OPEN
          module_count.times do |col_index|
            result << (qr.checked?(row_index, col_index) ? TD_BLACK : TD_WHITE)
          end
          result << TR_CLOSE
        end
        result << TABLE_CLOSE

        result
      end
    end
  end
end

RQRCode::QRCode.include RQRCode::Export::HTML
