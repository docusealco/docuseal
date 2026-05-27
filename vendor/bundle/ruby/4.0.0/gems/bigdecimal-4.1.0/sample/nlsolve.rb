#
# nlsolve.rb
# An example for solving nonlinear algebraic equation system.
#

require "bigdecimal"
require_relative "linear"

# Requires gem matrix
require "matrix"

# :stopdoc:

def func((x, y)) # defines functions solved
  [
    x**2 + y**2 - 2,
    (x - 1)**2 + (y + 1)**2 - 3
  ]
end

def jacobian(x, f, delta, prec)
  dim = x.size
  dim.times.map do |i|
    xplus = Array.new(dim) {|j| x[i] + (j == i ? delta : 0) }
    xminus = Array.new(dim) {|j| x[i] - (j == i ? delta : 0) }
    yplus = f.call(xplus)
    yminus = f.call(xminus)
    yplus.zip(yminus).map {|p, m| (p - m).div(2 * delta, prec) }
  end.transpose
end

def nlsolve(initial_x, prec:, max_iteration: 100, &f)
  initial_x = initial_x.map {|v| BigDecimal(v) }
  x = initial_x
  delta = BigDecimal(0.01)
  calc_prec = prec + 10
  max_iteration.times do |iteration|
    # Newton step
    jacobian = jacobian(x, f, delta, calc_prec)
    matrix = Matrix[*jacobian.map {|row| row.map {|v| PrecisionSpecifiedValue.new(v, calc_prec) } }]
    y = f.call(x)
    vector = y.map {|v| PrecisionSpecifiedValue.new(v, calc_prec) }
    dx = matrix.lup.solve(vector).map(&:value)
    x_prev = x
    x = x.zip(dx).map {|xi, di| xi.sub(di, prec) }
    movement = x_prev.zip(x).map {|xn, xi| (xn - xi).abs }.max
    delta = [movement, delta].min.mult(1, 10)
    break if movement.zero? || movement.exponent < -prec
  end
  x
end

initial_value = [1, 1]
ans = nlsolve(initial_value, prec: 100) {|x| func(x) }
diff = func(ans).map {|v| v.mult(1, 10) }
p(ans:)
p(diff:)
