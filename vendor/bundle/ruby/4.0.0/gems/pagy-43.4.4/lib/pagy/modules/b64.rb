# frozen_string_literal: true

class Pagy
  # Cheap Base64 specialized methods to avoid dependencies
  module B64
    module_function

    def encode(bin)
      [bin].pack('m0')
    end

    def decode(str)
      str.unpack1('m0')
    end

    def urlsafe_encode(bin)
      str = encode(bin)
      str.tr!('+/', '-_')
      str.delete!('=')

      str
    end

    def urlsafe_decode(str)
      if !str.end_with?('=') && str.length % 4 != 0
        str = str.ljust((str.length + 3) & ~3, '=')
        str.tr!('-_', '+/')
      else
        str = str.tr('-_', '+/')
      end

      decode(str)
    end
  end
end
