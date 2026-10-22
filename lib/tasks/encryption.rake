# frozen_string_literal: true

namespace :encryption do
  desc 'Re-encrypt every encrypted attribute with the current SECRET_KEY_BASE (run with SECRET_KEY_BASE_PREVIOUS set)'
  task reencrypt: :environment do
    [EncryptedConfig, EncryptedUserConfig, AccessToken].each do |model|
      count = 0

      model.find_each do |record|
        record.encrypt
        count += 1
      end

      puts "#{model.name}: #{count} re-encrypted"
    end
  end
end
