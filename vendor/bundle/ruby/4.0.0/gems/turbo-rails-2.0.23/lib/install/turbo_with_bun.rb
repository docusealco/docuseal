if (js_entrypoint_path = Rails.root.join("app/javascript/application.js")).exist?
  say "Import Turbo"
  append_to_file "app/javascript/application.js", %(import "@hotwired/turbo-rails"\n)
else
  say "You must import @hotwired/turbo-rails in your JavaScript entrypoint file", :red
end

say "Install Turbo"
run "bun add @hotwired/turbo-rails"
