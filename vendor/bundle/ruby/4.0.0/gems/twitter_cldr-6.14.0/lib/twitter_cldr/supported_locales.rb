require 'yaml'

module TwitterCldr
  SUPPORTED_LOCALES_FILE = File.expand_path('../../resources/supported_locales.yml', __dir__)
  SUPPORTED_LOCALES = YAML.load_file(SUPPORTED_LOCALES_FILE).freeze
end
