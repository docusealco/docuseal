# -*- ruby -*-
# frozen_string_literal: true

module PG
	module TextEncoder
		# This is a encoder class for conversion of Ruby Date values to PostgreSQL date type.
		class Date < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value
			end
		end
	end
end # module PG
