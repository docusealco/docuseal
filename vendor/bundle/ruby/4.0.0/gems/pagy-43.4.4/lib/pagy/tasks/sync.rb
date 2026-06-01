# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

class Pagy
  class SyncTask < Rake::TaskLib
    def initialize(resource, destination, *targets)
      namespace :pagy do
        namespace :sync do
          desc "Sync #{resource}"
          task(resource) do
            Pagy.sync(resource, destination, *targets)
          end
        end
      end
    end
  end
end
