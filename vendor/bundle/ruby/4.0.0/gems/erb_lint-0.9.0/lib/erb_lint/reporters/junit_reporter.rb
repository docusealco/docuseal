# frozen_string_literal: true

module ERBLint
  module Reporters
    class JunitReporter < Reporter
      ESCAPE_MAP = {
        '"' => "&quot;",
        "'" => "&apos;",
        "<" => "&lt;",
        ">" => "&gt;",
        "&" => "&amp;",
      }.freeze

      PROPERTIES = [
        ["erb_lint_version", ERBLint::VERSION],
        ["ruby_engine", RUBY_ENGINE],
        ["ruby_version", RUBY_VERSION],
        ["ruby_patchlevel", RUBY_PATCHLEVEL.to_s],
        ["ruby_platform", RUBY_PLATFORM],
      ].freeze

      def preview; end

      def show
        puts %(<?xml version="1.0" encoding="UTF-8"?>)
        puts %(<testsuite name="erblint" tests="#{@stats.processed_files.size}" failures="#{@stats.found}">)

        puts %(  <properties>)
        PROPERTIES.each do |key, value|
          puts %(    <property name="#{xml_escape(key)}" value="#{xml_escape(value)}"/>)
        end
        puts %(  </properties>)

        processed_files.each do |filename, offenses|
          filename_escaped = xml_escape(filename)
          if offenses.empty?
            puts %(  <testcase name="#{filename_escaped}" file="#{filename_escaped}"/>)
          else
            offenses.each do |offense|
              type = offense.simple_name
              message = "#{type}: #{offense.message}"
              body = "#{message} at #{filename}:#{offense.line_number}:#{offense.column}"

              puts %(  <testcase name="#{filename_escaped}" file="#{filename_escaped}" lineno="#{offense.line_number}">)
              puts %(    <failure message="#{xml_escape(message)}" type="#{xml_escape(type)}">)
              puts %(      #{xml_escape(body)})
              puts %(    </failure>)
              puts %(  </testcase>)
            end
          end
        end

        puts %(</testsuite>)
      end

      private

      def xml_escape(string)
        string.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
      end
    end
  end
end
