#
#--
# cmdparse: advanced command line parser supporting commands
# Copyright (C) 2004-2020 Thomas Leitner
#
# This file is part of cmdparse which is licensed under the MIT.
#++
#

require 'optparse'

OptionParser::Officious.delete('version')
OptionParser::Officious.delete('help')


# Extension for OptionParser objects to allow access to some internals.
class OptionParser #:nodoc:

  # Access the option list stack.
  attr_reader :stack

  # Returns +true+ if at least one local option is defined.
  #
  # The zeroth stack element is not respected when doing the query because it contains either the
  # OptionParser::DefaultList or a CmdParse::MultiList with the global options of the
  # CmdParse::CommandParser.
  def options_defined?
    stack[1..-1].each do |list|
      list.each_option do |switch|
        return true if switch.kind_of?(OptionParser::Switch) && (switch.short || switch.long)
      end
    end
    false
  end

  # Returns +true+ if a banner has been set.
  def banner?
    !@banner.nil?
  end

end


# Namespace module for cmdparse.
#
# See CmdParse::CommandParser and CmdParse::Command for the two important classes.
module CmdParse

  # The version of this cmdparse implemention
  VERSION = '3.0.7'.freeze


  # Base class for all cmdparse errors.
  class ParseError < StandardError

    # Sets the error reason for the subclass.
    def self.reason(reason)
      @reason = reason
    end

    # Returns the error reason or 'CmdParse error' if it has not been set.
    def self.get_reason
      @reason ||= 'CmdParse error'
    end

    # Returns the reason plus the original message.
    def message
      str = super
      self.class.get_reason + (str.empty? ? "" : ": #{str}")
    end

  end

  # This error is thrown when an invalid command is encountered.
  class InvalidCommandError < ParseError
    reason 'Invalid command'
  end

  # This error is thrown when an invalid argument is encountered.
  class InvalidArgumentError < ParseError
    reason 'Invalid argument'
  end

  # This error is thrown when an invalid option is encountered.
  class InvalidOptionError < ParseError
    reason 'Invalid option'
  end

  # This error is thrown when no command was given and no default command was specified.
  class NoCommandGivenError < ParseError
    reason 'No command given'

    def initialize #:nodoc:
      super('')
    end
  end

  # This error is thrown when a command is added to another command which does not support commands.
  class TakesNoCommandError < ParseError
    reason 'This command takes no other commands'
  end

  # This error is thrown when not enough arguments are provided for the command.
  class NotEnoughArgumentsError < ParseError
    reason 'Not enough arguments provided, minimum is'
  end

  # This error is thrown when too many arguments are provided for the command.
  class TooManyArgumentsError < ParseError
    reason 'Too many arguments provided, maximum is'
  end

  # Command Hash - will return partial key matches as well if there is a single non-ambigous
  # matching key
  class CommandHash < Hash #:nodoc:

    def key?(name) #:nodoc:
      !self[name].nil?
    end

    def [](cmd_name) #:nodoc:
      super || begin
        possible = keys.select {|key| key[0, cmd_name.length] == cmd_name }
        fetch(possible[0]) if possible.size == 1
      end
    end

  end

  # Container for multiple OptionParser::List objects.
  #
  # This is needed for providing what's equivalent to stacked OptionParser instances and the global
  # options implementation.
  class MultiList #:nodoc:

    def initialize(list) #:nodoc:
      @list = list
    end

    def summarize(*args, &block) #:nodoc:
      # We don't want summary information of the global options to automatically appear.
    end

    [:accept, :reject, :prepend, :append].each do |mname|
      module_eval <<-EOF
        def #{mname}(*args, &block)
          @list[-1].#{mname}(*args, &block)
        end
      EOF
    end

    [:search, :complete, :each_option, :add_banner, :compsys].each do |mname|
      module_eval <<-EOF
        def #{mname}(*args, &block) #:nodoc:
          @list.reverse_each {|list| list.#{mname}(*args, &block)}
        end
      EOF
    end

    def get_candidates(id, &b)
      @list.reverse_each {|list| list.get_candidates(id, &b)}
    end

  end

  # === Base class for commands
  #
  # This class implements all needed methods so that it can be used by the CommandParser class.
  #
  # Commands can either be created by sub-classing or on the fly when using the #add_command method.
  # The latter allows for a more terse specification of a command while the sub-class approach
  # allows to customize all aspects of a command by overriding methods.
  #
  # Basic example for sub-classing:
  #
  #   class TestCommand < CmdParse::Command
  #     def initialize
  #       super('test', takes_commands: false)
  #       options.on('-m', '--my-opt', 'My option') { 'Do something' }
  #     end
  #   end
  #
  #   parser = CmdParse::CommandParser.new
  #   parser.add_command(TestCommand.new)
  #   parser.parse
  #
  # Basic example for on the fly creation:
  #
  #   parser = CmdParse::CommandParser.new
  #   parser.add_command('test') do |cmd|
  #     takes_commands(false)
  #     options.on('-m', '--my-opt', 'My option') { 'Do something' }
  #   end
  #   parser.parse
  #
  # === Basic Properties
  #
  # The only thing that is mandatory to set for a Command is its #name. If the command does not take
  # any sub-commands, then additionally an #action block needs to be specified or the #execute
  # method overridden.
  #
  # However, there are several other methods that can be used to configure the behavior of a
  # command:
  #
  # #takes_commands:: For specifying whether sub-commands are allowed.
  # #options:: For specifying command specific options.
  # #add_command:: For specifying sub-commands if the command takes them.
  #
  # === Help Related Methods
  #
  # Many of this class' methods are related to providing useful help output. While the most common
  # methods can directly be invoked to set or retrieve information, many other methods compute the
  # needed information dynamically and therefore need to be overridden to customize their return
  # value.
  #
  # #short_desc::
  #     For a short description of the command (getter/setter).
  # #long_desc::
  #     For a detailed description of the command (getter/setter).
  # #argument_desc::
  #     For describing command arguments (setter).
  # #help, #help_banner, #help_short_desc, #help_long_desc, #help_commands, #help_arguments, #help_options::
  #     For outputting the general command help or individual sections of the command help (getter).
  # #usage, #usage_options, #usage_arguments, #usage_commands::
  #     For outputting the usage line or individual parts of it (getter).
  #
  # === Built-in Commands
  #
  # cmdparse ships with two built-in commands:
  # * HelpCommand (for showing help messages) and
  # * VersionCommand (for showing version information).
  class Command

    # The name of the command.
    attr_reader :name

    # Returns the name of the default sub-command or +nil+ if there isn't any.
    attr_reader :default_command

    # Sets or returns the super-command of this command. The super-command is either a Command
    # instance for normal commands or a CommandParser instance for the main command (ie.
    # CommandParser#main_command).
    attr_accessor :super_command

    # Returns the mapping of command name to command for all sub-commands of this command.
    attr_reader :commands

    # A data store (initially an empty Hash) that can be used for storing anything. For example, it
    # can be used to store option values. cmdparse itself doesn't do anything with it.
    attr_accessor :data

    # Initializes the command called +name+.
    #
    # Options:
    #
    # takes_commands:: Specifies whether this command can take sub-commands.
    def initialize(name, takes_commands: true)
      @name = name.freeze
      @options = OptionParser.new
      @commands = CommandHash.new
      @default_command = nil
      @action = nil
      @argument_desc ||= {}
      @data = {}
      takes_commands(takes_commands)
    end

    # Sets whether this command can take sub-command.
    #
    # The argument +val+ needs to be +true+ or +false+.
    def takes_commands(val)
      if !val && !commands.empty?
        raise Error, "Can't change takes_commands to false because there are already sub-commands"
      else
        @takes_commands = val
      end
    end
    alias takes_commands= takes_commands

    # Return +true+ if this command can take sub-commands.
    def takes_commands?
      @takes_commands
    end

    # :call-seq:
    #   command.options {|opts| ...}   -> opts
    #   command.options                -> opts
    #
    # Yields the OptionParser instance that is used for parsing the options of this command (if a
    # block is given) and returns it.
    def options #:yields: options
      yield(@options) if block_given?
      @options
    end

    # :call-seq:
    #   command.add_command(other_command, default: false) {|cmd| ... }     -> command
    #   command.add_command('other', default: false) {|cmd| ...}            -> command
    #
    # Adds a command to the command list.
    #
    # The argument +command+ can either be a Command object or a String in which case a new Command
    # object is created. In both cases the Command object is yielded.
    #
    # If the optional argument +default+ is +true+, then the command is used when no other
    # sub-command is specified on the command line.
    #
    # If this command takes no other commands, an error is raised.
    def add_command(command, default: false) # :yields: command_object
      raise TakesNoCommandError.new(name) unless takes_commands?

      command = Command.new(command) if command.kind_of?(String)
      command.super_command = self
      @commands[command.name] = command
      @default_command = command.name if default
      command.fire_hook_after_add
      yield(command) if block_given?

      self
    end

    # :call-seq:
    #   command.command_chain   -> [top_level_command, super_command, ..., command]
    #
    # Returns the command chain, i.e. a list containing this command and all of its super-commands,
    # starting at the top level command.
    def command_chain
      cmds = []
      cmd = self
      while !cmd.nil? && !cmd.super_command.kind_of?(CommandParser)
        cmds.unshift(cmd)
        cmd = cmd.super_command
      end
      cmds
    end

    # Returns the associated CommandParser instance for this command or +nil+ if no command parser
    # is associated.
    def command_parser
      cmd = super_command
      cmd = cmd.super_command while !cmd.nil? && !cmd.kind_of?(CommandParser)
      cmd
    end

    # Sets the given +block+ as the action block that is used on when executing this command.
    #
    # If a sub-class is created for specifying a command, then the #execute method should be
    # overridden instead of setting an action block.
    #
    # See also: #execute
    def action(&block)
      @action = block
    end

    # Invokes the action block with the parsed arguments.
    #
    # This method is called by the CommandParser instance if this command was specified on the
    # command line to be executed.
    #
    # Sub-classes can either specify an action block or directly override this method (the latter is
    # preferred).
    def execute(*args)
      @action.call(*args)
    end

    # Sets the short description of the command if an argument is given. Always returns the short
    # description.
    #
    # The short description is ideally shorter than 60 characters.
    def short_desc(*val)
      @short_desc = val[0] unless val.empty?
      @short_desc
    end
    alias short_desc= short_desc

    # Sets the detailed description of the command if an argument is given. Always returns the
    # detailed description.
    #
    # This may be a single string or an array of strings for multiline description. Each string
    # is ideally shorter than 76 characters.
    def long_desc(*val)
      @long_desc = val.flatten unless val.empty?
      @long_desc
    end
    alias long_desc= long_desc

    # :call-seq:
    #   cmd.argument_desc(name => desc, ...)
    #
    # Sets the descriptions for one or more arguments using name-description pairs.
    #
    # The used names should correspond to the names used in #usage_arguments.
    def argument_desc(hash)
      @argument_desc.update(hash)
    end

    # Returns the number of arguments required for the execution of the command, i.e. the number of
    # arguments the #action block or the #execute method takes.
    #
    # If the returned number is negative, it means that the minimum number of arguments is -n-1.
    #
    # See: Method#arity, Proc#arity
    def arity
      (@action || method(:execute)).arity
    end

    # Returns +true+ if the command can take one or more arguments.
    def takes_arguments?
      arity.abs > 0
    end

    # Returns a string containing the help message for the command.
    def help
      output = ''
      output << help_banner
      output << help_short_desc
      output << help_long_desc
      output << help_commands
      output << help_arguments
      output << help_options('Options (take precedence over global options)', options)
      output << help_options('Global Options', command_parser.global_options)
    end

    # Returns the banner (including the usage line) of the command.
    #
    # The usage line is command specific but the rest is the same for all commands and can be set
    # via +command_parser.main_options.banner+.
    def help_banner
      output = ''
      if command_parser.main_options.banner?
        output << format(command_parser.main_options.banner, indent: 0) << "\n\n"
      end
      output << format(usage, indent: 7) << "\n\n"
    end

    # Returns the usage line for the command.
    #
    # The usage line is automatically generated from the available information. If this is not
    # suitable, override this method to provide a command specific usage line.
    #
    # Typical usage lines looks like the following:
    #
    #   Usage: program [options] command [options] {sub_command1 | sub_command2}
    #   Usage: program [options] command [options] ARG1 [ARG2] [REST...]
    #
    # See: #usage_options, #usage_arguments, #usage_commands
    def usage
      tmp = "Usage: #{command_parser.main_options.program_name}"
      tmp << command_parser.main_command.usage_options
      tmp << command_chain.map {|cmd| " #{cmd.name}#{cmd.usage_options}"}.join('')
      if takes_commands?
        tmp << " #{usage_commands}"
      elsif takes_arguments?
        tmp << " #{usage_arguments}"
      end
      tmp
    end

    # Returns a string describing the options of the command for use in the usage line.
    #
    # If there are any options, the resulting string also includes a leading space!
    #
    # A typical return value would look like the following:
    #
    #   [options]
    #
    # See: #usage
    def usage_options
      (options.options_defined? ? ' [options]' : '')
    end

    # Returns a string describing the arguments for the command for use in the usage line.
    #
    # By default the names of the action block or #execute method arguments are used (done via
    # Ruby's reflection API). If this is not wanted, override this method.
    #
    # A typical return value would look like the following:
    #
    #   ARG1 [ARG2] [REST...]
    #
    # See: #usage, #argument_desc
    def usage_arguments
      (@action || method(:execute)).parameters.map do |type, name|
        case type
        when :req then name.to_s
        when :opt then "[#{name}]"
        when :rest then "[#{name}...]"
        end
      end.join(" ").upcase
    end

    # Returns a string describing the sub-commands of the commands for use in the usage line.
    #
    # Override this method for providing a command specific specialization.
    #
    # A typical return value would look like the following:
    #
    #   {command | other_command | another_command }
    def usage_commands
      (commands.empty? ? '' : "{#{commands.keys.sort.join(" | ")}}")
    end

    # Returns the formatted short description.
    #
    # For the output format see #cond_format_help_section
    def help_short_desc
      cond_format_help_section("Summary", "#{name} - #{short_desc}",
                               condition: short_desc && !short_desc.empty?)
    end

    # Returns the formatted detailed description.
    #
    # For the output format see #cond_format_help_section
    def help_long_desc
      cond_format_help_section("Description", [long_desc].flatten,
                               condition: long_desc && !long_desc.empty?)
    end

    # Returns the formatted sub-commands of this command.
    #
    # For the output format see #cond_format_help_section
    def help_commands
      describe_commands = lambda do |command, level = 0|
        command.commands.sort.collect do |name, cmd|
          str = "  " * level << name << (name == command.default_command ? " (*)" : '')
          str = str.ljust(command_parser.help_desc_indent) << cmd.short_desc.to_s
          str = format(str, width: command_parser.help_line_width - command_parser.help_indent,
                       indent: command_parser.help_desc_indent)
          str << "\n" << (cmd.takes_commands? ? describe_commands.call(cmd, level + 1) : "")
        end.join('')
      end
      cond_format_help_section("Available commands", describe_commands.call(self),
                               condition: takes_commands?, preformatted: true)
    end

    # Returns the formatted arguments of this command.
    #
    # For the output format see #cond_format_help_section
    def help_arguments
      desc = @argument_desc.map {|k, v| k.to_s.ljust(command_parser.help_desc_indent) << v.to_s}
      cond_format_help_section('Arguments', desc, condition: !@argument_desc.empty?)
    end

    # Returns the formatted option descriptions for the given OptionParser instance.
    #
    # The section title needs to be specified with the +title+ argument.
    #
    # For the output format see #cond_format_help_section
    def help_options(title, options)
      summary = ''
      summary_width = command_parser.main_options.summary_width
      options.summarize([], summary_width, summary_width - 1, '') do |line|
        summary << format(line, width: command_parser.help_line_width - command_parser.help_indent,
                          indent: summary_width + 1, indent_first_line: false) << "\n"
      end
      cond_format_help_section(title, summary, condition: !summary.empty?, preformatted: true)
    end

    # This hook method is called when the command (or one of its super-commands) is added to another
    # Command instance that has an associated command parser (#see command_parser).
    #
    # It can be used, for example, to add global options.
    def on_after_add
    end

    # For sorting commands by name.
    def <=>(other)
      name <=> other.name
    end

    protected

    # Conditionally formats a help section.
    #
    # Returns either the formatted help section if the condition is +true+ or an empty string
    # otherwise.
    #
    # The help section starts with a title and the given lines are indented to easily distinguish
    # different sections.
    #
    # A typical help section would look like the following:
    #
    #   Summary:
    #       help - Provide help for individual commands
    #
    # Options:
    #
    # condition:: The formatted help section is only returned if the condition is +true+.
    #
    # indent:: Whether the lines should be indented with CommandParser#help_indent spaces.
    #
    # preformatted:: Assume that the given lines are already correctly formatted and don't try to
    #                reformat them.
    def cond_format_help_section(title, *lines, condition: true, indent: true, preformatted: false)
      if condition
        out = "#{title}:\n"
        lines = lines.flatten.join("\n").split(/\n/)
        if preformatted
          lines.map! {|l| ' ' * command_parser.help_indent << l} if indent
          out << lines.join("\n")
        else
          out << format(lines.join("\n"), indent: (indent ? command_parser.help_indent : 0), indent_first_line: true)
        end
        out << "\n\n"
      else
        ''
      end
    end

    # Returns the text in +content+ formatted so that no line is longer than +width+ characters.
    #
    # Options:
    #
    # width:: The maximum width of a line. If not specified, the CommandParser#help_line_width value
    #         is used.
    #
    # indent:: This option specifies the amount of spaces prepended to each line. If not specified,
    #          the CommandParser#help_indent value is used.
    #
    # indent_first_line:: If this option is +true+, then the first line is also indented.
    def format(content, width: command_parser.help_line_width,
               indent: command_parser.help_indent, indent_first_line: false)
      content = (content || '').dup
      line_length = width - indent
      first_line_pattern = other_lines_pattern = /\A.{1,#{line_length}}\z|\A.{1,#{line_length}}[ \n]/m
      (first_line_pattern = /\A.{1,#{width}}\z|\A.{1,#{width}}[ \n]/m) unless indent_first_line
      pattern = first_line_pattern

      content.split(/\n\n/).map do |paragraph|
        lines = []
        until paragraph.empty?
          unless (str = paragraph.slice!(pattern)) and (str = str.sub(/[ \n]\z/, ''))
            str = paragraph.slice!(0, line_length)
          end
          lines << (lines.empty? && !indent_first_line ? '' : ' ' * indent) + str.tr("\n", ' ')
          pattern = other_lines_pattern
        end
        lines.join("\n")
      end.join("\n\n")
    end

    def fire_hook_after_add #:nodoc:
      return unless command_parser
      @options.stack[0] = MultiList.new(command_parser.global_options.stack)
      on_after_add
      @commands.each_value {|cmd| cmd.fire_hook_after_add}
    end

  end

  # The default help Command.
  #
  # It adds the options "-h" and "--help" to the CommandParser#global_options.
  #
  # When the command is specified on the command line (or one of the above mentioned options), it
  # shows the main help or individual command help.
  class HelpCommand < Command

    def initialize #:nodoc:
      super('help', takes_commands: false)
      short_desc('Provide help for individual commands')
      long_desc('This command prints the program help if no arguments are given. If one or ' \
                'more command names are given as arguments, these arguments are interpreted ' \
                'as a hierachy of commands and the help for the right most command is show.')
      argument_desc(COMMAND: 'The name of a command or sub-command')
    end

    def on_after_add #:nodoc:
      command_parser.global_options.on_tail("-h", "--help", "Show help") do
        execute(*command_parser.current_command.command_chain.map(&:name))
        exit
      end
    end

    def usage_arguments #:nodoc:
      "[COMMAND COMMAND...]"
    end

    def execute(*args) #:nodoc:
      if !args.empty?
        cmd = command_parser.main_command
        arg = args.shift
        while !arg.nil? && cmd.commands.key?(arg)
          cmd = cmd.commands[arg]
          arg = args.shift
        end
        if arg.nil?
          puts cmd.help
        else
          raise InvalidArgumentError, args.unshift(arg).join(' ')
        end
      else
        puts command_parser.main_command.help
      end
    end

  end


  # The default version command.
  #
  # It adds the options "-v" and "--version" to the CommandParser#main_options but this can be
  # changed in ::new.
  #
  # When the command is specified on the command line (or one of the above mentioned options), it
  # shows the version of the program configured by the settings
  #
  # * command_parser.main_options.program_name
  # * command_parser.main_options.version
  class VersionCommand < Command

    # Create a new version command.
    #
    # Options:
    #
    # add_switches:: Specifies whether the '-v' and '--version' switches should be added to the
    #                CommandParser#main_options
    def initialize(add_switches: true)
      super('version', takes_commands: false)
      short_desc("Show the version of the program")
      @add_switches = add_switches
    end

    def on_after_add #:nodoc:
      command_parser.main_options.on_tail("--version", "-v", "Show the version of the program") do
        execute
      end if @add_switches
    end

    def execute #:nodoc:
      version = command_parser.main_options.version
      version = version.join('.') if version.kind_of?(Array)
      puts command_parser.main_options.banner + "\n" if command_parser.main_options.banner?
      puts "#{command_parser.main_options.program_name} #{version}"
      exit
    end

  end


  # === Main Class for Creating a Command Based CLI Program
  #
  # This class can directly be used (or sub-classed, if need be) to create a command based CLI
  # program.
  #
  # The CLI program itself is represented by the #main_command, a Command instance (as are all
  # commands and sub-commands). This main command can either hold sub-commands (the normal use case)
  # which represent the programs top level commands or take no commands in which case it acts
  # similar to a simple OptionParser based program (albeit with better help functionality).
  #
  # Parsing the command line for commands is done by this class, option parsing is delegated to the
  # battle tested OptionParser of the Ruby standard library.
  #
  # === Usage
  #
  # After initialization some optional information is expected to be set on the Command#options of
  # the #main_command:
  #
  # banner:: A banner that appears in the help output before anything else.
  # program_name:: The name of the program. If not set, this value is computed from $0.
  # version:: The version string of the program.
  #
  # In addition to the main command's options instance (which represents the top level options that
  # need to be specified before any command name), there is also a #global_options instance which
  # represents options that can be specified anywhere on the command line.
  #
  # Top level commands can be added to the main command by using the #add_command method.
  #
  # Once everything is set up, the #parse method is used for parsing the command line.
  class CommandParser

    # The top level command representing the program itself.
    attr_reader :main_command

    # The command that is being executed. Only available during parsing of the command line
    # arguments.
    attr_reader :current_command

    # A data store (initially an empty Hash) that can be used for storing anything. For example, it
    # can be used to store global option values. cmdparse itself doesn't do anything with it.
    attr_accessor :data

    # Should exceptions be handled gracefully? I.e. by printing error message and the help screen?
    #
    # See ::new for possible values.
    attr_reader :handle_exceptions

    # The maximum width of the help lines.
    attr_accessor :help_line_width

    # The amount of spaces to indent the content of help sections.
    attr_accessor :help_indent

    # The indentation used for, among other things, command descriptions.
    attr_accessor :help_desc_indent

    # Creates a new CommandParser object.
    #
    # Options:
    #
    # handle_exceptions:: Set to +true+ if exceptions should be handled gracefully by showing the
    #                     error and a help message, or to +false+ if exception should not be handled
    #                     at all. If this options is set to :no_help, the exception is handled but
    #                     no help message is shown.
    #
    # takes_commands:: Specifies whether the main program takes any commands.
    def initialize(handle_exceptions: false, takes_commands: true)
      @global_options = OptionParser.new
      @main_command = Command.new('main', takes_commands: takes_commands)
      @main_command.super_command = self
      @main_command.options.stack[0] = MultiList.new(@global_options.stack)
      @handle_exceptions = handle_exceptions
      @help_line_width = 80
      @help_indent = 4
      @help_desc_indent = 18
      @data = {}
    end

    # :call-seq:
    #   cmdparse.main_options              -> OptionParser instance
    #   cmdparse.main_options {|opts| ...} -> opts (OptionParser instance)
    #
    # Yields the main options (that are only available directly after the program name) if a block
    # is given and returns them.
    #
    # The main options are also used for setting the program name, version and banner.
    def main_options
      yield(@main_command.options) if block_given?
      @main_command.options
    end

    # :call-seq:
    #   cmdparse.global_options              -> OptionParser instance
    #   cmdparse.gloabl_options {|opts| ...} -> opts (OptionParser instance)
    #
    # Yields the global options if a block is given and returns them.
    #
    # The global options are those options that can be used on the top level and with any
    # command.
    def global_options
      yield(@global_options) if block_given?
      @global_options
    end

    # Adds a top level command.
    #
    # See Command#add_command for detailed invocation information.
    def add_command(*args, **kws, &block)
      @main_command.add_command(*args, **kws, &block)
    end

    # Parses the command line arguments.
    #
    # If a block is given, the current hierarchy level and the name of the current command is
    # yielded after the option parsing is done but before a command is executed.
    def parse(argv = ARGV) # :yields: level, command_name
      level = 0
      @current_command = @main_command

      while true
        argv = if @current_command.takes_commands? || ENV.include?('POSIXLY_CORRECT')
                 @current_command.options.order(argv)
               else
                 @current_command.options.permute(argv)
               end
        yield(level, @current_command.name) if block_given?

        if @current_command.takes_commands?
          cmd_name = argv.shift || @current_command.default_command

          if cmd_name.nil?
            raise NoCommandGivenError.new
          elsif !@current_command.commands.key?(cmd_name)
            raise InvalidCommandError.new(cmd_name)
          end

          @current_command = @current_command.commands[cmd_name]
          level += 1
        else
          original_n = @current_command.arity
          n = (original_n < 0 ? -original_n - 1 : original_n)
          if argv.size < n
            raise NotEnoughArgumentsError.new("#{n} - #{@current_command.usage_arguments}")
          elsif argv.size > n && original_n > 0
            raise TooManyArgumentsError.new("#{n} - #{@current_command.usage_arguments}")
          end

          argv.slice!(n..-1) unless original_n < 0
          @current_command.execute(*argv)
          break
        end
      end
    rescue ParseError, OptionParser::ParseError => e
      raise unless @handle_exceptions
      puts "Error while parsing command line:\n    " + e.message
      if @handle_exceptions != :no_help && @main_command.commands.key?('help')
        puts
        @main_command.commands['help'].execute(*@current_command.command_chain.map(&:name))
      end
      exit(64) # FreeBSD standard exit error for "command was used incorrectly"
    rescue Interrupt
      exit(128 + 2)
    rescue Errno::EPIPE
      # Behave well when used in a pipe
    ensure
      @current_command = nil
    end

  end

end
