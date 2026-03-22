# frozen_string_literal: true

module HtmlToPlainTextInterceptor
  module_function

  def delivering_email(message)
    process(message)
  end

  def previewing_email(message)
    process(message)
  end

  def process(message)
    return message unless html_part(message)
    return message if message.text_part

    add_text_part(message)

    message
  end

  def add_text_part(message)
    html = html_part(message).decoded
    text = HtmlToPlainText.call(html)

    text_part = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      body text
    end

    if pure_html_message?(message)
      message.body = nil
      message.content_type = 'multipart/alternative'
      message.add_part(text_part)
      message.add_part(Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body html
      end)
    else
      alternative = Mail::Part.new(content_type: 'multipart/alternative')
      alternative.add_part(text_part)
      alternative.add_part(message.html_part)
      replace_part(message.parts, message.html_part, alternative)
    end
  end

  def pure_html_message?(message)
    message.content_type.to_s.include?('text/html')
  end

  def html_part(message)
    pure_html_message?(message) ? message : message.html_part
  end

  def replace_part(parts, old_part, new_part)
    if (index = parts.index(old_part))
      parts[index] = new_part
    else
      parts.each do |part|
        replace_part(part.parts, old_part, new_part) if part.respond_to?(:parts)
      end
    end
  end
end
