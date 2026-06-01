# frozen_string_literal: true
##
# Extracts sections of text enclosed in plus, tt or code.  Used to discover
# undocumented parameters.

class RDoc::Markup::ToTtOnly < RDoc::Markup::Formatter

  ##
  # Stack of list types

  attr_reader :list_type

  ##
  # Output accumulator

  attr_reader :res

  ##
  # Creates a new tt-only formatter.

  def initialize(markup = nil)
    super nil, markup
  end

  ##
  # Adds tts from +block_quote+ to the output

  def accept_block_quote(block_quote)
    tt_sections block_quote.text
  end

  ##
  # Pops the list type for +list+ from #list_type

  def accept_list_end(list)
    @list_type.pop
  end

  ##
  # Pushes the list type for +list+ onto #list_type

  def accept_list_start(list)
    @list_type << list.type
  end

  ##
  # Prepares the visitor for consuming +list_item+

  def accept_list_item_start(list_item)
    case @list_type.last
    when :NOTE, :LABEL then
      Array(list_item.label).map do |label|
        tt_sections label
      end.flatten
    end
  end

  ##
  # Adds +paragraph+ to the output

  def accept_paragraph(paragraph)
    tt_sections(paragraph.text)
  end

  ##
  # Does nothing to +markup_item+ because it doesn't have any user-built
  # content

  def do_nothing(markup_item)
  end

  alias accept_blank_line    do_nothing # :nodoc:
  alias accept_heading       do_nothing # :nodoc:
  alias accept_list_item_end do_nothing # :nodoc:
  alias accept_raw           do_nothing # :nodoc:
  alias accept_rule          do_nothing # :nodoc:
  alias accept_verbatim      do_nothing # :nodoc:

  ##
  # Extracts tt sections from +text+

  def tt_sections(text)
    parsed = RDoc::Markup::InlineParser.new(text).parse
    traverse = -> node {
      next if String === node
      if node[:type] == :TT
        res << nil
        res << node[:children][0] || ''
        res << nil
      else
        node[:children].each(&traverse)
      end
    }
    parsed.each(&traverse)
    res
  end

  ##
  # Returns an Array of items that were wrapped in plus, tt or code.

  def end_accepting
    @res.compact
  end

  ##
  # Prepares the visitor for gathering tt sections

  def start_accepting
    @res = []

    @list_type = []
  end

end
