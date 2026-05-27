module SnakyHash
  # serializer is being introduced as an always disabled option for backwards compatibility.
  # In snaky_hash v3 it will default to true.
  # If you want to start using it immediately, reopen this class and add the Serializer module:
  #
  #   SnakyHash::SymbolKeyed.class_eval do
  #     extend SnakyHash::Serializer
  #   end
  #
  class SymbolKeyed < Hashie::Mash
    include SnakyHash::Snake.new(key_type: :symbol, serializer: false)
  end
end
