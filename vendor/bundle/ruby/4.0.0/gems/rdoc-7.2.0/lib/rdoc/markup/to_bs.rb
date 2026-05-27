# frozen_string_literal: true
##
# Outputs RDoc markup with hot backspace action!  You will probably need a
# pager to use this output format.
#
# This formatter won't work on 1.8.6 because it lacks String#chars.

class RDoc::Markup::ToBs < RDoc::Markup::ToRdoc

  ##
  # Returns a new ToBs that is ready for hot backspace action!

  def initialize(markup = nil)
    super

    @in_b  = false
    @in_em = false
  end

  def handle_inline(text)
    initial_style = []
    initial_style << :BOLD if @in_b
    initial_style << :EM   if @in_em
    super(text, initial_style)
  end

  def add_text(text)
    attrs = @attributes.keys
    if attrs.include? :BOLD
      styled = +''
      text.chars.each do |c|
        styled << "#{c}\b#{c}"
      end
      text = styled
    elsif attrs.include? :EM
      styled = +''
      text.chars.each do |c|
        styled << "_\b#{c}"
      end
      text = styled
    end
    emit_inline(text)
  end

  ##
  # Makes heading text bold.

  def accept_heading(heading)
    use_prefix or @res << ' ' * @indent
    @res << @headings[heading.level][0]
    @in_b = true
    @res << attributes(heading.text)
    @in_b = false
    @res << @headings[heading.level][1]
    @res << "\n"
  end

  ##
  # Prepares the visitor for consuming +list_item+

  def accept_list_item_start(list_item)
    type = @list_type.last

    case type
    when :NOTE, :LABEL then
      bullets = Array(list_item.label).map do |label|
        attributes(label).strip
      end.join "\n"

      bullets << ":\n" unless bullets.empty?

      @prefix = ' ' * @indent
      @indent += 2
      @prefix << bullets + (' ' * @indent)
    else
      bullet = type == :BULLET ? '*' :  @list_index.last.to_s + '.'
      @prefix = (' ' * @indent) + bullet.ljust(bullet.length + 1)
      width = bullet.length + 1
      @indent += width
    end
  end

  def calculate_text_width(text)
    text.gsub(/_\x08/, '').gsub(/\x08./, '').size
  end
end
