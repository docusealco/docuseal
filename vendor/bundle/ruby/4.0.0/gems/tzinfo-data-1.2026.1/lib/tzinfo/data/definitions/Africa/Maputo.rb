# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Africa
        module Maputo
          include TimezoneDefinition
          
          timezone 'Africa/Maputo' do |tz|
            tz.offset :o0, 7818, 0, :LMT
            tz.offset :o1, 7200, 0, :CAT
            
            tz.transition 1908, 12, :o1, -1924999818, 34823626697, 14400
          end
        end
      end
    end
  end
end
