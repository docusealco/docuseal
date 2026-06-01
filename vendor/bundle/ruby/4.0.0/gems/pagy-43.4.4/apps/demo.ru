# frozen_string_literal: true

# DESCRIPTION
#    Showcase all the helpers and styles
#
# DOC
#    https://ddnexus.github.io/pagy/playground/#demo-app
#
# BIN HELP
#    pagy -h
#
# DEMO USAGE
#    pagy demo
#
# DEV USAGE
#    pagy clone demo
#    pagy ./demo.ru
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
  gem 'rouge'
  gem 'sinatra'
end

# pagy initializer
SECTIONS = { pagy:      { css_anchor: 'pagy-css' },
             tailwind:  { css_anchor: 'pagy-tailwind-css' },
             bootstrap: { style: :bootstrap, classes: 'pagination pagination-sm' },
             bulma:     { style: :bulma, classes: 'pagination is-small' },
             template:  { css_anchor: 'pagy-css', template: :template } }.freeze

# Sinatra setup
require 'sinatra/base'

# Pagy init
Pagy::OPTIONS[:client_max_limit] = 100

# Sinatra application
class PagyDemo < Sinatra::Base
  include Pagy::Method

  get '/' do
    redirect '/pagy'
  end

  get('/javascripts/:file') do
    format = params[:file].split('.').last
    if format == 'js'
      content_type 'application/javascript'
    elsif format == 'map'
      content_type 'application/json'
    end
    send_file Pagy::ROOT.join('javascripts', params[:file])
  end

  get('/stylesheets/:file') do
    content_type 'text/css'
    send_file Pagy::ROOT.join('stylesheets', params[:file])
  end

  if ENV['E2E_TEST']
    get('/assets/:file') do
      content_type 'text/css'
      send_file Pagy::ROOT.join('../test/e2e/assets', params[:file])
    end
  end

  # One route/action per style
  SECTIONS.each do |section, value|
    get("/#{section}") do
      collection      = MockCollection.new
      @pagy, @records = pagy(:offset, collection)
      erb value[:template] || :page,
          locals: { section:,
                    pagy:       @pagy,
                    style:      value[:style],
                    classes:    value[:classes],
                    css_anchor: value[:css_anchor] }
    end
  end

  PAGY_LIKE_HEAD =
    %(#{Pagy.dev_tools unless ENV['E2E_TEST']}
      <style>
        /* black/white backdrop color based on --B */
        .pagy { background-color: hsl(0 0 calc(100 * var(--B))) !important; }
      </style>).freeze

  helpers do
    def style_menu
      html = +%(<div id="style-menu"> )
      SECTIONS.each_key do |section|
        name    = section.to_s
        name[0] = name[0].capitalize
        html << %(<a href="/#{section}">#{name}</a>)
      end
      html << %(</div>)
      html
    end

    def head_for(section)
      case section
      when :pagy, :template
        %(#{PAGY_LIKE_HEAD}
        <link rel="stylesheet" href="/stylesheets/pagy.css">)
      when :tailwind
        %(#{PAGY_LIKE_HEAD}
        #{if ENV['E2E_TEST']
            '<script src="/assets/tailwind.js"></script>'
          else
            '<script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>'
          end}
        <style type="text/tailwindcss">
          #{Pagy::ROOT.join('stylesheets/pagy-tailwind.css').read}
        </style>)
      when :bootstrap
        if ENV['E2E_TEST']
          '<link rel="stylesheet" href="/assets/bootstrap.min.css">'
        else
          '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5/dist/css/bootstrap.min.css">'
        end
      when :bulma
        if ENV['E2E_TEST']
          '<link rel="stylesheet" href="/assets/bulma.min.css">'
        else
          '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1/css/bulma.min.css">'
        end
      end
    end

    def highlight(html, format: :html)
      if format == :html
        html = html.gsub(/>\s*</, '><').strip # template single line no spaces around/between tags
        html = Formatter.new.format(html)
      end
      lexer     = Rouge::Lexers::ERB.new
      formatter = Rouge::Formatters::HTMLInline.new('monokai.sublime')
      summary   = { html: 'Served HTML (pretty formatted)', erb: 'ERB Template' }
      %(<details><summary>#{summary[format]}</summary><pre>\n#{
      formatter.format(lexer.lex(html))
      }</pre></details>)
    end
  end

  # Views
  template :layout do
    <<~HTML
      <!DOCTYPE html>
      <html lang="en" data-theme="light">
      <head>
        <title>Pagy Demo App</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%= head_for(section) %>
        <script src="/javascripts/pagy.js"></script>
        <script>window.addEventListener("load", Pagy.init);</script>
        <% unless ENV['E2E_TEST'] %>
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:ital,opsz,wght@0,6..12,200..1000;1,6..12,200..1000&display=swap" rel="stylesheet">
        <% end %>
        <style>
          @media screen { html, body {
            font-size: 1rem;
            line-height: 1.2;
            padding: 0;
            margin: 0;
          } }
          *,
          *::before,
          *::after {
            box-sizing: border-box;
          }
          html {
            background-color: transparent !important; /* Fix for Bulma */
          }
          body {
            margin: 0 !important;
            font-family: <%= '"Nunito Sans", ' unless ENV['E2E_TEST'] %>"Helvetica Neue", Helvetica, Arial, sans-serif !important;
            color: #303030 !important;
            background-color: #f5f5f5 !important;
          }
          svg {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            z-index: -10;
          }
          h1, h2 {
            font-size: 1.8rem !important;
            font-weight: 600 !important;
            margin-top: 1rem !important;
            margin-bottom: 0.7rem !important;
            line-height: 1.5 !important;
            color: #303030  !important;
          }
          h2 {
            font-family: monospace;
            font-size: .9rem !important;
            margin-top: 1.6rem !important;
          }
          hr {
            height: 0;
            color: inherit;
            border-top-width: 1px;
            border-top-color: gray;
            margin: 8px 0 !important;
          }
          summary, .notes {
            font-size: .8rem;
            margin-top: .6rem;
            font-style: italic;
            cursor: pointer;
          }
          .notes {
            font-family: sans-serif;
            font-weight: normal;
          }
          .notes code{
            background-color: rgba(255, 255, 255, .6);
            padding: 0 0.3rem;
            font-style: normal;
            border-radius: 3px;
          }
          .description {
             margin: 1rem 0;
          }
          .description a {
            color: blue;
            text-decoration: underline;
          }
          pre, pre code {
            display: inline-block;
            margin-top: .3rem;
            margin-bottom: 1rem;
            font-size: .8rem !important;
            line-height: 1rem !important;
            color: white;
            background-color: rgb(30 30 30);
            padding: 1rem;
            overflow-x: auto;
            max-width: 100%;
            white-space: pre;
          }
          .main-content {
            padding: 0 1.5rem 2rem !important;
          }
          #style-menu {
            flex;
            font-family: sans-serif;
            font-size: 1.1rem;
            line-height: 1.5rem;
            white-space: nowrap;
            color: white;
            background-color: rgba(0,0,0,.65);
            padding: .2rem 1.5rem;
          }
          #style-menu > :not([hidden]) ~ :not([hidden]) {
            --space-reverse: 0;
            margin-right: calc(0.5rem * var(--space-reverse));
            margin-left: calc(0.5rem * calc(1 - var(--space-reverse)));
          }
          #style-menu a {
            color: inherit;
            text-decoration: none;
          }
          .pagy, .pagy-bootstrap, .pagy-bulma {
            background-color: white;
            padding: 1.5em;
            margin: .3em 0;
            width: fit-content;
            box-shadow: 8px 8px 18px 0px rgba(0,0,0,0.25);
          }
          span.pagy {
            display: block;
          }
          .pagy-bootstrap .pagination {
            margin: 0;
          }
          /* Demo app custom style */
          .pagy {
            --B: 1;
            --H: 109;
            --S: 40;
            --L: 70;
            --spacing: 0.125rem;
            --padding: 0.75rem;
            --rounding: 0.8125rem;
            --border-width: 0.03125rem;
            --font-size: 0.875rem;
            --font-weight: 450;
            --line-height: 1.75;
          }
        </style>
      </head>
      <body>
        <svg xmlns="http://www.w3.org/2000/svg" width="0" height="0">
          <filter id="noiseFilter">
            <feTurbulence type="fractalNoise" baseFrequency="0.6" numOctaves="100" stitchTiles="stitch" />
            <feColorMatrix type="matrix" values="0.5 0 0 0 0, 0.5 0 0 0 0, 0.5 0 0 0 0, 0 0 0 0.5 0" />
         </filter>
          <rect width="100%" height="100%" filter="url(#noiseFilter)" fill="rgb(255, 255, 255)" />
        </svg>
        <!-- each different class used by each style -->
        <%= style_menu %>
        <div class="main-content">
          <%= yield %>
        </div>
      </body>
      </html>
    HTML
  end

  template :page do
    <<~ERB
      <h1><%= title = section.to_s; title[0] = title[0].capitalize; title %></h1>

      <% if css_anchor %>
        <p>Check the <u><i><b><a href="http://ddnexus.github.io/pagy/resources/stylesheets/#<%= css_anchor %>" target="blank"><%= css_anchor.gsub('-', '.') %></a></b></u></i>
        for details.</p>
      <% end %>
      </p>
      <div id="main-container">
        <div id="content">
          <hr id="top-hr">
          <h2>@records</h2>
          <p id="records"><%= @records.join(',') %></p>

          <h2>@pagy.series_nav<br/>
            <span class="notes">Series nav <code>{slots: 7}</code></span>
          </h2>
          <%= html = @pagy.series_nav(style, classes:,
                                      id: 'series-nav',
                                      aria_label: 'Pages series_nav') %>
          <%= highlight(html) %>

          <h2>@pagy.series_nav_js<br/>
            <span class="notes">Responsive nav: <code>{steps: {0 => 5, 500 => 7, 600 => 9, 700 => 11}}</code><br/>
            (Resize the window to see)
            </span>
          </h2>
          <%= html = @pagy.series_nav_js(style, classes:,
                                         id: 'series-nav-js-responsive',
                                         aria_label: 'Pages series_nav_js_responsive',
                                         steps: { 0 => 5, 500 => 7, 600 => 9, 700 => 11 }) %>
          <%= highlight(html) %>

          <h2>@pagy.input_nav_js</h2>
          <%= html = @pagy.input_nav_js(style, classes:,
                                        id: 'input-nav-js',
                                        aria_label: 'Pages inpup_nav_js') %>
          <%= highlight(html) %>

          <h2>@pagy.limit_tag_js</h2>
          <%= html = @pagy.limit_tag_js(id: 'limit-tag-js') %>
          <%= highlight(html) %>

          <h2>@pagy.info_tag</h2>
          <%= html = @pagy.info_tag(id: 'pagy-info') %>
          <%= highlight(html) %>
        </div>
      </div>
    ERB
  end

  template :template do
     <<~ERB
       <h1>Pagy Template Demo</h1>

       <p class="description">
       See the <a href="https://ddnexus.github.io/pagy/docs/how-to/#using-your-pagination-templates">
       Custom Templates</a> documentation.
       </p>

       <h2>Collection</h2>
       <p id="records">@records: <%= @records.join(',') %></p>

       <h2>Rendered ERB template</h2>

       <div class="backdrop">
         <%# We don't inline the template here, so we can highlight it more easily %>
         <%= html = ERB.new(TEMPLATE).result(binding) %>
       </div>
       <%= highlight(TEMPLATE, format: :erb) %>
       <%= highlight(html) %>
     ERB
   end

  # Easier code highlighting
  TEMPLATE = <<~ERB
    <%# IMPORTANT: replace '<%=' with '<%==' if you run this in rails %>

    <%# The a variable below is set to a lambda that generates the a tag %>
    <%# Usage: anchor_tag = a_lambda.(page_number, text, classes: nil, aria_label: nil) %>
    <% a_lambda = @pagy.send(:a_lambda) %>
    <nav class="pagy series-nav" aria-label="Pages">
      <%# Previous page link %>
      <% if pagy.previous %>
        <%= a_lambda.(pagy.previous, '&lt;', aria_label: 'Previous') %>
      <% else %>
        <a role="link" aria-disabled="true" aria-label="Previous">&lt;</a>
      <% end %>
      <%# Page links (series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]) %>
      <% pagy.send(:series).each do |item| %>
        <% if item.is_a?(Integer) %>
          <%= a_lambda.(item) %>
        <% elsif item.is_a?(String) %>
          <a role="link" aria-disabled="true" aria-current="page"><%= item %></a>
        <% elsif item == :gap %>
          <a role="separator" aria-disabled="true">&hellip;</a>
        <% end %>
      <% end %>
      <%# Next page link %>
      <% if pagy.next %>
        <%= a_lambda.(pagy.next, '&gt;', aria_label: 'Next') %>
      <% else %>
        <a role="link" aria-disabled="true" aria-label="Next">&lt;</a>
      <% end %>
    </nav>
  ERB
