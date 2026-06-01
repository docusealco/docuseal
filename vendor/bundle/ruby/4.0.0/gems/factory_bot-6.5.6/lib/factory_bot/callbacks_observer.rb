module FactoryBot
  # @api private
  class CallbacksObserver
    def initialize(callbacks, evaluator)
      @callbacks = callbacks
      @evaluator = evaluator
      @completed = []
    end

    def update(name, result_instance)
      callbacks_by_name(name).each do |callback|
        if !completed?(result_instance, callback)
          callback.run(result_instance, @evaluator)
          record_completion!(result_instance, callback)
        end
      end
    end

    private

    def callbacks_by_name(name)
      @callbacks.select { |callback| callback.name == name }
    end

    def completed?(instance, callback)
      key = completion_key_for(instance, callback)
      @completed.include?(key)
    end

    def record_completion!(instance, callback)
      key = completion_key_for(instance, callback)
      @completed << key
    end

    def completion_key_for(instance, callback)
      "#{instance.object_id}-#{callback.object_id}"
    end
  end
end
