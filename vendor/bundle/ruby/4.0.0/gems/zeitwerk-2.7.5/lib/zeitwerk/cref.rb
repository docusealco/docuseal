# frozen_string_literal: true

# This private class encapsulates pairs (mod, cname).
#
# Objects represent the constant `cname` in the class or module object `mod`,
# and have API to manage them. Examples:
#
#   cref.path
#   cref.set(value)
#   cref.get
#
# The constant may or may not exist in `mod`.
class Zeitwerk::Cref
  require_relative "cref/map"

  include Zeitwerk::RealModName

  #: Module
  attr_reader :mod

  #: Symbol
  attr_reader :cname

  # The type of the first argument is Module because Class < Module, class
  # objects are also valid.
  #
  #: (Module, Symbol) -> void
  def initialize(mod, cname)
    @mod   = mod
    @cname = cname
    @path  = nil
  end

  #: () -> String
  def path
    @path ||= Object == @mod ? @cname.name : "#{real_mod_name(@mod)}::#{@cname.name}".freeze
  end
  alias to_s path

  #: () -> String?
  def autoload?
    @mod.autoload?(@cname, false)
  end

  #: (String) -> nil
  def autoload(abspath)
    @mod.autoload(@cname, abspath)
  end

  #: () -> bool
  def defined?
    @mod.const_defined?(@cname, false)
  end

  #: (top) -> top
  def set(value)
    @mod.const_set(@cname, value)
  end

  #: () -> top ! NameError
  def get
    @mod.const_get(@cname, false)
  end

  #: () -> void ! NameError
  def remove
    @mod.__send__(:remove_const, @cname)
  end
end
