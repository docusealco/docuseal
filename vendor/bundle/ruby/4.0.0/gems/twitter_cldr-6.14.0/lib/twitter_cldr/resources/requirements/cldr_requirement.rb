# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'i18n'
require 'net/ftp'
require 'nokogiri'
require 'tempfile'
require 'uri'
require 'zip'

module TwitterCldr
  module Resources
    module Requirements

      class CldrRequirement
        CLDR_URL = "ftp://unicode.org/Public/cldr/%{version}/core.zip".freeze

        attr_reader :version

        def initialize(version)
          @version = version
        end

        def prepare
          # download and unzip if source directory doesn't exist
          unless File.directory?(source_path)
            STDOUT.write("Downloading cldr v#{version}... ")
            download
            puts 'done'
          end

          puts "Using cldr v#{version} from #{source_path}"
        end

        def source_path
          @source_path ||= File.join(TwitterCldr::VENDOR_DIR, "cldr_v#{version}")
        end

        def common_path
          File.join(source_path, 'common')
        end

        def alt?(node)
          !node.attribute('alt').nil?
        end

        def draft?(node)
          draft = node.attribute('draft')
          draft && (
            draft.value == 'unconfirmed' || draft.value == 'provisional'
          )
        end

        def build_data(locale, &block)
          CldrDataBuilder.new(locale_for(locale)).merge_each_ancestor(&block)
        end

        def docset(path, root_locale)
          CldrDocumentSet.new(path, locale_for(root_locale), self)
        end

        def dtd
          @dtd ||= CldrDTD.new(self)
        end

        private

        def locale_for(locale)
          locales[locale] ||= CldrLocale.new(locale, self)
        end

        def locales
          @locales ||= {}
        end

        def cldr_url
          CLDR_URL % { version: version }
        end

        def download
          FileUtils.mkdir_p(source_path)

          uri = URI(cldr_url)
          ext_name = File.extname(cldr_url)
          file_name = File.basename(cldr_url).chomp(ext_name)

          Net::FTP.open(uri.host) do |ftp|
            ftp.login

            Tempfile.open([file_name, ext_name]) do |tmp|
              ftp.getbinaryfile(uri.path, tmp.path)

              Zip::File.open(tmp.path) do |file|
                file.each do |entry|
                  path = File.join(source_path, entry.name)
                  FileUtils.mkdir_p(File.dirname(path))
                  file.extract(entry, path)
                end
              end
            end
          end
        end
      end

    end
  end
end
