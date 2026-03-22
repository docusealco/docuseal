# frozen_string_literal: true

module HtmlToPlainText
  module_function

  def call(html, line_length = 65)
    return '' if html.nil? || html.strip.empty?

    cleaned = html.gsub(%r{<!-- start text/html -->.*?<!-- end text/html -->}m, '')

    doc = Nokogiri::HTML.fragment(cleaned)

    doc.css('script').each(&:remove)

    result = process_nodes(doc, line_length)

    result.gsub!(/\r\n?/, "\n")
    result.gsub!(/[ \t]*\u00A0+[ \t]*/, ' ')
    result.gsub!(/\n[ \t]+/, "\n")
    result.gsub!(/[ \t]+\n/, "\n")
    result.gsub!(/\n{3,}/, "\n\n")

    result = word_wrap(result, line_length)

    result.gsub!(/\(([ \n])(http[^)]+)([\n ])\)/) do
      "#{"\n" if ::Regexp.last_match(1) == "\n"}( #{::Regexp.last_match(2)} )#{"\n" if ::Regexp.last_match(3) == "\n"}"
    end

    result.strip
  end

  def process_nodes(node, line_length)
    result = +''

    node.children.each do |child|
      case child
      when Nokogiri::XML::Text
        result << child.text
      when Nokogiri::XML::Comment
        next
      when Nokogiri::XML::Element
        result << process_element(child, line_length)
      end
    end

    result
  end

  def process_element(node, line_length)
    case node.name
    when 'br'
      "\n"
    when 'p', 'div'
      inner = process_nodes(node, line_length)
      inner.strip.empty? ? '' : "#{inner}\n\n"
    when 'img'
      node['alt'] || ''
    when 'a'
      process_link(node, line_length)
    when /\Ah([1-6])\z/
      process_heading(node, ::Regexp.last_match(1).to_i, line_length)
    when 'li'
      inner = process_nodes(node, line_length)
      "* #{inner.strip}\n"
    else
      process_nodes(node, line_length)
    end
  end

  def process_link(node, line_length)
    text = process_nodes(node, line_length).strip
    return '' if text.empty?

    href = node['href']
    href = href.sub(/\Amailto:/i, '') if href

    if href.nil? || text.casecmp(href.strip) == 0
      text
    else
      "#{text} ( #{href.strip} )"
    end
  end

  def process_heading(node, level, line_length)
    text = +''
    node.children.each do |child|
      text << if child.name == 'br'
                "\n"
              else
                child.text
              end
    end
    text.strip!

    hlength = text.each_line.map { |l| l.strip.length }.max || 0
    hlength = line_length if hlength > line_length

    decorated = case level
                when 1
                  "#{'*' * hlength}\n#{text}\n#{'*' * hlength}"
                when 2
                  "#{'-' * hlength}\n#{text}\n#{'-' * hlength}"
                else
                  "#{text}\n#{'-' * hlength}"
                end

    "\n\n#{decorated}\n\n"
  end

  def word_wrap(txt, line_length)
    txt.split("\n").map do |line|
      if line.length > line_length
        line.gsub(/(.{1,#{line_length}})(\s+|$)/, "\\1\n").strip
      else
        line
      end
    end.join("\n")
  end
end
