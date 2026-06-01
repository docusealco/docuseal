module RailsI18n
  module Pluralization
    module Arabic
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          mod100 = n % 100

          if n == 0
            :zero
          elsif n == 1
            :one
          elsif n == 2
            :two
          elsif (3..10).to_a.include?(mod100)
            :few
          elsif (11..99).to_a.include?(mod100)
            :many
          else
            :other
          end
        end
      end
    end

    module ScottishGaelic
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          floorn = n.floor

          if floorn == 1 || floorn == 11
            :one
          elsif floorn == 2 || floorn == 12
            :two
          elsif (3..19).member?(floorn)
            :few
          else
            :other
          end
        end
      end
    end

    module UpperSorbian
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          mod100 = n % 100

          case mod100
          when 1 then :one
          when 2 then :two
          when 3, 4 then :few
          else :other
          end
        end
      end
    end

    module Lithuanian
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          mod10 = n % 10
          mod100 = n % 100

          if mod10 == 1 && !(11..19).to_a.include?(mod100)
            :one
          elsif (2..9).to_a.include?(mod10) && !(11..19).to_a.include?(mod100)
            :few
          else
            :other
          end
        end
      end
    end

    module Latvian
      def self.rule
        lambda do |n|
          if n.is_a?(Numeric) && n % 10 == 1 && n % 100 != 11
            :one
          else
            :other
          end
        end
      end
    end

    module Macedonian
      def self.rule
        lambda do |n|
          if n.is_a?(Numeric) && n % 10 == 1 && n != 11
            :one
          else
            :other
          end
        end
      end
    end

    module Polish
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          mod10 = n % 10
          mod100 = n % 100

          if n == 1
            :one
          elsif [2, 3, 4].include?(mod10) && ![12, 13, 14].include?(mod100)
            :few
          elsif [0, 1, 5, 6, 7, 8, 9].include?(mod10) || [12, 13, 14].include?(mod100)
            :many
          else
            :other
          end
        end
      end
    end

    module Slovenian
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          case n % 100
          when 1 then :one
          when 2 then :two
          when 3, 4 then :few
          else :other
          end
        end
      end
    end
  end
end
