if RUBY_ENGINE == 'jruby'
  JRuby::Util.load_ext("org.jruby.ext.bigdecimal.BigDecimalLibrary")

  class BigDecimal
    def _decimal_shift(i) # :nodoc:
      to_java.move_point_right(i).to_d
    end
  end
else
  require 'bigdecimal.so'
end

class BigDecimal
  module Internal # :nodoc:
    # Default extra precision for intermediate calculations
    # This value is currently the same as BigDecimal.double_fig, but defined separately for future changes.
    EXTRA_PREC = 16

    # Coerce x to BigDecimal with the specified precision.
    # TODO: some methods (example: BigMath.exp) require more precision than specified to coerce.
    def self.coerce_to_bigdecimal(x, prec, method_name) # :nodoc:
      case x
      when BigDecimal
        return x
      when Integer, Float
        return BigDecimal(x, 0)
      when Rational
        return BigDecimal(x, [prec, 2 * BigDecimal.double_fig].max)
      end
      raise ArgumentError, "#{x.inspect} can't be coerced into BigDecimal"
    end

    def self.coerce_validate_prec(prec, method_name, accept_zero: false) # :nodoc:
      unless Integer === prec
        original = prec
        # Emulate Integer.try_convert for ruby < 3.1
        if prec.respond_to?(:to_int)
          prec = prec.to_int
        else
          raise TypeError, "no implicit conversion of #{original.class} into Integer"
        end
        raise TypeError, "can't convert #{original.class} to Integer" unless Integer === prec
      end

      if accept_zero
        raise ArgumentError, "Negative precision for #{method_name}" if prec < 0
      else
        raise ArgumentError, "Zero or negative precision for #{method_name}" if prec <= 0
      end
      prec
    end

    def self.infinity_computation_result # :nodoc:
      if BigDecimal.mode(BigDecimal::EXCEPTION_ALL).anybits?(BigDecimal::EXCEPTION_INFINITY)
        raise FloatDomainError, "Computation results in 'Infinity'"
      end
      BigDecimal::INFINITY
    end

    def self.nan_computation_result # :nodoc:
      if BigDecimal.mode(BigDecimal::EXCEPTION_ALL).anybits?(BigDecimal::EXCEPTION_NaN)
        raise FloatDomainError, "Computation results to 'NaN'"
      end
      BigDecimal::NAN
    end

    # Iteration for Newton's method with increasing precision
    def self.newton_loop(prec, initial_precision: BigDecimal.double_fig / 2, safe_margin: 2) # :nodoc:
      precs = []
      while prec > initial_precision
        precs << prec
        prec = (precs.last + 1) / 2 + safe_margin
      end
      precs.reverse_each do |p|
        yield p
      end
    end

    # Calculates Math.log(x.to_f) considering large or small exponent
    def self.float_log(x) # :nodoc:
      Math.log(x._decimal_shift(-x.exponent).to_f) + x.exponent * Math.log(10)
    end

    # Calculating Taylor series sum using binary splitting method
    # Calculates f(x) = (x/d0)*(1+(x/d1)*(1+(x/d2)*(1+(x/d3)*(1+...))))
    # x.n_significant_digits or ds.size must be small to be performant.
    def self.taylor_sum_binary_splitting(x, ds, prec) # :nodoc:
      fs = ds.map {|d| [0, BigDecimal(d)] }
      # fs = [[a0, a1], [b0, b1], [c0, c1], ...]
      # f(x) = a0/a1+(x/a1)*(1+b0/b1+(x/b1)*(1+c0/c1+(x/c1)*(1+d0/d1+(x/d1)*(1+...))))
      while fs.size > 1
        # Merge two adjacent fractions
        # from: (1 + a0/a1 + x/a1 * (1 + b0/b1 + x/b1 * rest))
        # to:   (1 + (a0*b1+x*(b0+b1))/(a1*b1) + (x*x)/(a1*b1) * rest)
        xn = xn ? xn.mult(xn, prec) : x
        fs = fs.each_slice(2).map do |(a, b)|
          b ||= [0, BigDecimal(1)._decimal_shift([xn.exponent, 0].max + 2)]
          [
            (a[0] * b[1]).add(xn * (b[0] + b[1]), prec),
            a[1].mult(b[1], prec)
          ]
        end
      end
      BigDecimal(fs[0][0]).div(fs[0][1], prec)
    end
  end

  #  call-seq:
  #    self ** other -> bigdecimal
  #
  #  Returns the \BigDecimal value of +self+ raised to power +other+:
  #
  #    b = BigDecimal('3.14')
  #    b ** 2              # => 0.98596e1
  #    b ** 2.0            # => 0.98596e1
  #    b ** Rational(2, 1) # => 0.98596e1
  #
  #  Related: BigDecimal#power.
  #
  def **(y)
    case y
    when BigDecimal, Integer, Float, Rational
      power(y)
    when nil
      raise TypeError, 'wrong argument type NilClass'
    else
      x, y = y.coerce(self)
      x**y
    end
  end

  # call-seq:
  #   power(n)
  #   power(n, prec)
  #
  # Returns the value raised to the power of n.
  #
  # Also available as the operator **.
  #
  def power(y, prec = 0)
    prec = Internal.coerce_validate_prec(prec, :power, accept_zero: true)
    x = self
    y = Internal.coerce_to_bigdecimal(y, prec.nonzero? || n_significant_digits, :power)

    return Internal.nan_computation_result if x.nan? || y.nan?
    return BigDecimal(1) if y.zero?

    if y.infinite?
      if x < 0
        return BigDecimal(0) if x < -1 && y.negative?
        return BigDecimal(0) if x > -1 && y.positive?
        raise Math::DomainError, 'Result undefined for negative base raised to infinite power'
      elsif x < 1
        return y.positive? ? BigDecimal(0) : BigDecimal::Internal.infinity_computation_result
      elsif x == 1
        return BigDecimal(1)
      else
        return y.positive? ? BigDecimal::Internal.infinity_computation_result : BigDecimal(0)
      end
    end

    if x.infinite? && y < 0
      # Computation result will be +0 or -0. Avoid overflow.
      neg = x < 0 && y.frac.zero? && y % 2 == 1
      return neg ? -BigDecimal(0) : BigDecimal(0)
    end

    if x.zero?
      return BigDecimal(1) if y.zero?
      return BigDecimal(0) if y > 0
      if y.frac.zero? && y % 2 == 1 && x.sign == -1
        return -BigDecimal::Internal.infinity_computation_result
      else
        return BigDecimal::Internal.infinity_computation_result
      end
    elsif x < 0
      if y.frac.zero?
        if y % 2 == 0
          return (-x).power(y, prec)
        else
          return -(-x).power(y, prec)
        end
      else
        raise Math::DomainError, 'Computation results in complex number'
      end
    elsif x == 1
      return BigDecimal(1)
    end

    limit = BigDecimal.limit
    frac_part = y.frac

    if frac_part.zero? && prec.zero? && limit.zero?
      # Infinite precision calculation for `x ** int` and `x.power(int)`
      int_part = y.fix.to_i
      int_part = -int_part if (neg = int_part < 0)
      ans = BigDecimal(1)
      n = 1
      xn = x
      while true
        ans *= xn if int_part.allbits?(n)
        n <<= 1
        break if n > int_part
        xn *= xn
        # Detect overflow/underflow before consuming infinite memory
        if (xn.exponent.abs - 1) * int_part / n >= 0x7FFFFFFFFFFFFFFF
          return ((xn.exponent > 0) ^ neg ? BigDecimal::Internal.infinity_computation_result : BigDecimal(0)) * (int_part.even? || x > 0 ? 1 : -1)
        end
      end
      return neg ? BigDecimal(1) / ans : ans
    end

    result_prec = prec.nonzero? || [x.n_significant_digits, y.n_significant_digits, BigDecimal.double_fig].max + BigDecimal.double_fig
    result_prec = [result_prec, limit].min if prec.zero? && limit.nonzero?

    prec2 = result_prec + BigDecimal::Internal::EXTRA_PREC

    if y < 0
      inv = x.power(-y, prec2)
      return BigDecimal(0) if inv.infinite?
      return BigDecimal::Internal.infinity_computation_result if inv.zero?
      return BigDecimal(1).div(inv, result_prec)
    end

    if frac_part.zero? && y.exponent < Math.log(result_prec) * 5 + 20
      # Use exponentiation by squaring if y is an integer and not too large
      pow_prec = prec2 + y.exponent
      n = 1
      xn = x
      ans = BigDecimal(1)
      int_part = y.fix.to_i
      while true
        ans = ans.mult(xn, pow_prec) if int_part.allbits?(n)
        n <<= 1
        break if n > int_part
        xn = xn.mult(xn, pow_prec)
      end
      ans.mult(1, result_prec)
    else
      if x > 1 && x.finite?
        # To calculate exp(z, prec), z needs prec+max(z.exponent, 0) precision if z > 0.
        # Estimate (y*log(x)).exponent
        logx_exponent = x < 2 ? (x - 1).exponent : Math.log10(x.exponent).round
        ylogx_exponent = y.exponent + logx_exponent
        prec2 += [ylogx_exponent, 0].max
      end
      BigMath.exp(BigMath.log(x, prec2).mult(y, prec2), result_prec)
    end
  end

  # Returns the square root of the value.
  #
  # Result has at least prec significant digits.
  #
  def sqrt(prec)
    prec = Internal.coerce_validate_prec(prec, :sqrt, accept_zero: true)
    return Internal.infinity_computation_result if infinite? == 1

    raise FloatDomainError, 'sqrt of negative value' if self < 0
    raise FloatDomainError, "sqrt of 'NaN'(Not a Number)" if nan?
    return self if zero?

    if prec == 0
      limit = BigDecimal.limit
      prec = n_significant_digits + BigDecimal.double_fig
      prec = [limit, prec].min if limit.nonzero?
    end

    ex = exponent / 2
    x = _decimal_shift(-2 * ex)
    y = BigDecimal(Math.sqrt(x.to_f), 0)
    Internal.newton_loop(prec + BigDecimal::Internal::EXTRA_PREC) do |p|
      y = y.add(x.div(y, p), p).div(2, p)
    end
    y._decimal_shift(ex).mult(1, prec)
  end
