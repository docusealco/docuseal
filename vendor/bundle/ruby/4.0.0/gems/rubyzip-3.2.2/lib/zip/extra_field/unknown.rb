# frozen_string_literal: true

require_relative 'generic'

module Zip
  # A class to hold unknown extra fields so that they are preserved.
  class ExtraField::Unknown < ExtraField::Generic # :nodoc:
    def initialize
      @local_bin = +''
      @cdir_bin = +''
    end

    def merge(binstr, local: false)
      return if binstr.empty?

      if local
        @local_bin << binstr
      else
        @cdir_bin << binstr
      end
    end

    def to_local_bin
      @local_bin
    end

    def to_c_dir_bin
      @cdir_bin
    end

    def ==(other)
      @local_bin == other.to_local_bin && @cdir_bin == other.to_c_dir_bin
    end
  end
end
