# frozen_string_literal: true

require 'json'
require_relative '../../../modules/b64'

# Relegate internal functions. Make overriding navs easier.
class Pagy
  private

  # Compose the data-pagy attribute, with the base64 encoded JSON-serialized args. Use the faster oj gem if defined.
  def data_pagy_attribute(*args)
    data = if defined?(Oj)
             Oj.dump(args, mode: :compat)
           else
             JSON.dump(args)
           end

    %(data-pagy="#{B64.encode(data)}")
  end
end
