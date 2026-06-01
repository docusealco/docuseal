module StripAttributes
  module Matchers
    # Whitespace is stripped from the beginning and end of the attribute
    #
    # RSpec Examples:
    #
    #   it { is_expected.to strip_attribute(:first_name) }
    #   it { is_expected.to strip_attributes(:first_name, :last_name) }
    #   it { is_expected.not_to strip_attribute(:password) }
    #   it { is_expected.not_to strip_attributes(:password, :encrypted_password) }
    #
    # Minitest Matchers Examples:
    #
    #   must { strip_attribute :first_name }
    #   must { strip_attributes(:first_name, :last_name) }
    #   wont { strip_attribute :password }
    #   wont { strip_attributes(:password, :encrypted_password) }
    def strip_attribute(*attributes)
      StripAttributeMatcher.new(attributes)
    end

    alias strip_attributes strip_attribute

    class StripAttributeMatcher
      def initialize(attributes)
        @attributes = attributes
        @options = {}
      end

      def matches?(subject)
        @attributes.all? do |attribute|
          @attribute = attribute
          subject.send("#{@attribute}=", " #{value} ")
          subject.valid?
          subject.send(@attribute) == value and collapse_spaces?(subject) and replace_newlines?(subject)
        end
      end

      def using(value)
        @options[:value] = value
        self
      end

      def collapse_spaces
        @options[:collapse_spaces] = true
        self
      end

      def replace_newlines
        @options[:replace_newlines] = true
        self
      end

      # RSpec 3.x
      def failure_message
        "Expected whitespace to be #{expectation} from ##{@attribute}, but it was not"
      end
      alias failure_message_for_should failure_message # RSpec 1.2, 2.x, and minitest-matchers

      # RSpec 3.x
      def failure_message_when_negated
        "Expected whitespace to remain on ##{@attribute}, but it was #{expectation}"
      end
      alias failure_message_for_should_not failure_message_when_negated # RSpec 1.2, 2.x, and minitest-matchers
      alias negative_failure_message       failure_message_when_negated # RSpec 1.1

      def description
        attrs = @attributes.map { |attr| "##{attr}" }.to_sentence
        "#{expectation(past: false)} whitespace from #{attrs}"
      end

      private

      def value
        @options[:value] || "string"
      end

      def collapse_spaces?(subject)
        return true unless @options[:collapse_spaces]

        subject.send("#{@attribute}=", " #{value}    #{value} ")
        subject.valid?
        subject.send(@attribute) == "#{value} #{value}"
      end

      def expectation(past: true)
        expectation = past ? "stripped" : "strip"
        expectation += past ? " and collapsed" : " and collapse" if @options[:collapse_spaces]
        expectation += past ? " and replaced" : " and replace" unless @options[:replace_newlines]
        expectation
      end

      def replace_newlines?(subject)
        return true unless @options[:replace_newlines]

        subject.send("#{@attribute}=", "#{value}\n#{value}")
        subject.valid?
        subject.send(@attribute) == "#{value} #{value}"
      end
    end
  end
end
