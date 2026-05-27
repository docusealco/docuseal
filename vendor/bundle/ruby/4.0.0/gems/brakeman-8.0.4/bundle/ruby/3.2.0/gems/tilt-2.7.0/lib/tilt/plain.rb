# frozen_string_literal: true

# = Plain
#
# Raw text (no template functionality).

require_relative 'template'

Tilt::PlainTemplate = Tilt::StaticTemplate.subclass{@data}
