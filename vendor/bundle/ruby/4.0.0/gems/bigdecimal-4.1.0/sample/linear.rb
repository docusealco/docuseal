#
# linear.rb
#
# Solves linear equation system(A*x = b) by LU decomposition method.
#  where  A is a coefficient matrix,x is an answer vector,b is a constant vector.
#
# USAGE:
#   ruby linear.rb [input file solved]
#

# :stopdoc:
require "bigdecimal"

# Requires gem matrix
require "matrix"

class PrecisionSpecifiedValue
  # NOTE:
  #   Change following PREC if needed.

  attr_reader :value
  def initialize(value, prec)
    @value = BigDecimal(value)
    @prec = prec
  end

  def unwrap(value)
    PrecisionSpecifiedValue === value ? value.value : value
  end

  def coerce(other)
    [self.class.new(unwrap(other), @prec), self]
  end

  def abs
    self.class.new(@value.abs, @prec)
  end

  def >(other)
    @value > unwrap(other)
  end

  def <(other)
    @value < unwrap(other)
  end

  def -(other)
    self.class.new(@value.sub(unwrap(other), @prec), @prec)
  end

  def +(other)
    self.class.new(@value.add(unwrap(other), @prec), @prec)
  end

  def *(other)
    self.class.new(@value.mult(unwrap(other), @prec), @prec)
  end

  def quo(other)
    self.class.new(@value.div(unwrap(other), @prec), @prec)
  end
end

return if __FILE__ != $0

def rd_order(na)
  printf("Number of equations ?") if(na <= 0)
  ARGF.gets().to_i
end

na = ARGV.size

while (n=rd_order(na))>0
  a = []
  b = []
  if na <= 0
     # Read data from console.
     printf("\nEnter coefficient matrix element A[i,j]\n")
     for i in 0...n do
       a << n.times.map do |j|
         printf("A[%d,%d]? ",i,j); s = ARGF.gets
         BigDecimal(s)
       end
       printf("Contatant vector element b[%d] ? ",i)
       b << BigDecimal(ARGF.gets)
     end
  else
    # Read data from specified file.
    printf("Coefficient matrix and constant vector.\n")
    for i in 0...n do
      s = ARGF.gets
      printf("%d) %s",i,s)
      s = s.split
      a << n.times.map {|j| BigDecimal(s[j]) }
      b << BigDecimal(s[n])
    end
  end

  prec = 100
  matrix = Matrix[*a.map {|row| row.map {|v| PrecisionSpecifiedValue.new(v, prec) } }]
  vector = b.map {|v| PrecisionSpecifiedValue.new(v, prec) }
  x = matrix.lup.solve(vector).map(&:value)

  printf("Answer(x[i] & (A*x-b)[i]) follows\n")
  for i in 0...n do
     printf("x[%d]=%s ",i,x[i].to_s)
     diff = a[i].zip(x).sum {|aij, xj| aij*xj }.sub(b[i], 10)
     printf(" & %s\n", diff.to_s)
  end
end
