module Vips
  # How accurate an operation should be.
  #
  # *   `:integer` int everywhere
  # *   `:float` float everywhere
  # *   `:approximate` approximate integer output

  class Precision < Symbol
  end
end
