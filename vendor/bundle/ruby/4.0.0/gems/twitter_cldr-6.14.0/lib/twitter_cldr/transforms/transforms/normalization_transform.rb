# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class NormalizationTransform < TransformRule
        class << self
          def accepts?(forward_form, backward_form)
            valid_form?(forward_form) && valid_form?(backward_form)
          end

          private

          def valid_form?(form)
            !form || form.null? || form.blank? || (
              form && TwitterCldr::Normalization::VALID_NORMALIZERS.include?(
                form.transform.downcase.to_sym
              )
            )
          end
        end

        attr_reader :forward_transform, :backward_transform

        def apply_to(cursor)
          if forward_transform
            puts forward_transform if $debug

            cursor.set_text(
              TwitterCldr::Normalization.normalize(
                cursor.text, using: forward_transform
              )
            )

            cursor.reset_position
          end
        end

        private

        def after_initialize
          @forward_transform = symbolize_transform(forward_form)
          @backward_transform = symbolize_transform(backward_form)
        end

        def symbolize_transform(form)
          if form && form.has_transform?
            form.transform.downcase.to_sym
          end
        end
      end

    end
  end
end
