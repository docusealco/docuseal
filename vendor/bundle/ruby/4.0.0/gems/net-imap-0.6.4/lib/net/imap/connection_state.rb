# frozen_string_literal: true

module Net
  class IMAP
    class ConnectionState < Data # :nodoc:
      def self.define(symbol, *attrs)
        symbol => Symbol
        state = super(*attrs)
        state.const_set :NAME, symbol
        state
      end

      def symbol; self.class::NAME      end
      def name;   self.class::NAME.name end
      alias to_sym symbol

      def deconstruct; [symbol, *super] end

      def deconstruct_keys(names)
        hash = super
        hash[:symbol] = symbol if names.nil? || names.include?(:symbol)
        hash[:name]   = name   if names.nil? || names.include?(:name)
        hash
      end

      def to_h(&block)
        hash = deconstruct_keys(nil)
        block ? hash.to_h(&block) : hash
      end

      def not_authenticated?; to_sym == :not_authenticated end
      def authenticated?;     to_sym == :authenticated     end
      def selected?;          to_sym == :selected          end
      def logout?;            to_sym == :logout            end

      NotAuthenticated = define(:not_authenticated)
      Authenticated    = define(:authenticated)
      Selected         = define(:selected)
      Logout           = define(:logout)

      class << self
        undef :define
      end
      freeze
    end

  end
end
