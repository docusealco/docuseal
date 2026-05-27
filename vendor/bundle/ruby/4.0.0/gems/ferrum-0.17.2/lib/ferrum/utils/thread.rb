# frozen_string_literal: true

module Ferrum
  module Utils
    module Thread
      module_function

      def spawn(abort_on_exception: true)
        ::Thread.new(abort_on_exception) do |whether_abort_on_exception|
          ::Thread.current.abort_on_exception = whether_abort_on_exception
          ::Thread.current.report_on_exception = true if ::Thread.current.respond_to?(:report_on_exception=)

          yield
        end
      end
    end
  end
end
