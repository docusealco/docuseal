# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

class Eprun
  class << self

    def enable_core_extensions!
      require 'eprun/core_ext/string' unless "".respond_to?(:normalize)
    end

    def ruby18?
      RUBY_VERSION >= "1.8.0" && RUBY_VERSION < "1.9.0"
    end

    def require_path
      ruby18? ? "eprun/ruby18" : "eprun"
    end

    def require_file(file)
      require File.join(require_path, file)
    end

  end
end