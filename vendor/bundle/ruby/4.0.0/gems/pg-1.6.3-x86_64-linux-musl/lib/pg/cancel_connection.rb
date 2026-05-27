# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )

if defined?(PG::CancelConnection)
	class PG::CancelConnection
		include PG::Connection::Pollable

		alias c_initialize initialize

		def initialize(conn)
			c_initialize(conn)

			# A cancel connection is always to one destination server only.
			# Prepare conninfo_hash with just enough information to allow a shared polling_loop.
			@host = conn.host
			@hostaddr = conn.hostaddr
			@port = conn.port

			@conninfo_hash = {
				host: @host,
				hostaddr: @hostaddr,
				port: @port.to_s,
				connect_timeout: conn.conninfo_hash[:connect_timeout],
			}
		end

		# call-seq:
		#    conn.cancel
		#
		# Requests that the server abandons processing of the current command in a blocking manner.
		#
		# If the cancel request wasn't successfully dispatched an error message is raised.
		#
		# Successful dispatch of the cancellation is no guarantee that the request will have any effect, however.
		# If the cancellation is effective, the command being canceled will terminate early and raises an error.
		# If the cancellation fails (say, because the server was already done processing the command), then there will be no visible result at all.
		#
		def cancel
			start
			polling_loop(:poll)
		end
		alias async_cancel cancel

		# These private methods are there to allow a shared polling_loop.
		private
		attr_reader :host
		attr_reader :hostaddr
		attr_reader :port
		attr_reader :conninfo_hash
	end
end
