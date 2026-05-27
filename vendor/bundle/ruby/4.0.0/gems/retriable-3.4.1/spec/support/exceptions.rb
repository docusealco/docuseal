# frozen_string_literal: true

class NonStandardError < Exception; end
class SecondNonStandardError < NonStandardError; end
class DifferentError < Exception; end
