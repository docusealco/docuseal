# frozen_string_literal: true

require Rails.root.join('lib/migration_database_url')

Rails.configuration.to_prepare do
  MigrationDatabaseUrl.migrate if ENV['RAILS_ENV'] == 'production' && ENV['RUN_MIGRATIONS'] != 'false'
end
