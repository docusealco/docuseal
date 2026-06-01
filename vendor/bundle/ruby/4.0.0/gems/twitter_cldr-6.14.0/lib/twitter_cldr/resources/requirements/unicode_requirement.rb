# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'net/ftp'
require 'fileutils'

module TwitterCldr
  module Resources
    module Requirements

      class UnicodeRequirement
        UNICODE_URL = "ftp://ftp.unicode.org/Public/%{version}".freeze

        attr_reader :version, :files

        def initialize(version, files)
          @version = version
          @files = files
        end

        def prepare
          files.each do |file|
            unless File.file?(source_path_for(file))
              STDOUT.write("Downloading #{file} from unicode v#{version}... ")
              download(file)
              puts 'done'
            end

            puts "Using #{file} from unicode v#{version}"
          end
        end

        def source_path_for(file)
          File.join(TwitterCldr::VENDOR_DIR, "unicode_v#{version}", file)
        end

        def url
          UNICODE_URL
        end

        private

        def download(file)
          source_path = source_path_for(file)
          FileUtils.mkdir_p(File.dirname(source_path))
          uri = URI(File.join(url % { version: version }, file))

          Net::FTP.open(uri.host) do |ftp|
            ftp.login
            ftp.getbinaryfile(uri.path, source_path)
          end
        end
      end

    end
  end
end
