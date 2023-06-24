# frozen_string_literal: true

ActiveRecord::Tasks::DatabaseTasks.migrate if ENV['RAILS_ENV'] == 'production'
