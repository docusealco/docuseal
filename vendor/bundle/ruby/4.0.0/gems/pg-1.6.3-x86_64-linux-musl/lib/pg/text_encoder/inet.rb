# -*- ruby -*-
# frozen_string_literal: true

require 'ipaddr'

module PG
	module TextEncoder
		# This is a encoder class for conversion of Ruby IPAddr values to PostgreSQL inet type.
		#
		# As soon as this class is used, it requires the ruby standard library 'ipaddr'.
		class Inet < SimpleEncoder
			def encode(value)
				case value
				when IPAddr
					default_prefix = (value.family == Socket::AF_INET ? 32 : 128)
					s = value.to_s
					if value.respond_to?(:prefix)
						prefix = value.prefix
					else
						range = value.to_range
						prefix  = default_prefix - Math.log(((range.end.to_i - range.begin.to_i) + 1), 2).to_i
					end
					s << "/" << prefix.to_s if prefix != default_prefix
					s
				else
					value
				end
			end
		end
	end
end # module PG
