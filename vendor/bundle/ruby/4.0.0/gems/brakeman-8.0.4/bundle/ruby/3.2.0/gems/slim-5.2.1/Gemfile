source 'https://rubygems.org/'

gemspec

gem 'minitest', '~> 5.15'
gem 'rake', '~> 13.0'
gem 'kramdown', '~> 2.4'

if ENV['TEMPLE'] && ENV['TEMPLE'] != 'master'
  gem 'temple', "= #{ENV['TEMPLE']}"
else
  # Test against temple master by default
  gem 'temple', github: 'judofyr/temple'
end

if ENV['TILT']
  if ENV['TILT'] == 'master'
    gem 'tilt', github: 'jeremyevans/tilt'
  else
    gem 'tilt', "= #{ENV['TILT']}"
  end
end

if ENV['RAILS']
  gem 'rails-controller-testing'

  # we need some smarter test logic for the different Rails versions
  if ENV['RAILS'] == 'main'
    gem 'rails', github: 'rails/rails', branch: 'main'
  else
    gem 'rails', "= #{ENV['RAILS']}"
  end
end

if ENV['SINATRA']
  gem 'rack-test'

  if ENV['SINATRA'] == 'main'
    gem 'sinatra', github: 'sinatra/sinatra'
  else
    gem 'sinatra', "= #{ENV['SINATRA']}"
  end
end
