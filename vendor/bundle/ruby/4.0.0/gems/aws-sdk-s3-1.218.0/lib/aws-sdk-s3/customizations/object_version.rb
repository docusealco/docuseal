# frozen_string_literal: true

module Aws
  module S3
    class ObjectVersion
      class Collection < Aws::Resources::Collection
        alias_method :delete, :batch_delete!
        extend Aws::Deprecations
        deprecated :delete, use: :batch_delete!
      end
    end
  end
end
