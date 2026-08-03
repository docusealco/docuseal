# frozen_string_literal: true

module MigrationDatabaseUrl
  module_function

  def migrate
    migration_database_url = ENV.fetch('MIGRATION_DATABASE_URL', '').to_s

    return ActiveRecord::Tasks::DatabaseTasks.migrate if migration_database_url.empty?

    app_database_config = ActiveRecord::Base.connection_db_config

    ActiveRecord::Base.establish_connection(migration_database_url)
    ActiveRecord::Tasks::DatabaseTasks.migrate
  ensure
    ActiveRecord::Base.establish_connection(app_database_config) if app_database_config
  end
end
