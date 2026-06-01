# frozen_string_literal: true

require 'yaml'
require_relative 'p11n'

class Pagy
  # Pagy i18n implementation, compatible with the I18n gem, just a lot faster and lighter
  module I18n
    class KeyError < KeyError; end

    extend self

    def pathnames
      @pathnames ||= [ROOT.join('locales')]
    end

    def locales
      @locales ||= {}
    end

    # Store the variable for the duration of a single request
    def locale=(value)
      Thread.current[:pagy_locale] = value.to_s
    end

    def locale
      Thread.current[:pagy_locale] || 'en'
    end

    # Translate and pluralize the key with the locale entries
    def translate(key, **options)
      data, p11n = locales[locale] || self.load
      key       += ".#{p11n.plural_for(options[:count])}" if !data[key] && options[:count]

      translation = data[key] or return %([translation missing: "#{key}"])

      translation.gsub(/%{[^}]+?}/) { options.fetch(_1[2..-2].to_sym, _1) } # replace the interpolation placeholders
    end

    private

    def load(locale: self.locale)
      path = pathnames.reverse.map { |p| p.join("#{locale}.yml") }.find(&:exist?)
      unless path
        warn %(Pagy::I18n: missing dictionary file for #{locale.inspect} locale; using "en" instead)
        return locales[locale] = locales['en'] || load(locale: 'en')
      end

      dictionary = YAML.load_file(path)[locale]
      raise KeyError, "missing 'pagy' key in #{locale.inspect} locale" unless dictionary['pagy']

      p11n = dictionary['pagy'].delete('p11n')
      raise KeyError, "missing 'p11n' key in #{locale.inspect} locale" unless p11n

      locales[locale] = [dotify_keys(dictionary), Object.const_get("Pagy::I18n::P11n::#{p11n}")]
    end

    # Flatten a nested hash by "dotifying" its keys
    # e.g. { 'a' => { 'b' => {'c' => 3, 'd' => 4 }}} -> { 'a.b.c' => 3, 'a.b.d' => 4 }
    def dotify_keys(initial, prefix = '')
      initial.each_with_object({}) do |(key, value), hash|
        key = "#{prefix}#{key}"

        if value.is_a?(Hash)
          hash.merge!(dotify_keys(value, "#{key}."))
        else
          hash[key] = value
        end
      end
    end
  end
end
