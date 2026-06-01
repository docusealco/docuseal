# frozen_string_literal: true
module Temple
  # Temple base filter
  # @api public
  class Filter
    include Utils
    include Mixins::Dispatcher
    include Mixins::Options
  end
end
