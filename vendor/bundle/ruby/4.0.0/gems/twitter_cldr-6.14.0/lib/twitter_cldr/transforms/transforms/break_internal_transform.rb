# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class BreakInternalTransform < NullTransform
        class << self
          def accepts?(forward_form, backward_form)
            forward_form && forward_form.transform.downcase == 'any-breakinternal'
          end
        end
      end

    end
  end
end
