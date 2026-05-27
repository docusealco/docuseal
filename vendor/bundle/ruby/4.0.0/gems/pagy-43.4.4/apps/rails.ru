# frozen_string_literal: true

# DESCRIPTION
#    Reproduce rails related issues
#
# DOC
#    https://ddnexus.github.io/pagy/playground/#rails-app
#
# BIN HELP
#    pagy -h
#
# DEV USAGE
#    pagy clone rails
#    pagy ./rails.ru
#
# URL
#    http://127.0.0.1:8000

VERSION = '43.4.4'

if VERSION != Pagy::VERSION
  Warning.warn("\n>>> WARNING! '#{File.basename(__FILE__)}-#{VERSION}' running with 'pagy-#{Pagy::VERSION}'! <<< \n\n")
end

# Bundle
require 'bundler/inline'
gemfile(!Pagy::ROOT.join('pagy.gemspec').exist?) do
  source 'https://rubygems.org'
  gem 'oj'
  gem 'puma'
  gem 'rails', '~> 8.0'
  gem 'sqlite3'
end

# require 'rails/all'     # too much stuff
require 'action_controller/railtie'
require 'active_record'

OUTPUT = Rails.env.showcase? ? IO::NULL : $stdout

# Rails config
class PagyRails < Rails::Application # :nodoc:
  config.root = __dir__
  config.session_store :cookie_store, key: 'cookie_store_key'
  Rails.application.credentials.secret_key_base = 'absolute_secret'

  config.logger = Logger.new(OUTPUT)
  Rails.logger  = config.logger

  # Pagy initializer
  # require Pagy::ROOT.join('apps/enable_rails_page_segment.rb') # Uncomment to test the enable_rails_page_segment.rb override

  routes.draw do
    root to: 'comments#index'
    # get '/comments(/:page)', to: 'comments#index'  # Uncomment to test the enable_rails_page_segment.rb override
    get '/javascripts/:file', to: 'pagy#javascripts', file: /.*/
  end
end

# Activerecord initializer
ActiveRecord::Base.logger = Logger.new(OUTPUT)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'file:memdb1?mode=memory&cache=shared')
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
  end

  create_table :comments, force: true do |t|
    t.string :body
    t.integer :post_id
  end
end

# Models
class Post < ActiveRecord::Base # :nodoc:
  has_many :comments
end

# :nodoc:

class Comment < ActiveRecord::Base # :nodoc:
  belongs_to :post
end

# :nodoc:

# Unused model, useful to test overriding conflicts
module Calendar
end

# DB seed
1.upto(11) do |pi|
  Post.create(title: "Post #{pi + 1}")
end
Post.all.each_with_index do |post, pi|
  2.times { |ci| Comment.create(post:, body: "Comment #{ci + 1} to Post #{pi + 1}") }
end

# Controllers
class CommentsController < ActionController::Base # :nodoc:
  include Rails.application.routes.url_helpers
  include Pagy::Method

  def index
    @pagy, @comments = pagy(:offset, Comment.all, limit: 10, client_max_limit: 100)
    # Reload the page in the network tab of the Chrome Inspector to check
    # response.headers.merge!(@pagy.headers_hash)
    render inline: TEMPLATE
  end
end

# You don't need this in real rails apps (see https://ddnexus.github.io/pagy/resources/javascripts)
class PagyController < ActionController::Base
  def javascripts
    format = params[:file].split('.').last
    if format == 'js'
      render js: Pagy::ROOT.join('javascripts', params[:file]).read
    elsif format == 'map'
      render json: Pagy::ROOT.join('javascripts', params[:file]).read
    end
  end
end

run PagyRails

TEMPLATE = <<~ERB
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <title>Pagy Rails App</title>
      <script src="/javascripts/pagy.js"></script>
      <script>
        window.addEventListener("load", Pagy.init);
      </script>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style type="text/css">
        @media screen { html, body {
          font-size: 1rem;
          line-height: 1.2;
          padding: 0;
          margin: 0;
        } }
        body {
          background: white !important;
          margin: 0 !important;
          font-family: sans-serif !important;
        }
        .main-content {
          padding: 1rem 1.5rem 2rem !important;
        }
        .pagy, .pagy-bootstrap, .pagy-bulma {
          padding: .5em;
          margin: .3em 0;
          width: fit-content;
          box-shadow: 5px 5px 10px 0px rgba(0,0,0,0.2);
        }

        /* Quick demo for overriding the element style attribute of certain pagy helpers
        .pagy input[style] {
          width: 5rem !important;
        }
        */

        /*
          If you want to customize the style,
          please replace the line below with the actual file content
        */
        <%== Pagy::ROOT.join('stylesheets/pagy.css').read %>
      </style>
    </head>

    <body>

      <div class="main-content">
        <h1>Pagy Rails App</h1>
        <p> Self-contained, standalone Rails app usable to easily reproduce any rails related pagy issue.</p>

        <h2>Versions</h2>
        <ul>
          <li>Ruby:  <%== RUBY_VERSION %></li>
          <li>Rack:  <%== Rack::RELEASE %></li>
          <li>Rails: <%== Rails.version %></li>
          <li>Pagy:  <%== Pagy::VERSION %></li>
        </ul>

        <h3>Collection</h3>
        <div id="records" class="collection">
        <% @comments.each do |comment| %>
          <p style="margin: 0;"><%= comment.body %></p>
        <% end %>
        </div>

        <hr>

        <h4>@pagy.series_nav</h4>
        <%== @pagy.series_nav(id: 'series-nav',
                              aria_label: 'Pages nav') %>

        <h4>@pagy.series_nav_js</h4>
        <%== @pagy.series_nav_js(id: 'series-nav-js',
                                 aria_label: 'Pages nav_js') %>

        <h4>@pagy.input_nav_js</h4>
        <%== @pagy.input_nav_js(id: 'input-nav-js',
                                aria_label: 'Pages input_nav_js') %>

        <h4>@pagy.limit_tag_js</h4>
        <%== @pagy.limit_tag_js(id: 'limit-tag-js') %>

        <h4>@pagy.info_tag</h4>
        <%== @pagy.info_tag(id: 'pagy-info') %>
      </div>

    </body>
  </html>
ERB
