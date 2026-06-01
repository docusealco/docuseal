module FactoryBot
  # @api private
  class AttributeAssigner
    def initialize(evaluator, build_class, &instance_builder)
      @build_class = build_class
      @instance_builder = instance_builder
      @evaluator = evaluator
      @attribute_list = evaluator.class.attribute_list
      @attribute_names_assigned = []
    end

    # constructs an object-based factory product
    def object
      @evaluator.instance = build_class_instance
      build_class_instance.tap do |instance|
        attributes_to_set_on_instance.each do |attribute|
          instance.public_send(:"#{attribute}=", get(attribute))
          @attribute_names_assigned << attribute
        end
      end
    end

    # constructs a Hash-based factory product
    def hash
      @evaluator.instance = build_hash

      attributes_to_set_on_hash.each_with_object({}) do |attribute, result|
        result[attribute] = get(attribute)
      end
    end

    private

    # Track evaluation of methods on the evaluator to prevent the duplicate
    # assignment of attributes accessed and via `initialize_with` syntax
    def method_tracking_evaluator
      @method_tracking_evaluator ||= Decorator::AttributeHash.new(
        decorated_evaluator,
        attribute_names_to_assign
      )
    end

    def decorated_evaluator
      Decorator::NewConstructor.new(
        Decorator::InvocationTracker.new(@evaluator),
        @build_class
      )
    end

    def methods_invoked_on_evaluator
      method_tracking_evaluator.__invoked_methods__
    end

    def build_class_instance
      @build_class_instance ||= method_tracking_evaluator.instance_exec(&@instance_builder)
    end

    def build_hash
      @build_hash ||= NullObject.new(hash_instance_methods_to_respond_to)
    end

    def get(attribute_name)
      @evaluator.send(attribute_name)
    end

    def attributes_to_set_on_instance
      (attribute_names_to_assign - @attribute_names_assigned - methods_invoked_on_evaluator).uniq
    end

    def attributes_to_set_on_hash
      attribute_names_to_assign - association_names
    end

    # Builds a list of attributes names that should be assigned to the factory product
    def attribute_names_to_assign
      @attribute_names_to_assign ||= begin
        # start a list of candidates containing non-transient attributes and overrides
        assignment_candidates = non_ignored_attribute_names + override_names
        # then remove any transient attributes (potentially reintroduced by the overrides),
        # and remove ignorable aliased attributes from the candidate list
        assignment_candidates - ignored_attribute_names - attribute_names_overriden_by_alias
      end
    end

    def non_ignored_attribute_names
      @attribute_list.non_ignored.names
    end

    def ignored_attribute_names
      @attribute_list.ignored.names
    end

    def association_names
      @attribute_list.associations.names
    end

    def override_names
      @evaluator.__override_names__
    end

    def attribute_names
      @attribute_list.names
    end

    def hash_instance_methods_to_respond_to
      attribute_names + override_names + @build_class.instance_methods
    end

    # Builds a list of attribute names which are slated to be interrupted by an override.
    def attribute_names_overriden_by_alias
      @attribute_list
        .non_ignored
        .flat_map { |attribute|
          override_names.map do |override|
            attribute.name if ignorable_alias?(attribute, override)
          end
        }
        .compact
    end

    # Is the attribute an ignorable alias of the override?
    # An attribute is ignorable when it is an alias of the override AND it is
    # either interrupting an assocciation OR is not the name of another attribute
    #
    # @note An "alias" is currently an overloaded term for two distinct cases:
    #   (1) attributes which are aliases and reference the same value
    #   (2) a logical grouping of a foreign key and an associated object
    def ignorable_alias?(attribute, override)
      return false unless attribute.alias_for?(override)

      # The attribute alias should be ignored when the override interrupts an association
      return true if override_interrupts_association?(attribute, override)

      # Remaining aliases should be ignored when the override does not match a declared attribute.
      # An override which is an alias to a declared attribute should not interrupt the aliased
      # attribute and interrupt only the attribute with a matching name. This workaround allows a
      # factory to declare both <attribute> and <attribute>_id as separate and distinct attributes.
      !override_matches_declared_attribute?(override)
    end

    # Does this override interrupt an association?
    # When true, this indicates the aliased attribute is related to a declared association and the
    # override does not match the attribute name.
    #
    # @note Association overrides should take precedence over a declared foreign key attribute.
    #
    # @note An override may interrupt an association by providing the associated object or
    #   by providing the foreign key.
    #
    # @param [FactoryBot::Attribute] aliased_attribute
    # @param [Symbol] override name of an override which is an alias to the attribute name
    def override_interrupts_association?(aliased_attribute, override)
      (aliased_attribute.association? || association_names.include?(override)) &&
        aliased_attribute.name != override
    end

    # Does this override match the name of any declared attribute?
    #
    # @note Checking against the names of all attributes, resolves any issues with having both
    #   <attribute> and <attribute>_id in the same factory. This also takes into account ignored
    #   attributes that should not be assigned (aka transient attributes)
    #
    # @param [Symbol] override the name of an override
    def override_matches_declared_attribute?(override)
      attribute_names.include?(override)
    end
  end
end
