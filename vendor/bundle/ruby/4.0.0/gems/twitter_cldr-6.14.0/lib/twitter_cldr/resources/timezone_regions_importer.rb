# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'tzinfo'

module TwitterCldr
  module Resources

    # This class should be used with JRuby in 1.9 mode
    class TimezoneRegionsImporter < Importer
      requirement :icu, Versions.icu_version
      output_path 'shared'
      ruby_engine :jruby

      def execute
        output_path = params.fetch(:output_path)
        FileUtils.mkdir_p(output_path)
        output_file = File.join(output_path, 'timezone_regions.yml')
        File.write(output_file, YAML.dump(regions))
      end

      private

      def regions
        TZInfo::Timezone.all_identifiers.each_with_object({}) do |id, ret|
          is_primary = output.new
          region = zone_meta.getCanonicalCountry(id, is_primary)

          if region
            ret[id.to_sym] = {
              region: region,
              primary: is_primary.value
            }
          end
        end
      end

      def output
        @output ||= requirements[:icu].get_class('com.ibm.icu.util.Output')
      end

      def zone_meta
        @zone_meta ||= requirements[:icu].get_class('com.ibm.icu.impl.ZoneMeta')
      end
    end

  end
end
