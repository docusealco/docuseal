# frozen_string_literal: true

# = Babel
#
#

require_relative 'template'
require 'babel/transpiler'

Tilt::BabelTemplate = Tilt::StaticTemplate.subclass(mime_type: 'application/javascript') do
  @options[:filename] ||= @file
  Babel::Transpiler.transform(@data)["code"]
end
