class Trilogy
  class Result
    attr_reader :fields, :rows, :query_time, :affected_rows, :last_insert_id

    EMPTY_ARRAY = [].freeze
    private_constant :EMPTY_ARRAY

    def initialize(fields, rows, query_time, in_transaction, affected_rows, last_insert_id)
      @fields = fields || EMPTY_ARRAY
      @rows = rows || EMPTY_ARRAY
      @query_time = query_time
      @in_transaction = in_transaction
      @affected_rows = affected_rows
      @last_insert_id = last_insert_id
    end

    def in_transaction?
      @in_transaction
    end

    def count
      rows.count
    end

    alias_method :size, :count

    def each_hash
      return enum_for(:each_hash) unless block_given?

      rows.each do |row|
        this_row = {}

        idx = 0
        row.each do |col|
          this_row[fields[idx]] = col
          idx += 1
        end

        yield this_row
      end

      self
    end

    def each(&bk)
      rows.each(&bk)
    end

    include Enumerable
  end
end
