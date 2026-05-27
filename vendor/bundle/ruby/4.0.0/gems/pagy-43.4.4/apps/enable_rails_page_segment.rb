# frozen_string_literal: true

# ################# IMPORTANT WARNING #################
# This setup forces Pagy to use the Rails `url_for` method,
# which is significantly slower (~20x) than Pagy's native URL generation.

# Use this file ONLY if you absolutely want to support the page param as a dynamic segment.
# (e.g. get '/comments(/:page)', to: 'comments#index').
# #####################################################

# USAGE

# initializers/pagy.rb
# require Pagy::ROOT.join('apps/enable_rails_page_segment.rb')

# config/routes.rb (example)
# get '/comments(/:page)', to: 'comments#index'


# Use plain Strings tokens instead of Pagy::EscapedValue strings
Pagy.send(:remove_const, :PAGE_TOKEN)  ; Pagy::PAGE_TOKEN  = '___PAGY_PAGE___'
Pagy.send(:remove_const, :LIMIT_TOKEN) ; Pagy::LIMIT_TOKEN = '___PAGY_LIMIT___'

# Require the pagy sources to override
require_relative '../lib/pagy/toolbox/paginators/method'
require_relative '../lib/pagy/modules/abilities/linkable'

class Pagy
  # Switch to the `request.params` to get access to rails-added path parameters
  module RequestOverride
    def get_params(request)
      request.params
    end
  end
  Request.prepend RequestOverride

  # Inject the caller context into the Pagy instance
  module MethodOverride
    def pagy(...)
      super.tap { _1[0].instance_variable_set(:@context, self) }
    end
  end
  Method.prepend MethodOverride

  # Compose the final URL using `url_for`.
  module LinkableOverride
    def compose_url(absolute, _path, params, fragment)
      params[:anchor]    = fragment if fragment
      params[:only_path] = !absolute
      @context.url_for(params)
    end
  end
  Linkable.prepend LinkableOverride
end
