# frozen_string_literal: true

Capybara.register_server :default do |app, port, _host|
  Capybara.run_default_server(app, port)
end

Capybara.register_server :webrick do |app, port, host, **options|
  base_class = begin
    require 'rack/handler/webrick'
    Rack
  rescue LoadError
    # Rack 3 separated out the webrick handle - no way test currently in Capybaras automated
    # tests due to Sinatra not yet supporting Rack 3 - experimental
    require 'rackup/handler/webrick'
    Rackup
  end
  options = { Host: host, Port: port, AccessLog: [], Logger: WEBrick::Log.new(nil, 0) }.merge(options)
  base_class::Handler::WEBrick.run(app, **options)
end

Capybara.register_server :puma do |app, port, host, **options| # rubocop:disable Metrics/BlockLength
  begin
    require 'rackup'
  rescue LoadError # rubocop:disable Lint/SuppressedException
  end
  begin
    require 'rack/handler/puma'
  rescue LoadError
    raise LoadError, 'Capybara is unable to load `puma` for its server, please add `puma` to your project or specify a different server via something like `Capybara.server = :webrick`.'
  end
  puma_rack_handler = defined?(Rackup::Handler::Puma) ? Rackup::Handler::Puma : Rack::Handler::Puma

  unless puma_rack_handler.respond_to?(:config)
    raise LoadError, 'Capybara requires `puma` version 3.8.0 or higher, please upgrade `puma` or register and specify your own server block'
  end

  # If we just run the Puma Rack handler it installs signal handlers which prevent us from being able to interrupt tests.
  # Therefore construct and run the Server instance ourselves.
  # puma_rack_handler.run(app, { Host: host, Port: port, Threads: "0:4", workers: 0, daemon: false }.merge(options))
  default_options = { Host: host, Port: port, Threads: '0:4', workers: 0, daemon: false }
  options = default_options.merge(options)

  conf = puma_rack_handler.config(app, options)
  conf.clamp

  puma_ver = Gem::Version.new(Puma::Const::PUMA_VERSION)
  require_relative 'patches/puma_ssl' if Gem::Requirement.new('>=4.0.0', '< 4.1.0').satisfied_by?(puma_ver)

  logger = (defined?(Puma::LogWriter) ? Puma::LogWriter : Puma::Events).then do |cls|
    conf.options[:Silent] ? cls.strings : cls.stdio
  end
  conf.options[:log_writer] = logger

  logger.log 'Capybara starting Puma...'
  logger.log "* Version #{Puma::Const::PUMA_VERSION}, codename: #{Puma::Const::CODE_NAME}"
  logger.log "* Min threads: #{conf.options[:min_threads]}, max threads: #{conf.options[:max_threads]}"

  Puma::Server.new(
    conf.app,
    defined?(Puma::LogWriter) ? nil : logger,
    conf.options
  ).tap do |s|
    s.binder.parse conf.options[:binds], (s.log_writer rescue s.events) # rubocop:disable Style/RescueModifier
    s.min_threads, s.max_threads = conf.options[:min_threads], conf.options[:max_threads] if s.respond_to? :min_threads=
  end.run.join
end
