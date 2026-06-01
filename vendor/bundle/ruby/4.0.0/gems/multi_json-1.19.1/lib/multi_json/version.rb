module MultiJson
  # Version information for MultiJson
  #
  # @api private
  class Version
    # Major version number
    MAJOR = 1 unless defined? MultiJson::Version::MAJOR
    # Minor version number
    MINOR = 19 unless defined? MultiJson::Version::MINOR
    # Patch version number
    PATCH = 1 unless defined? MultiJson::Version::PATCH
    # Pre-release version suffix
    PRE = nil unless defined? MultiJson::Version::PRE

    class << self
      # Return the version string
      #
      # @api private
      # @return [String] version in semver format
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join(".")
      end
    end
  end

  # Current version string in semver format
  VERSION = Version.to_s.freeze
end
