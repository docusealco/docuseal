# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class CalendarDataReader < DataReader

      DEFAULT_TYPE = :medium

      TYPE_PATHS = {
        full:       [:full, :pattern],
        long:       [:long, :pattern],
        medium:     [:medium, :pattern],
        short:      [:short, :pattern],
        additional: [:additional_formats]
      }

      class << self
        def types
          TYPE_PATHS.keys
        end
      end

      attr_reader :calendar_type, :type, :additional_format

      def initialize(locale, options = {})
        super(locale)
        @calendar_type = options[:calendar_type] || TwitterCldr::DEFAULT_CALENDAR_TYPE
        @type = options[:type] || type || :default
        @type = DEFAULT_TYPE if type == :default
        @additional_format = options[:additional_format]
      end

      def pattern
        if type == :additional
          additional_format_selector.find_closest(additional_format)
        else
          traverse(path_for(type, calendar_type) + TYPE_PATHS[type])
        end
      end

      def calendar
        @calendar ||= TwitterCldr::Shared::Calendar.new(locale)
      end

      def additional_format_selector
        @format_selector ||= AdditionalDateFormatSelector.new(
          traverse([:calendars, calendar_type, :additional_formats])
        )
      end

      protected

      def path_for(type, calendar_type)
        raise NotImplementedError
      end

      def resource
        @resource ||= begin
          resource = TwitterCldr.get_locale_resource(locale, :calendars)[locale]
          resource[:calendars].each_pair do |calendar_type, options|
            next if calendar_type == TwitterCldr::DEFAULT_CALENDAR_TYPE
            mirror_resource(
              from: resource[:calendars][TwitterCldr::DEFAULT_CALENDAR_TYPE],
              to:   resource[:calendars][calendar_type]
            )
          end
          resource
        end
      end

      def mirror_resource(options)
        from = options[:from]
        to = options[:to]

        from.each_pair do |key, value|
          if !to[key]
            to[key] = from[key]
          else
            if to[key].is_a?(Hash) and from[key].is_a?(Hash)
              mirror_resource(from: from[key], to: to[key])
            end
          end
        end
      end

    end
  end
end