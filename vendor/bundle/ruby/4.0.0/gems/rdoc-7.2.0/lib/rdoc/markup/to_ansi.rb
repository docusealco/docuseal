# frozen_string_literal: true
##
# Outputs RDoc markup with vibrant ANSI color!

class RDoc::Markup::ToAnsi < RDoc::Markup::ToRdoc

  ##
  # Creates a new ToAnsi visitor that is ready to output vibrant ANSI color!

  def initialize(markup = nil)
    super

    @headings.clear
    @headings[1] = ["\e[1;32m", "\e[m"] # bold
    @headings[2] = ["\e[4;32m", "\e[m"] # underline
    @headings[3] = ["\e[32m",   "\e[m"] # just green
  end

  ##
  # Maps attributes to ANSI sequences

  ANSI_STYLE_CODES_ON = {
    BOLD: 1,
    TT: 7,
    EM: 4,
    STRIKE: 9
  }

  ANSI_STYLE_CODES_OFF = {
    BOLD: 22,
    TT: 27,
    EM: 24,
    STRIKE: 29
  }

  # Apply the given attributes by emitting ANSI sequences.
  # Emitting attribute changes are deferred until new text is added and applied in batch.
  # This method computes the necessary ANSI codes to transition from the
  # current set of applied attributes to the new set of +attributes+.

  def apply_attributes(attributes)
    before = @applied_attributes
    after = attributes.sort
    return if before == after

    if after.empty?
      emit_inline("\e[m")
    elsif !before.empty? && before.size > (before & after).size + 1
      codes = after.map {|attr| ANSI_STYLE_CODES_ON[attr] }.compact
      emit_inline("\e[#{[0, *codes].join(';')}m")
    else
      off_codes = (before - after).map {|attr| ANSI_STYLE_CODES_OFF[attr] }.compact
      on_codes = (after - before).map {|attr| ANSI_STYLE_CODES_ON[attr] }.compact
      emit_inline("\e[#{(off_codes + on_codes).join(';')}m")
    end
    @applied_attributes = attributes
  end

  def add_text(text)
    attrs = @attributes.keys
    if @applied_attributes != attrs
      apply_attributes(attrs)
    end
    emit_inline(text)
  end

  def handle_inline(text)
    @applied_attributes = []
    res = super
    res << "\e[m" unless @applied_attributes.empty?
    @applied_attributes = []
    res
  end

  ##
  # Overrides indent width to ensure output lines up correctly.

  def accept_list_item_end(list_item)
    width = case @list_type.last
            when :BULLET then
              2
            when :NOTE, :LABEL then
              if @prefix then
                @res << @prefix.strip
                @prefix = nil
              end

              @res << "\n" unless res.length == 1
              2
            else
              bullet = @list_index.last.to_s
              @list_index[-1] = @list_index.last.succ
              bullet.length + 2
            end

    @indent -= width
  end

  ##
  # Adds coloring to note and label list items

  def accept_list_item_start(list_item)
    bullet = case @list_type.last
             when :BULLET then
               '*'
             when :NOTE, :LABEL then
               labels = Array(list_item.label).map do |label|
                 attributes(label).strip
               end.join "\n"

               labels << ":\n" unless labels.empty?

               labels
             else
               @list_index.last.to_s + '.'
             end

    case @list_type.last
    when :NOTE, :LABEL then
      @indent += 2
      @prefix = bullet + (' ' * @indent)
    else
      @prefix = (' ' * @indent) + bullet.ljust(bullet.length + 1)

      width = bullet.gsub(/\e\[[\d;]*m/, '').length + 1

      @indent += width
    end
  end

  def calculate_text_width(text)
    text.gsub(/\e\[[\d;]*m/, '').size
  end

  ##
  # Starts accepting with a reset screen

  def start_accepting
    super

    @res = ["\e[0m"]
  end

end
