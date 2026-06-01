# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Requirements

      class DependencyRequirement
        attr_reader :importer_classes

        def initialize(importer_classes)
          @importer_classes = importer_classes
        end

        def prepare
        end
      end

    end
  end
end
