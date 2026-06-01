# frozen_string_literal: true

# = LiveScript
#
# LiveScript template implementation.
#
# LiveScript templates do not support object scopes, locals, or yield.
#
# === See also
#
# * http://livescript.net

require_relative 'template'
require 'livescript'

Tilt::LiveScriptTemplate = Tilt::StaticTemplate.subclass(mime_type: 'application/javascript') do
  LiveScript.compile(@data, @options)
end
