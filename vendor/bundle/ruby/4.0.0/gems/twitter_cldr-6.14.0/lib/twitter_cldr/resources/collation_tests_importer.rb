# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'zip'

module TwitterCldr
  module Resources
    class CollationTestsImporter < Importer

      ZIP_FILE = 'CollationAuxiliary.zip'.freeze

      TEST_FILES = %w[
        CollationTest_CLDR_NON_IGNORABLE.txt
        CollationTest_CLDR_NON_IGNORABLE_SHORT.txt
      ].freeze

      requirement :uca, '6.1.0', [ZIP_FILE]
      output_path 'collation/spec'
      ruby_engine :mri

      private

      def execute
        FileUtils.mkdir_p(output_path)
        zip_path = requirements[:uca].source_path_for(ZIP_FILE)

        Zip::File.open(zip_path) do |zip|
          TEST_FILES.each do |test_file|
            File.open(File.join(output_path, test_file), 'w') do |file|
              file.write(zip.read("CollationAuxiliary/#{test_file}"))
            end
          end
        end
      end

      def output_path
        params[:output_path]
      end
    end
  end
end
