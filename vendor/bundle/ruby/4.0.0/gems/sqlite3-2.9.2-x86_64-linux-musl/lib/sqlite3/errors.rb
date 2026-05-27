require "sqlite3/constants"

module SQLite3
  class Exception < ::StandardError
    # A convenience for accessing the error code for this exception.
    attr_reader :code

    # If the error is associated with a SQL query, this is the query
    attr_reader :sql

    # If the error is associated with a particular offset in a SQL query, this is the non-negative
    # offset. If the offset is not available, this will be -1.
    attr_reader :sql_offset

    def message
      [super, sql_error].compact.join(":\n")
    end

    private def sql_error
      return nil unless @sql
      return @sql.chomp unless @sql_offset >= 0

      offset = @sql_offset
      sql.lines.flat_map do |line|
        if offset >= 0 && line.length > offset
          blanks = " " * offset
          offset = -1
          [line.chomp, blanks + "^"]
        else
          offset -= line.length if offset
          line.chomp
        end
      end.join("\n")
    end
  end

  class SQLException < Exception; end

  class InternalException < Exception; end

  class PermissionException < Exception; end

  class AbortException < Exception; end

  class BusyException < Exception; end

  class LockedException < Exception; end

  class MemoryException < Exception; end

  class ReadOnlyException < Exception; end

  class InterruptException < Exception; end

  class IOException < Exception; end

  class CorruptException < Exception; end

  class NotFoundException < Exception; end

  class FullException < Exception; end

  class CantOpenException < Exception; end

  class ProtocolException < Exception; end

  class EmptyException < Exception; end

  class SchemaChangedException < Exception; end

  class TooBigException < Exception; end

  class ConstraintException < Exception; end

  class MismatchException < Exception; end

  class MisuseException < Exception; end

  class UnsupportedException < Exception; end

  class AuthorizationException < Exception; end

  class FormatException < Exception; end

  class RangeException < Exception; end

  class NotADatabaseException < Exception; end
end
