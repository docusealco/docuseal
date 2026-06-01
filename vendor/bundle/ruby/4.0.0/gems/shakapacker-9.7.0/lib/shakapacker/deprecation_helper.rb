require "thor"

module Shakapacker
  SHELL = Thor::Shell::Color.new

  def puts_deprecation_message(message)
    SHELL.say "\n#{message}\n", :yellow
  end
end
