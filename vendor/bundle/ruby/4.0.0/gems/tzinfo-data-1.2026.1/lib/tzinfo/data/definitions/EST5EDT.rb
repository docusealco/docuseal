# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module EST5EDT
        include TimezoneDefinition
        
        linked_timezone 'EST5EDT', 'America/New_York'
      end
    end
  end
end
