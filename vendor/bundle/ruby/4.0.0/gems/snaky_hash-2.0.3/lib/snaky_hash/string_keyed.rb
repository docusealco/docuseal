module SnakyHash
  # serializer is being introduced as an always disabled option for backwards compatibility.
  # In snaky_hash v3 it will default to true.
  # If you want to start using it immediately, reopen this class and add the Serializer module:
  #
  #   SnakyHash::StringKeyed.class_eval do
  #     extend SnakyHash::Serializer
  #   end
  #
  class StringKeyed < Hashie::Mash
    include SnakyHash::Snake.new(key_type: :string, serializer: false)
  end
end
