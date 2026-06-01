namespace :shakapacker do
  desc "Verifies that bin/shakapacker is present"
  task :check_binstubs do
    verify_file_existence("bin/shakapacker")
    verify_file_existence("bin/shakapacker-dev-server")
  end
end

def verify_file_existence(binstub_file)
  unless File.exist?(Rails.root.join(binstub_file))
    puts <<~MSG
      Couldn't find shakapacker binstubs!
      Possible solutions:
      - Ensure you have run `bundle exec rake shakapacker:install`.
      - Run `bundle exec rake shakapacker:binstubs` if you have already installed shakapacker.
      - Ensure the `bin` directory, `bin/shakapacker`, and `bin/shakapacker-dev-server` are not included in .gitignore.
    MSG
    exit!
  end
end
