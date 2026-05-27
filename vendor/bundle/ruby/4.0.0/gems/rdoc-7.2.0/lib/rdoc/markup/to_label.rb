# frozen_string_literal: true
require 'cgi/escape'
require 'cgi/util' unless defined?(CGI::EscapeExt)

##
# Creates HTML-safe labels suitable for use in id attributes.  Tidylinks are
# converted to their link part and cross-reference links have the suppression
# marks removed (\\SomeClass is converted to SomeClass).

class RDoc::Markup::ToLabel < RDoc::Markup::Formatter

  attr_reader :res # :nodoc:

  ##
  # Creates a new formatter that will output HTML-safe labels

  def initialize(markup = nil)
    super nil, markup

    @markup.add_regexp_handling RDoc::CrossReference::CROSSREF_REGEXP, :CROSSREF

    @res = []
  end

  def handle_PLAIN_TEXT(text)
    @res << text
  end

  def handle_REGEXP_HANDLING_TEXT(text)
    @res << text
  end

  def handle_TT(text)
    @res << text
  end

  def extract_plaintext(text)
    @res = []
    handle_inline(text)
    @res.join
  end

  ##
  # Converts +text+ to an HTML-safe label using GitHub-style anchor formatting.

  def convert(text)
    label = extract_plaintext(text)

    RDoc::Text.to_anchor(label)
  end

  ##
  # Converts +text+ to an HTML-safe label using legacy RDoc formatting.
  # Used for generating backward-compatible anchor aliases.

  def convert_legacy(text)
    label = extract_plaintext(text)

    CGI.escape(label).gsub('%', '-').sub(/^-/, '')
  end

  ##
  # Converts the CROSSREF +target+ to plain text, removing the suppression
  # marker, if any

  def handle_regexp_CROSSREF(text)
    text.sub(/^\\/, '')
  end

  alias accept_blank_line         ignore
  alias accept_block_quote        ignore
  alias accept_heading            ignore
  alias accept_list_end           ignore
  alias accept_list_item_end      ignore
  alias accept_list_item_start    ignore
  alias accept_list_start         ignore
  alias accept_paragraph          ignore
  alias accept_raw                ignore
  alias accept_rule               ignore
  alias accept_verbatim           ignore
  alias end_accepting             ignore
  alias start_accepting           ignore

end
