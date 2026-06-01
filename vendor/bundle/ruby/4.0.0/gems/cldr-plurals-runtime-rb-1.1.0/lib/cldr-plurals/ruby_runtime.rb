# encoding: UTF-8

require 'cldr-plurals/ruby-runtime/str_num'

module CldrPlurals
  module RubyRuntime
    class << self

      def build_args_for(num_str)
        num = StrNum.from_string(num_str)

        [
          n(num), i(num), f(num),
          t(num), v(num), w(num),
          e(num)
        ]
      end

      # absolute value of the source number (integer and decimals).
      def n(num)
        wrap(num).abs.strip.to_val
      end

      # integer digits of n.
      def i(num)
        wrap(num).apply_exp.int_val
      end

      # visible fractional digits in n, with trailing zeros.
      def f(num)
        wrap(num).apply_exp.frac_val.to_i
      end

      # visible fractional digits in n, without trailing zeros.
      def t(num)
        wrap(num).apply_exp.strip.frac_val.to_i
      end

      # number of visible fraction digits in n, with trailing zeros.
      def v(num)
        wrap(num).apply_exp.frac.length
      end

      # number of visible fraction digits in n, without trailing zeros.
      def w(num)
        wrap(num).apply_exp.strip.frac_val.length
      end

      def e(num)
        wrap(num).exp
      end

      private

      def wrap(str_or_num)
        return str_or_num if str_or_num.is_a?(StrNum)
        StrNum.from_string(str_or_num)
      end

    end
  end
end
