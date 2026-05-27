# A decorated debouncer that will store instances in the current thread clearing them
# after the debounced logic triggers.
class Turbo::ThreadDebouncer
  delegate :wait, to: :debouncer

  class_attribute :debouncer_class, default: Turbo::Debouncer

  def self.for(key, delay: Turbo::Debouncer::DEFAULT_DELAY)
    Thread.current[key] ||= new(key, Thread.current, delay: delay)
  end

  private_class_method :new

  def initialize(key, thread, delay: )
    @key = key
    @debouncer = debouncer_class.new(delay: delay)
    @thread = thread
  end

  def debounce
    debouncer.debounce do
      yield.tap do
        thread[key] = nil
      end
    end
  end

  private
    attr_reader :key, :debouncer, :thread
end
