# frozen_string_literal: true

module Aws
  module Partitions
    # @api private
    module Metadata
      class << self

        # aws.partition(region: string) Option<Partition>
        def partition(region)
          partition =
            partitions.find { |p| p['regions']&.fetch(region, nil) } ||
            partitions.find { |p| region.match(p['regionRegex']) } ||
            partitions.find { |p| p['id'] == 'aws' }

          return nil unless partition

          partition['outputs']
        end

        def partitions
          @partitions ||= default_partition_metadata
        end

        def default_partition_metadata
          path = File.expand_path('../../../partitions-metadata.json', __FILE__)
          JSON.parse(File.read(path), freeze: true)['partitions']
        end
      end
    end
  end
end