end

# Core BigMath methods for BigDecimal (log, exp) are defined here.
# Other methods (sin, cos, atan) are defined in 'bigdecimal/math.rb'.
module BigMath
  module_function

  # call-seq:
  #   BigMath.log(decimal, numeric)    -> BigDecimal
  #
  # Computes the natural logarithm of +decimal+ to the specified number of
  # digits of precision, +numeric+.
  #
  # If +decimal+ is zero or negative, raises Math::DomainError.
  #
  # If +decimal+ is positive infinity, returns Infinity.
  #
  # If +decimal+ is NaN, returns NaN.
  #
  def log(x, prec)
    prec = BigDecimal::Internal.coerce_validate_prec(prec, :log)
    raise Math::DomainError, 'Complex argument for BigMath.log' if Complex === x

    x = BigDecimal::Internal.coerce_to_bigdecimal(x, prec, :log)
    return BigDecimal::Internal.nan_computation_result if x.nan?
    raise Math::DomainError, 'Negative argument for log' if x < 0
    return -BigDecimal::Internal.infinity_computation_result if x.zero?
    return BigDecimal::Internal.infinity_computation_result if x.infinite?
    return BigDecimal(0) if x == 1

    prec2 = prec + BigDecimal::Internal::EXTRA_PREC

    # Reduce x to near 1
    if x > 1.01 || x < 0.99
      # log(x) = log(x/exp(logx_approx)) + logx_approx
      logx_approx = BigDecimal(BigDecimal::Internal.float_log(x), 0)
      x = x.div(exp(logx_approx, prec2), prec2)
    else
      logx_approx = BigDecimal(0)
    end

    # Solve exp(y) - x = 0 with Newton's method
    # Repeat: y -= (exp(y) - x) / exp(y)
    y = BigDecimal(BigDecimal::Internal.float_log(x), 0)
    exp_additional_prec = [-(x - 1).exponent, 0].max
    BigDecimal::Internal.newton_loop(prec2) do |p|
      expy = exp(y, p + exp_additional_prec)
      y = y.sub(expy.sub(x, p).div(expy, p), p)
    end
    y.add(logx_approx, prec)
  end

  private_class_method def _exp_binary_splitting(x, prec) # :nodoc:
    return BigDecimal(1) if x.zero?
    # Find k that satisfies x**k / k! < 10**(-prec)
    log10 = Math.log(10)
    logx = BigDecimal::Internal.float_log(x.abs)
    step = (1..).bsearch { |k| Math.lgamma(k + 1)[0] - k * logx > prec * log10 }
    # exp(x)-1 = x*(1+x/2*(1+x/3*(1+x/4*(1+x/5*(1+...)))))
    1 + BigDecimal::Internal.taylor_sum_binary_splitting(x, [*1..step], prec)
  end

  # call-seq:
  #   BigMath.exp(decimal, numeric)    -> BigDecimal
  #
  # Computes the value of e (the base of natural logarithms) raised to the
  # power of +decimal+, to the specified number of digits of precision.
  #
  # If +decimal+ is infinity, returns Infinity.
  #
  # If +decimal+ is NaN, returns NaN.
  #
  def exp(x, prec)
    prec = BigDecimal::Internal.coerce_validate_prec(prec, :exp)
    x = BigDecimal::Internal.coerce_to_bigdecimal(x, prec, :exp)
    return BigDecimal::Internal.nan_computation_result if x.nan?
    return x.positive? ? BigDecimal::Internal.infinity_computation_result : BigDecimal(0) if x.infinite?
    return BigDecimal(1) if x.zero?

    # exp(x * 10**cnt) = exp(x)**(10**cnt)
    cnt = x < -1 || x > 1 ? x.exponent : 0
    prec2 = prec + BigDecimal::Internal::EXTRA_PREC + cnt
    x = x._decimal_shift(-cnt)

    # Decimal form of bit-burst algorithm
    # Calculate exp(x.xxxxxxxxxxxxxxxx) as
    # exp(x.xx) * exp(0.00xx) * exp(0.0000xxxx) * exp(0.00000000xxxxxxxx)
    x = x.mult(1, prec2)
    n = 2
    y = BigDecimal(1)
    BigDecimal.save_limit do
      BigDecimal.limit(0)
      while x != 0 do
        partial_x = x.truncate(n)
        x -= partial_x
        y = y.mult(_exp_binary_splitting(partial_x, prec2), prec2)
        n *= 2
      end
    end

    # calculate exp(x * 10**cnt) from exp(x)
    # exp(x * 10**k) = exp(x * 10**(k - 1)) ** 10
    cnt.times do
      y2 = y.mult(y, prec2)
      y5 = y2.mult(y2, prec2).mult(y, prec2)
      y = y5.mult(y5, prec2)
    end

    y.mult(1, prec)
  end
end
