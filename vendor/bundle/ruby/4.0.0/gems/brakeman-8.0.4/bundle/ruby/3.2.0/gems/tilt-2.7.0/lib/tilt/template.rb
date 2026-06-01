# frozen_string_literal: true
module Tilt
  # @private
  module CompiledTemplates
  end

  # @private
  TOPOBJECT = CompiledTemplates

  # @private
  LOCK = Mutex.new

  # Base class for template implementations. Subclasses must implement
  # the #prepare method and one of the #evaluate or #precompiled_template
  # methods.
  class Template
    # Template source; loaded from a file or given directly.
    attr_reader :data

    # The name of the file where the template data was loaded from.
    attr_reader :file

    # The line number in #file where template data was loaded from.
    attr_reader :line

    # A Hash of template engine specific options. This is passed directly
    # to the underlying engine and is not used by the generic template
    # interface.
    attr_reader :options

    # A path ending in .rb that the template code will be written to, then
    # required, instead of being evaled.  This is useful for determining
    # coverage of compiled template code, or to use static analysis tools
    # on the compiled template code.
    attr_reader :compiled_path

    class << self
      # An empty Hash that the template engine can populate with various
      # metadata.
      def metadata
        @metadata ||= {}
      end

      # Use <tt>.metadata[:mime_type]</tt> instead.
      def default_mime_type
        metadata[:mime_type]
      end

      # Use <tt>.metadata[:mime_type] = val</tt> instead.
      def default_mime_type=(value)
        metadata[:mime_type] = value
      end
    end

    # Create a new template with the file, line, and options specified. By
    # default, template data is read from the file. When a block is given,
    # it should read template data and return as a String. When file is nil,
    # a block is required.
    #
    # All arguments are optional. The following options are respected and
    # are used by Tilt::Template itself and not the underlying template
    # libraries:
    #
    # :default_encoding :: Force the encoding of the template to the given
    #                      encoding.
    # :skip_compiled_encoding_detection :: Do not scan template code for
    #                                      an encoding magic comment.
    # :fixed_locals :: Force a specific method parameter signature, and call
    #                  the method with a splat of locals, instead of passing
    #                  the locals hash as a positional argument, and
    #                  extracting locals from that. Should be a string
    #                  containing the parameters for the compiled method,
    #                  surrounded by parentheses.  Can be set to false to
    #                  disable the scan for embedded fixed locals.
    # :extract_fixed_locals :: Whether embedded fixed locals should be scanned for
    #                          and extracted from the template code.
    # :default_fixed_locals :: Similar to fixed_locals, but lowest priority,
    #                          only used if :fixed_locals is not provided
    #                          and no embedded locals are found (or scanned for).
    # :scope_class :: Force the scope class used for the method.  By default,
    #                 uses the class of the scope provided to render.
    def initialize(file=nil, line=nil, options=nil)
      @file, @line, @options = nil, 1, nil

      process_arg(options)
      process_arg(line)
      process_arg(file)

      raise ArgumentError, "file or block required" unless @file || block_given?

      @options ||= {}

      # Force a specific scope class, instead of using the class of the provided
      # scope as the scope class.
      @scope_class = @options.delete :scope_class

      # Force the encoding of the input data
      @default_encoding = @options.delete :default_encoding

      # Skip encoding detection from magic comments and forcing that encoding
      # for compiled templates
      @skip_compiled_encoding_detection = @options.delete :skip_compiled_encoding_detection

      # Compiled path to use.  This must be specified as an option if
      # providing the :scope_class option and using fixed locals,
      # since template compilation occurs during initialization in that case.
      if compiled_path = @options.delete(:compiled_path)
        self.compiled_path = compiled_path
      end

      # load template data and prepare (uses binread to avoid encoding issues)
      @data = block_given? ? yield(self) : read_template_file

      if @data.respond_to?(:force_encoding)
        if default_encoding
          @data = _dup_string_if_frozen(@data)
          @data.force_encoding(default_encoding)
        end

        if !@data.valid_encoding?
          raise Encoding::InvalidByteSequenceError, "#{eval_file} is not valid #{@data.encoding}"
        end
      end

      set_fixed_locals
      prepare
      set_compiled_method_cache
    end

    # Render the template in the given scope with the locals specified. If a
    # block is given, it is typically available within the template via
    # +yield+.
    def render(scope=nil, locals=nil, &block)
      evaluate(scope || Object.new, locals || EMPTY_HASH, &block)
    end

    # The basename of the template file.
    def basename(suffix='')
      File.basename(@file, suffix) if @file
    end

    # The template file's basename with all extensions chomped off.
    def name
      if bname = basename
        bname.split('.', 2).first
      end
    end

    # The filename used in backtraces to describe the template.
    def eval_file
      @file || '(__TEMPLATE__)'
    end

    # Whether the template uses fixed locals.
    def fixed_locals?
      @fixed_locals ? true : false
    end

    # An empty Hash that the template engine can populate with various
    # metadata.
    def metadata
      if respond_to?(:allows_script?)
        self.class.metadata.merge(:allows_script => allows_script?)
      else
        self.class.metadata
      end
    end

    # Set the prefix to use for compiled paths, similar to using the
    # :compiled_path template option. Note that this only
    # has affect for future template compilations.  When using the
    # :scope_class template option, and using fixed_locals, calling
    # this after the template is created has no effect, since the
    # template is compiled during initialization in that case. It
    # is recommended to use the :compiled_path template option
    # instead of this method in new code.
    def compiled_path=(path)
      if path
        # Use expanded paths when loading, since that is helpful
        # for coverage.  Remove any .rb suffix, since that will
        # be added back later.
        path = File.expand_path(path.sub(/\.rb\z/i, ''))
      end
      @compiled_path = path
    end

    # The compiled method for the locals keys and scope_class provided.
    # Returns an UnboundMethod, which can be used to define methods
    # directly on the scope class, which are much faster to call than
    # Tilt's normal rendering.
    def compiled_method(locals_keys, scope_class=nil)
      if @fixed_locals
        if @scope_class
          return @compiled_method
        else
          key = scope_class
        end
      elsif @scope_class
        key = locals_keys.dup.freeze
      else
        key = [scope_class, locals_keys].freeze
      end

      LOCK.synchronize do
        if meth = @compiled_method[key]
          return meth
        end
      end
      meth = compile_template_method(locals_keys, scope_class)
      LOCK.synchronize do
        @compiled_method[key] = meth
      end
      meth
    end

    protected

    # @!group For template implementations

    # The encoding of the source data. Defaults to the
    # default_encoding-option if present. You may override this method
    # in your template class if you have a better hint of the data's
    # encoding.
    attr_reader :default_encoding

    def skip_compiled_encoding_detection?
      @skip_compiled_encoding_detection
    end

    # Do whatever preparation is necessary to setup the underlying template
    # engine. Called immediately after template data is loaded. Instance
    # variables set in this method are available when #evaluate is called.
    #
    # Empty by default as some subclasses do not need separate preparation.
    def prepare
    end

    CLASS_METHOD = Kernel.instance_method(:class)
    USE_BIND_CALL = RUBY_VERSION >= '3'

    # Execute the compiled template and return the result string. Template
    # evaluation is guaranteed to be performed in the scope object with the
    # locals specified and with support for yielding to the block.
    #
    # This method is only used by source generating templates. Subclasses that
    # override render() may not support all features.
    def evaluate(scope, locals, &block)
      if @fixed_locals
        locals_keys = EMPTY_ARRAY
      else
        locals_keys = locals.keys
        locals_keys.sort!{|x, y| x.to_s <=> y.to_s}
      end

      unless scope_class = @scope_class
        scope_class = case scope
        when Object
          Module === scope ? scope : scope.class
        else
          # :nocov:
          USE_BIND_CALL ? CLASS_METHOD.bind_call(scope) : CLASS_METHOD.bind(scope).call
          # :nocov:
        end
      end

      evaluate_method(compiled_method(locals_keys, scope_class), scope, locals, &block)
    end

    # Generates all template source by combining the preamble, template, and
    # postamble and returns a two-tuple of the form: [source, offset], where
    # source is the string containing (Ruby) source code for the template and
    # offset is the integer line offset where line reporting should begin.
    #
    # Template subclasses may override this method when they need complete
    # control over source generation or want to adjust the default line
    # offset. In most cases, overriding the #precompiled_template method is
    # easier and more appropriate.
    def precompiled(local_keys)
      preamble = precompiled_preamble(local_keys)
      template = precompiled_template(local_keys)
      postamble = precompiled_postamble(local_keys)
      source = String.new

      unless skip_compiled_encoding_detection?
        # Ensure that our generated source code has the same encoding as the
        # the source code generated by the template engine.
        template_encoding = extract_encoding(template){|t| template = t}

        if template.encoding != template_encoding
          # template should never be frozen here. If it was frozen originally,
          # then extract_encoding should yield a dup.
          template.force_encoding(template_encoding)
        end
      end

      source.force_encoding(template.encoding)
      source << preamble << "\n" << template << "\n" << postamble

      [source, preamble.count("\n")+1]
    end

    # A string containing the (Ruby) source code for the template. The
    # default Template#evaluate implementation requires either this
    # method or the #precompiled method be overridden. When defined,
    # the base Template guarantees correct file/line handling, locals
    # support, custom scopes, proper encoding, and support for template
    # compilation.
    def precompiled_template(local_keys)
      raise NotImplementedError
    end

    def precompiled_preamble(local_keys)
      ''
    end

    def precompiled_postamble(local_keys)
      ''
    end

    # !@endgroup

    private

    if RUBY_VERSION >= '2.3'
      def _dup_string_if_frozen(string)
        +string
      end
    # :nocov:
    else
      def _dup_string_if_frozen(string)
        string.frozen? ? string.dup : string
      end
    end
    # :nocov:

    def process_arg(arg)
      if arg
        case
        when arg.respond_to?(:to_str)  ; @file = arg.to_str
        when arg.respond_to?(:to_int)  ; @line = arg.to_int
        when arg.respond_to?(:to_hash) ; @options = arg.to_hash.dup
        when arg.respond_to?(:path)    ; @file = arg.path
        when arg.respond_to?(:to_path) ; @file = arg.to_path
        else raise TypeError, "Can't load the template file. Pass a string with a path " +
          "or an object that responds to 'to_str', 'path' or 'to_path'"
        end
      end
    end

    def read_template_file
      data = File.binread(file)
      # Set it to the default external (without verifying)
      # :nocov:
      data.force_encoding(Encoding.default_external) if Encoding.default_external
      # :nocov:
      data
    end

    def set_compiled_method_cache
      @compiled_method = if @fixed_locals && @scope_class
        # No hash needed, only a single compiled method per template.
        compile_template_method(EMPTY_ARRAY, @scope_class)
      else
        {}
      end
    end

    def local_extraction(local_keys)
      assignments = local_keys.map do |k|
        if k.to_s =~ /\A[a-z_][a-zA-Z_0-9]*\z/
          "#{k} = locals[#{k.inspect}]"
        else
          raise "invalid locals key: #{k.inspect} (keys must be variable names)"
        end
      end

      s = "locals = locals[:locals]"
      if assignments.delete(s)
        # If there is a locals key itself named <tt>locals</tt>, delete it from the ordered keys so we can
        # assign it last. This is important because the assignment of all other locals depends on the
        # <tt>locals</tt> local variable still matching the <tt>locals</tt> method argument given to the method
        # created in <tt>#compile_template_method</tt>.
        assignments << s
      end

      assignments.join("\n")
    end

    if USE_BIND_CALL
      def evaluate_method(method, scope, locals, &block)
        if @fixed_locals
          method.bind_call(scope, **locals, &block)
        else
          method.bind_call(scope, locals, &block)
        end
      end
    # :nocov:
    else
      def evaluate_method(method, scope, locals, &block)
        if @fixed_locals
          if locals.empty?
            # Empty keyword splat on Ruby 2.0-2.6 passes empty hash
            method.bind(scope).call(&block)
          else
            method.bind(scope).call(**locals, &block)
          end
        else
          method.bind(scope).call(locals, &block)
        end
      end
    end
    # :nocov:

    def compile_template_method(local_keys, scope_class=nil)
      source, offset = precompiled(local_keys)
      if @fixed_locals
        method_args = @fixed_locals
      else
        method_args = "(locals)"
        local_code = local_extraction(local_keys)
      end

      method_name = "__tilt_#{Thread.current.object_id.abs}"
      method_source = String.new
      method_source.force_encoding(source.encoding)

      if freeze_string_literals?
        method_source << "# frozen-string-literal: true\n"
      end

      # Don't indent method source, to avoid indentation warnings when using compiled paths
      method_source << "::Tilt::TOPOBJECT.class_eval do\ndef #{method_name}#{method_args}\n#{local_code}\n"

      offset += method_source.count("\n")
      method_source << source
      method_source << "\nend;end;"

      bind_compiled_method(method_source, offset, scope_class)
      unbind_compiled_method(method_name)
    end

    def bind_compiled_method(method_source, offset, scope_class)
      path = compiled_path
      if path && scope_class.name
        path = path.dup

        if defined?(@compiled_path_counter)
          path << '-' << @compiled_path_counter.succ!
        else
          @compiled_path_counter = "0".dup
        end
        path << ".rb"

        # Wrap method source in a class block for the scope, so constant lookup works
        if freeze_string_literals?
          method_source_prefix = "# frozen-string-literal: true\n"
          method_source = method_source.sub(/\A# frozen-string-literal: true\n/, '')
        end
        method_source = "#{method_source_prefix}class #{scope_class.name}\n#{method_source}\nend"

        load_compiled_method(path, method_source)
      else
        if path
          warn "compiled_path (#{compiled_path.inspect}) ignored on template with anonymous scope_class (#{scope_class.inspect})"
        end

        eval_compiled_method(method_source, offset, scope_class)
      end
    end

    def eval_compiled_method(method_source, offset, scope_class)
      (scope_class || Object).class_eval(method_source, eval_file, line - offset)
    end

    def load_compiled_method(path, method_source)
      # Write to a temporary path specific to the current process, and
      # rename after writing. This prevents issues during parallel
      # coverage testing.
      tmp_path = "#{path}-#{$$}"
      File.binwrite(tmp_path, method_source)
      File.rename(tmp_path, path)

      # Use load and not require, so unbind_compiled_method does not
      # break if the same path is used more than once.
      load path
    end

    def unbind_compiled_method(method_name)
      method = TOPOBJECT.instance_method(method_name)
      TOPOBJECT.class_eval { remove_method(method_name) }
      method
    end

    # Set the fixed locals for the template, which may be nil if no fixed locals can
    # be determined.
    def set_fixed_locals
      fixed_locals = @options.delete(:fixed_locals)
      extract_fixed_locals = @options.delete(:extract_fixed_locals)
      default_fixed_locals = @options.delete(:default_fixed_locals)

      if fixed_locals.nil?
        if extract_fixed_locals.nil?
          extract_fixed_locals = Tilt.extract_fixed_locals
        end

        if extract_fixed_locals
          fixed_locals = extract_fixed_locals()
        end

        if fixed_locals.nil?
          fixed_locals = default_fixed_locals
        end
      end

      @fixed_locals = fixed_locals
    end

    # Extract fixed locals from the template code string. Should return nil
    # if there are no fixed locals specified, or a method argument string
    # surrounded by parentheses if there are fixed locals.  The method
    # argument string will be used when defining the template method if given.
    def extract_fixed_locals
      if @data.is_a?(String) && (match = /\#\s*locals:\s*(\(.*\))/.match(@data))
        match[1]
      end
    end

    def extract_encoding(script, &block)
      extract_magic_comment(script, &block) || script.encoding
    end

    def extract_magic_comment(script)
      was_frozen = script.frozen?
      script = _dup_string_if_frozen(script)

      if was_frozen
        yield script
      end

      binary(script) do
        script[/\A[ \t]*\#.*coding\s*[=:]\s*([[:alnum:]\-_]+).*$/n, 1]
      end
    end

    def freeze_string_literals?
      false
    end

    def binary(string)
      original_encoding = string.encoding
      string.force_encoding(Encoding::BINARY)
      yield
    ensure
      string.force_encoding(original_encoding)
    end
  end

  # Static templates are templates that return the same output for every render
  #
  # Instead of inheriting from the StaticTemplate class, you will use the .subclass
  # method with a block which processes @data and returns the transformed value.
  #
  # Basic example which transforms the template to uppercase:
  #
  #   UppercaseTemplate = Tilt::StaticTemplate.subclass do
  #     @data.upcase
  #   end
  class StaticTemplate < Template
    def self.subclass(mime_type: 'text/html', &block)
      Class.new(self) do
        self.default_mime_type = mime_type

        private

        define_method(:_prepare_output, &block)
      end
    end

    # Static templates always return the prepared output.
    def render(scope=nil, locals=nil)
      @output
    end

    # Raise NotImplementedError, since static templates
    # do not support compiled methods.
    def compiled_method(locals_keys, scope_class=nil)
      raise NotImplementedError
    end

    # Static templates never allow script.
    def allows_script?
      false
    end

    protected

    def prepare
      @output = _prepare_output
    end

    private

    # Do nothing, since compiled method cache is not used.
    def set_compiled_method_cache
    end

    # Do nothing, since fixed locals are not used.
    def set_fixed_locals
    end
  end
end
