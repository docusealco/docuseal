# frozen_string_literal: true

module RQRCodeCore
  class QRMath
    module_eval {
      exp_table = Array.new(256)
      log_table = Array.new(256)

      8.times do |i|
        exp_table[i] = 1 << i
      end

      (8...256).each do |i|
        exp_table[i] = exp_table[i - 4] \
          ^ exp_table[i - 5] \
          ^ exp_table[i - 6] \
          ^ exp_table[i - 8]
      end

      255.times do |i|
        log_table[exp_table[i]] = i
      end

      const_set(:EXP_TABLE, exp_table).freeze
      const_set(:LOG_TABLE, log_table).freeze
    }

    class << self
      def glog(n)
        raise QRCodeRunTimeError, "glog(#{n})" if n < 1
        LOG_TABLE[n]
      end

      def gexp(n)
        while n < 0
          n += 255
        end

        while n >= 256
          n -= 255
        end

        EXP_TABLE[n]
      end
    end
  end
end
