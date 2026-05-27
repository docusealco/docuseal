require "mini_magick/shell"

module MiniMagick
  ##
  # Class that wraps command-line tools directly, as opposed MiniMagick::Image
  # which is more high-level.
  #
  # @example
  #   MiniMagick.mogrify do |mogrify|
  #     mogrify.resize "500x500"
  #     mogrify << "path/to/image.jpg"
  #   end
  #
  class Tool

    CREATION_OPERATORS = %w[xc canvas logo rose gradient radial-gradient plasma
                            pattern text pango]

    ##
    # Aside from classic instantiation, it also accepts a block, and then
    # executes the command in the end.
    #
    # @example
    #   puts MiniMagick.identify(&:version)
    #
    # @return [MiniMagick::Tool, String] If no block is given, returns an
    #   instance of the tool, if block is given, returns the output of the
    #   command.
    #
    def self.new(name, **options)
      instance = super

      if block_given?
        yield instance
        instance.call
      else
        instance
      end
    end

    # @private
    attr_reader :name, :args

    # @param name [String]
    # @param options [Hash]
    # @option options [Boolean] :errors Whether to raise errors on non-zero
    #   exit codes.
    # @option options [Boolean] :warnings Whether to print warnings to stderrr.
    # @option options [String] :stdin Content to send to standard input stream.
    # @example
    #   MiniMagick.identify(errors: false) do |identify|
    #     identify.help # returns exit status 1, which would otherwise throw an error
    #   end
    def initialize(name, **options)
      @name = name
      @args = []
      @options = options
    end

    ##
    # Executes the command that has been built up.
    #
    # @example
    #   mogrify = MiniMagick.mogrify
    #   mogrify.resize("500x500")
    #   mogrify << "path/to/image.jpg"
    #   mogrify.call # executes `mogrify -resize 500x500 path/to/image.jpg`
    #
    # @example
    #   mogrify = MiniMagick.mogrify
    #   # build the command
    #   mogrify.call do |stdout, stderr, status|
    #     # ...
    #   end
    #
    # @yield [Array] Optionally yields stdout, stderr, and exit status
    #
    # @return [String] Returns the output of the command
    #
    def call(**options)
      options = @options.merge(options)
      options[:warnings] = false if block_given?

      shell = MiniMagick::Shell.new
      stdout, stderr, status = shell.run(command, **options)
      yield stdout, stderr, status if block_given?

      stdout.chomp("\n")
    end

    ##
    # The currently built-up command.
    #
    # @return [Array<String>]
    #
    # @example
    #   mogrify = MiniMagick.mogrify
    #   mogrify.resize "500x500"
    #   mogrify.contrast
    #   mogrify.command #=> ["mogrify", "-resize", "500x500", "-contrast"]
    #
    def command
      [*executable, *args]
    end

    ##
    # The executable used for this tool. Respects
    # {MiniMagick::Configuration#cli_prefix}.
    #
    # @return [Array<String>]
    #
    # @example
    #   identify = MiniMagick.identify
    #   identify.executable #=> ["magick", "identify"]
    #
    # @example
    #   MiniMagick.configure do |config|
    #     config.cli_prefix = ['firejail', '--force']
    #   end
    #   identify = MiniMagick.identify
    #   identify.executable #=> ["firejail", "--force", "magick", "identify"]
    #
    def executable
      exe = Array(MiniMagick.cli_prefix).dup
      exe << "magick" if MiniMagick.imagemagick7? && name != "magick"
      exe << "gm" if MiniMagick.graphicsmagick
      exe << name
    end

    ##
    # Appends raw options, useful for appending image paths.
    #
    # @return [self]
    #
    def <<(arg)
      args << arg.to_s
      self
    end

    ##
    # Merges a list of raw options.
    #
    # @return [self]
    #
    def merge!(new_args)
      new_args.each { |arg| self << arg }
      self
    end

    ##
    # Changes the last operator to its "plus" form.
    #
    # @example
    #   MiniMagick.mogrify do |mogrify|
    #     mogrify.antialias.+
    #     mogrify.distort.+("Perspective", "0,0,4,5 89,0,45,46")
    #   end
    #   # executes `mogrify +antialias +distort Perspective '0,0,4,5 89,0,45,46'`
    #
    # @return [self]
    #
    def +(*values)
      args[-1] = args[-1].sub(/^-/, '+')
      self.merge!(values)
      self
    end

    ##
    # Create an ImageMagick stack in the command (surround.
    #
    # @example
    #   MiniMagick.convert do |convert|
    #     convert << "wand.gif"
    #     convert.stack do |stack|
    #       stack << "wand.gif"
    #       stack.rotate(30)
    #     end
    #     convert.append.+
    #     convert << "images.gif"
    #   end
    #   # executes `convert wand.gif \( wizard.gif -rotate 30 \) +append images.gif`
    #
    def stack(*args)
      self << "("
      args.each do |value|
        case value
        when Hash   then value.each { |key, value| send(key, *value) }
        when String then self << value
        end
      end
      yield self if block_given?
      self << ")"
    end

    ##
    # Adds ImageMagick's pseudo-filename `-` for standard input.
    #
    # @example
    #   identify = MiniMagick.identify
    #   identify.stdin
    #   identify.call(stdin: image_content)
    #   # executes `identify -` with the given standard input
    #
    def stdin
      self << "-"
    end

    ##
    # Adds ImageMagick's pseudo-filename `-` for standard output.
    #
    # @example
    #   content = MiniMagick.convert do |convert|
    #     convert << "input.jpg"
    #     convert.auto_orient
    #     convert.stdout
    #   end
    #   # executes `convert input.jpg -auto-orient -` which returns file contents
    #
    def stdout
      self << "-"
    end

    ##
    # Define creator operator methods
    #
    # @example
    #   mogrify = MiniMagick::Tool.new("mogrify")
    #   mogrify.canvas("khaki")
    #   mogrify.command.join(" ") #=> "mogrify canvas:khaki"
    #
    CREATION_OPERATORS.each do |operator|
      define_method(operator.tr('-', '_')) do |value = nil|
        self << "#{operator}:#{value}"
        self
      end
    end

    ##
    # This option is a valid ImageMagick option, but it's also a Ruby method,
    # so we need to override it so that it correctly acts as an option method.
    #
    def clone(*args)
      self << '-clone'
      self.merge!(args)
      self
    end

    ##
    # Any undefined method will be transformed into a CLI option
    #
    # @example
    #   mogrify = MiniMagick::Tool.new("mogrify")
    #   mogrify.adaptive_blur("...")
    #   mogrify.foo_bar
    #   mogrify.command.join(" ") # => "mogrify -adaptive-blur ... -foo-bar"
    #
    def method_missing(name, *args)
      option = "-#{name.to_s.tr('_', '-')}"
      self << option
      self.merge!(args)
      self
    end

    # deprecated tool subclasses
    %w[animate compare composite conjure convert display identify import magick mogrify montage stream].each do |tool|
      const_set(tool.capitalize, Class.new(self) {
        define_method(:initialize) do |*args|
          super(tool, *args)
        end
      })
      deprecate_constant(tool.capitalize)
    end
  end
end
