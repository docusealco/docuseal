# frozen_string_literal: true

class RenameDocusealAatlCert < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(EncryptedConfig)

    EncryptedConfig.where(key: EncryptedConfig::ESIGN_CERTS_KEY).find_each do |config|
      custom = config.value['custom']
      next unless custom.is_a?(Array)

      changed = false
      custom.each do |entry|
        next unless entry.is_a?(Hash) && entry['name'] == 'docuseal_aatl'

        entry['name'] = 'wabosign_aatl'
        changed = true
      end

      config.save!(touch: false) if changed
    end
  end

  def down
    return unless defined?(EncryptedConfig)

    EncryptedConfig.where(key: EncryptedConfig::ESIGN_CERTS_KEY).find_each do |config|
      custom = config.value['custom']
      next unless custom.is_a?(Array)

      changed = false
      custom.each do |entry|
        next unless entry.is_a?(Hash) && entry['name'] == 'wabosign_aatl'

        entry['name'] = 'docuseal_aatl'
        changed = true
      end

      config.save!(touch: false) if changed
    end
  end
end
