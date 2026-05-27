# -*- ruby -*-
# frozen_string_literal: true

require 'json'

module PG
	module TextDecoder
		# This is a decoder class for conversion of PostgreSQL JSON/JSONB type to Ruby Hash, Array, String, Numeric, nil values.
		#
		# As soon as this class is used, it requires the ruby standard library 'json'.
		class JSON < SimpleDecoder
			def decode(string, tuple=nil, field=nil)
				::JSON.parse(string, quirks_mode: true)
			end
		end
	end
end # module PG
