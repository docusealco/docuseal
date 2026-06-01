# frozen_string_literal: true

require "spec_helper"

RSpec.describe "bin/ldiff" do
  include CaptureSubprocessIO

  # standard:disable Style/HashSyntax
  fixtures = [
    {:name => "diff", :left => "aX", :right => "bXaX", :diff => 1},
    {:name => "diff.missing_new_line1", :left => "four_lines", :right => "four_lines_with_missing_new_line", :diff => 1},
    {:name => "diff.missing_new_line2", :left => "four_lines_with_missing_new_line", :right => "four_lines", :diff => 1},
    {:name => "diff.issue95_trailing_context", :left => "123_x", :right => "456_x", :diff => 1},
    {:name => "diff.four_lines.vs.empty", :left => "four_lines", :right => "empty", :diff => 1},
    {:name => "diff.empty.vs.four_lines", :left => "empty", :right => "four_lines", :diff => 1},
    {:name => "diff.bin1", :left => "file1.bin", :right => "file1.bin", :diff => 0},
    {:name => "diff.bin2", :left => "file1.bin", :right => "file2.bin", :diff => 1},
    {:name => "diff.chef", :left => "old-chef", :right => "new-chef", :diff => 1},
    {:name => "diff.chef2", :left => "old-chef2", :right => "new-chef2", :diff => 1}
  ].product([nil, "-e", "-f", "-c", "-u"]).map { |(fixture, flag)|
    fixture = fixture.dup
    fixture[:flag] = flag
    fixture
  }
  # standard:enable Style/HashSyntax

  def self.test_ldiff(fixture)
    desc = [
      fixture[:flag],
      "spec/fixtures/#{fixture[:left]}",
      "spec/fixtures/#{fixture[:right]}",
      "#",
      "=>",
      "spec/fixtures/ldiff/output.#{fixture[:name]}#{fixture[:flag]}"
    ].join(" ")

    it desc do
      stdout, stderr, status = run_ldiff(fixture)
      expect(status).to eq(fixture[:diff])
      expect(stderr).to eq(read_fixture(fixture, mode: "error", allow_missing: true))
      expect(stdout).to eq(read_fixture(fixture, mode: "output", allow_missing: false))
    end
  end

  fixtures.each do |fixture|
    test_ldiff(fixture)
  end

  def read_fixture(options, mode: "output", allow_missing: false)
    fixture = options.fetch(:name)
    flag = options.fetch(:flag)
    name = "spec/fixtures/ldiff/#{mode}.#{fixture}#{flag}"

    return "" if !::File.exist?(name) && allow_missing

    data = IO.__send__(IO.respond_to?(:binread) ? :binread : :read, name)
    clean_data(data, flag)
  end

  def clean_data(data, flag)
    data =
      case flag
      when "-c", "-u"
        clean_output_timestamp(data)
      else
        data
      end
    data.gsub(/\r\n?/, "\n")
  end

  def clean_output_timestamp(data)
    data.gsub(
      %r{
        ^
        [-+*]{3}
        \s*
        spec/fixtures/(\S+)
        \s*
        \d{4}-\d\d-\d\d
        \s*
        \d\d:\d\d:\d\d(?:\.\d+)
        \s*
        (?:[-+]\d{4}|Z)
      }x,
      '*** spec/fixtures/\1	0000-00-00 :00 =>:00 =>00.000000000 -0000'
    )
  end

  def run_ldiff(options)
    flag = options.fetch(:flag)
    left = options.fetch(:left)
    right = options.fetch(:right)

    stdout, stderr = capture_subprocess_io do
      system("ruby -Ilib bin/ldiff #{flag} spec/fixtures/#{left} spec/fixtures/#{right}")
    end

    [clean_data(stdout, flag), stderr, $?.exitstatus]
  end
end
