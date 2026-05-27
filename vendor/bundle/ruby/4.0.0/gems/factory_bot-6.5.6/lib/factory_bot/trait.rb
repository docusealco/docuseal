module FactoryBot
  # @api private
  class Trait
    attr_reader :name, :uid, :definition

    delegate :add_callback, :declare_attribute, :to_create, :define_trait, :constructor,
      :callbacks, :attributes, :klass, :klass=, to: :@definition

    def initialize(name, **options, &block)
      @name = name.to_s
      @block = block
      @uri_manager = FactoryBot::UriManager.new(names, paths: options[:uri_paths])

      @definition = Definition.new(@name, uri_manager: @uri_manager)
      proxy = FactoryBot::DefinitionProxy.new(@definition)

      if block
        proxy.instance_eval(&@block)
      end
    end

    def clone
      Trait.new(name, uri_paths: definition.uri_manager.paths, &block)
    end

    def names
      [@name]
    end

    def ==(other)
      name == other.name &&
        block == other.block
    end

    protected

    attr_reader :block
  end
end
