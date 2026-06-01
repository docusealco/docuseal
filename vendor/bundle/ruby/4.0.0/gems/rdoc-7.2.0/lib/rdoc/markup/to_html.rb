# frozen_string_literal: true
require 'cgi/escape'
require 'cgi/util' unless defined?(CGI::EscapeExt)

##
# Outputs RDoc markup as HTML.

class RDoc::Markup::ToHtml < RDoc::Markup::Formatter

  include RDoc::Text

  # :section: Utilities

  ##
  # Maps RDoc::Markup::Parser::LIST_TOKENS types to HTML tags

  LIST_TYPE_TO_HTML = {
    :BULLET => ['<ul>',                                      '</ul>'],
    :LABEL  => ['<dl class="rdoc-list label-list">',         '</dl>'],
    :LALPHA => ['<ol style="list-style-type: lower-alpha">', '</ol>'],
    :NOTE   => ['<dl class="rdoc-list note-list">',          '</dl>'],
    :NUMBER => ['<ol>',                                      '</ol>'],
    :UALPHA => ['<ol style="list-style-type: upper-alpha">', '</ol>'],
  }

  attr_reader :res # :nodoc:
  attr_reader :in_list_entry # :nodoc:
  attr_reader :list # :nodoc:

  ##
  # The RDoc::CodeObject HTML is being generated for.  This is used to
  # generate namespaced URI fragments

  attr_accessor :code_object

  ##
  # Path to this document for relative links

  attr_accessor :from_path

  # :section:

  ##
  # Creates a new formatter that will output HTML

  def initialize(options, markup = nil)
    super

    @code_object = nil
    @from_path = ''
    @in_list_entry = nil
    @list = nil
    @th = nil
    @in_tidylink_label = false
    @hard_break = "<br>\n"

    init_regexp_handlings
  end

  # :section: Regexp Handling
  #
  # These methods are used by regexp handling markup added by RDoc::Markup#add_regexp_handling.

  # :nodoc:
  URL_CHARACTERS_REGEXP_STR = /[A-Za-z0-9\-._~:\/\?#\[\]@!$&'\(\)*+,;%=]/.source

  ##
  # Adds regexp handlings.

  def init_regexp_handlings
    # external links
    @markup.add_regexp_handling(/(?:link:|https?:|mailto:|ftp:|irc:|www\.)#{URL_CHARACTERS_REGEXP_STR}+\w/,
                                :HYPERLINK)

    # suppress crossref: \#method \::method \ClassName \method_with_underscores
    @markup.add_regexp_handling(/\\(?:[#:A-Z]|[a-z]+_[a-z0-9])/, :SUPPRESSED_CROSSREF)

    init_link_notation_regexp_handlings
  end

  ##
  # Adds regexp handlings about link notations.

  def init_link_notation_regexp_handlings
    add_regexp_handling_RDOCLINK
  end

  def handle_RDOCLINK(url) # :nodoc:
    case url
    when /^rdoc-ref:/
      CGI.escapeHTML($')
    when /^rdoc-label:/
      return CGI.escapeHTML(url) if in_tidylink_label?
      text = $'

      text = case text
             when /\Alabel-/    then $'
             when /\Afootmark-/ then $'
             when /\Afoottext-/ then $'
             else                    text
             end

      gen_url CGI.escapeHTML(url), CGI.escapeHTML(text)
    when /^rdoc-image:/
      # Split the string after "rdoc-image:" into url and alt.
      #   "path/to/image.jpg:alt text" => ["path/to/image.jpg", "alt text"]
      #   "http://example.com/path/to/image.jpg:alt text" => ["http://example.com/path/to/image.jpg", "alt text"]
      url, alt = $'.split(/:(?!\/)/, 2)
      if alt && !alt.empty?
        %[<img src="#{CGI.escapeHTML(url)}" alt="#{CGI.escapeHTML(alt)}">]
      else
        %[<img src="#{CGI.escapeHTML(url)}">]
      end
    when /\Ardoc-[a-z]+:/
      CGI.escapeHTML($')
    end
  end

  def handle_PLAIN_TEXT(text)
    emit_inline(convert_string(text))
  end

  def handle_REGEXP_HANDLING_TEXT(text)
    emit_inline(text)
  end

  def handle_BOLD(nodes)
    emit_inline('<strong>')
    super
    emit_inline('</strong>')
  end

  def handle_EM(nodes)
    emit_inline('<em>')
    super
    emit_inline('</em>')
  end

  def handle_BOLD_WORD(word)
    emit_inline('<strong>')
    super
    emit_inline('</strong>')
  end

  def handle_EM_WORD(word)
    emit_inline('<em>')
    super
    emit_inline('</em>')
  end

  def handle_TT(code)
    emit_inline('<code>')
    super
    emit_inline('</code>')
  end

  def handle_STRIKE(nodes)
    emit_inline('<del>')
    super
    emit_inline('</del>')
  end

  def handle_HARD_BREAK
    emit_inline('<br>')
  end

  def emit_inline(text)
    @inline_output << text
  end

  # Returns true if we are processing inside a tidy link label.

  def in_tidylink_label?
    @in_tidylink_label
  end

  # Special handling for tidy link labels.
  # When a tidy link is <tt>{rdoc-image:path/to/image.jpg:alt text}[http://example.com]</tt>,
  # label part is normally considered RDOCLINK <tt>rdoc-image:path/to/image.jpg:alt</tt> and a text <tt>" text"</tt>
  # but RDoc's test code expects the whole label part to be treated as RDOCLINK only in tidy link label.
  # When a tidy link is <tt>{^1}[url]</tt> or <tt>{*1}[url]</tt>, the label part needs to drop leading * or ^.
  # TODO: reconsider this workaround.

  def apply_tidylink_label_special_handling(label, url)
    # ^1 *1 will be converted to just 1 in tidy link label.
    return label[1..] if label.match?(/\A[*^]\d+\z/)

    # rdoc-image in label specially allows spaces in alt text.
    return handle_RDOCLINK(label) if label.start_with?('rdoc-image:')
  end

  def handle_TIDYLINK(label_part, url)
    # When url is an image, ignore label part (maybe bug?) and just generate img tag.
    if url.match?(/\Ahttps?:\/\/.+\.(png|gif|jpg|jpeg|bmp)\z/)
      emit_inline("<img src=\"#{CGI.escapeHTML(url)}\" />")
      return
    elsif url.match?(/\Ardoc-image:/)
      emit_inline(handle_RDOCLINK(url))
      return
    end

    if label_part.size == 1 && String === label_part[0]
      raw_label = label_part[0]

      @in_tidylink_label = true
      special = apply_tidylink_label_special_handling(raw_label, url)
      @in_tidylink_label = false

      if special
        tag = gen_url(CGI.escapeHTML(url), special)
        unless tag.empty?
          emit_inline(tag)
          return
        end
      end
    end

    tag = gen_url(CGI.escapeHTML(url), '')
    open_tag, close_tag = tag.split(/(?=<\/a>)/, 2)
    valid_tag = open_tag && close_tag
    emit_inline(open_tag) if valid_tag
    @in_tidylink_label = true
    traverse_inline_nodes(label_part)
    @in_tidylink_label = false
    emit_inline(close_tag) if valid_tag
  end

  def handle_inline(text) # :nodoc:
    @inline_output = +''
    super
    out = @inline_output
    @inline_output = nil
    out
  end

  # Converts suppressed cross-reference +text+ to HTML by removing the leading backslash.

  def handle_regexp_SUPPRESSED_CROSSREF(text)
    convert_string(text.delete_prefix('\\'))
  end

  ##
  # +target+ is a potential link.  The following schemes are handled:
  #
  # <tt>mailto:</tt>::
  #   Inserted as-is.
  # <tt>http:</tt>::
  #   Links are checked to see if they reference an image. If so, that image
  #   gets inserted using an <tt><img></tt> tag. Otherwise a conventional
  #   <tt><a href></tt> is used.
  # <tt>link:</tt>::
  #   Reference to a local file relative to the output directory.

  def handle_regexp_HYPERLINK(text)
    return convert_string(text) if in_tidylink_label?

    url = CGI.escapeHTML(text)
    gen_url url, url
  end

  ##
  # +target+ is an rdoc-schemed link that will be converted into a hyperlink.
  #
  # For the +rdoc-ref+ scheme the named reference will be returned without
  # creating a link.
  #
  # For the +rdoc-label+ scheme the footnote and label prefixes are stripped
  # when creating a link.  All other contents will be linked verbatim.

  def handle_regexp_RDOCLINK(text)
    handle_RDOCLINK text
  end

  # :section: Visitor
  #
  # These methods implement the HTML visitor.

  ##
  # Prepares the visitor for HTML generation

  def start_accepting
    @res = []
    @in_list_entry = []
    @list = []
    @heading_ids = {}
  end

  ##
  # Returns the generated output

  def end_accepting
    @res.join
  end

  ##
  # Adds +block_quote+ to the output

  def accept_block_quote(block_quote)
    @res << "\n<blockquote>"

    block_quote.parts.each do |part|
      part.accept self
    end

    @res << "</blockquote>\n"
  end

  ##
  # Adds +paragraph+ to the output

  def accept_paragraph(paragraph)
    @res << "\n<p>"
    text = paragraph.text @hard_break
    text = text.gsub(/(#{SPACE_SEPARATED_LETTER_CLASS})?\K\r?\n(?=(?(1)(#{SPACE_SEPARATED_LETTER_CLASS})?))/o) {
      defined?($2) && ' '
    }
    @res << to_html(text)
    @res << "</p>\n"
  end

  ##
  # Adds +verbatim+ to the output

  def accept_verbatim(verbatim)
    text = verbatim.text.rstrip
    format = verbatim.format

    klass = nil

    # Apply Ruby syntax highlighting if
    # - explicitly marked as Ruby (via ruby? which accepts :ruby or :rb)
    # - no format specified but the text is parseable as Ruby
    # Otherwise, add language class when applicable and skip Ruby highlighting
    content = if verbatim.ruby? || (format.nil? && parseable?(text))
                begin
                  tokens = RDoc::Parser::RipperStateLex.parse text
                  klass  = ' class="ruby"'

                  result = RDoc::TokenStream.to_html tokens
                  result = result + "\n" unless "\n" == result[-1]
                  result
                rescue
                  CGI.escapeHTML text
                end
              else
                klass = " class=\"#{format}\"" if format
                CGI.escapeHTML text
              end

    if @options.pipe then
      @res << "\n<pre><code>#{CGI.escapeHTML text}\n</code></pre>\n"
    else
      @res << "\n<pre#{klass}>#{content}</pre>\n"
    end
  end

  ##
  # Adds +rule+ to the output

  def accept_rule(rule)
    @res << "<hr>\n"
  end

  ##
  # Prepares the visitor for consuming +list+

  def accept_list_start(list)
    @list << list.type
    @res << html_list_name(list.type, true)
    @in_list_entry.push false
  end

  ##
  # Finishes consumption of +list+

  def accept_list_end(list)
    @list.pop
    if tag = @in_list_entry.pop
      @res << tag
    end
    @res << html_list_name(list.type, false) << "\n"
  end

  ##
  # Prepares the visitor for consuming +list_item+

  def accept_list_item_start(list_item)
    if tag = @in_list_entry.last
      @res << tag
    end

    @res << list_item_start(list_item, @list.last)
  end

  ##
  # Finishes consumption of +list_item+

  def accept_list_item_end(list_item)
    @in_list_entry[-1] = list_end_for(@list.last)
  end

  ##
  # Adds +blank_line+ to the output

  def accept_blank_line(blank_line)
    # @res << annotate("<p />") << "\n"
  end

  ##
  # Adds +heading+ to the output.  The headings greater than 6 are trimmed to
  # level 6.

  def accept_heading(heading)
    level = [6, heading.level].min

    label = deduplicate_heading_id(heading.label(@code_object))
    legacy_label = deduplicate_heading_id(heading.legacy_label(@code_object))

    # Add legacy anchor before the heading for backward compatibility.
    # This allows old links with label- prefix to still work.
    if @options.output_decoration && !@options.pipe
      @res << "\n<span id=\"#{legacy_label}\" class=\"legacy-anchor\"></span>"
    end

    @res << if @options.output_decoration
              "\n<h#{level} id=\"#{label}\">"
            else
              "\n<h#{level}>"
            end

    if @options.pipe
      @res << to_html(heading.text)
    else
      @res << "<a href=\"##{label}\">#{to_html(heading.text)}</a>"
    end

    @res << "</h#{level}>\n"
  end

  ##
  # Adds +raw+ to the output

  def accept_raw(raw)
    @res << raw.parts.join("\n")
  end

  ##
  # Adds +table+ to the output

  def accept_table(header, body, aligns)
    @res << "\n<table role=\"table\">\n<thead>\n<tr>\n"
    header.zip(aligns) do |text, align|
      @res << '<th'
      @res << ' align="' << align << '"' if align
      @res << '>' << to_html(text) << "</th>\n"
    end
    @res << "</tr>\n</thead>\n<tbody>\n"
    body.each do |row|
      @res << "<tr>\n"
      row.zip(aligns) do |text, align|
        @res << '<td'
        @res << ' align="' << align << '"' if align
        @res << '>' << to_html(text) << "</td>\n"
      end
      @res << "</tr>\n"
    end
    @res << "</tbody>\n</table>\n"
  end

  # :section: Utilities

  ##
  # Returns a unique heading ID, appending -1, -2, etc. for duplicates.
  # Matches GitHub's behavior for duplicate heading anchors.

  def deduplicate_heading_id(id)
    if @heading_ids.key?(id)
      @heading_ids[id] += 1
      "#{id}-#{@heading_ids[id]}"
    else
      @heading_ids[id] = 0
      id
    end
  end

  ##
  # CGI-escapes +text+

  def convert_string(text)
    CGI.escapeHTML text
  end

  ##
  # Generates an HTML link or image tag for the given +url+ and +text+.
  #
  # - Image URLs (http/https/link ending in .gif, .png, .jpg, .jpeg, .bmp)
  #   become <img> tags
  # - File references (.rb, .rdoc, .md) are converted to .html paths
  # - Anchor URLs (#foo) pass through unchanged for GitHub-style header linking
  # - Footnote links get wrapped in <sup> tags

  def gen_url(url, text)
    scheme, url, id = parse_url url

    if %w[http https link].include?(scheme) && url =~ /\.(gif|png|jpg|jpeg|bmp)\z/
      "<img src=\"#{url}\" />"
    else
      if scheme != 'link' and %r%\A((?!https?:)(?:[^/#]*/)*+)([^/#]+)\.(rb|rdoc|md)(?=\z|#)%i =~ url
        url = "#$1#{$2.tr('.', '_')}_#$3.html#$'"
      end

      text = text.sub %r%^#{scheme}:/*%i, ''
      text = text.sub %r%^[*\^](\d+)$%,   '\1'

      link = "<a#{id} href=\"#{url}\">#{text}</a>"

      if /"foot/.match?(id)
        "<sup>#{link}</sup>"
      else
        link
      end
    end
  end

  ##
  # Determines the HTML list element for +list_type+ and +open_tag+

  def html_list_name(list_type, open_tag)
    tags = LIST_TYPE_TO_HTML[list_type]
    raise RDoc::Error, "Invalid list type: #{list_type.inspect}" unless tags
    tags[open_tag ? 0 : 1]
  end

  ##
  # Returns the HTML tag for +list_type+, possible using a label from
  # +list_item+

  def list_item_start(list_item, list_type)
    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "<li>"
    when :LABEL, :NOTE then
      Array(list_item.label).map do |label|
        "<dt>#{to_html label}</dt>\n"
      end.join << "<dd>"
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end

  ##
  # Returns the HTML end-tag for +list_type+

  def list_end_for(list_type)
    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "</li>"
    when :LABEL, :NOTE then
      "</dd>"
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end

  ##
  # Returns true if text is valid ruby syntax

  def parseable?(text)
    verbose, $VERBOSE = $VERBOSE, nil
    catch(:valid) do
      eval("BEGIN { throw :valid, true }\n#{text}")
    end
  rescue SyntaxError
    false
  ensure
    $VERBOSE = verbose
  end

  ##
  # Converts +item+ to HTML using RDoc::Text#to_html

  def to_html(item)
    # Ideally, we should convert html characters at handle_PLAIN_TEXT or somewhere else,
    # but we need to convert it here for now because to_html_characters converts pair of backticks to ’‘ and pair of double backticks to ”“.
    # Known bugs: `...` in `<code>def f(...); end</code>` and `(c) in `<a href="(c)">` will be wrongly converted.
    to_html_characters(handle_inline(item))
  end
end

##
# Formatter dedicated to rendering tidy link labels without mutating the
# calling formatter's state.

class RDoc::Markup::LinkLabelToHtml < RDoc::Markup::ToHtml
  def self.render(label, options, from_path)
    new(options, from_path).to_html(label)
  end

  def initialize(options, from_path = nil)
    super(options)

    self.from_path = from_path if from_path
  end
end
