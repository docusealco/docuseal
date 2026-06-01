# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'open-uri'

module TwitterCldr
  module Resources
    module Requirements

      # This requirement makes use of the JarClassLoader package (https://github.com/kamranzafar/JCL)
      # to load ICU in an isolated environment to keep different versions of the
      # library separate. If ICU versions are not kept separate, the one that's
      # first on the classpath wins, which can be surprising if you're not
      # expecting it. Oh, and it can break all the tests.
      class IcuRequirement
        POM_FILE = File.join(TwitterCldr::VENDOR_DIR, 'maven', 'pom.xml').freeze

        attr_reader :version

        def initialize(version)
          @version = version
        end

        def prepare
          pom.add_dependency('com.ibm.icu', 'icu4j', version)
          pom.add_dependency('org.xeustechnologies', 'jcl-core', '2.7')

          pom.install
          pom.require_jar('org.xeustechnologies', 'jcl-core')

          java_import 'org.xeustechnologies.jcl.JarClassLoader'
          class_loader.add(pom.get('com.ibm.icu', 'icu4j').path)
        end

        def get_class(name)
          class_loader.load_class(name).ruby_class
        end

        private

        def class_loader
          @class_loader ||= JarClassLoader.new
        end

        def pom
          @pom ||= PomManager.new(POM_FILE)
        end
      end

    end
  end
end
