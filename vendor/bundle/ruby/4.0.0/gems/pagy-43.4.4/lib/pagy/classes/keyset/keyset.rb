# frozen_string_literal: true

require 'json'
require_relative '../../modules/b64'

class Pagy
  # Implement wicked-fast keyset pagination for big data
  class Keyset < Pagy
    # Autoload adapters: files are loaded only when const_get accesses them
    module Adapters
      path = Pathname.new(__dir__)
      autoload :ActiveRecord, path.join('adapters/active_record')
      autoload :Sequel,       path.join('adapters/sequel')
    end

    autoload :Keynav, Pathname.new(__dir__).join('keynav')

    # Define empty subclasses to allow specific typing without triggering autoload
    class ActiveRecord < self; end
    class Sequel       < self; end

    class TypeError < ::TypeError; end

    # Factory method: detects the set type, configures the subclass, and instantiates
    def self.new(set, **)
      # 1. Handle direct subclass usage (e.g. Pagy::Keyset::ActiveRecord.new)
      if /::(?:ActiveRecord|Sequel)$/.match?(name)
        # Ensure the adapter is mixed in (lazy load)
        mix_in_adapter(name.split('::').last)
        return allocate.tap { _1.send(:initialize, set, **) }
      end

      # 2. Handle Factory usage (Pagy::Keyset.new)
      adapter = if defined?(::ActiveRecord) && set.is_a?(::ActiveRecord::Relation)
                  :ActiveRecord
                elsif defined?(::Sequel) && set.is_a?(::Sequel::Dataset)
                  :Sequel
                else
                  raise TypeError, "expected an ActiveRecord::Relation or Sequel::Dataset; got #{set.class}"
                end

      const_get(adapter).tap { _1.mix_in_adapter(adapter) }.new(set, **)
    end

    # Helper to lazy-include the adapter module
    def self.mix_in_adapter(adapter)
      adapter_module = Adapters.const_get(adapter)
      include(adapter_module) unless self < adapter_module
    end

    def initialize(set, **)
      assign_options(**)
      assign_and_check(limit: 1)
      @set    = set
      @keyset = @options[:keyset] || extract_keyset
      raise InternalError, 'the set must be ordered' if @keyset.empty?

      @identifiers = quoted_identifiers(@set.model.table_name)

      assign_page
      self.next
    end

    # Return the array of records for the current page
    def records
      @records ||= begin
                     ensure_select
                     fetch_records
                   end
    end

    # Return the next page (i.e., the cutoff of the current page)
    def next
      records
      return unless @more

      @next ||= B64.urlsafe_encode(extract_cutoff.to_json)
    end

    protected

    def keyset? = true

    def assign_page
      return unless (@page = @options[:page])

      @prior_cutoff = JSON.parse(B64.urlsafe_decode(@page))
    end

    def fetch_records
      apply_where(compose_predicate, arguments_from(@prior_cutoff)) if @prior_cutoff
      @set.limit(@limit + 1).to_a.tap do |records|
        @more = records.size > @limit && !records.pop.nil?
      end
    end

    # Compose the parameterized predicate used to extract the page records.
    #
    # For example, with a set like Pet.order(animal: :asc, name: :desc, id: :asc)
    # it returns a union of intersections:
    #
    #    ("pets"."animal" = :animal AND "pets"."name" = :name AND "pets"."id" > :id) OR
    #    ("pets"."animal" = :animal AND "pets"."name" < :name) OR
    #    ("pets"."animal" > :animal)
    #
    # When :tuple_comparison is enabled, and if the order is all :asc or all :desc,
    # with a set like Pet.order(:animal, :name, :id) it returns the following string:
    #
    #     ("pets"."animal", "pets"."name", "pets"."id") > (:animal, :name, :id)
    #
    def compose_predicate(prefix = nil)
      operator    = { asc: '>', desc: '<' }
      directions  = @keyset.values
      identifier  = @identifiers
      placeholder = @keyset.to_h { |column| [column, ":#{prefix}#{column}"] }

      return "(#{identifier.values.join(', ')}) #{operator[directions.first]} (#{placeholder.values.join(', ')})" \
             if @options[:tuple_comparison] && (directions.all?(:asc) || directions.all?(:desc))

      keyset = @keyset.to_a
      ors    = []
      until keyset.empty?
        column, direction = keyset.pop
        ands = keyset.map { |k, _| "#{identifier[k]} = #{placeholder[k]}" }
        ands << "#{identifier[column]} #{operator[direction]} #{placeholder[column]}"
        ors << "(#{ands.join(' AND ')})"
      end
      query = ors.join(' OR ')

      return query unless @keyset.size > 1

      # Add hint predicate for DB optimizers that struggle with ORs
      column, direction = @keyset.first
      hint = "#{identifier[column]} #{operator[direction]}= #{placeholder[column]}"
      "#{hint} AND (#{query})"
    end

    # Return the prefixed arguments from a cutoff
    def arguments_from(cutoff, prefix = nil)
      attributes = typecast(@keyset.keys.zip(cutoff).to_h)
      prefix ? attributes.transform_keys { |key| :"#{prefix}#{key}" } : attributes
    end

    # Extract the cutoff from the last record (only called if @more)
    def extract_cutoff
      attributes = keyset_attributes_from(@records.last)
      @options[:pre_serialize]&.(attributes)
      attributes.values
    end
  end
end
