require "shoulda/context"

module StripAttributes
  module Shoulda
    module Macros
      # Deprecated. Use `should strip_attribute :attribute` instead.
      def should_strip_attributes(*attributes)
        warn "[DEPRECATION] should_strip_attributes is deprecated. " <<
             "Use `should strip_attribute :attribute` instead."
        attributes.each do |attribute|
          attribute = attribute.to_sym
          should "strip whitespace from #{attribute}" do
            subject.send("#{attribute}=", " string ")
            subject.valid?
            assert_equal "string", subject.send(attribute)
          end
        end
      end

      # Deprecated. Use `should_not strip_attribute :attribute` instead.
      def should_not_strip_attributes(*attributes)
        warn "[DEPRECATION] should_not_strip_attributes is deprecated. " <<
             "Use `should_not strip_attribute :attribute` instead."
        attributes.each do |attribute|
          attribute = attribute.to_sym
          should "not strip whitespace from #{attribute}" do
            subject.send("#{attribute}=", " string ")
            subject.valid?
            assert_equal " string ", subject.send(attribute)
          end
        end
      end
    end
  end
end
