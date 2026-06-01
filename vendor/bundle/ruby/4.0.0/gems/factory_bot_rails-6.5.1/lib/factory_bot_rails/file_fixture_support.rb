module FactoryBotRails
  module FileFixtureSupport
    def self.included(klass)
      klass.cattr_accessor :file_fixture_support

      klass.delegate :file_fixture, to: "self.class.file_fixture_support"
    end
  end
end
