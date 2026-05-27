# this class is responsible of normalizing the hash of conditions
# by exploding has_many through associations
# when a condition is defined with an has_many through association this is exploded in all its parts
# TODO: it could identify STI and normalize it
module CanCan
  module ModelAdapters
    class ConditionsNormalizer
      class << self
        def normalize(model_class, rules)
          rules.each { |rule| rule.conditions = normalize_conditions(model_class, rule.conditions) }
        end

        def normalize_conditions(model_class, conditions)
          return conditions unless conditions.is_a? Hash

          conditions.each_with_object({}) do |(key, value), result_hash|
            if value.is_a? Hash
              result_hash.merge!(calculate_result_hash(model_class, key, value))
            else
              result_hash[key] = value
            end
            result_hash
          end
        end

        private

        def calculate_result_hash(model_class, key, value)
          reflection = model_class.reflect_on_association(key)
          unless reflection
            raise WrongAssociationName, "Association '#{key}' not defined in model '#{model_class.name}'"
          end

          if normalizable_association? reflection
            key = reflection.options[:through]
            value = { reflection.source_reflection_name => value }
            reflection = model_class.reflect_on_association(key)
          end

          { key => normalize_conditions(reflection.klass.name.constantize, value) }
        end

        def normalizable_association?(reflection)
          reflection.options[:through].present? && !reflection.options[:source_type].present?
        end
      end
    end
  end
end
