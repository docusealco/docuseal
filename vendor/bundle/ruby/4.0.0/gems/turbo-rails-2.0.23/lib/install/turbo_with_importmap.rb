say "Import Turbo"
append_to_file "app/javascript/application.js", %(import "@hotwired/turbo-rails"\n)

say "Pin Turbo"
append_to_file "config/importmap.rb", %(pin "@hotwired/turbo-rails", to: "turbo.min.js"\n)
