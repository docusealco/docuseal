# frozen_string_literal: true
##
# Parse a non-source file. We basically take the whole thing as one big
# comment.

class RDoc::Parser::Simple < RDoc::Parser

  include RDoc::Parser::Text

  parse_files_matching(//)

  attr_reader :content # :nodoc:

  ##
  # Prepare to parse a plain file

  def initialize(top_level, content, options, stats)
    super

    preprocess = RDoc::Markup::PreProcess.new @file_name, @options.rdoc_include

    content = RDoc::Text.expand_tabs(@content)
    @content, = preprocess.run_pre_processes(content, @top_level, 1, :simple)
  end

  ##
  # Extract the file contents and attach them to the TopLevel as a comment

  def scan
    content = remove_coding_comment @content

    comment = RDoc::Comment.new content, @top_level

    @top_level.comment = comment
    @top_level
  end

  ##
  # Removes the encoding magic comment from +text+

  def remove_coding_comment(text)
    text.sub(/\A# .*coding[=:].*$/, '')
  end
end
