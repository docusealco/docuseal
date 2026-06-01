require 'brakeman/processors/haml_template_processor'

class Brakeman::Haml6TemplateProcessor < Brakeman::HamlTemplateProcessor

  OUTPUT_BUFFER = s(:ivar, :@output_buffer)
  HAML_UTILS = s(:colon2, s(:colon3, :Haml), :Util)
  HAML_UTILS2 = s(:colon2, s(:const, :Haml), :Util)
  # @output_buffer = output_buffer || ActionView::OutputBuffer.new
  AV_SAFE_BUFFER = s(:or, s(:call, nil, :output_buffer), s(:call, s(:colon2, s(:const, :ActionView), :OutputBuffer), :new))
  EMBEDDED_FILTER = s(:const, :BrakemanFilter)

  def initialize(*)
    super

    # Because of how Haml 6 handles line breaks -
    # we have to track where _haml_compiler variables are assigned.
    # then change the line number of where they are output to where
    # they are assigned.
    #
    # Like this:
    #
    #   ; _haml_compiler1 = (params[:x]; 
    #   ; ); @output_buffer.safe_concat((((::Haml::Util.escape_html_safe((_haml_compiler1))).to_s).to_s));
    #
    #  `_haml_compiler1` is output a line after it's assigned,
    #  but the assignment matches the "real" line where it is output in the template.
    @compiler_assigns = {}
  end

  # @output_buffer.safe_concat
  def buffer_append? exp
    call? exp and
      output_buffer? exp.target and
      exp.method == :safe_concat
  end

  def process_lasgn exp
    if exp.lhs.match?(/_haml_compiler\d+/)
      @compiler_assigns[exp.lhs] = exp.rhs
      ignore
    else
      exp
    end
  end

  def process_lvar exp
    if exp.value.match?(/_haml_compiler\d+/)
      exp = @compiler_assigns[exp.value] || exp
    end

    exp
  end

  def is_escaped? exp
    return unless call? exp

    html_escaped? exp or
      javascript_escaped? exp
  end

  def javascript_escaped? call
    # TODO: Adding here to match existing behavior for HAML,
    # but really this is not safe and needs to be revisited
      call.method == :j or
        call.method == :escape_javascript
  end

  def html_escaped? call
    (call.target == HAML_UTILS or call.target == HAML_UTILS2) and
      (call.method == :escape_html or call.method == :escape_html_safe)
  end

  def output_buffer? exp
    exp == OUTPUT_BUFFER or
      exp == AV_SAFE_BUFFER
  end

  def normalize_output arg
    arg = super(arg)

    if embedded_filter? arg
      super(arg.first_arg)
    else
      arg
    end
  end

  # Handle our "fake" embedded filters
  def embedded_filter? arg
    call? arg and arg.method == :render and arg.target == EMBEDDED_FILTER
  end
end
