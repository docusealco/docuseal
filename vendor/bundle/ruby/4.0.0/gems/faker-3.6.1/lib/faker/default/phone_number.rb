# frozen_string_literal: true

module Faker
  class PhoneNumber < Base
    class << self
      ##
      # Produces a phone number in a random format without the country code and it can have different dividers.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.phone_number #=> "(504) 113-1705"
      #   Faker::PhoneNumber.phone_number #=> "662.291.7201"
      #   Faker::PhoneNumber.phone_number #=> "9415283713"
      #
      # @faker.version 0.3.0
      def phone_number
        parse('phone_number.formats')
      end

      ##
      # Produces a random cell phone number in a random format without the country code and it can have different dividers.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone #=> "(836) 115-8995"
      #   Faker::PhoneNumber.cell_phone #=> "382-597-5739"
      #   Faker::PhoneNumber.cell_phone #=> "316.828.1822"
      #
      # @faker.version 1.0.0
      def cell_phone
        parse('cell_phone.formats')
      end

      ##
      # Produces a random country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.country_code #=> "+20"
      #   Faker::PhoneNumber.country_code #=> "+39"
      #   Faker::PhoneNumber.country_code #=> "+852"
      #
      # @faker.version 1.9.2
      def country_code
        "+#{fetch('phone_number.country_code')}"
      end

      ##
      # Produces a random phone number with country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.phone_number_with_country_code #=> "+55 466-746-6882"
      #   Faker::PhoneNumber.phone_number_with_country_code #=> "+81 3718219558"
      #   Faker::PhoneNumber.phone_number_with_country_code #=> "+49 140 957 9846"
      #
      # @faker.version 1.9.2
      def phone_number_with_country_code
        "#{country_code} #{phone_number}"
      end

      ##
      # Produces a random cell phone number with country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone_with_country_code #=> "+852 (190) 987-9034"
      #   Faker::PhoneNumber.cell_phone_with_country_code #=> "+64 (820) 583-6474"
      #   Faker::PhoneNumber.cell_phone_with_country_code #=> "+1 591.871.7985"
      #
      # @faker.version 1.9.2
      def cell_phone_with_country_code
        "#{country_code} #{cell_phone}"
      end

      ##
      # Produces a random phone number in e164 format, i.e., without any dividers.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone_in_e164 #=> "+542024834991"
      #   Faker::PhoneNumber.cell_phone_in_e164 #=> "+8522846847703"
      #   Faker::PhoneNumber.cell_phone_in_e164 #=> "+649477546575"
      #
      # @faker.version 1.9.2
      def cell_phone_in_e164
        cell_phone_with_country_code.delete('^+0-9')
      end

      ##
      # Produces a random area code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.area_code #=> "201"
      #   Faker::PhoneNumber.area_code #=> "613"
      #   Faker::PhoneNumber.area_code #=> "321"
      #
      # @faker.version 1.3.0
      def area_code
        fetch('phone_number.area_code')
      end

      ##
      # Produces a random exchange code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.exchange_code #=> "208"
      #   Faker::PhoneNumber.exchange_code #=> "415"
      #   Faker::PhoneNumber.exchange_code #=> "652"
      #
      # @faker.version 1.3.0
      def exchange_code
        fetch('phone_number.exchange_code')
      end

      ##
      # Produces a random extension / subscriber number. Can be used for both extensions and last four digits of phone number.
      #
      # @param length [Integer] Specifies the length of the return value. Defaults to 4.
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.subscriber_number #=> "3873"
      #   Faker::PhoneNumber.subscriber_number(length: 2) #=> "39"
      #   Faker::PhoneNumber.extension #=> "3764"
      #   Faker::PhoneNumber.extension(length: 2) => "37"
      #
      # @faker.version 1.3.0
      def subscriber_number(length: 4)
        if !length.is_a?(Integer) || length > 10
          raise ArgumentError, 'length must be an Integer and be lesser than 10'
        end

        generate(:string) do |g|
          g.int(length: length)
        end
      end

      alias extension subscriber_number
    end
  end
end
