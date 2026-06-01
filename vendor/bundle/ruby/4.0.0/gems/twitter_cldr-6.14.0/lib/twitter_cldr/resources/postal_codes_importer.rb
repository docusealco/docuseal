# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'json'
require 'open-uri'
require 'set'
require 'yaml'

module TwitterCldr
  module Resources

    class PostalCodesImporter < Importer

      BASE_URL = 'https://chromium-i18n.appspot.com/ssl-address/data/'

      output_path 'shared'
      ruby_engine :mri

      private

      def execute
        data = YAML.dump(fetch_data)
        File.write(File.join(output_path, 'postal_codes.yml'), data)
        puts
      end

      def output_path
        params.fetch(:output_path)
      end

      def fetch_data
        territories = Set.new

        each_territory.each_with_object({}) do |territory, ret|
          if regex = get_regex_for(territory)
            ret[territory] = {
              regex: Regexp.compile(regex),
              ast: TwitterCldr::Utils::RegexpAst.dump(
                RegexpAstGenerator.generate(regex)
              )
            }
          end

          territories.add(territory)
          STDOUT.write("\rImported postal codes for #{territory}, #{territories.size} of #{territory_count} total")
        end
      end

      def get_regex_for(territory)
        result = URI.open("#{BASE_URL}#{territory.to_s.upcase}").read
        data = JSON.parse(result)
        data['zip']
      end

      def territory_count
        TwitterCldr::Shared::Territories.all.size
      end

      def each_territory
        return to_enum(__method__) unless block_given?

        TwitterCldr::Shared::Territories.all.each_pair do |territory, _|
          yield territory
        end
      end

    end

  end
end
