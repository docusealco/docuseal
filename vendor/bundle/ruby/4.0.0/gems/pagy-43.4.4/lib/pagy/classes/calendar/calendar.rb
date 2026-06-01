# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/time'

class Pagy
  # Calendar class
  # noinspection RubyMismatchedArgumentType
  class Calendar < Hash
    path = Pathname.new(__dir__)
    autoload :Unit,    path.join('unit')
    autoload :Day,     path.join('day')
    autoload :Week,    path.join('week')
    autoload :Month,   path.join('month')
    autoload :Quarter, path.join('quarter')
    autoload :Year,    path.join('year')

    # List of units in desc order of duration. It can be used for custom units.
    UNITS = %i[year quarter month week day]  # rubocop:disable Style/MutableConstant

    class << self
      # Localize with rails-i18n in any env
      def localize_with_rails_i18n_gem(*locales)
        Unit.prepend(Module.new { def localize(...) = ::I18n.localize(...) })
        # :nocov:
        raise RailsI18nLoadError, "Pagy: The gem 'rails-i18n' must be installed if you don't use Rails" \
              unless (path = Gem.loaded_specs['rails-i18n']&.full_gem_path)

        # :nocov:
        path = Pathname.new(path)
        ::I18n.load_path += locales.map { |locale| path.join("rails/locale/#{locale}.yml") }
      end

      private

      # Return calendar, from, to
      def init(...) = new.send(:init, ...)
    end

    # Return the current time of the smallest time unit shown
    def showtime = self[@units.last].from

    # Return the url for the calendar (shortest unit) page at time
    def url_at(time, **)
      page_keys = {}

      @units.inject(nil) do |parent, unit|
        unit_conf          = @conf[unit]
        unit_conf[:period] = parent&.send(:active_period) || @period
        unit_conf[:page]   = page = create(unit, **unit_conf).send(:page_at, time, **)

        page_keys["#{unit}_#{@page_key}"] = page
        unit_conf[:querify] = ->(params) { params.merge!(page_keys) }

        create(unit, **unit_conf)
      end.send(:compose_page_url, 1, **)
    end

    private

    # Create the calendar
    def init(conf, period, params)
      @conf     = conf
      @units    = Calendar::UNITS & conf.keys # get the units in time length desc order
      @period   = period
      @params   = params
      @page_key = conf[:offset][:page_key] || DEFAULT[:page_key]

      # set all the :page_key options for later deletion
      @units.each { |unit| conf[unit][:page_key] = "#{unit}_#{@page_key}" }

      calendar    = {}
      unit_object = nil

      @units.each_with_index do |unit, index|
        params_to_delete    = @units[(index + 1)..].map { conf[_1][:page_key] } + [@page_key]
        unit_conf           = conf[unit]
        unit_conf[:querify] = ->(up) { up.except!(*params_to_delete.map(&:to_s)) }
        unit_conf[:period]  = unit_object&.send(:active_period) || @period
        unit_conf[:page]    = @params[unit_conf[:page_key]] # requested page
        # :nocov:
        # simplecov doesn't need to fail block_given?
        unit_conf[:counts] = yield(unit, unit_conf[:period]) if block_given?
        # :nocov:
        calendar[unit] = unit_object = create(unit, **unit_conf)
      end

      [replace(calendar), unit_object.from, unit_object.to]
    end

    # Create a unit subclass instance by using the unit name (internal use)
    def create(unit, **)
      raise InternalError, "unit must be in #{UNITS.inspect}; got #{unit}" unless UNITS.include?(unit)

      unit_class = Pagy::Calendar.const_get(unit.to_s.capitalize)

      unit_class.new(**, request: @conf[:request])
    end
  end
end
