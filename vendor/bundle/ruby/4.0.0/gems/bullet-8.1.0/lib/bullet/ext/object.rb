# frozen_string_literal: true

module Bullet
  module Ext
    module Object
      refine ::Object do
        attr_writer :bullet_key, :bullet_primary_key_value

        def bullet_key
          return "#{self.class}:" if respond_to?(:persisted?) && !persisted?

          @bullet_key ||= "#{self.class}:#{bullet_primary_key_value}"
        end

        def bullet_primary_key_value
          return if respond_to?(:persisted?) && !persisted?

          @bullet_primary_key_value ||=
            begin
              primary_key = self.class.try(:primary_keys) || self.class.try(:primary_key) || :id

              bullet_join_potential_composite_primary_key(primary_key)
            end
        end

        private

        def bullet_join_potential_composite_primary_key(primary_keys)
          return read_attribute(primary_keys) unless primary_keys.is_a?(Enumerable)

          primary_keys.map { |primary_key| read_attribute primary_key }
                      .compact.join(',')
        end
      end
    end
  end
end