end

# Cheap pagy formatter for helpers output
class Formatter
  INDENT     = '  '
  TEXT_SPACE = "\u00B7"
  TEXT       = /^([^<>]+)(.*)/
  UNPAIRED   = /^(<(input|link).*?>)(.*)/
  PAIRED     = %r{^(<(head|nav|div|span|p|a|b|label|ul|li).*?>)(.*?)(</\2>)(.*)}
  WRAPPER    = /<.*?>/
  DATA_PAGY  = /(data-pagy="([^"]+)")/

  def initialize
    @formatted = +''
  end

  def format(input, level = 0)
    process(input, level)
    @formatted
  end

  private

  def process(input, level)
    push = ->(content) { @formatted << ((INDENT * level) << content << "\n") }
    rest = nil
    if (match = input.match(TEXT))
      text, rest = match.captures
      push.(text.gsub(' ', TEXT_SPACE))
    elsif (match = input.match(UNPAIRED))
      tag, _name, rest = match.captures
      push.(tag)
    elsif (match = input.match(PAIRED))
      tag_start, name, block, tag_end, rest = match.captures
      # Handle incomplete same-tag nesting
      while block.scan(/<#{name}.*?>/).size > block.scan(tag_end).size
        more, rest = rest.split(tag_end, 2)
        block << (tag_end + more)
      end
      if (match = tag_start.match(DATA_PAGY))
        search, data = match.captures
        formatted    = data.scan(/.{1,76}/).join("\n")
        replace      = %(\n#{INDENT * (level + 1)}data-pagy="#{formatted}")
        tag_start.sub!(search, replace)
      end
      if block.match(WRAPPER)
        push.(tag_start)
        process(block, level + 1)
        push.(tag_end)
      else
        push.(tag_start << (block + tag_end))
      end
    end
    process(rest, level) if rest
  end
end

# Simple array-based collection that acts as a standard DB collection.
class MockCollection < Array
  def initialize(arr = Array(1..1000))
    super
    @collection = clone
  end

  def offset(value)
    @collection = self[value..] || []
    self
  end

  def limit(value)
    @collection.empty? ? [] : @collection[0, value]
  end

  def count(*)
    size
  end
end

run PagyDemo
