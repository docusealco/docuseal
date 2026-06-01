# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    class UnicodeFileParser

      class << self
        def parse_standard_file(file)
          if block_given?
            File.open(file) do |input|
              input.each_line do |line|
                unless line[0] == '#'
                  comment_idx = if idx = line.index('#')
                    idx - 1 # consume #
                  else
                    line.size
                  end

                  line = line.chomp[0..comment_idx]
                  if line.size > 0
                    yield line.split(';', -1).map(&:strip)
                  end
                end
              end
            end
          else
            enum_for(__method__, file)
          end
        end
      end

    end
  end
end
