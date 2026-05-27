# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'open-uri'

module TwitterCldr
  module Resources

    class LanguageCodesImporter < Importer

      BCP_47_FILE, ISO_639_FILE = %w[bcp-47.txt iso-639.txt]

      INPUT_DATA = {
        BCP_47_FILE  => 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry',

        # docs: https://iso639-3.sil.org/code_tables/download_tables#639-3%20Code%20Set
        ISO_639_FILE => 'https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3.tab'
      }

      KEYS_TO_STANDARDS = {
        Part1:      :iso_639_1,
        Part2B:     :iso_639_2,
        Part2T:     :iso_639_2_term,
        Id:         :iso_639_3,
        bcp_47:     :bcp_47,
        bcp_47_alt: :bcp_47_alt
      }.freeze

      STANDARDS_TO_KEYS = KEYS_TO_STANDARDS.invert.freeze

      output_path 'shared'
      ruby_engine :mri

      private

      def execute
        prepare_data
        import_data
      end

      def prepare_data
        INPUT_DATA.each do |file, url|
          source_path = source_path_for(file)

          unless File.exist?(source_path)
            open(source_path, 'wb') { |file| file << URI.open(url).read }
          end
        end
      end

      def source_path_for(file)
        File.join(TwitterCldr::VENDOR_DIR, file)
      end

      def import_data
        result = import_iso_639
        result = import_bcp_47(result)

        language_codes = Hash[result.inject({}) { |memo, (key, value)| memo[key] = Hash[value.sort]; memo }.sort]
        language_codes_table = build_table(language_codes)

        write('language_codes_table.dump', Marshal.dump(language_codes_table))
      end

      def write(file, data)
        File.write(File.join(params.fetch(:output_path), file), data)
      end

      # Generates codes in the following format:
      #
      # {
      #   :Albanian => {
      #     :iso_639_1      => "sq",
      #     :iso_639_2      => "alb", # default (bibliographic) code
      #     :iso_639_2_term => "sqi", # terminology code (optional)
      #     :iso_639_3      => "sqi"
      #   }
      # }
      #
      def import_iso_639(result = {})
        File.open(source_path_for(ISO_639_FILE)) do |file|
          lines = file.each_line
          lines.next # skip header

          lines.each do |line|
            entry = line.chomp.gsub(/"(.*)"/) { $1.gsub("\t", '') }
            data = Hash[ISO_639_COLUMNS.zip(entry.split("\t"))]
            h = result[data[:Ref_Name].to_sym] ||= {}

            STANDARDS_TO_KEYS.each do |standard_key, data_key|
              value = data[data_key]
              h[standard_key] = value.to_sym if value && !value.empty?
            end
          end
        end

        result
      end

      # Generates codes in the following format:
      #
      # {
      #   :Bangka => {
      #       :bcp_47     => "mfb",   # preferred code
      #       :bcp_47_alt => "ms-mfb" # alternative code (optional)
      #   }
      # }
      def import_bcp_47(result = {})
        File.open(source_path_for(BCP_47_FILE)) do |file|
          lines = file.each_line
          lines.next # skip header

          data  = {}
          entry = ''

          lines.each do |line|
            line.chomp!

            if line == '%%'
              process_bcp_47_entry(entry, data)
              process_bcp_47_data(data, result)
            else
              if line.include?(':')
                process_bcp_47_entry(entry, data)
                entry = line
              else
                entry += line
              end
            end
          end

          process_bcp_47_entry(entry, data)
          process_bcp_47_data(data, result)
        end

        result
      end

      def process_bcp_47_entry(entry, data)
        return if entry.nil? || entry.empty?

        key, value = entry.chomp.split(':', 2).map(&:strip)

        if key == 'Description'
          (data['names'] ||= []) << value.to_sym
        else
          data[key.downcase] = value
        end

        entry.clear
      end

      def process_bcp_47_data(data, result)
        if !data.empty? && %w[language extlang].include?(data['type']) && !data['names'].include?('Private use') && data['scope'] != 'collection'
          existing_names = data['names'].select { |name| result.has_key?(name) }

          prefered    = data['preferred-value']
          alternative = [data['prefix'], data['subtag']].compact.join('-')

          bcp_47 = {}

          bcp_47[:bcp_47]     = (prefered || alternative).to_sym
          bcp_47[:bcp_47_alt] = alternative.to_sym if prefered

          existing_names.each do |name|
            result[name.to_sym].merge!(bcp_47)
          end

          bcp_47.merge!(result[existing_names.first]) unless existing_names.empty?

          (data['names'] - existing_names).each do |name|
            result[name.to_sym] = bcp_47.dup
          end
        end

        data.clear
      end

      def build_table(language_codes_map)
        # can't use Hash with default proc here, because we won't be able to marshal this hash later in this case
        table = ([:name] + KEYS_TO_STANDARDS.values.uniq.sort_by(&:to_s)).inject({}) do |memo, key|
          memo.merge!(key => {})
        end

        language_codes_map.each do |name, codes|
          table[:name][name] = { name: name }.merge(codes)
        end

        table[:name].each_pair do |name, standards|
          STANDARDS_TO_KEYS.each do |standard, _|
            if standards[standard]
              table[standard.to_sym][standards[standard].to_sym] = table[:name][name]
            end
          end
        end

        table.each do |key, codes|
          table[key] = Hash[codes.sort]
        end
      end

      ISO_639_COLUMNS = [
        :Id,       # The three-letter 639-3 identifier
        :Part2B,   # Equivalent 639-2 identifier of the bibliographic applications
                   # code set, if there is one
        :Part2T,   # Equivalent 639-2 identifier of the terminology applications code
                   # set, if there is one
        :Part1,    # Equivalent 639-1 identifier, if there is one
        :Scope,    # I(ndividual), M(acrolanguage), S(pecial)
        :Type,     # A(ncient), C(onstructed),
                   # E(xtinct), H(istorical), L(iving), S(pecial)
        :Ref_Name, # Reference language name
        :Comment   # Comment relating to one or more of the columns
      ].freeze

    end

  end
end
