# frozen_string_literal: true
##
# A TopLevel context is a representation of the contents of a single file

class RDoc::TopLevel < RDoc::Context

  MARSHAL_VERSION = 0 # :nodoc:

  ##
  # Relative name of this file

  attr_accessor :relative_name

  ##
  # Absolute name of this file

  attr_accessor :absolute_name

  ##
  # Base name of this file

  attr_reader :base_name

  ##
  # Base name of this file without the extension

  attr_reader :page_name

  ##
  # All the classes or modules that were declared in
  # this file. These are assigned to either +#classes_hash+
  # or +#modules_hash+ once we know what they really are.

  attr_reader :classes_or_modules

  ##
  # The parser class that processed this file

  attr_reader :parser

  ##
  # Creates a new TopLevel for the file at +absolute_name+.  If documentation
  # is being generated outside the source dir +relative_name+ is relative to
  # the source directory.

  def initialize(absolute_name, relative_name = absolute_name)
    super()
    @name = nil
    @absolute_name = absolute_name
    @relative_name = relative_name
    @parser        = nil

    if relative_name
      @base_name = File.basename(relative_name)
      @page_name = @base_name.sub(/\.(rb|rdoc|txt|md)\z/i, '')
    else
      @base_name = nil
      @page_name = nil
    end

    @classes_or_modules = []
  end

  ##
  # Sets the parser for this toplevel context, also the store.

  def parser=(val)
    @parser = val
    @store.update_parser_of_file(absolute_name, val) if @store
    @parser
  end

  ##
  # An RDoc::TopLevel is equal to another with the same relative_name

  def ==(other)
    self.class === other and @relative_name == other.relative_name
  end

  alias eql? ==

  ##
  # Adds +an_alias+ to +Object+ instead of +self+.

  def add_alias(an_alias)
    object_class.record_location self
    return an_alias unless @document_self
    object_class.add_alias an_alias
  end

  ##
  # Adds +constant+ to +Object+ instead of +self+.

  def add_constant(constant)
    object_class.record_location self
    return constant unless @document_self
    object_class.add_constant constant
  end

  ##
  # Adds +include+ to +Object+ instead of +self+.

  def add_include(include)
    object_class.record_location self
    return include unless @document_self
    object_class.add_include include
  end

  ##
  # Adds +method+ to +Object+ instead of +self+.

  def add_method(method)
    object_class.record_location self
    return method unless @document_self
    object_class.add_method method
  end

  ##
  # Adds class or module +mod+. Used in the building phase
  # by the Ruby parser.

  def add_to_classes_or_modules(mod)
    @classes_or_modules << mod
  end

  alias name base_name

  ##
  # See RDoc::TopLevel::find_class_or_module
  #--
  # TODO Why do we search through all classes/modules found, not just the
  #       ones of this instance?

  def find_class_or_module(name)
    @store.find_class_or_module name
  end

  ##
  # Finds a class or module named +symbol+

  def find_local_symbol(symbol)
    find_class_or_module(symbol) || super
  end

  ##
  # Finds a module or class with +name+

  def find_module_named(name)
    find_class_or_module(name)
  end

  alias get_module_named find_module_named

  ##
  # Returns the relative name of this file

  def full_name
    @relative_name
  end

  ##
  # An RDoc::TopLevel has the same hash as another with the same
  # relative_name

  def hash
    @relative_name.hash
  end

  ##
  # URL for this with a +prefix+

  def http_url
    @relative_name.tr('.', '_') + '.html'
  end

  def inspect # :nodoc:
    "#<%s:0x%x %p modules: %p classes: %p>" % [
      self.class, object_id,
      base_name,
      @modules.map { |n, m| m },
      @classes.map { |n, c| c }
    ]
  end

  ##
  # Dumps this TopLevel for use by ri.  See also #marshal_load

  def marshal_dump
    [
      MARSHAL_VERSION,
      @relative_name,
      @parser,
      parse(@comment),
    ]
  end

  ##
  # Loads this TopLevel from +array+.

  def marshal_load(array) # :nodoc:
    initialize array[1]

    @parser  = array[2]
    @comment = RDoc::Comment.from_document array[3]
  end

  ##
  # Returns the NormalClass "Object", creating it if not found.
  #
  # Records +self+ as a location in "Object".

  def object_class
    @object_class ||= begin
      oc = @store.find_class_named('Object') || add_class(RDoc::NormalClass, 'Object')
      oc.record_location self
      oc
    end
  end

  ##
  # Path to this file for use with HTML generator output.

  def path
    prefix = options.file_path_prefix
    return http_url unless prefix
    File.join(prefix, http_url)
  end

  def pretty_print(q) # :nodoc:
    q.group 2, "[#{self.class}: ", "]" do
      q.text "base name: #{base_name.inspect}"
      q.breakable

      items = @modules.map { |n, m| m }
      items.concat @modules.map { |n, c| c }
      q.seplist items do |mod| q.pp mod end
    end
  end

  ##
  # Search record used by RDoc::Generator::JsonIndex
  #
  # TODO: Remove this method after dropping the darkfish theme and JsonIndex generator.
  # Use #search_snippet instead for getting documentation snippets.

  def search_record
    return unless @parser < RDoc::Parser::Text

    [
      page_name,
      '',
      page_name,
      '',
      path,
      '',
      search_snippet,
    ]
  end

  ##
  # Returns an HTML snippet of the comment for search results.

  def search_snippet
    return '' if @comment.empty?

    snippet(@comment)
  end

  ##
  # Is this TopLevel from a text file instead of a source code file?

  def text?
    @parser and @parser.include? RDoc::Parser::Text
  end

  def to_s # :nodoc:
    "file #{full_name}"
  end

end
