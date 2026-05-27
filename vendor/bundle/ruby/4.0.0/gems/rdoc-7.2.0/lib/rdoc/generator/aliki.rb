# frozen_string_literal: true

require 'uri'

##
# Aliki theme for RDoc documentation
#
# Author: Stan Lo
#

class RDoc::Generator::Aliki < RDoc::Generator::Darkfish
  RDoc::RDoc.add_generator self

  def initialize(store, options)
    super
    aliki_template_dir = File.expand_path(File.join(__dir__, 'template', 'aliki'))
    @template_dir = Pathname.new(aliki_template_dir)
  end

  ##
  # Generate documentation. Overrides Darkfish to use Aliki's own search index
  # instead of the JsonIndex generator.

  def generate
    setup

    write_style_sheet
    generate_index
    generate_class_files
    generate_file_files
    generate_table_of_contents
    write_search_index

    copy_static

  rescue => e
    debug_msg "%s: %s\n  %s" % [
      e.class.name, e.message, e.backtrace.join("\n  ")
    ]

    raise
  end

  ##
  # Copy only the static assets required by the Aliki theme. Unlike Darkfish we
  # don't ship embedded fonts or image sprites, so limit the asset list to keep
  # generated documentation lightweight.

  def write_style_sheet
    debug_msg "Copying Aliki static files"
    options = { verbose: $DEBUG_RDOC, noop: @dry_run }

    install_rdoc_static_file @template_dir + 'css/rdoc.css', "./css/rdoc.css", options

    unless @options.template_stylesheets.empty?
      FileUtils.cp @options.template_stylesheets, '.', **options
    end

    Dir[(@template_dir + 'js/**/*').to_s].each do |path|
      next if File.directory?(path)
      next if File.basename(path).start_with?('.')

      dst = Pathname.new(path).relative_path_from(@template_dir)

      install_rdoc_static_file @template_dir + path, dst, options
    end
  end

  ##
  # Build a search index array for Aliki's searcher.

  def build_search_index
    setup

    index = []

    @classes.each do |klass|
      next unless klass.display?

      index << build_class_module_entry(klass)

      klass.constants.each do |const|
        next unless const.display?

        index << build_constant_entry(const, klass)
      end
    end

    @methods.each do |method|
      next unless method.display?

      index << build_method_entry(method)
    end

    index
  end

  ##
  # Write the search index as a JavaScript file
  # Format: var search_data = { index: [...] }
  #
  # We still write to a .js instead of a .json because loading a JSON file triggers CORS check in browsers.
  # And if we simply inspect the generated pages using file://, which is often the case due to lack of the server mode,
  # the JSON file will be blocked by the browser.

  def write_search_index
    debug_msg "Writing Aliki search index"

    index = build_search_index

    FileUtils.mkdir_p 'js' unless @dry_run

    search_index_path = 'js/search_data.js'
    return if @dry_run

    data = { index: index }
    File.write search_index_path, "var search_data = #{JSON.generate(data)};"
  end

  ##
  # Resolves a URL for use in templates. Absolute URLs are returned unchanged.
  # Relative URLs are prefixed with rel_prefix to ensure they resolve correctly from any page.

  def resolve_url(rel_prefix, url)
    uri = URI.parse(url)
    if uri.absolute?
      url
    else
      "#{rel_prefix}/#{url}"
    end
  rescue URI::InvalidURIError
    "#{rel_prefix}/#{url}"
  end

  private

  def build_class_module_entry(klass)
    type = case klass
           when RDoc::NormalClass then 'class'
           when RDoc::NormalModule then 'module'
           else 'class'
           end

    entry = {
      name: klass.name,
      full_name: klass.full_name,
      type: type,
      path: klass.path
    }

    snippet = klass.search_snippet
    entry[:snippet] = snippet unless snippet.empty?
    entry
  end

  def build_method_entry(method)
    type = method.singleton ? 'class_method' : 'instance_method'

    entry = {
      name: method.name,
      full_name: method.full_name,
      type: type,
      path: method.path
    }

    snippet = method.search_snippet
    entry[:snippet] = snippet unless snippet.empty?
    entry
  end

  def build_constant_entry(const, parent)
    entry = {
      name: const.name,
      full_name: "#{parent.full_name}::#{const.name}",
      type: 'constant',
      path: parent.path
    }

    snippet = const.search_snippet
    entry[:snippet] = snippet unless snippet.empty?
    entry
  end
end
