# frozen_string_literal: true

module PdfTextToHtml
  module_function

  def call(page_text)
    output = +''
    current_list = nil

    page_text.split(/\r?\n/).each do |line|
      stripped = line.strip
      if stripped.empty?
        output << close_list(current_list) if current_list
        current_list = nil
        next
      end
      current_list = process_line(stripped, output, current_list)
    end

    output << close_list(current_list)
    output
  end

  def process_line(stripped, output, current_list)
    if numbered_heading?(stripped)
      output << close_list(current_list)
      output << "<h3>#{ERB::Util.html_escape(stripped)}</h3>"
      nil
    elsif all_caps_heading?(stripped)
      output << close_list(current_list)
      output << "<h2>#{ERB::Util.html_escape(stripped)}</h2>"
      nil
    elsif (match = stripped.match(/\A[•*-]\s+(.+)/))
      output << close_list(current_list) << '<ul>' unless current_list == :ul
      output << "<li>#{ERB::Util.html_escape(match[1])}</li>"
      :ul
    else
      output << close_list(current_list)
      output << %(<p dir="auto">#{ERB::Util.html_escape(stripped)}</p>)
      nil
    end
  end

  def numbered_heading?(line)
    line.length <= 80 && line.match?(/\A\d+\.\s+[A-Z]/) && !line.match?(/[.!?,;]\z/)
  end

  def all_caps_heading?(line)
    line.length >= 3 && !line.match?(/[.!?,;]\z/) &&
      line == line.upcase && line.match?(/[A-Z]/)
  end

  def close_list(current_list)
    case current_list
    when :ol then '</ol>'
    when :ul then '</ul>'
    else ''
    end
  end
end
