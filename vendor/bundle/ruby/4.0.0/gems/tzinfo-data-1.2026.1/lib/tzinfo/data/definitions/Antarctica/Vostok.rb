# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Antarctica
        module Vostok
          include TimezoneDefinition
          
          timezone 'Antarctica/Vostok' do |tz|
            tz.offset :o0, 0, 0, :'-00'
            tz.offset :o1, 25200, 0, :'+07'
            tz.offset :o2, 18000, 0, :'+05'
            
            tz.transition 1957, 12, :o1, -380073600, 4872377, 2
            tz.transition 1994, 1, :o0, 760035600
            tz.transition 1994, 11, :o1, 783648000
            tz.transition 2023, 12, :o2, 1702839600
          end
        end
      end
    end
  end
end
