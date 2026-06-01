module Vips
  # How sensitive loaders are to errors, from never stop (very insensitive),
  # to stop on the smallest warning (very sensitive).
  #
  # Each implies the ones before it, so `:error` implies `:truncated`, for
  # example.
  #
  # *   `:none` never stop
  # *   `:truncated` stop on image truncated, nothing else
  # *   `:error` stop on serious error or truncation
  # *   `:warning` stop on anything, even warnings

  class FailOn < Symbol
  end
end
