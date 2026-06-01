# frozen_string_literal: true

class Pagy
  # Decouple the request from the env, allowing non-rack apps to use pagy by passing a hash.
  # Resolve the :page and :limit options from params.
  class Request
    def initialize(options)
      @options = options
      request  = @options[:request]
      @base_url, @path, @params, @cookie =
        if request.is_a?(Hash)
          request.values_at(:base_url, :path, :params, :cookie)
        else
          [request.base_url, request.path, get_params(request), request.cookies['pagy']]
        end
      freeze
    end

    attr_reader :base_url, :path, :params, :cookie

    def resolve_page(force_integer: true)
      page_key = @options[:page_key] || DEFAULT[:page_key]
      page     = @params.dig(@options[:root_key], page_key) || @params[page_key]
      return [page.to_s.to_i, 1].max if force_integer

      page if page.is_a?(String) && !page.empty?
    end

    def resolve_limit
      default   = @options[:limit] || DEFAULT[:limit]
      max_limit = @options[:client_max_limit]
      return default unless max_limit

      limit_key = @options[:limit_key] || DEFAULT[:limit_key]
      limit     = (@params.dig(@options[:root_key], limit_key) || @params[limit_key]).to_s.to_i
      limit.zero? ? default : [limit, max_limit].min
    end

    private

    def get_params(request)
      request.GET.merge(request.POST).to_h.freeze
    end
  end
end
