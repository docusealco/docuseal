require "sqlite3/errors"
require "sqlite3/resultset"

class String
  def to_blob
    SQLite3::Blob.new(self)
  end
end

module SQLite3
  # A statement represents a prepared-but-unexecuted SQL query. It will rarely
  # (if ever) be instantiated directly by a client, and is most often obtained
  # via the Database#prepare method.
  class Statement
    include Enumerable

    # This is any text that followed the first valid SQL statement in the text
    # with which the statement was initialized. If there was no trailing text,
    # this will be the empty string.
    attr_reader :remainder

    # call-seq: SQLite3::Statement.new(db, sql)
    #
    # Create a new statement attached to the given Database instance, and which
    # encapsulates the given SQL text. If the text contains more than one
    # statement (i.e., separated by semicolons), then the #remainder property
    # will be set to the trailing text.
    def initialize(db, sql)
      raise ArgumentError, "prepare called on a closed database" if db.closed?

      sql = sql.encode(Encoding::UTF_8) if sql && sql.encoding != Encoding::UTF_8

      @connection = db
      @columns = nil
      @types = nil
      @remainder = prepare db, sql
    end

    # Binds the given variables to the corresponding placeholders in the SQL
    # text.
    #
    # See Database#execute for a description of the valid placeholder
    # syntaxes.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table where a=? and b=?" )
    #   stmt.bind_params( 15, "hello" )
    #
    # See also #execute, #bind_param, Statement#bind_param, and
    # Statement#bind_params.
    def bind_params(*bind_vars)
      index = 1
      bind_vars.flatten.each do |var|
        if Hash === var
          var.each { |key, val| bind_param key, val }
        else
          bind_param index, var
          index += 1
        end
      end
    end

    # Execute the statement. This creates a new ResultSet object for the
    # statement's virtual machine. If a block was given, the new ResultSet will
    # be yielded to it; otherwise, the ResultSet will be returned.
    #
    # Any parameters will be bound to the statement using #bind_params.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table" )
    #   stmt.execute do |result|
    #     ...
    #   end
    #
    # See also #bind_params, #execute!.
    def execute(*bind_vars)
      reset! if active? || done?

      bind_params(*bind_vars) unless bind_vars.empty?
      results = @connection.build_result_set self

      step if column_count == 0

      yield results if block_given?
      results
    end

    # Execute the statement. If no block was given, this returns an array of
    # rows returned by executing the statement. Otherwise, each row will be
    # yielded to the block.
    #
    # Any parameters will be bound to the statement using #bind_params.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table" )
    #   stmt.execute! do |row|
    #     ...
    #   end
    #
    # See also #bind_params, #execute.
    def execute!(*bind_vars, &block)
      execute(*bind_vars)
      block ? each(&block) : to_a
    end

    # Returns true if the statement is currently active, meaning it has an
    # open result set.
    def active?
      !done?
    end

    # Return an array of the column names for this statement. Note that this
    # may execute the statement in order to obtain the metadata; this makes it
    # a (potentially) expensive operation.
    def columns
      get_metadata unless @columns
      @columns
    end

    def each
      loop do
        val = step
        break self if done?
        yield val
      end
    end

    # Return an array of the data types for each column in this statement. Note
    # that this may execute the statement in order to obtain the metadata; this
    # makes it a (potentially) expensive operation.
    def types
      must_be_open!
      get_metadata unless @types
      @types
    end

    # Performs a sanity check to ensure that the statement is not
    # closed. If it is, an exception is raised.
    def must_be_open! # :nodoc:
      if closed?
        raise SQLite3::Exception, "cannot use a closed statement"
      end
    end

    # Returns a Hash containing information about the statement.
    # The contents of the hash are implementation specific and may change in
    # the future without notice. The hash includes information about internal
    # statistics about the statement such as:
    #   - +fullscan_steps+: the number of times that SQLite has stepped forward
    # in a table as part of a full table scan
    #   - +sorts+: the number of sort operations that have occurred
    #   - +autoindexes+: the number of rows inserted into transient indices
    # that were created automatically in order to help joins run faster
    #   - +vm_steps+: the number of virtual machine operations executed by the
    # prepared statement
    #   - +reprepares+: the number of times that the prepare statement has been
    # automatically regenerated due to schema changes or changes to bound
    # parameters that might affect the query plan
    #   - +runs+: the number of times that the prepared statement has been run
    #   - +filter_misses+: the number of times that the Bloom filter returned
    # a find, and thus the join step had to be processed as normal
    #   - +filter_hits+: the number of times that a join step was bypassed
    # because a Bloom filter returned not-found
    def stat key = nil
      if key
        stat_for(key)
      else
        stats_as_hash
      end
    end

    private

    # A convenience method for obtaining the metadata about the query. Note
    # that this will actually execute the SQL, which means it can be a
    # (potentially) expensive operation.
    def get_metadata
      @columns = Array.new(column_count) do |column|
        column_name column
      end
      @types = Array.new(column_count) do |column|
        val = column_decltype(column)
        val&.downcase
      end
    end
  end
end
