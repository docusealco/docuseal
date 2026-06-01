# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class NamedTransform < TransformRule
        Transformer = TwitterCldr::Transforms::Transformer

        class << self
          def accepts?(forward_form, backward_form)
            exists?(forward_form) && exists?(backward_form)
          end

          private

          def exists?(form)
            !form || form.null? || form.blank? || Transformer.exists?(form.transform)
          end
        end

        def apply_to(cursor)
          if forward_form
            forward_form.apply_to(cursor)
          end
        end

        private

        def after_initialize
          if forward_form
            @backward_form ||= TransformPair.new(
              nil, TransformId.parse(forward_form.transform).reverse.to_s
            )
          end
        end
      end
    end
  end
end
