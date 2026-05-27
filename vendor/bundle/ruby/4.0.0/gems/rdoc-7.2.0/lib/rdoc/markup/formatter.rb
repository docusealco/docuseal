# frozen_string_literal: true
##
# Base class for RDoc markup formatters
#
# Formatters are a visitor that converts an RDoc::Markup tree (from a comment)
# into some kind of output.  RDoc ships with formatters for converting back to
# rdoc, ANSI text, HTML, a Table of Contents and other formats.
#
# If you'd like to write your own Formatter use
# RDoc::Markup::FormatterTestCase.  If you're writing a text-output formatter
# use RDoc::Markup::TextFormatterTestCase which provides extra test cases.

require 'rdoc/markup/inline_parser'

class RDoc::Markup::Formatter

  ##
  # Tag for inline markup containing a +bit+ for the bitmask and the +on+ and
  # +off+ triggers.

  InlineTag = Struct.new(:bit, :on, :off)


  ##
  # Converts a target url to one that is relative to a given path

  def self.gen_relative_url(path, target)
    from        = File.dirname path
    to, to_file = File.split target

    from = from.split "/"
    to   = to.split "/"

    from.delete '.'
    to.delete '.'

    while from.size > 0 and to.size > 0 and from[0] == to[0] do
      from.shift
      to.shift
    end

    from.fill ".."
    from.concat to
    from << to_file
    File.join(*from)
  end

  ##
  # Creates a new Formatter

  def initialize(options, markup = nil)
    @options = options

    @markup = markup || RDoc::Markup.new

    @from_path = '.'
  end

  ##
  # Adds +document+ to the output

  def accept_document(document)
    document.parts.each do |item|
      case item
      when RDoc::Markup::Document then # HACK
        accept_document item
      else
        item.accept self
      end
    end
  end

  ##
  # Adds a regexp handling for links of the form rdoc-...:

  def add_regexp_handling_RDOCLINK
    @markup.add_regexp_handling(/rdoc-[a-z]+:[^\s\]]+/, :RDOCLINK)
  end

  ##
  # Allows +tag+ to be decorated with additional information.

  def annotate(tag)
    tag
  end

  ##
  # Marks up +content+

  def convert(content)
    @markup.convert content, self
  end

  # Applies regexp handling to +text+ and returns an array of [text, converted?] pairs.

  def apply_regexp_handling(text)
    output = []
    start = 0
    loop do
      pos = text.size
      matched_name = matched_text = nil
      @markup.regexp_handlings.each do |pattern, name|
        m = text.match(pattern, start)
        next unless m
        idx = m[1] ? 1 : 0
        if m.begin(idx) < pos
          pos = m.begin(idx)
          matched_text = m[idx]
          matched_name = name
        end
      end
      output << [text[start...pos], false] if pos > start
      if matched_name
        handled = public_send(:"handle_regexp_#{matched_name}", matched_text)
        output << [handled, true]
        start = pos + matched_text.size
      else
        start = pos
      end
      break if pos == text.size
    end
    output
  end

  # Called when processing plain text while traversing inline nodes from handle_inline.
  # +text+ may need proper escaping.

  def handle_PLAIN_TEXT(text)
  end

  # Called when processing regexp-handling-processed text while traversing inline nodes from handle_inline.
  # +text+ may contain markup tags.

  def handle_REGEXP_HANDLING_TEXT(text)
  end

  # Called when processing text node while traversing inline nodes from handle_inline.
  # Apply regexp handling and dispatch to the appropriate handler: handle_REGEXP_HANDLING_TEXT or handle_PLAIN_TEXT.

  def handle_TEXT(text)
    apply_regexp_handling(text).each do |part, converted|
      if converted
        handle_REGEXP_HANDLING_TEXT(part)
      else
        handle_PLAIN_TEXT(part)
      end
    end
  end

  # Called when processing a hard break while traversing inline nodes from handle_inline.

  def handle_HARD_BREAK
  end

  # Called when processing bold nodes while traversing inline nodes from handle_inline.
  # Traverse the children nodes and dispatch to the appropriate handlers.

  def handle_BOLD(nodes)
    traverse_inline_nodes(nodes)
  end

  # Called when processing emphasis nodes while traversing inline nodes from handle_inline.
  # Traverse the children nodes and dispatch to the appropriate handlers.

  def handle_EM(nodes)
    traverse_inline_nodes(nodes)
  end

  # Called when processing bold word nodes while traversing inline nodes from handle_inline.
  # +word+ may need proper escaping.

  def handle_BOLD_WORD(word)
    handle_PLAIN_TEXT(word)
  end

  # Called when processing emphasis word nodes while traversing inline nodes from handle_inline.
  # +word+ may need proper escaping.

  def handle_EM_WORD(word)
    handle_PLAIN_TEXT(word)
  end

  # Called when processing tt nodes while traversing inline nodes from handle_inline.
  # +code+ may need proper escaping.

  def handle_TT(code)
    handle_PLAIN_TEXT(code)
  end

  # Called when processing strike nodes while traversing inline nodes from handle_inline.
  # Traverse the children nodes and dispatch to the appropriate handlers.

  def handle_STRIKE(nodes)
    traverse_inline_nodes(nodes)
  end

  # Called when processing tidylink nodes while traversing inline nodes from handle_inline.
  # +label_part+ is an array of strings or nodes representing the link label.
  # +url+ is the link URL.
  # Traverse the label_part nodes and dispatch to the appropriate handlers.

  def handle_TIDYLINK(label_part, url)
    traverse_inline_nodes(label_part)
  end

  # Parses inline +text+, traverse the resulting nodes, and calls the appropriate handler methods.

  def handle_inline(text)
    nodes = RDoc::Markup::InlineParser.new(text).parse
    traverse_inline_nodes(nodes)
  end

  # Traverses +nodes+ and calls the appropriate handler methods
  # Nodes formats are described in RDoc::Markup::InlineParser#parse

  def traverse_inline_nodes(nodes)
    nodes.each do |node|
      next handle_TEXT(node) if String === node
      case node[:type]
      when :TIDYLINK
        handle_TIDYLINK(node[:children], node[:url])
      when :HARD_BREAK
        handle_HARD_BREAK
      when :BOLD
        handle_BOLD(node[:children])
      when :BOLD_WORD
        handle_BOLD_WORD(node[:children][0] || '')
      when :EM
        handle_EM(node[:children])
      when :EM_WORD
        handle_EM_WORD(node[:children][0] || '')
      when :TT
        handle_TT(node[:children][0] || '')
      when :STRIKE
        handle_STRIKE(node[:children])
      end
    end
  end

  ##
  # Converts a string to be fancier if desired

  def convert_string(string)
    string
  end

  ##
  # Use ignore in your subclass to ignore the content of a node.
  #
  #   ##
  #   # We don't support raw nodes in ToNoRaw
  #
  #   alias accept_raw ignore

  def ignore *node
  end

  ##
  # Extracts and a scheme, url and an anchor id from +url+ and returns them.

  def parse_url(url)
    case url
    when /^rdoc-label:([^:]*)(?::(.*))?/ then
      scheme = 'link'
      path   = "##{$1}"
      id     = " id=\"#{$2}\"" if $2
    when /([A-Za-z]+):(.*)/ then
      scheme = $1.downcase
      path   = $2
    when /^#/ then
    else
      scheme = 'http'
      path   = url
      url    = url
    end

    if scheme == 'link' then
      url = if path[0, 1] == '#' then # is this meaningful?
              path
            else
              self.class.gen_relative_url @from_path, path
            end
    end

    [scheme, url, id]
  end

  ##
  # Is +tag+ a tt tag?

  def tt?(tag)
    tag.bit == @tt_bit
  end

end
