# frozen_string_literal: true

require "optparse"
require "diff/lcs/hunk"

class Diff::LCS::Ldiff # :nodoc:
  # standard:disable Layout/HeredocIndentation
  BANNER = <<-COPYRIGHT
ldiff #{Diff::LCS::VERSION}
  Copyright 2004-2025 Austin Ziegler

  Part of Diff::LCS.
  https://github.com/halostatue/diff-lcs

  This program is free software. It may be redistributed and/or modified under
  the terms of the GPL version 2 (or later), the Perl Artistic licence, or the
  MIT licence.
  COPYRIGHT
  # standard:enable Layout/HeredocIndentation

  InputInfo = Struct.new(:filename, :data, :stat) do
    def initialize(filename)
      super(filename, ::File.read(filename), ::File.stat(filename))
    end
  end

  attr_reader :format, :lines # :nodoc:
  attr_reader :file_old, :file_new # :nodoc:
  attr_reader :data_old, :data_new # :nodoc:

  def self.run(args, input = $stdin, output = $stdout, error = $stderr) # :nodoc:
    new.run(args, input, output, error)
  end

  def initialize
    @binary = nil
    @format = :old
    @lines = 0
  end

  def run(args, _input = $stdin, output = $stdout, error = $stderr) # :nodoc:
    args.options do |o|
      o.banner = "Usage: #{File.basename($0)} [options] oldfile newfile"
      o.separator ""
      o.on(
        "-c", "-C", "--context [LINES]", Integer,
        "Displays a context diff with LINES lines", "of context. Default 3 lines."
      ) do |ctx|
        @format = :context
        @lines = ctx || 3
      end
      o.on(
        "-u", "-U", "--unified [LINES]", Integer,
        "Displays a unified diff with LINES lines", "of context. Default 3 lines."
      ) do |ctx|
        @format = :unified
        @lines = ctx || 3
      end
      o.on("-e", "Creates an 'ed' script to change", "oldfile to newfile.") do |_ctx|
        @format = :ed
      end
      o.on("-f", "Creates an 'ed' script to change", "oldfile to newfile in reverse order.") do |_ctx|
        @format = :reverse_ed
      end
      o.on(
        "-a", "--text",
        "Treat the files as text and compare them", "line-by-line, even if they do not seem", "to be text."
      ) do |_txt|
        @binary = false
      end
      o.on("--binary", "Treats the files as binary.") do |_bin|
        @binary = true
      end
      o.on("-q", "--brief", "Report only whether or not the files", "differ, not the details.") do |_ctx|
        @format = :report
      end
      o.on_tail("--help", "Shows this text.") do
        error << o
        return 0
      end
      o.on_tail("--version", "Shows the version of Diff::LCS.") do
        error << Diff::LCS::Ldiff::BANNER
        return 0
      end
      o.on_tail ""
      o.on_tail 'By default, runs produces an "old-style" diff, with output like UNIX diff.'
      o.parse!
    end

    unless args.size == 2
      error << args.options
      return 127
    end

    # Defaults are for old-style diff
    @format ||= :old
    @lines ||= 0

    file_old, file_new = *ARGV
    diff?(
      InputInfo.new(file_old),
      InputInfo.new(file_new),
      @format,
      output,
      binary: @binary,
      lines: @lines
    ) ? 1 : 0
  end

  def diff?(info_old, info_new, format, output, binary: nil, lines: 0)
    case format
    when :context
      char_old = "*" * 3
      char_new = "-" * 3
    when :unified
      char_old = "-" * 3
      char_new = "+" * 3
    end

    # After we've read up to a certain point in each file, the number of
    # items we've read from each file will differ by FLD (could be 0).
    file_length_difference = 0

    # Test binary status
    if binary.nil?
      old_bin = info_old.data[0, 4096].include?("\0")
      new_bin = info_new.data[0, 4096].include?("\0")
      binary = old_bin || new_bin
    end

    # diff yields lots of pieces, each of which is basically a Block object
    if binary
      has_diffs = (info_old.data != info_new.data)
      if format != :report
        if has_diffs
          output << "Binary files #{info_old.filename} and #{info_new.filename} differ\n"
          return true
        end
        return false
      end
    else
      data_old = info_old.data.lines.to_a
      data_new = info_new.data.lines.to_a
      diffs = Diff::LCS.diff(data_old, data_new)
      return false if diffs.empty?
    end

    case format
    when :report
      output << "Files #{info_old.filename} and #{info_new.filename} differ\n"
      return true
    when :unified, :context
      ft = info_old.stat.mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.000000000 %z")
      output << "#{char_old} #{info_old.filename}\t#{ft}\n"
      ft = info_new.stat.mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.000000000 %z")
      output << "#{char_new} #{info_new.filename}\t#{ft}\n"
    when :ed
      real_output = output
      output = []
    end

    # Loop over hunks. If a hunk overlaps with the last hunk, join them.
    # Otherwise, print out the old one.
    oldhunk = hunk = nil
    diffs.each do |piece|
      begin
        hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, lines, file_length_difference)
        file_length_difference = hunk.file_length_difference

        next unless oldhunk
        next if lines.positive? && hunk.merge(oldhunk)

        output << oldhunk.diff(format)
        output << "\n" if format == :unified
      ensure
        oldhunk = hunk
      end
    end

    last = oldhunk.diff(format, true)
    last << "\n" unless last.is_a?(Diff::LCS::Hunk) || last.empty? || last.end_with?("\n")

    output << last

    output.reverse_each { |e| real_output << e.diff(:ed_finish, e == output[0]) } if format == :ed

    true
  end
end
