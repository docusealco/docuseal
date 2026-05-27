module FactoryBot
  # @api private
  class UriManager
    attr_reader :endpoints, :paths, :uri_list

    delegate :size, :any?, :empty?, :each?, :include?, :first, to: :@uri_list
    delegate :build_uri, to: :class

    # Concatenate the parts, sripping leading/following slashes
    # and returning a Symbolized String or nil.
    #
    # Example:
    #   build_uri(:my_factory, :my_trait, :my_sequence)
    #   #=> :"myfactory/my_trait/my_sequence"
    #
    def self.build_uri(*parts)
      return nil if parts.empty?

      parts.join("/")
        .sub(/\A\/+/, "")
        .sub(/\/+\z/, "")
        .tr(" ", "_")
        .to_sym
    end

    # Configures the new UriManager
    #
    # Arguments:
    #   endpoints: (Array of Strings or Symbols)
    #     the objects endpoints.
    #
    #   paths: (Array of Strings or Symbols)
    #     the parent URIs to prepend to each endpoint
    #
    def initialize(*endpoints, paths: [])
      if endpoints.empty?
        fail ArgumentError, "wrong number of arguments (given 0, expected 1+)"
      end

      @uri_list = []
      @endpoints = endpoints.flatten
      @paths = Array(paths).flatten

      build_uri_list
    end

    def to_a
      @uri_list.dup
    end

    private

    def build_uri_list
      @endpoints.each do |endpoint|
        if @paths.any?
          @paths.each { |path| @uri_list << build_uri(path, endpoint) }
        else
          @uri_list << build_uri(endpoint)
        end
      end
    end
  end
end
