# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'yaml'
require 'date'
require 'time'
require 'fileutils'

require 'forwardable'

require 'twitter_cldr/version'
require 'twitter_cldr/supported_locales'

Enumerator = Enumerable::Enumerator unless defined?(Enumerator)

module TwitterCldr

  autoload :Collation,     'twitter_cldr/collation'
  autoload :DataReaders,   'twitter_cldr/data_readers'
  autoload :Formatters,    'twitter_cldr/formatters'
  autoload :Localized,     'twitter_cldr/localized'
  autoload :Normalization, 'twitter_cldr/normalization'
  autoload :Parsers,       'twitter_cldr/parsers'
  autoload :Resources,     'twitter_cldr/resources'
  autoload :Segmentation,  'twitter_cldr/segmentation'
  autoload :Shared,        'twitter_cldr/shared'
  autoload :Tokenizers,    'twitter_cldr/tokenizers'
  autoload :Utils,         'twitter_cldr/utils'
  autoload :Timezones,     'twitter_cldr/timezones'
  autoload :Transforms,    'twitter_cldr/transforms'
  autoload :Versions,      'twitter_cldr/versions'

  extend SingleForwardable

  DEFAULT_LOCALE = :en
  DEFAULT_CALENDAR_TYPE = :gregorian

  RESOURCES_DIR = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'resources')
  VENDOR_DIR = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'vendor')
  LIB_DIR = File.dirname(File.expand_path(__FILE__))
  SPEC_DIR = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'spec')

  # maps twitter locales to cldr locales
  TWITTER_LOCALE_MAP = {
    msa: :ms,
    'zh-cn': :zh,
    'zh-tw': :'zh-Hant',
    no: :nb
  }

  # maps cldr locales to twitter locales
  CLDR_LOCALE_MAP = TWITTER_LOCALE_MAP.invert

  def_delegator :resources, :get_resource
  def_delegator :resources, :get_locale_resource
  def_delegator :resources, :resource_exists?
  def_delegator :resources, :locale_resource_exists?
  def_delegator :resources, :absolute_resource_path
  def_delegator :resources, :resource_file_path

  class << self

    attr_writer :locale
    attr_accessor :disable_custom_locale_resources

    def resources
      @resources ||= TwitterCldr::Resources::Loader.new
    end

    def locale
      # doing all this work in locale getter rather than locale setter makes it possible to use locale fallbacks
      # even if they were configured (or became available) after @locale was already assigned an unsupported locale
      locale = supported_locale?(@locale) ? @locale : find_fallback
      locale = DEFAULT_LOCALE if locale.to_s.empty?
      (supported_locale?(locale) ? locale : DEFAULT_LOCALE).to_sym
    end

    def with_locale(locale)
      raise "Unsupported locale" unless supported_locale?(locale)

      begin
        old_locale = @locale
        @locale = locale
        result = yield
      ensure
        @locale = old_locale
        result
      end
    end

    def register_locale_fallback(proc_or_locale)
      case proc_or_locale
        when Symbol, String, Proc
          locale_fallbacks << proc_or_locale
        else
          raise "A locale fallback must be of type String, Symbol, or Proc."
      end
      nil
    end

    def reset_locale_fallbacks
      locale_fallbacks.clear
      TwitterCldr.register_locale_fallback(lambda { I18n.locale if defined?(I18n) && I18n.respond_to?(:locale) })
      TwitterCldr.register_locale_fallback(lambda { FastGettext.locale if defined?(FastGettext) && FastGettext.respond_to?(:locale) })
    end

    def locale_fallbacks
      @locale_fallbacks ||= []
    end

    def convert_locale(locale)
      locale = normalize_locale(locale)

      unless supported_locale?(locale)
        loc = TwitterCldr::Shared::Locale.parse(locale)
        max_supported = loc.max_supported

        if loc.dasherized == 'und' || !max_supported
          return locale
        end

        locale = normalize_locale(max_supported.dasherized)
      end

      locale
    end

    def normalize_locale(locale)
      return locale unless (locale.is_a?(String) || locale.is_a?(Symbol))

      locale = locale.to_sym
      locale = lowercase_locales_map.fetch(locale, locale)
      TWITTER_LOCALE_MAP.fetch(locale.downcase, locale)
    end

    def twitter_locale(locale)
      locale = locale.to_sym
      CLDR_LOCALE_MAP.fetch(locale, locale)
    end

    def supported_locales
      TwitterCldr::SUPPORTED_LOCALES
    end

    def supported_locale?(locale)
      !!locale && supported_locales.include?(normalize_locale(locale))
    end

    protected

    def find_fallback
      locale_fallbacks.reverse_each do |fallback|
        result = if fallback.is_a?(Proc)
          begin
            fallback.call
          rescue
            nil
          end
        else
          fallback
        end
        return result if result
      end
      nil
    end

    def lowercase_locales_map
      @lowercase_locales_map ||= supported_locales.inject({}) do |memo, locale|
        lowercase = locale.to_s.downcase.to_sym
        memo[lowercase] = locale unless lowercase == locale
        memo
      end
    end

  end

end

TwitterCldr.reset_locale_fallbacks

require 'twitter_cldr/core_ext'
