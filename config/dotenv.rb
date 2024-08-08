# frozen_string_literal: true

if ENV['RAILS_ENV'] == 'production'
  if !ENV['AWS_SECRET_MANAGER_ID'].to_s.empty?
    require 'aws-sdk-secretsmanager'

    client = Aws::SecretsManager::Client.new

    secret_id = ENV.fetch('AWS_SECRET_MANAGER_ID', '')

    client.get_secret_value(secret_id:).secret_string.split("\n").each do |line|
      key, value = line.split('=', 2)

      ENV[key] = value if !key.to_s.empty? && !value.to_s.empty?
    end

    RubyVM::YJIT.enable if ENV['RUBY_YJIT_ENABLE'] == 'true'
  elsif ENV['SECRET_KEY_BASE'].to_s.empty?
    require 'dotenv'
    require 'securerandom'

    dotenv_path = "#{ENV.fetch('WORKDIR', '.')}/docuseal.env"

    unless File.exist?(dotenv_path)
      default_env = <<~TEXT
        DATABASE_URL= # keep empty to use sqlite or specify postgresql database URL
        SECRET_KEY_BASE=#{SecureRandom.hex(64)}
      TEXT

      File.write(dotenv_path, default_env)
    end

    database_url = ENV.fetch('DATABASE_URL', nil)

    Dotenv.load(dotenv_path)

    ENV['DATABASE_URL'] = ENV['DATABASE_URL'].to_s.empty? ? database_url : ENV.fetch('DATABASE_URL', nil)
  end
end

if ENV['DATABASE_URL'].to_s.split('@').last.to_s.split('/').first.to_s.include?('_')
  require 'addressable'

  url = Addressable::URI.parse(ENV.fetch('DATABASE_URL', ''))

  ENV['DATABASE_HOST'] = url.host
  ENV['DATABASE_PORT'] = (url.port || 5432).to_s
  ENV['DATABASE_USER'] = url.user
  ENV['DATABASE_PASSWORD'] = url.password
  ENV['DATABASE_NAME'] = url.path.to_s.delete_prefix('/')

  ENV.delete('DATABASE_URL')
end

if ENV['REDIS_URL'].to_s.empty?
  require 'digest'

  redis_password = Digest::SHA1.hexdigest("redis#{ENV.fetch('SECRET_KEY_BASE', '')}")

  ENV['REDIS_URL'] = "redis://default:#{redis_password}@0.0.0.0:6379/0"
  ENV['LOCAL_REDIS_URL'] = ENV.fetch('REDIS_URL', nil)
end
