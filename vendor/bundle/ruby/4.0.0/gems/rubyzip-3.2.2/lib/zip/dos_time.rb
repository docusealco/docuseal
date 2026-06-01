# frozen_string_literal: true

require 'rubygems'

module Zip
  class DOSTime < Time # :nodoc:all
    # MS-DOS File Date and Time format as used in Interrupt 21H Function 57H:

    # Register CX, the Time:
    # Bits 0-4  2 second increments (0-29)
    # Bits 5-10 minutes (0-59)
    # bits 11-15 hours (0-24)

    # Register DX, the Date:
    # Bits 0-4 day (1-31)
    # bits 5-8 month (1-12)
    # bits 9-15 year (four digit year minus 1980)

    attr_writer :absolute_time # :nodoc:

    def absolute_time?
      # If absolute time is not set, we can assume it is an absolute time
      # because times do have timezone information by default.
      @absolute_time.nil? || @absolute_time
    end

    def to_binary_dos_time
      (sec / 2) +
        (min << 5) +
        (hour << 11)
    end

    def to_binary_dos_date
      day +
        (month << 5) +
        ((year - 1980) << 9)
    end

    # Deprecated. Remove for version 4.
    def dos_equals(other) # rubocop:disable Naming/PredicateMethod
      warn 'Zip::DOSTime#dos_equals is deprecated. Use `==` instead.'
      self == other
    end

    # Dos time is only stored with two seconds accuracy.
    def <=>(other)
      return unless other.kind_of?(Time)

      (to_i / 2) <=> (other.to_i / 2)
    end

    # Create a DOSTime instance from a vanilla Time instance.
    def self.from_time(time)
      local(time.year, time.month, time.day, time.hour, time.min, time.sec)
    end

    def self.parse_binary_dos_format(bin_dos_date, bin_dos_time)
      second = 2 * (0b11111 & bin_dos_time)
      minute = (0b11111100000 & bin_dos_time) >> 5
      hour   = (0b1111100000000000 & bin_dos_time) >> 11
      day    = (0b11111 & bin_dos_date)
      month  = (0b111100000 & bin_dos_date) >> 5
      year   = ((0b1111111000000000 & bin_dos_date) >> 9) + 1980

      time = local(year, month, day, hour, minute, second)
      time.absolute_time = false
      time
    end

    if defined? JRUBY_VERSION && Gem::Version.new(JRUBY_VERSION) < '9.2.18.0'
      module JRubyCMP # :nodoc:
        def ==(other)
          (self <=> other).zero?
        end

        def <(other)
          (self <=> other).negative?
        end

        def <=(other)
          (self <=> other) <= 0
        end

        def >(other)
          (self <=> other).positive?
        end

        def >=(other)
          (self <=> other) >= 0
        end
      end

      include JRubyCMP
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
