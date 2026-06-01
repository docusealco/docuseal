# frozen_string_literal: true
require 'haml/engine'
require 'haml/error'
require 'haml/version'
require 'haml/template'

if File.basename($0) != 'haml'
  begin
    require 'rails'
    require 'haml/railtie'
  rescue LoadError
  end
end
