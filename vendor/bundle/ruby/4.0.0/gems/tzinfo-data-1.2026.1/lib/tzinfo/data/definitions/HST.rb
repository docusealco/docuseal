# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module HST
        include TimezoneDefinition
        
        linked_timezone 'HST', 'Pacific/Honolulu'
      end
    end
  end
end
