# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'erb'

module TwitterCldr
  module Resources
    class CasefolderClassGenerator < Importer

      requirement :dependency, [UnicodeDataImporter]
      output_path File.join(TwitterCldr::LIB_DIR, 'twitter_cldr', 'shared')
      parameter :template_file, File.join(TwitterCldr::LIB_DIR, 'twitter_cldr', 'resources', 'casefolder.rb.erb')
      ruby_engine :mri

      private

      def execute
        File.open(output_path, 'w+') do |f|
          f.write(
            ERB.new(File.read(template_file)).result(binding)
          )
        end
      end

      def template_file
        params.fetch(:template_file)
      end

      def output_path
        File.join(params.fetch(:output_path), output_file)
      end

      def output_file
        File.basename(template_file).chomp('.erb')
      end

      def casefolding_char_class_for(status)
        to_regex_char_sequence(casefolding_data_for(status))
      end

      def casefolding_hash_for(statuses)
        statuses.inject({}) do |ret, status|
          ret.merge!(casefolding_data_for(status))
          ret
        end
      end

      def inspect_hash_in_lines(hash, per_line, indent)
        str = "{\n#{"  " * indent}"
        hash.each_with_index do |(key, val), idx|
          if idx > 0 && idx % per_line == 0
            str << "\n#{"  " * indent}"
          end
          str << "#{key.inspect}=>#{val.inspect}"
          str << ", " if idx != (hash.size - 1)
        end
        str << "\n#{"  " * (indent - 1)}}"
      end

      def to_regex_char_sequence(casefold_data)
        casefold_data.map { |(source, _)| to_utf8(source) }.join("|")
      end

      def to_utf8(obj)
        arr = obj.is_a?(Array) ? obj : [obj]
        arr.pack("U*").bytes.to_a.map { |s| "\\" + s.to_s(8) }.join
      end

      def casefolding_data_for(status)
        resource.inject({}) do |ret, data|
          ret[data[:source]] = data[:target] if data[:status] == status
          ret
        end
      end

      def resource
        @resource ||= TwitterCldr.get_resource('unicode_data', 'casefolding')
      end

    end
  end
end
