module Shakapacker
  module Install
    module Env
      TRUTHY_VALUES = %w[true 1 yes].freeze

      module_function

      def truthy_env?(name)
        TRUTHY_VALUES.include?(ENV[name].to_s.downcase)
      end

      def conflict_option
        if truthy_env?("FORCE")
          { force: true }
        elsif truthy_env?("SKIP")
          { skip: true }
        else
          {}
        end
      end

      # Preserve existing shakapacker.yml when SKIP mode is active, but still
      # update newly-copied files on fresh installs.
      def update_transpiler_config?(transpiler_to_install:, conflict_option:, config_preexisting:)
        return false if transpiler_to_install == "swc"
        return true if conflict_option[:force]
        return true unless conflict_option[:skip]

        !config_preexisting
      end
    end
  end
end
