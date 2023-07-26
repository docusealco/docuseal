# frozen_string_literal: true

Rails.configuration.to_prepare do
  ActiveRecord::Tasks::DatabaseTasks.migrate if ENV['RAILS_ENV'] == 'production'
end
