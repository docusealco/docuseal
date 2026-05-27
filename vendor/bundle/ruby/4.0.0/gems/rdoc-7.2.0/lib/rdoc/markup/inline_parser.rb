# frozen_string_literal: true

require 'set'
require 'strscan'

# Parses inline markup in RDoc text.
# This parser handles em, bold, strike, tt, hard break, and tidylink.
# Block-level constructs are handled in RDoc::Markup::Parser.

class RDoc::Markup::InlineParser

  # TT, BOLD_WORD, EM_WORD: regexp-handling(example: crossref) is disabled
  WORD_PAIRS = {
    '*' => :BOLD_WORD,
    '**' => :BOLD_WORD,
    '_' => :EM_WORD,
    '__' => :EM_WORD,
    '+' => :TT,
    '++' => :TT,
    '`' => :TT,
    '``' => :TT
  } # :nodoc:

  # Other types: regexp-handling(example: crossref) is enabled
  TAGS = {
    'em' => :EM,
    'i' => :EM,
    'b' => :BOLD,
    's' => :STRIKE,
    'del' => :STRIKE,
  } # :nodoc:

  STANDALONE_TAGS = { 'br' => :HARD_BREAK } # :nodoc:

  CODEBLOCK_TAGS = %w[tt code] # :nodoc:

  TOKENS = {
    **WORD_PAIRS.transform_values { [:word_pair, nil] },
    **TAGS.keys.to_h {|tag| ["<#{tag}>", [:open_tag, tag]] },
    **TAGS.keys.to_h {|tag| ["</#{tag}>", [:close_tag, tag]] },
    **CODEBLOCK_TAGS.to_h {|tag| ["<#{tag}>", [:code_start, tag]] },
    **STANDALONE_TAGS.keys.to_h {|tag| ["<#{tag}>", [:standalone_tag, tag]] },
    '{' => [:tidylink_start, nil],
    '}' => [:tidylink_mid, nil],
    '\\' => [:escape, nil],
    '[' => nil # To make `label[url]` scan as separate tokens
  } # :nodoc:

  multi_char_tokens_regexp = Regexp.union(TOKENS.keys.select {|s| s.size > 1 }).source
  token_starts_regexp = TOKENS.keys.map {|s| s[0] }.uniq.map {|s| Regexp.escape(s) }.join

  SCANNER_REGEXP =
    /(?:
      #{multi_char_tokens_regexp}
      |[^#{token_starts_regexp}\sa-zA-Z0-9\.]+ # chunk of normal text
      |\s+|[a-zA-Z0-9\.]+|.
    )/x # :nodoc:

  # Characters that can be escaped with backslash.
  ESCAPING_CHARS = '\\*_+`{}[]<>' # :nodoc:

  # Pattern to match code block content until <code></tt></code> or <tt></code></tt>.
  CODEBLOCK_REGEXPS = CODEBLOCK_TAGS.to_h {|name| [name, /((?:\\.|[^\\])*?)<\/#{name}>/] } # :nodoc:

  # Word contains alphanumeric and <tt>_./:[]-</tt> characters.
  # Word may start with <tt>#</tt> and may end with any non-space character. (e.g. <tt>#eql?</tt>).
  # Underscore delimiter have special rules.
  WORD_REGEXPS = {
    # Words including _, longest match.
    # Example: `_::A_` `_-42_` `_A::B::C.foo_bar[baz]_` `_kwarg:_`
    # Content must not include _ followed by non-alphanumeric character
    # Example: `_host_:_port_` will be `_host_` + `:` + `_port_`
    '_' => /#?([a-zA-Z0-9.\/:\[\]-]|_+[a-zA-Z0-9])+[^\s]?_(?=[^a-zA-Z0-9_]|\z)/,
    # Words allowing _ but not allowing __
    '__' => /#?[a-zA-Z0-9.\/:\[\]-]*(_[a-zA-Z0-9.\/:\[\]-]+)*[^\s]?__(?=[^a-zA-Z0-9]|\z)/,
    **%w[* ** + ++ ` ``].to_h do |s|
      # normal words that can be used within +word+ or *word*
      [s, /#?[a-zA-Z0-9_.\/:\[\]-]+[^\s]?#{Regexp.escape(s)}(?=[^a-zA-Z0-9]|\z)/]
    end
  } # :nodoc:

  def initialize(string)
    @scanner = StringScanner.new(string)
    @last_match = nil
    @scanner_negative_cache = Set.new
    @stack = []
    @delimiters = {}
  end

  # Return the current parsing node on <tt>@stack</tt>.

  def current
    @stack.last
  end

  # Parse and return an array of nodes.
  # Node format:
  #   {
  #     type: :EM | :BOLD | :BOLD_WORD | :EM_WORD | :TT | :STRIKE | :HARD_BREAK | :TIDYLINK,
  #     url: string # only for :TIDYLINK
  #     children: [string_or_node, ...]
  #   }

  def parse
    stack_push(:root, nil)
    while true
      type, token, value = scan_token
      close = nil
      tidylink_url = nil
      case type
      when :node
        current[:children] << value
        invalidate_open_tidylinks if value[:type] == :TIDYLINK
      when :eof
        close = :root
      when :tidylink_open
        stack_push(:tidylink, token)
      when :tidylink_close
        close = :tidylink
        if value
          tidylink_url = value
        else
          # Tidylink closing brace without URL part. Treat opening and closing braces as normal text
          # `{labelnodes}...` case.
          current[:children] << token
        end
      when :invalidated_tidylink_close
        # `{...{label}[url]...}` case. Nested tidylink invalidates outer one. The last `}` closes the invalidated tidylink.
        current[:children] << token
        close = :invalidated_tidylink
      when :text
        current[:children] << token
      when :open
        stack_push(value, token)
      when :close
        if @delimiters[value]
          close = value
        else
          # closing tag without matching opening tag. Treat as normal text.
          current[:children] << token
        end
      end

      next unless close

      while current[:delimiter] != close
        children = current[:children]
        open_token = current[:token]
        stack_pop
        current[:children] << open_token if open_token
        current[:children].concat(children)
      end

      token = current[:token]
      children = compact_string(current[:children])
      stack_pop

      return children if close == :root

      if close == :tidylink || close == :invalidated_tidylink
        if tidylink_url
          current[:children] << { type: :TIDYLINK, children: children, url: tidylink_url }
          invalidate_open_tidylinks
        else
          current[:children] << token
          current[:children].concat(children)
        end
      else
        current[:children] << { type: TAGS[close], children: children }
      end
    end
  end

  private

  # When a valid tidylink node is encountered, invalidate all nested tidylinks.

  def invalidate_open_tidylinks
    return unless @delimiters[:tidylink]

    @delimiters[:invalidated_tidylink] ||= []
    @delimiters[:tidylink].each do |idx|
      @delimiters[:invalidated_tidylink] << idx
      @stack[idx][:delimiter] = :invalidated_tidylink
    end
    @delimiters.delete(:tidylink)
  end

  # Pop the top node off the stack when node is closed by a closing delimiter or an error.

  def stack_pop
    delimiter = current[:delimiter]
    @delimiters[delimiter].pop
    @delimiters.delete(delimiter) if @delimiters[delimiter].empty?
    @stack.pop
  end

  # Push a new node onto the stack when encountering an opening delimiter.

  def stack_push(delimiter, token)
    node = { delimiter: delimiter, token: token, children: [] }
    (@delimiters[delimiter] ||= []) << @stack.size
    @stack << node
  end

  # Compacts adjacent strings in +nodes+ into a single string.

  def compact_string(nodes)
    nodes.chunk {|e| String === e }.flat_map do |is_str, elems|
      is_str ? elems.join : elems
    end
  end

  # Scan from StringScanner with +pattern+
  # If +negative_cache+ is true, caches scan failure result. <tt>scan(pattern, negative_cache: true)</tt> return nil when it is called again after a failure.
  # Be careful to use +negative_cache+ with a pattern and position that does not match after previous failure.

  def strscan(pattern, negative_cache: false)
    return if negative_cache && @scanner_negative_cache.include?(pattern)

    string = @scanner.scan(pattern)
    @last_match = string if string
    @scanner_negative_cache << pattern if !string && negative_cache
    string
  end

  # Scan and return the next token for parsing.
  # Returns <tt>[token_type, token_string_or_nil, extra_info]</tt>

  def scan_token
    last_match = @last_match
    token = strscan(SCANNER_REGEXP)
    type, name = TOKENS[token]

    case type
    when :word_pair
      # If the character before word pair delimiter is alphanumeric, do not treat as word pair.
      word_pair = strscan(WORD_REGEXPS[token]) unless /[a-zA-Z0-9]\z/.match?(last_match)

      if word_pair.nil?
        [:text, token, nil]
      elsif token == '__' && word_pair.match?(/\A[a-zA-Z]+__\z/)
        # Special exception: __FILE__, __LINE__, __send__ should be treated as normal text.
        [:text, "#{token}#{word_pair}", nil]
      else
        [:node, nil, { type: WORD_PAIRS[token], children: [word_pair.delete_suffix(token)] }]
      end
    when :open_tag
      [:open, token, name]
    when :close_tag
      [:close, token, name]
    when :code_start
      if (codeblock = strscan(CODEBLOCK_REGEXPS[name], negative_cache: true))
        # Need to unescape `\\` and `\<`.
        # RDoc also unescapes backslash + word separators, but this is not really necessary.
        content = codeblock.delete_suffix("</#{name}>").gsub(/\\(.)/) { '\\<*+_`'.include?($1) ? $1 : $& }
        [:node, nil, { type: :TT, children: content.empty? ? [] : [content] }]
      else
        [:text, token, nil]
      end
    when :standalone_tag
      [:node, nil, { type: STANDALONE_TAGS[name], children: [] }]
    when :tidylink_start
      [:tidylink_open, token, nil]
    when :tidylink_mid
      if @delimiters[:tidylink]
        if (url = read_tidylink_url)
          [:tidylink_close, nil, url]
        else
          [:tidylink_close, token, nil]
        end
      elsif @delimiters[:invalidated_tidylink]
        [:invalidated_tidylink_close, token, nil]
      else
        [:text, token, nil]
      end
    when :escape
      next_char = strscan(/./)
      if next_char.nil?
        # backslash at end of string
        [:text, '\\', nil]
      elsif next_char && ESCAPING_CHARS.include?(next_char)
        # escaped character
        [:text, next_char, nil]
      else
        # If next_char not an escaping character, it is treated as text token with backslash + next_char
        # For example, backslash of `\Ruby` (suppressed crossref) remains.
        [:text, "\\#{next_char}", nil]
      end
    else
      if token.nil?
        [:eof, nil, nil]
      elsif token.match?(/\A[A-Za-z0-9]*\z/) && (url = read_tidylink_url)
        # Simplified tidylink: label[url]
        [:node, nil, { type: :TIDYLINK, children: [token], url: url }]
      else
        [:text, token, nil]
      end
    end
  end

  # Read the URL part of a tidylink from the current position.
  # Returns nil if no valid URL part is found.
  # URL part is enclosed in square brackets and may contain escaped brackets.
  # Example: <tt>[http://example.com/?q=\[\]]</tt> represents <tt>http://example.com/?q=[]</tt>.
  # If we're accepting rdoc-style links in markdown, url may include <tt>*+<_</tt> with backslash escape.

  def read_tidylink_url
    bracketed_url = strscan(/\[([^\s\[\]\\]|\\[\[\]\\*+<_])+\]/)
    bracketed_url[1...-1].gsub(/\\(.)/, '\1') if bracketed_url
  end
end
