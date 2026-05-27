# A debouncer that executes immediately without delays or background threads.
# This doesn't debounce at all, but is safe to use in tests.
class Turbo::ImmediateDebouncer # :nodoc:
  def initialize(delay: Turbo::Debouncer::DEFAULT_DELAY)
  end

  def debounce(&block)
    block.call
  end

  def wait
  end

  def complete?
    true
  end
end
