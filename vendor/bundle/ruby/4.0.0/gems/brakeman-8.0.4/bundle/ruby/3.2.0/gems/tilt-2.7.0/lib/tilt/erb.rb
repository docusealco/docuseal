# frozen_string_literal: true

# = ERB (<tt>erb</tt>, <tt>rhtml</tt>)
#
# ERB is a simple but powerful template languge for Ruby. In Tilt it's
# backed by {Erubi}[rdoc-ref:lib/tilt/erubi.rb] (if installed on your system] or by
# {erb.rb}[rdoc-ref:lib/tilt/erb.rb] (which is included in Ruby's standard library]. This
# documentation applies to both implementations.
#
# === Example
#
#     Hello <%= world %>!
#
# === Usage
#
# ERB templates support custom evaluation scopes and locals:
#
#     >> require 'erb'
#     >> template = Tilt.new('hello.html.erb')
#     >> template.render(self, :world => 'World!')
#     => "Hello World!"
#
# Or, use <tt>Tilt['erb']</tt> directly to process strings:
#
#     template = Tilt['erb'].new { "Hello <%= world %>!" }
#     template.render(self, :world => 'World!')
#
# The <tt>Tilt::ERBTemplate</tt> class is registered for all files ending in <tt>.erb</tt> or
# <tt>.rhtml</tt> by default, but with a *lower* priority than ErubiTemplate.
# If you specifically want to use ERB, it's recommended to use
# <tt>#prefer</tt>:
#
#     Tilt.prefer Tilt::ERBTemplate
#
# __NOTE:__ It's suggested that your program <tt>require 'erb'</tt> at load time when
# using this template engine within a threaded environment.
#
# === Options
#
# ==== <tt>:trim => trim</tt>
#
# The ERB trim mode flags. This is a string consisting of any combination of the
# following characters:
#
# * <tt>'>'</tt>  omits newlines for lines ending in <tt>></tt>
# * <tt>'<>'</tt> omits newlines for lines starting with <tt><%</tt> and ending in <tt>%></tt>
# * <tt>'%'</tt>  enables processing of lines beginning with <tt>%</tt>
# * <tt>true</tt> is an alias of <tt><></tt>
#
# ==== <tt>:outvar => '_erbout'</tt>
#
# The name of the variable used to accumulate template output. This can be
# any valid Ruby expression but must be assignable. By default a local
# variable named <tt>_erbout</tt> is used.
#
# ==== <tt>:freeze => false</tt>
#
# If set to true, will set the <tt>frozen_string_literal</tt> flag in the compiled
# template code, so that string literals inside the templates will be frozen.
#
# === See also
#
# * http://www.ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html
#
# === Related module
#
# * Tilt::ERBTemplate

require_relative 'template'
require 'erb'

module Tilt
  class ERBTemplate < Template
    SUPPORTS_KVARGS = ::ERB.instance_method(:initialize).parameters.assoc(:key) rescue false

    def prepare
      @freeze_string_literals = !!@options[:freeze]
      @outvar = @options[:outvar] || '_erbout'
      trim = case @options[:trim]
      when false
        nil
      when nil, true
        '<>'
      else
        @options[:trim]
      end
      @engine = if SUPPORTS_KVARGS
        ::ERB.new(@data, trim_mode: trim, eoutvar: @outvar)
      # :nocov:
      else
        ::ERB.new(@data, options[:safe], trim, @outvar)
      # :nocov:
      end
    end

    def precompiled_template(locals)
      source = @engine.src
      source
    end

    def precompiled_preamble(locals)
      <<-RUBY
        begin
          __original_outvar = #{@outvar} if defined?(#{@outvar})
          #{super}
      RUBY
    end

    def precompiled_postamble(locals)
      <<-RUBY
          #{super}
        ensure
          #{@outvar} = __original_outvar
        end
      RUBY
    end

    # ERB generates a line to specify the character coding of the generated
    # source in 1.9. Account for this in the line offset.
    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end

