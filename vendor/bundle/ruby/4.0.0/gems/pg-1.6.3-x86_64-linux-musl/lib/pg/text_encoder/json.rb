# -*- ruby -*-
# frozen_string_literal: true

require 'json'

module PG
	module TextEncoder
		# This is a encoder class for conversion of Ruby Hash, Array, String, Numeric, nil values to PostgreSQL JSON/JSONB type.
		#
		# As soon as this class is used, it requires the ruby standard library 'json'.
		class JSON < SimpleEncoder
			def encode(value)
				::JSON.generate(value, quirks_mode: true)
			end
		end
	end
end # module PG
