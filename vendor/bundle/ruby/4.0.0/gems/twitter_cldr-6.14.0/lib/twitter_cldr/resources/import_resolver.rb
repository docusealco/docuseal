require 'tsort'

module TwitterCldr
  module Resources
    class ImportResolver
      include TSort

      attr_reader :importers, :options

      def initialize(importers = Resources.importer_classes_for_ruby_engine, options = {})
        @importers = importers
        @options = options
      end

      def import
        check_unmet_deps
        import_in_order
      end

      private

      def import_in_order
        tsort.each { |instance| instance.import }
      end

      def tsort_each_node(&block)
        instances.each(&block)
      end

      def tsort_each_child(instance, &block)
        deps_for(instance).map do |dep_class|
          dep = instances.find { |ins| ins.class == dep_class }
          yield dep if dep

          unless options[:allow_missing_dependencies]
            raise "Could not find dependency #{dep_class.name}"
          end
        end
      end

      def check_unmet_deps
        instances.each do |instance|
          check_unmet_instance_deps(instance)
        end
      end

      def check_unmet_instance_deps(instance)
        return if options[:allow_missing_dependencies]

        unmet_deps = unmet_deps_for(instance)

        unless unmet_deps.empty?
          list = unmet_deps.map { |d| d.name }.join(', ')
          raise "#{instance.class} dependencies are not met: #{list}"
        end
      end

      def instances
        @instances ||= importers.map do |importer|
          importer.is_a?(Class) ? importer.new : importer
        end
      end

      def unmet_deps_for(instance)
        deps_for(instance).reject do |dep_class|
          instances.any? { |ins| ins.class == dep_class }
        end
      end

      def deps_for(instance)
        if dep_requirement = instance.requirements[:dependency]
          dep_requirement.importer_classes
        else
          []
        end
      end
    end
  end
end
