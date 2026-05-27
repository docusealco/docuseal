# frozen_string_literal: true

# = Erubi (<tt>erb</tt>, <tt>rhtml</tt>, <tt>erubi</tt>)
#
# {Erubi}[https://github.com/jeremyevans/erubi] is an ERB implementation that uses the same algorithm as
# the erubis gem, but is maintained and offers numerous improvements.
#
# All the documentation of {ERB}[rdoc-ref:lib/tilt/erb.rb] applies in addition to the following:
#
# === Usage
#
# The <tt>Tilt::ErubiTemplate</tt> class is registered for all files ending in <tt>.erb</tt> or
# <tt>.rhtml</tt> by default, with the *highest* priority.
#
# __NOTE:__ It's suggested that your program <tt>require 'erubi'</tt> at load time when
# using this template engine within a threaded environment.
#
# === Options
#
# ==== <tt>:engine_class => Erubi::Engine</tt>
#
# Allows you to specify a custom engine class to use instead of the
# default which is <tt>Erubi::Engine</tt>.
#
# ==== Other
#
# Other options are passed to the constructor of the engine class.
#
# ErubiTemplate supports the following additional options, in addition
# to the options supported by the Erubi engine:
#
# :engine_class :: allows you to specify a custom engine class to use
#                  instead of the default (which is ::Erubi::Engine).
#
# === See also
#
# * {Erubi Home}[https://github.com/jeremyevans/erubi]
#
# === Related module
#
# * Tilt::ErubiTemplate

require_relative 'template'
require 'erubi'

module Tilt
  class ErubiTemplate < Template
    def prepare
      @options[:preamble] = false
      @options[:postamble] = false
      @options[:ensure] = true

      engine_class = @options[:engine_class] || Erubi::Engine

      # If :freeze option is given, the intent is to setup frozen string
      # literals in the template.  So enable frozen string literals in the
      # code Tilt generates if the :freeze option is given.
      if @freeze_string_literals = !!@options[:freeze]
        # Passing the :freeze option to Erubi sets the
        # frozen-string-literal magic comment, which doesn't have an effect
        # with Tilt as Tilt wraps the resulting code.  Worse, the magic
        # comment appearing not at the top of the file can cause a warning.
        # So remove the :freeze option before passing to Erubi.
        @options.delete(:freeze)

        # Erubi by default appends .freeze to template literals on Ruby 2.1+,
        # but that is not necessary and slows down code when Tilt is using
        # frozen string literals, so pass the :freeze_template_literals
        # option to not append .freeze.
        @options[:freeze_template_literals] = false
      end

      @engine = engine_class.new(@data, @options)
      @outvar = @engine.bufvar
      @src = @engine.src

      @engine
    end

    def precompiled_template(locals)
      @src
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end
