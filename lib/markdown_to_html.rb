# frozen_string_literal: true

module MarkdownToHtml
  TAGS = {
    '' => %w[<em> </em>],
    '*' => %w[<strong> </strong>],
    '~' => %w[<s> </s>]
  }.freeze

  INLINE_TOKENIZER = /(\[)|(\]\(([^)]+?)\))|(?:`([^`].*?)`)|(\*\*\*|\*\*|\*|~~)/

  ALLOWED_TAGS = %w[p br strong b em i u a].freeze
  ALLOWED_ATTRIBUTES = %w[href].freeze

  module_function

  def call(markdown)
    return '' if markdown.blank?

    text = auto_link_urls(markdown)
    html = render_markdown(text)

    ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end

  BRACKETS = { ')' => '(', ']' => '[', '}' => '{' }.freeze

  def auto_link_urls(text)
    link_parts = text.split(%r{((?:https?://|www\.)[^\s<>\u00A0"]+)})

    link_parts.map.with_index do |part, index|
      if part.match?(%r{\A(?:https?://|www\.)}) && !(index > 0 && link_parts[index - 1]&.match?(/\]\(\s*\z/))
        url_part = part.dup
        punctuation = []

        while url_part.sub!(%r{[^\p{Word}/\-=;]\z}, '')
          punctuation.push(::Regexp.last_match(0))

          opening = BRACKETS[punctuation.last]

          next unless opening && url_part.count(opening) > url_part.count(punctuation.last)

          url_part << punctuation.pop

          break
        end

        trail = punctuation.reverse.join
        url = url_part.start_with?('www.') ? "https://#{url_part}" : url_part

        "[#{url_part}](#{url})#{trail}"
      else
        part
      end
    end.join
  end

  def render_markdown(text)
    text = text.gsub(/\+\+([^+]+)\+\+/, '<u>\1</u>')

    paragraphs = text.split(/\n{2,}/)

    html = paragraphs.filter_map do |para|
      content = para.strip

      next if content.empty?

      next '<p><br></p>' if ['&nbsp;', '&amp;nbsp;'].include?(content)

      content = content.gsub(/ *\n/, '<br>')

      "<p>#{parse_inline(content)}</p>"
    end.join

    html.presence || '<p></p>'
  end

  # rubocop:disable Metrics
  def parse_inline(text)
    context = []
    out = ''
    last = 0

    tag = lambda do |t|
      desc = TAGS[t[1] || '']

      return t unless desc

      is_end = context.last == t
      is_end ? context.pop : context.push(t)
      desc[is_end ? 1 : 0]
    end

    flush = lambda do
      str = ''
      str += tag.call(context.last) while context.any?
      str
    end

    while last <= text.length && (m = INLINE_TOKENIZER.match(text, last))
      prev = text[last...m.begin(0)]
      last = m.end(0)
      chunk = m[0]

      if m[4]
        chunk = "<code>#{ERB::Util.html_escape(m[4])}</code>"
      elsif m[2]
        out = out.sub(/\A(.*)<a>/m, "\\1<a href=\"#{ERB::Util.html_escape(m[3])}\">")
        out = out.gsub('<a>', '[')
        chunk = "#{flush.call}</a>"
      elsif m[1]
        chunk = '<a>'
      elsif m[5]
        chunk =
          if m[5] == '***'
            if context.include?('*') && context.include?('**')
              tag.call('*') + tag.call('**')
            else
              tag.call('**') + tag.call('*')
            end
          else
            tag.call(m[5])
          end
      end

      out += prev.to_s + chunk
    end

    (out + text[last..].to_s + flush.call).gsub('<a>', '[')
  end
  # rubocop:enable Metrics
end
