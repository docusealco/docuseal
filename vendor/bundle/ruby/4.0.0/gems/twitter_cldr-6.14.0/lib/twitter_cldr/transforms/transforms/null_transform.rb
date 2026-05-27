# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class NullTransform < TransformRule
        class << self
          def accepts?(forward_form, backward_form)
            valid_form?(forward_form) || valid_form?(backward_form)
          end

          private

          def valid_form?(form)
            form && (form.null? || form.transform.downcase == 'null')
          end
        end

        def apply_to(cursor)
          puts 'NULL' if $debug
          cursor.reset_position
        end

        def null?
          true
        end
      end

    end
  end
end
