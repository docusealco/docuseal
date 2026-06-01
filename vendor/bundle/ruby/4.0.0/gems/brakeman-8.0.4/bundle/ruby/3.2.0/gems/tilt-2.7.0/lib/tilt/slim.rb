# frozen_string_literal: true

# = Slim (<tt>slim</tt>)
#
# === Embedded locals
#
# In slim templates, the comment format looks like this:
#
#   //# locals: ()
#
# === See also
#
# * https://slim-template.github.io

require_relative 'template'
require 'slim'

Tilt::SlimTemplate = Slim::Template
