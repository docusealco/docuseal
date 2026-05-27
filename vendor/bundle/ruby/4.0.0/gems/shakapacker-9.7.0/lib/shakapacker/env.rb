class Shakapacker::Env
  FALLBACK_ENV = "production".freeze

  delegate :config_path, :logger, to: :@instance

  def self.inquire(instance)
    new(instance).inquire
  end

  def initialize(instance)
    @instance = instance
  end

  def inquire
    fallback_env_warning if config_path.exist? && !current
    (current || FALLBACK_ENV).inquiry
  end

  private
    def current
      env = if defined?(Rails) && Rails.respond_to?(:env)
        Rails.env
      else
        ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || Shakapacker::DEFAULT_ENV
      end
      env.presence_in(available_environments)
    end

    def fallback_env_warning
      env_value = if defined?(Rails) && Rails.respond_to?(:env)
        Rails.env
      else
        ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || Shakapacker::DEFAULT_ENV
      end
      logger.info "RAILS_ENV=#{env_value} environment is not defined in #{config_path}, falling back to #{FALLBACK_ENV} environment"
    rescue NameError, NoMethodError
      # Logger may not be fully functional without Rails (e.g., ActiveSupport::IsolatedExecutionState
      # is not available). Fall back to puts, matching Configuration#log_fallback.
      puts "RAILS_ENV=#{env_value} environment is not defined in #{config_path}, falling back to #{FALLBACK_ENV} environment"
    end

    def available_environments
      if config_path.exist?
        begin
          YAML.load_file(config_path.to_s, aliases: true)
        rescue ArgumentError
          YAML.load_file(config_path.to_s)
        end
      else
        [].freeze
      end
    rescue Psych::SyntaxError => e
      raise "YAML syntax error occurred while parsing #{config_path}. " \
            "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
            "Error: #{e.message}"
    end
end
