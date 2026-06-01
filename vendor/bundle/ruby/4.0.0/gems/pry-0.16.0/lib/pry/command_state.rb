# frozen_string_literal: true

class Pry
  # CommandState is a data structure to hold per-command state.
  #
  # Pry commands can store arbitrary state here. This state persists between
  # subsequent command invocations. All state saved here is unique to the
  # command.
  #
  # @since v0.13.0
  # @api private
  class CommandState
    def self.default
      @default ||= new
    end

    def initialize
      @command_state = {}
    end

    def state_for(command_class)
      @command_state[command_class] ||= command_struct(command_class)
    end

    def reset(command_class)
      @command_state[command_class] = command_struct(command_class)
    end

    private

    def command_struct(command_class)
      Struct.new(:command, *command_class.command_options[:state])
        .new(command: command_class)
    end
  end
end
