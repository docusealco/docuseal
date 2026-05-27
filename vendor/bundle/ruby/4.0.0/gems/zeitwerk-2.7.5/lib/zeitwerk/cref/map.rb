# frozen_string_literal: true

# Description of the structure
# ----------------------------
#
# This class emulates a hash table whose keys are of type Zeitwerk::Cref.
#
# It is a synchronized 2-level hash.
#
# The keys of the top one, stored in `@map`, are class and module objects, but
# their hash code is forced to be their object IDs because class and module
# objects may not be hashable (https://github.com/fxn/zeitwerk/issues/188).
#
# Then, each one of them stores a hash table with their constants and values.
# Constants are stored as symbols.
#
# For example, if we store values 0, 1, and 2 for the crefs that would
# correspond to `M::X`, `M::Y`, and `N::Z`, the map will look like this:
#
#   { M => { X: 0, Y: 1 }, N => { Z: 2 } }
#
# This structure is internal, so only the needed interface is implemented.
#
# Alternative approaches
# -----------------------
#
# 1. We could also use a 1-level hash whose keys are constant paths. In the
#    example above it would be:
#
#      { "M::X" => 0, "M::Y" => 1, "N::Z" => 2 }
#
#    The gem used this approach for several years.
#
#  2. Write a custom `hash`/`eql?` in Zeitwerk::Cref. Hash code would be
#
#       real_mod_hash(@mod) ^ @cname.hash
#
#     where `real_mod_hash(@mod)` would actually be a call to the real `hash`
#     method in Module. Like what we do for module names to bypass overrides.
#
#  3. Similar to 2, but use
#
#       @mod.object_id ^ @cname.object_id
#
#     as hash code instead.
#
# Benchmarks
# ----------
#
# Writing:
#
#   map - baseline
#   (3) - 1.74x  slower
#   (2) - 2.91x  slower
#   (1) - 3.87x  slower
#
# Reading:
#
#   map - baseline
#   (3) - 1.99x  slower
#   (2) - 2.80x  slower
#   (1) - 3.48x  slower
#
# Extra ball
# ----------
#
# In addition to that, the map is synchronized and provides `delete_mod_cname`,
# which is ad-hoc for the hot path in `const_added`, we do not need to create
# unnecessary cref objects for constants we do not manage (but we do not know in
# advance there).

#: [Value]
class Zeitwerk::Cref::Map # :nodoc: all
  #: () -> void
  def initialize
    @map = {}
    @map.compare_by_identity
    @mutex = Mutex.new
  end

  #: (Zeitwerk::Cref, Value) -> Value
  def []=(cref, value)
    @mutex.synchronize do
      cnames = (@map[cref.mod] ||= {})
      cnames[cref.cname] = value
    end
  end

  #: (Zeitwerk::Cref) -> Value?
  def [](cref)
    @mutex.synchronize do
      @map[cref.mod]&.[](cref.cname)
    end
  end

  #: (Zeitwerk::Cref, { () -> Value }) -> Value
  def get_or_set(cref, &block)
    @mutex.synchronize do
      cnames = (@map[cref.mod] ||= {})
      cnames.fetch(cref.cname) { cnames[cref.cname] = block.call }
    end
  end

  #: (Zeitwerk::Cref) -> Value?
  def delete(cref)
    delete_mod_cname(cref.mod, cref.cname)
  end

  # Ad-hoc for loader_for, called from const_added. That is a hot path, I prefer
  # to not create a cref in every call, since that is global.
  #
  #: (Module, Symbol) -> Value?
  def delete_mod_cname(mod, cname)
    @mutex.synchronize do
      if cnames = @map[mod]
        value = cnames.delete(cname)
        @map.delete(mod) if cnames.empty?
        value
      end
    end
  end

  #: (Value) -> void
  def delete_by_value(value)
    @mutex.synchronize do
      @map.delete_if do |mod, cnames|
        cnames.delete_if { _2 == value }
        cnames.empty?
      end
    end
  end

  # Order of yielded crefs is undefined.
  #
  #: () { (Zeitwerk::Cref) -> void } -> void
  def each_key
    @mutex.synchronize do
      @map.each do |mod, cnames|
        cnames.each_key do |cname|
          yield Zeitwerk::Cref.new(mod, cname)
        end
      end
    end
  end

  #: () -> void
  def clear
    @mutex.synchronize do
      @map.clear
    end
  end

  #: () -> bool
  def empty? # for tests
    @mutex.synchronize do
      @map.empty?
    end
  end
end
