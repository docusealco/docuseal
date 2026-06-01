# frozen_string_literal: true

module RuboCop
  # Reports information about pending cops that are not explicitly configured.
  #
  # This class is responsible for displaying warnings when new cops have been added to RuboCop
  # but have not yet been enabled or disabled in the user's configuration.
  # It provides a centralized way to determine whether such warnings should be shown,
  # based on global flags or configuration settings.
  class PendingCopsReporter
    class << self
      PENDING_BANNER = <<~BANNER
        The following cops were added to RuboCop, but are not configured. Please set Enabled to either `true` or `false` in your `.rubocop.yml` file.

        Please also note that you can opt-in to new cops by default by adding this to your config:
          AllCops:
            NewCops: enable
      BANNER

      attr_accessor :disable_pending_cops, :enable_pending_cops

      def warn_if_needed(config)
        return if possible_new_cops?(config)

        pending_cops = pending_cops_only_qualified(config.pending_cops)
        warn_on_pending_cops(pending_cops) unless pending_cops.empty?
      end

      private

      def pending_cops_only_qualified(pending_cops)
        pending_cops.select { |cop| Cop::Registry.qualified_cop?(cop.name) }
      end

      def possible_new_cops?(config)
        disable_pending_cops || enable_pending_cops ||
          config.disabled_new_cops? || config.enabled_new_cops?
      end

      def warn_on_pending_cops(pending_cops)
        warn Rainbow(PENDING_BANNER).yellow

        pending_cops.each { |cop| warn_pending_cop cop }

        warn Rainbow('For more information: https://docs.rubocop.org/rubocop/versioning.html').yellow
      end

      def warn_pending_cop(cop)
        version = cop.metadata['VersionAdded'] || 'N/A'

        warn Rainbow("#{cop.name}: # new in #{version}").yellow
        warn Rainbow('  Enabled: true').yellow
      end
    end
  end
end
