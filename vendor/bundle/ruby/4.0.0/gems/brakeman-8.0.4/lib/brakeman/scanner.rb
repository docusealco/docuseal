begin
  Brakeman.load_brakeman_dependency 'ruby_parser'
  require 'ruby_parser/bm_sexp.rb'
  require 'ruby_parser/bm_sexp_processor.rb'
  require 'brakeman/processor'
  require 'brakeman/app_tree'
  require 'brakeman/file_parser'
  require 'brakeman/parsers/template_parser'
  require 'brakeman/processors/lib/file_type_detector'
  require 'brakeman/tracker/file_cache'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit(-1)
end

#Scans the Rails application.
class Brakeman::Scanner
  attr_reader :options

  #Pass in path to the root of the Rails application
  def initialize options, processor = nil
    @options = options
    @app_tree = Brakeman::AppTree.from_options(options)

    if (!@app_tree.root || !@app_tree.exists?("app")) && !options[:force_scan]
      message = "Please supply the path to a Rails application (looking in #{@app_tree.root}).\n" <<
                "  Use `--force` to run a scan anyway."

      raise Brakeman::NoApplication, message
    end

    @processor = processor || Brakeman::Processor.new(@app_tree, options)
  end

  #Returns the Tracker generated from the scan
  def tracker
    @processor.tracked_events
  end

  def file_cache
    tracker.file_cache
  end

  def process_step(description, &)
    Brakeman.process_step(description, &)
  end

  def process_step_file(description, &)
    Brakeman.logger.single_context(description, &)
  end

  #Process everything in the Rails application
  def process(ruby_paths: nil, template_paths: nil)
    process_step 'Processing gems' do
      process_gems
    end

    process_step 'Processing configuration' do
      guess_rails_version
      process_config
    end

    # -
    # If ruby_paths or template_paths are set,
    # only parse those files. The rest will be fetched
    # from the file cache.
    #
    # Otherwise, parse everything normally.
    #
    astfiles = nil
    process_step 'Finding files' do
      ruby_paths ||= tracker.app_tree.ruby_file_paths
      template_paths ||= tracker.app_tree.template_paths
    end

    process_step 'Parsing files' do
      astfiles = parse_files(ruby_paths: ruby_paths, template_paths: template_paths)
    end

    process_step 'Detecting file types' do
      detect_file_types(astfiles)
    end

    tracker.save_file_cache! if support_rescanning?
    # -

    process_step 'Processing initializers' do
      process_initializers
    end

    process_step 'Processing libraries' do
      process_libs
    end

    process_step 'Processing routes' do
      process_routes
    end

    process_step 'Processing templates' do
      process_templates
    end

    process_step 'Processing data flow' do
      process_template_data_flows
    end

    process_step 'Processing models' do
      process_models
    end

    process_step 'Processing controllers' do
      process_controllers
    end

    process_step 'Processing data flow' do
      process_controller_data_flows
    end

    process_step 'Indexing method calls' do
      index_call_sites
    end

    tracker
  end

  def parse_files(ruby_paths:, template_paths:)
    fp = Brakeman::FileParser.new(tracker.app_tree, tracker.options[:parser_timeout], tracker.options[:parallel_checks], tracker.options[:use_prism])

    fp.parse_files ruby_paths

    template_parser = Brakeman::TemplateParser.new(tracker, fp)

    fp.read_files(template_paths) do |path, contents|
      Brakeman.logger.spin
      template_parser.parse_template(path, contents)
    end

    # Collect errors raised during parsing
    tracker.add_errors(fp.errors)

    fp.file_list
  end

  def detect_file_types(astfiles)
    detector = Brakeman::FileTypeDetector.new

    astfiles.each do |file|
      Brakeman.logger.spin

      if file.is_a? Brakeman::TemplateParser::TemplateFile
        file_cache.add_file file, :template
      else
        type = detector.detect_type(file)

        unless type == :skip
          if file_cache.valid_type? type
            file_cache.add_file(file, type)
          else
            raise "Unexpected file type: #{type.inspect}"
          end
        end
      end
    end
  end

  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    # Sometimes folks like to put constants in environment.rb
    # so let's always process it even for newer Rails versions
    process_config_file "environment.rb"

    if options[:rails3] or options[:rails4] or options[:rails5] or options[:rails6]
      process_config_file "application.rb"
      process_config_file "environments/production.rb"
    else
      process_config_file "gems.rb"
    end

    if @app_tree.exists?("vendor/plugins/rails_xss") or
      options[:rails3] or options[:escape_html]

      tracker.config.escape_html = true
      Brakeman.debug 'Escaping HTML by default'
    end

    if @app_tree.exists? ".ruby-version"
      if version = @app_tree.file_path(".ruby-version").read[/(\d\.\d.\d+)/]
        tracker.config.set_ruby_version version, @app_tree.file_path(".ruby-version"), 1
      end
    end

    tracker.config.load_rails_defaults
  end

  def process_config_file file
    path = @app_tree.file_path("config/#{file}")

    if path.exists?
      @processor.process_config(parse_ruby_file(path), path)
    end

  rescue => e
    Brakeman.alert "Error while processing #{path}"
    tracker.error e.exception(e.message + "\nwhile processing #{path}"), e.backtrace
  end

  private :process_config_file

  #Process Gemfile
  def process_gems
    gem_files = {}
    gem_file_names = ['Gemfile', 'gems.rb']
    lock_file_names = ['Gemfile.lock', 'gems.locked']

    if tracker.options[:gemfile]
      name = tracker.options[:gemfile]
      gem_file_names.unshift name
      lock_file_names.unshift "#{name}.lock"
    end

    gem_file_names.each do |name|
      if @app_tree.exists? name
        file = @app_tree.file_path(name)
        gem_files[:gemfile] = { :src => parse_ruby_file(file), :file => file }
        break
      end
    end

    lock_file_names.each do |name|
      if @app_tree.exists? name
        file = @app_tree.file_path(name)
        gem_files[:gemlock] = { :src => file.read, :file => file }
        break
      end
    end

    if @app_tree.gemspec
      gem_files[:gemspec] = { :src => parse_ruby_file(@app_tree.gemspec), :file => @app_tree.gemspec }
    end

    if not gem_files.empty?
      @processor.process_gems gem_files
    end
  rescue => e
    Brakeman.alert 'Error while processing Gemfile'
    tracker.error e.exception(e.message + "\nWhile processing Gemfile"), e.backtrace
  end

  #Set :rails3/:rails4 option if version was not determined from Gemfile
  def guess_rails_version
    unless tracker.options[:rails3] or tracker.options[:rails4]
      if @app_tree.exists?("script/rails")
        tracker.options[:rails3] = true
        Brakeman.debug 'Detected Rails 3 application'
      elsif @app_tree.exists?("app/channels")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        tracker.options[:rails5] = true
        Brakeman.debug 'Detected Rails 5 application'
      elsif not @app_tree.exists?("script")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        Brakeman.debug 'Detected Rails 4 application'
      end
    end
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
    track_progress file_cache.initializers do |path, init|
      process_step_file path do
        process_initializer init
      end
    end
  end

  #Process an initializer
  def process_initializer init
    @processor.process_initializer(init.path, init.ast)
  end

  # Adds parsed information to tracker.libs.
  # This is a catch-all for any Ruby files that weren't determined
  # to be a specific type of file (like a controller).
  def process_libs
    libs = file_cache.libs.sort_by { |path, _| path }

    track_progress libs do |path, lib|
      process_step_file path do
        process_lib lib
      end
    end
  end

  #Process a library
  def process_lib lib
    @processor.process_lib lib.ast, lib.path
  end

  #Process config/routes.rb
  #
  #Adds parsed information to tracker.routes
  def process_routes
    if @app_tree.exists?("config/routes.rb")
      file = @app_tree.file_path("config/routes.rb")
      if routes_sexp = parse_ruby_file(file)
        @processor.process_routes routes_sexp
      else
        Brakeman.alert 'Error while processing routes - assuming all public controller methods are actions.'
        options[:assume_all_routes] = true
      end
    else
      Brakeman.alert 'No route information found'
    end
  end

  #Process all .rb files in controllers/
  #
  #Adds processed controllers to tracker.controllers
  def process_controllers
    controllers = file_cache.controllers.sort_by { |path, _| path }

    track_progress controllers do |path, controller|
      process_step_file path do
        process_controller controller
      end
    end
  end

  def process_controller_data_flows
    controllers = tracker.controllers.sort_by { |name, _| name }

    track_progress controllers, "controllers" do |name, controller|
      process_step_file name do
        controller.src.each do |file, src|
          @processor.process_controller_alias name, src, nil, file
        end
      end
    end

    #No longer need these processed filter methods
    tracker.filter_cache.clear
  end

  def process_controller astfile
    begin
      @processor.process_controller(astfile.ast, astfile.path)
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{astfile.path}"), e.backtrace
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates
    templates = file_cache.templates.sort_by { |path, _| path }

    track_progress templates, "templates" do |path, template|
      process_step_file path do
        process_template template
      end
    end
  end

  def process_template template
    @processor.process_template(template.name, template.ast, template.type, nil, template.path)
  end

  def process_template_data_flows
    templates = tracker.templates.sort_by { |name, _| name }

    track_progress templates, "templates" do |name, template|
      process_step_file name do
        @processor.process_template_alias template
      end
    end
  end

  #Process all the .rb files in models/
  #
  #Adds the processed models to tracker.models
  def process_models
    models = file_cache.models.sort_by { |path, _| path }

    track_progress models do |path, model|
      process_step_file path do
        process_model model
      end
    end
  end

  def process_model astfile
    @processor.process_model(astfile.ast, astfile.path)
  end

  def track_progress list, type = "files"
    total = list.length
    current = 0
    list.each do |item|
      report_progress current, total
      current += 1
      yield item
    end
  end

  def report_progress(current, total)
    return unless @options[:report_progress]
    Brakeman.logger.update_progress(current, total)
  end

  def index_call_sites
    tracker.index_call_sites
  end

  def parse_ruby_file file
    fp = Brakeman::FileParser.new(tracker.app_tree, tracker.options[:parser_timeout], false, tracker.options[:use_prism])
    fp.parse_ruby(file.read, file)
  rescue Exception => e
    tracker.error(e)
    nil
  end

  def support_rescanning?
    tracker.options[:support_rescanning]
  end
end

# This is to allow operation without loading the Haml library
module Haml; class Error < StandardError; end; end
