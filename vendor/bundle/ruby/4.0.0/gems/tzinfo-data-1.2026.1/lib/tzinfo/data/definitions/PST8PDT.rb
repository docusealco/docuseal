# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module PST8PDT
        include TimezoneDefinition
        
        linked_timezone 'PST8PDT', 'America/Los_Angeles'
      end
    end
  end
end
