# frozen_string_literal: true

if ENV['RAILS_ENV'] == 'production'
  if Process.uid.zero?
    begin
      workdir = ENV.fetch('WORKDIR', '.')

      if File.exist?(workdir) && File.stat(workdir).uid != 2000
        puts 'Changing the owner of the docuseal directory...' unless Dir.empty?(workdir)

        FileUtils.chown_R(2000, 2000, workdir)
      end
    rescue StandardError
      puts 'Unable to change docuseal directory owner'
    end
  end

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

    if Process.uid.zero?
      begin
        File.chown(0, 0, dotenv_path)
        File.chmod(0o600, dotenv_path)
      rescue StandardError
        puts 'Unable to set dotenv mod'
      end
    end

    database_url = ENV.fetch('DATABASE_URL', nil)

    Dotenv.load(dotenv_path)

    ENV['DATABASE_URL'] = ENV['DATABASE_URL'].to_s.empty? ? database_url : ENV.fetch('DATABASE_URL', nil)
  end

  if Process.uid.zero? && Process.euid != 2000
    begin
      test_file = "#{ENV.fetch('WORKDIR', '.')}/test"

      orig_euid = Process.euid
      orig_egid = Process.egid

      Process::Sys.setegid(2000)
      Process::Sys.seteuid(2000)

      File.open(test_file, 'w') { true }
    rescue StandardError
      Process::Sys.seteuid(orig_euid)
      Process::Sys.setegid(orig_egid)

      puts "Unable to run as 2000:2000, running as #{orig_euid}:#{orig_egid}"
    ensure
      begin
        File.unlink(test_file)
      rescue StandardError
        nil
      end
    end
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
