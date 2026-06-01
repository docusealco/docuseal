# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class CasingTransform < TransformRule
        VALID_FORMS = %w(lower upper title)

        class << self
          def accepts?(forward_form, backward_form)
            valid_form?(forward_form) && valid_form?(backward_form)
          end

          private

          def valid_form?(form)
            !form || form.null? || form.blank? || (
              VALID_FORMS.include?(form.transform.downcase)
            )
          end
        end

        attr_reader :forward_transform, :backward_transform

        def apply_to(cursor)
          if forward_transform
            case forward_transform
              when 'lower'
                apply_lower(cursor)
              when 'upper'
                apply_upper(cursor)
              when 'title'
                apply_title(cursor)
            end

            cursor.reset_position
          end
        end

        private

        def after_initialize
          @forward_transform = normalize_transform(forward_form)
          @backward_transform = normalize_transform(backward_form)
        end

        def normalize_transform(form)
          if form && form.has_transform?
            form.transform.downcase
          end
        end

        def apply_lower(cursor)
          cursor.set_text(caser.downcase(cursor.text))
        end

        def apply_upper(cursor)
          cursor.set_text(caser.upcase(cursor.text))
        end

        def apply_title(cursor)
          cursor.set_text(caser.titlecase(cursor.text))
        end

        def caser
          TwitterCldr::Shared::Caser
        end
      end

    end
  end
end
