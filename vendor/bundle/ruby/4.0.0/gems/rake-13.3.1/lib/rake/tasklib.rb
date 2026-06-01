# frozen_string_literal: true
require_relative "../rake"

module Rake

  # Base class for Task Libraries.
  class TaskLib
    include Cloneable
    include Rake::DSL
  end

end
