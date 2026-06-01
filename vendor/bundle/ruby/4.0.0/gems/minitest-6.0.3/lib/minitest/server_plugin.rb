require_relative "../minitest"

# :stopdoc:

module Minitest
  @server = false

  def self.plugin_server_options opts, options # :nodoc:
    opts.on "--server=pid", Integer, "Connect to minitest server w/ pid." do |s|
      @server = s
    end
  end

  def self.plugin_server_init options
    if @server then
      require_relative "server"
      self.reporter << Minitest::ServerReporter.new(@server)
    end
  end
end

class Minitest::ServerReporter < Minitest::AbstractReporter
  def initialize pid
    uri = Minitest::Server.path(pid)
    @mt_server = DRbObject.new_with_uri uri
    super()
  end

  def start
    @mt_server.start
  end

  def record result
    r = result
    c = r.class

    case r
    when Minitest::Result then
      file, = r.source_location
      cn = r.klass
    else
      # TODO: remove? when is this used?
      file, = r.method(r.name).source_location
      cn = c.name
    end

    sanitize r.failures

    @mt_server.result file, cn, r.name, r.failures, r.assertions, r.time
  end

  def sanitize failures
    failures.map! { |e|
      case e
      when Minitest::UnexpectedError then
        # embedded exception might not be able to be marshaled.
        bt = e.error.backtrace

        ex = RuntimeError.new(e.error.message)
        e.error = ex
        ex.set_backtrace bt

        e = Minitest::UnexpectedError.new ex # ugh. some rails plugin. ugh.

        if ex.instance_variables.include? :@bindings then # web-console is Evil
          ex.instance_variable_set :@bindings, nil
          e.instance_variable_set  :@bindings, nil
        end
      when Minitest::Skip then
        # do nothing
      when Minitest::Assertion then
        bt = e.backtrace
        e = e.class.new(e.message)
        e.set_backtrace bt
      else
        warn "Unhandled exception type: #{e.class}\n\n#{e.inspect}"
      end

      e
    }
  end

  def report
    @mt_server.report
  end
end

# :startdoc:
