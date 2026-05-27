# frozen_string_literal: true
##
# Outputs RDoc markup as paragraphs with inline markup only.

class RDoc::Markup::ToHtmlSnippet < RDoc::Markup::ToHtml

  ##
  # After this many characters the input will be cut off.

  attr_reader :character_limit

  ##
  # The number of characters seen so far.

  attr_reader :characters # :nodoc:

  ##
  # The attribute bitmask

  attr_reader :mask

  ##
  # After this many paragraphs the input will be cut off.

  attr_reader :paragraph_limit

  ##
  # Count of paragraphs found

  attr_reader :paragraphs

  ##
  # Creates a new ToHtmlSnippet formatter that will cut off the input on the
  # next word boundary after the given number of +characters+ or +paragraphs+
  # of text have been encountered.

  def initialize(options, characters = 100, paragraphs = 3, markup = nil)
    super options, markup

    @character_limit = characters
    @paragraph_limit = paragraphs

    @characters = 0
    @mask       = 0
    @paragraphs = 0

    @markup.add_regexp_handling RDoc::CrossReference::CROSSREF_REGEXP, :CROSSREF
  end

  ##
  # Adds +heading+ to the output as a paragraph

  def accept_heading(heading)
    @res << "<p>#{to_html heading.text}\n"

    add_paragraph
  end

  ##
  # Raw sections are untrusted and ignored

  alias accept_raw ignore

  ##
  # Rules are ignored

  alias accept_rule ignore

  ##
  # Adds +paragraph+ to the output

  def accept_paragraph(paragraph)
    para = @in_list_entry.last || "<p>"

    text = paragraph.text @hard_break

    @res << "#{para}#{to_html text}\n"

    add_paragraph
  end

  ##
  # Finishes consumption of +list_item+

  def accept_list_item_end(list_item)
  end

  ##
  # Prepares the visitor for consuming +list_item+

  def accept_list_item_start(list_item)
    @res << list_item_start(list_item, @list.last)
  end

  ##
  # Prepares the visitor for consuming +list+

  def accept_list_start(list)
    @list << list.type
    @res << html_list_name(list.type, true)
    @in_list_entry.push ''
  end

  ##
  # Adds +verbatim+ to the output

  def accept_verbatim(verbatim)
    throw :done if @characters >= @character_limit
    input = verbatim.text.rstrip
    text = truncate(input, @character_limit - @characters)
    @characters += input.length
    text << ' ...' unless text == input

    super RDoc::Markup::Verbatim.new text

    add_paragraph
  end

  ##
  # Prepares the visitor for HTML snippet generation

  def start_accepting
    super

    @characters = 0
  end

  ##
  # Removes escaping from the cross-references in +target+

  def handle_regexp_CROSSREF(text)
    text.sub(/\A\\/, '')
  end

  ##
  # Lists are paragraphs, but notes and labels have a separator

  def list_item_start(list_item, list_type)
    throw :done if @characters >= @character_limit

    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "<p>"
    when :LABEL, :NOTE then
      labels = Array(list_item.label).map do |label|
        to_html label
      end.join ', '

      labels << " &mdash; " unless labels.empty?

      start = "<p>#{labels}"
      @characters += 1 # try to include the label
      start
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end

  ##
  # Returns just the text of +link+, +url+ is only used to determine the link
  # type.

  def gen_url(url, text)
    if url =~ /^rdoc-label:([^:]*)(?::(.*))?/ then
      type = "link"
    elsif url =~ /([A-Za-z]+):(.*)/ then
      type = $1
    else
      type = "http"
    end

    if (type == "http" or type == "https" or type == "link") and
       url =~ /\.(gif|png|jpg|jpeg|bmp)$/ then
      ''
    else
      text.sub(%r%^#{type}:/*%, '')
    end
  end

  ##
  # In snippets, there are no lists

  def html_list_name(list_type, open_tag)
    ''
  end

  ##
  # Throws +:done+ when paragraph_limit paragraphs have been encountered

  def add_paragraph
    @paragraphs += 1

    throw :done if @paragraphs >= @paragraph_limit
  end

  ##
  # Marks up +content+

  def convert(content)
    catch :done do
      return super
    end

    end_accepting
  end

  def handle_PLAIN_TEXT(text) # :nodoc:
    return if inline_limit_reached?

    truncated = truncate(text, @inline_character_limit)
    @inline_character_limit -= text.size
    emit_inline(convert_string(truncated))
  end

  def handle_REGEXP_HANDLING_TEXT(text) # :nodoc:
    return if inline_limit_reached?

    # We can't truncate text including html tags.
    # Just emit as is, and count all characters including html tag part.
    emit_inline(text)
    @inline_character_limit -= text.size
  end

  def handle_BOLD(nodes)
    super unless inline_limit_reached?
  end

  def handle_BOLD_WORD(word)
    super unless inline_limit_reached?
  end

  def handle_EM(nodes)
    super unless inline_limit_reached?
  end

  def handle_EM_WORD(word)
    super unless inline_limit_reached?
  end

  def handle_TT(code)
    super unless inline_limit_reached?
  end

  def handle_STRIKE(nodes)
    super unless inline_limit_reached?
  end

  def handle_HARD_BREAK
    super unless inline_limit_reached?
  end

  def handle_TIDYLINK(label_part, url)
    traverse_inline_nodes(label_part) unless inline_limit_reached?
  end

  def inline_limit_reached?
    @inline_character_limit <= 0
  end

  def handle_inline(text)
    limit = @character_limit - @characters
    return ['', 0] if limit <= 0
    @inline_character_limit = limit
    res = super
    res << ' ...' if @inline_character_limit <= 0
    @characters += limit - @inline_character_limit
    res
  end

  def to_html(item)
    throw :done if @characters >= @character_limit
    to_html_characters(handle_inline(item))
  end

  ##
  # Truncates +text+ at the end of the first word after the limit.

  def truncate(text, limit)
    return text if limit >= text.size
    return '' if limit <= 0

    text =~ /\A(.{#{limit},}?)(\s|$)/m # TODO word-break instead of \s?

    $1
  end

end
