# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    class HyphenationImporter < Importer
      GIT_SHA = '0d3b5e5314e68c3cf5d573b2e7bdc11143dcb821'
      REPO_URL = 'git@github.com:LibreOffice/dictionaries.git'
      ENCODING_MAP = {
        'microsoft-cp1251' => Encoding::Windows_1251
      }

      requirement :git, REPO_URL, GIT_SHA
      requirement :dependency, [LocalesResourcesImporter, ValidityDataImporter, UnicodePropertyAliasesImporter]
      output_path 'shared/hyphenation'
      ruby_engine :mri

      def execute
        FileUtils.mkdir_p(output_path)

        each_dictionary do |path, locale|
          import_dictionary(path, locale)
        end
      end

      private

      def import_dictionary(path, locale)
        options = {}
        rules = []

        File.foreach(path).with_index do |line, idx|
          if options[:encoding]
            line.force_encoding(options[:encoding])
            line.encode(Encoding::UTF_8)
          end

          line.strip!

          if idx == 0
            options[:encoding] = lookup_encoding(line)
            next
          end

          next if line.empty?

          # ignore comments
          next if line.start_with?('%') || line.start_with?('#')

          if line =~ /\A[A-Z]+/  # capitals
            option, value = line.split(' ')
            options[option.downcase.to_sym] = value
            next
          end

          rules << line
        end

        # no need to write this out since everything's been re-encoded in UTF-8
        options.delete(:encoding)

        File.write(
          File.join(output_path, "#{locale}.yml"),
          YAML.dump({ options: options, rules: rules })
        )
      end

      def lookup_encoding(encoding)
        ENCODING_MAP.fetch(encoding.downcase, encoding)
      end

      def source_path
        requirements[:git].source_path
      end

      def output_path
        params.fetch(:output_path)
      end

      def each_dictionary
        Dir.glob(File.join(source_path, '**/hyph_*.dic')) do |path|
          locale = TwitterCldr::Shared::Locale.parse(File.basename(path)[5..-5])
          yield path, locale.dasherized
        end
      end
    end

  end
end
