# frozen_string_literal: true

# PagyApps module
module PagyApps
  # Return the hash of app name/path
  INDEX = Dir[File.expand_path('./*.ru', __dir__)].to_h do |f|
    [File.basename(f, '.ru'), f]
  end.freeze
end
