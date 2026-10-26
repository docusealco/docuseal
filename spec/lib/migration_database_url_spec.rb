# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/migration_database_url')

RSpec.describe MigrationDatabaseUrl do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  describe '.migrate' do
    it 'runs migrations with the application database when no migration URL is configured' do
      ENV.delete('MIGRATION_DATABASE_URL')

      expect(ActiveRecord::Base).not_to receive(:establish_connection)
      expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate)

      described_class.migrate
    end

    it 'uses MIGRATION_DATABASE_URL for migrations and restores the application database' do
      original_config = Object.new
      migration_database_url = 'postgres://user:***@ep-direct.us-east-1.aws.neon.tech/docuseal?sslmode=require'
      connections = []

      ENV['MIGRATION_DATABASE_URL'] = migration_database_url

      allow(ActiveRecord::Base).to receive(:connection_db_config).and_return(original_config)
      allow(ActiveRecord::Base).to receive(:establish_connection) { |config| connections << config }

      expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate)

      described_class.migrate

      expect(connections).to eq([migration_database_url, original_config])
    end

    it 'restores the application database when migration fails' do
      original_config = Object.new
      migration_database_url = 'postgres://user:***@ep-direct.us-east-1.aws.neon.tech/docuseal?sslmode=require'
      connections = []

      ENV['MIGRATION_DATABASE_URL'] = migration_database_url

      allow(ActiveRecord::Base).to receive(:connection_db_config).and_return(original_config)
      allow(ActiveRecord::Base).to receive(:establish_connection) { |config| connections << config }
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate).and_raise(ActiveRecord::StatementInvalid)

      expect { described_class.migrate }.to raise_error(ActiveRecord::StatementInvalid)
      expect(connections).to eq([migration_database_url, original_config])
    end
  end
end
