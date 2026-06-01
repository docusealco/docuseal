module CldrPlurals
  module RubyRuntime

    class StrNum
      def self.from_string(str)
        sign, int, frac, exp = str.scan(/([+-])?(\d+)\.?(\d+)?[eEcC]?(-?\d+)?/).flatten
        new(sign || '', int, frac || '', exp.to_i)
      end

      attr_reader :sign, :int, :frac, :exp

      def initialize(sign, int, frac, exp)
        @sign = sign
        @int = int
        @frac = frac
        @exp = exp
      end

      def int_val
        int.to_i
      end

      def frac_val
        # remove leading zeroes
        frac.sub(/\A0*/, '')
      end

      def apply_exp
        new_int, new_frac = if exp > 0
          shift_right(exp)
        else
          shift_left(exp.abs)
        end

        self.class.new(sign, new_int || '', new_frac || '', 0)
      end

      def abs
        self.class.new('', int, frac, exp)
      end

      def to_s
        ''.tap do |result|
          result << "#{sign}#{int}"
          result << ".#{frac}" unless frac.empty?
          result << "e#{exp}" if exp != 0
        end
      end

      def strip
        self.class.new(sign, int, frac.sub(/0+\z/, ''), exp)
      end

      def to_val
        str = to_s

        if str.include?('.')
          str.to_f
        else
          str.to_i * (10 ** exp)
        end
      end

      private

      def shift_right(n)
        return [int, frac] if exp == 0

        new_int = "#{int}#{frac[0...n]}"

        if n - frac.length > 0
          new_int << '0' * (n - frac.length)
        end

        new_frac = frac[n..-1]
        new_frac = (!new_frac || new_frac.empty?) && !frac.empty? ? '0' : new_frac

        [new_int, new_frac]
      end

      def shift_left(n)
        return [int, frac] if exp == 0

        new_frac = ''

        if n - int.length > 0
          new_frac << '0' * (n - int.length)
        end

        new_frac << int[0...n]
        new_frac << frac
        new_int = int[n..-1]
        new_int = !new_int || new_int.empty? ? '0' : new_int

        [new_int, new_frac]
      end
    end

  end
end
