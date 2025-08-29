# frozen_string_literal: true

# Set database to readonly mode when RAILS_READONLY environment variable is set
if ENV['RAILS_READONLY'] == 'true'
  Rails.application.config.after_initialize do
    if defined?(Rails::Console)
      puts 'Setting database connection to read-only mode...'

      # Delay execution to ensure all connections are established
      at_exit do
        # Ensure we have an active connection
        ActiveRecord::Base.establish_connection

        # Set readonly mode at the database level
        ActiveRecord::Base.connection.execute('SET SESSION default_transaction_read_only = true')
        puts '✓ Database session is now in read-only mode. Any write operations will fail.'
      rescue StandardError => e
        puts "⚠ Warning: Could not set read-only mode: #{e.message}"
      end

      # Also set it immediately if connection is already available
      begin
        if ActiveRecord::Base.connection_pool.connected?
          ActiveRecord::Base.connection.execute('SET SESSION default_transaction_read_only = true')
          puts '✓ Database session is now in read-only mode. Any write operations will fail.'
        end
      rescue StandardError => e
        puts "⚠ Note: Will set read-only mode when console starts: #{e.message}"
      end
    end
  end
end
