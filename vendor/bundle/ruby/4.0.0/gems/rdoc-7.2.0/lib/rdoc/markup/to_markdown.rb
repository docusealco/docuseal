# frozen_string_literal: true
# :markup: markdown

##
# Outputs parsed markup as Markdown

class RDoc::Markup::ToMarkdown < RDoc::Markup::ToRdoc

  ##
  # Creates a new formatter that will output Markdown format text

  def initialize(markup = nil)
    super

    @headings[1] = ['# ',      '']
    @headings[2] = ['## ',     '']
    @headings[3] = ['### ',    '']
    @headings[4] = ['#### ',   '']
    @headings[5] = ['##### ',  '']
    @headings[6] = ['###### ', '']

    add_regexp_handling_RDOCLINK

    @hard_break = "  \n"
  end

  ##
  # Finishes consumption of `list`

  def accept_list_end(list)
    super
  end

  ##
  # Finishes consumption of `list_item`

  def accept_list_item_end(list_item)
    width = case @list_type.last
            when :BULLET then
              4
            when :NOTE, :LABEL then
              use_prefix

              @res << "\n"

              4
            else
              @list_index[-1] = @list_index.last.succ
              4
            end

    @indent -= width
  end

  ##
  # Prepares the visitor for consuming `list_item`

  def accept_list_item_start(list_item)
    type = @list_type.last

    case type
    when :NOTE, :LABEL then
      bullets = Array(list_item.label).map do |label|
        attributes(label).strip
      end.join "\n"

      bullets << "\n" unless bullets.empty?

      @prefix = ' ' * @indent
      @indent += 4
      @prefix << bullets << ":" << (' ' * (@indent - 1))
    else
      bullet = type == :BULLET ? '*' : @list_index.last.to_s + '.'
      @prefix = (' ' * @indent) + bullet.ljust(4)

      @indent += 4
    end
  end

  def add_tag(tag, simple_tag, content)
    if content.match?(/\A[\w\s]+\z/)
      emit_inline("#{simple_tag}#{content}#{simple_tag}")
    else
      emit_inline("<#{tag}>#{content}</#{tag}>")
    end
  end

  def handle_tag(nodes, simple_tag, tag)
    if nodes.size == 1 && String === nodes[0]
      content = apply_regexp_handling(nodes[0]).map do |text, converted|
        converted ? text : convert_string(text)
      end.join
      add_tag(tag, simple_tag, content)
    else
      emit_inline("<#{tag}>")
      traverse_inline_nodes(nodes)
      emit_inline("</#{tag}>")
    end
  end

  def handle_TIDYLINK(label_part, url)
    if url =~ /^rdoc-label:foot/ then
      emit_inline(handle_rdoc_link(url))
    else
      emit_inline('[')
      traverse_inline_nodes(label_part)
      emit_inline("](#{url})")
    end
  end

  def handle_BOLD(nodes)
    handle_tag(nodes, '**', 'strong')
  end

  def handle_EM(nodes)
    handle_tag(nodes, '*', 'em')
  end

  def handle_BOLD_WORD(word)
    add_tag('strong', '**', convert_string(word))
  end

  def handle_EM_WORD(word)
    add_tag('em', '*', convert_string(word))
  end

  def handle_TT(text)
    add_tag('code', '`', convert_string(text))
  end

  def handle_STRIKE(nodes)
    handle_tag(nodes, '~~', 's')
  end

  def handle_HARD_BREAK
    emit_inline("  \n")
  end

  ##
  # Prepares the visitor for consuming `list`

  def accept_list_start(list)
    case list.type
    when :BULLET, :LABEL, :NOTE then
      @list_index << nil
    when :LALPHA, :NUMBER, :UALPHA then
      @list_index << 1
    else
      raise RDoc::Error, "invalid list type #{list.type}"
    end

    @list_width << 4
    @list_type << list.type
  end

  ##
  # Adds `rule` to the output

  def accept_rule(rule)
    use_prefix or @res << ' ' * @indent
    @res << '-' * 3
    @res << "\n"
  end

  ##
  # Outputs `verbatim` indented 4 columns

  def accept_verbatim(verbatim)
    indent = ' ' * (@indent + 4)

    verbatim.parts.each do |part|
      @res << indent unless part == "\n"
      @res << part
    end

    @res << "\n"
  end

  ##
  # Creates a Markdown-style URL from +url+ with +text+.

  def gen_url(url, text)
    scheme, url, = parse_url url

    "[#{text.sub(%r{^#{scheme}:/*}i, '')}](#{url})"
  end

  ##
  # Handles <tt>rdoc-</tt> type links for footnotes.

  def handle_rdoc_link(url)
    case url
    when /^rdoc-ref:/ then
      $'
    when /^rdoc-label:footmark-(\d+)/ then
      "[^#{$1}]:"
    when /^rdoc-label:foottext-(\d+)/ then
      "[^#{$1}]"
    when /^rdoc-label:label-/ then
      gen_url url, $'
    when /^rdoc-image:/ then
      "![](#{$'})"
    when /^rdoc-[a-z]+:/ then
      $'
    end
  end

  ##
  # Converts the rdoc-...: links into a Markdown.style links.

  def handle_regexp_RDOCLINK(text)
    handle_rdoc_link text
  end

end
