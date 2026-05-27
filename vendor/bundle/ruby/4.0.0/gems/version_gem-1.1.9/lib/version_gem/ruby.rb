# frozen_string_literal: true

module VersionGem
  # Helpers for library CI integration against many different versions of Ruby
  module Ruby
    RUBY_VER = ::Gem::Version.new(RUBY_VERSION)

    # Check if the current Ruby version is greater than or equal to the given version
    def gte_minimum_version?(version, engine = "ruby")
      RUBY_VER >= ::Gem::Version.new(version) && ::RUBY_ENGINE == engine
    end
    module_function :gte_minimum_version?

    # Check if the current Ruby version (MAJOR.MINOR) is equal to the given version
    def actual_minor_version?(major, minor, engine = "ruby")
      segs = RUBY_VER.segments
      major.to_i == segs[0] &&
        minor.to_i == segs[1] &&
        ::RUBY_ENGINE == engine
    end
    module_function :actual_minor_version?
  end
end
