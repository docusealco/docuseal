# frozen_string_literal: true

class Pagy
  # The aliaser defines loader methods and aliases them.
  # When a method is called for the first time, its loader will load the full implementation
  # which will overwrite the alias and will be executed.
  # Subsequent calls will run the full implementation directly.
  aliaser = lambda do |receiver, paths|
              receiver.instance_eval do
                paths.each do |visibility, methods|
                  methods.each do |method, path|
                    loader_name = :"_pagy_loader_for_#{method}"
                    define_method(loader_name) do |*args, **kwargs|
                      # Tests shadow the usage of these lines
                      # :nocov:
                      require_relative path
                      send(method, *args, **kwargs)
                      # :nocov:
                    end
                    alias_method method, loader_name
                    send(visibility, method)
                  end
                end
              end
            end

  module HelperLoader
  end

  paths = { public: { page_url:     'page_url',
                      data_hash:    'data_hash',
                      headers_hash: 'headers_hash',
                      urls_hash:    'urls_hash',
                      next_tag:     'anchor_tags' } }.freeze

  aliaser.(HelperLoader, paths)

  module NumericHelperLoader
  end

  paths = { public:    { previous_tag:            'anchor_tags',
                         input_nav_js:            'input_nav_js',
                         info_tag:                'info_tag',
                         limit_tag_js:            'limit_tag_js',
                         series_nav:              'series_nav',
                         series_nav_js:           'series_nav_js' },
            protected: { bootstrap_series_nav:    'bootstrap/series_nav',
                         bootstrap_series_nav_js: 'bootstrap/series_nav_js',
                         bootstrap_input_nav_js:  'bootstrap/input_nav_js',
                         bulma_series_nav:        'bulma/series_nav',
                         bulma_series_nav_js:     'bulma/series_nav_js',
                         bulma_input_nav_js:      'bulma/input_nav_js' } }.freeze

  aliaser.(NumericHelperLoader, paths)
end
