# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )


module PG

	class Error < StandardError
		def initialize(msg=nil, connection: nil, result: nil)
			@connection = connection
			@result = result
			super(msg)
		end
	end

	class NotAllCopyDataRetrieved < PG::Error
	end
	class LostCopyState < PG::Error
	end
	class NotInBlockingMode < PG::Error
	end

	# PG::Connection#transaction uses this exception to distinguish a deliberate rollback from other exceptional situations.
	# Normally, raising an exception will cause the .transaction method to rollback the database transaction and pass on the exception.
	# But if you raise an PG::RollbackTransaction exception, then the database transaction will be rolled back, without passing on the exception.
	class RollbackTransaction < StandardError
	end

end # module PG

