module Shakapacker::Helper
  # Returns the current Shakapacker instance.
  # Could be overridden to use multiple Shakapacker
  # configurations within the same app (e.g. with engines).
  def current_shakapacker_instance
    Shakapacker.instance
  end

  # Computes the relative path for a given Shakapacker asset.
  # Returns the relative path using manifest.json and passes it to path_to_asset helper.
  # This will use path_to_asset internally, so most of their behaviors will be the same.
  #
  # Example:
  #
  #   <%= asset_pack_path 'calendar.css' %> # => "/packs/calendar-1016838bab065ae1e122.css"
  def asset_pack_path(name, **options)
    path_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
  end

  # Computes the absolute path for a given Shakapacker asset.
  # Returns the absolute path using manifest.json and passes it to url_to_asset helper.
  # This will use url_to_asset internally, so most of their behaviors will be the same.
  #
  # Example:
  #
  #   <%= asset_pack_url 'calendar.css' %> # => "http://example.com/packs/calendar-1016838bab065ae1e122.css"
  def asset_pack_url(name, **options)
    url_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
  end

  # Computes the relative path for a given Shakapacker image with the same automated processing as image_pack_tag.
  # Returns the relative path using manifest.json and passes it to path_to_asset helper.
  # This will use path_to_asset internally, so most of their behaviors will be the same.
  def image_pack_path(name, **options)
    resolve_path_to_image(name, **options)
  end

  # Computes the absolute path for a given Shakapacker image with the same automated
  # processing as image_pack_tag. Returns the relative path using manifest.json
  # and passes it to path_to_asset helper. This will use path_to_asset internally,
  # so most of their behaviors will be the same.
  def image_pack_url(name, **options)
    resolve_path_to_image(name, **options.merge(protocol: :request))
  end

  # Creates an image tag that references the named pack file.
  #
  # Example:
  #
  #  <%= image_pack_tag 'application.png', size: '16x10', alt: 'Edit Entry' %>
  #  <img alt='Edit Entry' src='/packs/application-k344a6d59eef8632c9d1.png' width='16' height='10' />
  #
  #  <%= image_pack_tag 'picture.png', srcset: { 'picture-2x.png' => '2x' } %>
  #  <img srcset= "/packs/picture-2x-7cca48e6cae66ec07b8e.png 2x" src="/packs/picture-c38deda30895059837cf.png" >
  def image_pack_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{resolve_path_to_image(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(resolve_path_to_image(name), options)
  end

  # Creates a link tag for a favicon that references the named pack file.
  #
  # Example:
  #
  #  <%= favicon_pack_tag 'mb-icon.png', rel: 'apple-touch-icon', type: 'image/png' %>
  #  <link href="/packs/mb-icon-k344a6d59eef8632c9d1.png" rel="apple-touch-icon" type="image/png" />
  def favicon_pack_tag(name, **options)
    favicon_link_tag(resolve_path_to_image(name), options)
  end

  # Creates script tags that reference the js chunks from entrypoints when using split chunks API,
  # as compiled by webpack per the entries list in package/environments/base.js.
  # By default, this list is auto-generated to match everything in
  # app/javascript/entrypoints/*.js and all the dependent chunks. In production mode, the digested reference is automatically looked up.
  # See: https://webpack.js.org/plugins/split-chunks-plugin/
  #
  # Example:
  #
  #   <%= javascript_pack_tag 'calendar', 'map', 'data-turbolinks-track': 'reload' %> # =>
  #   <script src="/packs/vendor-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/calendar~runtime-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/calendar-1016838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/map~runtime-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/map-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #
  # DO:
  #
  #   <%= javascript_pack_tag 'calendar', 'map' %>
  #
  # DON'T:
  #
  #   <%= javascript_pack_tag 'calendar' %>
  #   <%= javascript_pack_tag 'map' %>
  #
  # Early Hints:
  #   By default, HTTP 103 Early Hints are sent automatically when this helper is called,
  #   allowing browsers to preload JavaScript assets in parallel with Rails rendering.
  #
  #   <%= javascript_pack_tag 'application' %>
  #   # Automatically sends early hints for 'application' pack
  #
  #   # Customize handling per pack:
  #   <%= javascript_pack_tag 'application', 'vendor',
  #         early_hints: { 'application' => 'preload', 'vendor' => 'prefetch' } %>
  #
  #   # Disable early hints:
  #   <%= javascript_pack_tag 'application', early_hints: false %>
  def javascript_pack_tag(*names, defer: true, async: false, early_hints: nil, **options)
    if @javascript_pack_tag_loaded
      raise "To prevent duplicated chunks on the page, you should call javascript_pack_tag only once on the page. " \
      "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helpers-javascript_pack_tag-and-stylesheet_pack_tag for the usage guide"
    end

    # Collect all packs (queue + direct args)
    append_javascript_pack_tag(*names, defer: defer, async: async)
    all_packs = javascript_pack_tag_queue.values.flatten.uniq

    # Resolve effective early hints value (nil = use config default)
    effective_hints = resolve_early_hints_value(early_hints, :javascript)

    # Send early hints automatically if enabled
    if early_hints_enabled? && effective_hints && effective_hints != "none"
      hints_config = normalize_pack_hints(all_packs, effective_hints)
      send_javascript_early_hints_internal(hints_config)
      # Flush accumulated hints (sends the single 103 response)
      flush_early_hints
    elsif early_hints_debug_enabled?
      store = early_hints_store
      store[:debug_buffer] ||= []
      store[:debug_buffer] << "<!-- Shakapacker Early Hints (JS): SKIPPED (early_hints: #{effective_hints.inspect}) -->"
    end

    sync = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:sync], type: :javascript)
    async = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:async], type: :javascript) - sync
    deferred = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:deferred], type: :javascript) - sync - async

    @javascript_pack_tag_loaded = true

    capture do
      # Output debug buffer first
      if early_hints_debug_enabled?
        store = early_hints_store
        if store[:debug_buffer] && store[:debug_buffer].any?
          concat store[:debug_buffer].join("\n").html_safe
          concat "\n"
        end
      end

      render_tags(async, :javascript, **options.dup.tap { |o| o[:async] = true })
      concat "\n" if async.any? && deferred.any?
      render_tags(deferred, :javascript, **options.dup.tap { |o| o[:defer] = true })
      concat "\n" if sync.any? && deferred.any?
      render_tags(sync, :javascript, options)
    end
  end

  # Creates a link tag, for preloading, that references a given Shakapacker asset.
  # In production mode, the digested reference is automatically looked up.
  # See: https://developer.mozilla.org/en-US/docs/Web/HTML/Preloading_content
  #
  # Example:
  #
  #   <%= preload_pack_asset 'fonts/fa-regular-400.woff2' %> # =>
  #   <link rel="preload" href="/packs/fonts/fa-regular-400-944fb546bd7018b07190a32244f67dc9.woff2" as="font" type="font/woff2" crossorigin="anonymous">
  def preload_pack_asset(name, **options)
    if self.class.method_defined?(:preload_link_tag)
      preload_link_tag(current_shakapacker_instance.manifest.lookup!(name), options)
    else
      raise "You need Rails >= 5.2 to use this tag."
    end
  end

  # Sends HTTP 103 Early Hints for specified packs with fine-grained control over
  # JavaScript and CSS handling. This is the "raw" method for maximum flexibility.
  #
  # Use this in controller actions BEFORE expensive work (database queries, API calls)
  # to maximize parallelism - the browser downloads assets while Rails processes the request.
  #
  # For simpler cases, use javascript_pack_tag and stylesheet_pack_tag which automatically
  # send hints when called (combining queued + direct pack names).
  #
  # HTTP 103 Early Hints allows the server to send preliminary responses with Link headers
  # before the final HTTP 200 response, enabling browsers to start downloading critical
  # assets during the server's "think time".
  #
  # Timeline:
  #   1. Browser requests page
  #   2. Controller calls send_pack_early_hints (this method)
  #   3. Server sends HTTP 103 with Link: headers
  #   4. Browser starts downloading assets IN PARALLEL with step 5
  #   5. Rails continues expensive work (queries, rendering)
  #   6. Server sends HTTP 200 with full HTML
  #   7. Assets already downloaded = faster page load
  #
  # Requires Rails 5.2+, HTTP/2, and server support (Puma 5+, nginx 1.13+).
  # Gracefully degrades if not supported.
  #
  # References:
  # - Rails API: https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-send_early_hints
  # - HTTP 103 Spec: https://datatracker.ietf.org/doc/html/rfc8297
  #
  # Examples:
  #
  #   # Controller pattern: send hints BEFORE expensive work
  #   def show
  #     send_pack_early_hints({
  #       "application" => { js: "preload", css: "preload" },
  #       "vendor" => { js: "prefetch", css: "none" }
  #     })
  #
  #     # Browser now downloading assets while we do expensive work
  #     @posts = Post.includes(:comments, :author).where(complex_conditions)
  #     # ... more expensive work ...
  #   end
  #
  #   # Supported handling values:
  #   # - "preload": High-priority, browser downloads immediately
  #   # - "prefetch": Low-priority, browser may download when idle
  #   # - "none" or false: Skip this asset type for this pack
  def send_pack_early_hints(config)
    return nil unless early_hints_supported? && early_hints_enabled?

    # Accumulate both JS and CSS hints, then send ONCE
    config.each do |pack_name, handlers|
      # Accumulate JavaScript hints
      js_handling = handlers[:js] || handlers["js"]
      normalized_js = normalize_hint_value(js_handling)
      if normalized_js
        send_early_hints_internal({ pack_name.to_s => normalized_js }, type: :javascript)
      end

      # Accumulate CSS hints
      css_handling = handlers[:css] || handlers["css"]
      normalized_css = normalize_hint_value(css_handling)
      if normalized_css
        send_early_hints_internal({ pack_name.to_s => normalized_css }, type: :stylesheet)
      end
    end

    # Flush the accumulated hints as a SINGLE 103 response
    # (Browsers only process the first 103)
    flush_early_hints

    nil
  end

  # Creates link tags that reference the css chunks from entrypoints when using split chunks API,
  # as compiled by webpack per the entries list in package/environments/base.js.
  # By default, this list is auto-generated to match everything in
  # app/javascript/entrypoints/*.js and all the dependent chunks. In production mode, the digested reference is automatically looked up.
  # See: https://webpack.js.org/plugins/split-chunks-plugin/
  #
  # Examples:
  #
  #   <%= stylesheet_pack_tag 'calendar', 'map' %> # =>
  #   <link rel="stylesheet" media="screen" href="/packs/3-8c7ce31a.chunk.css" />
  #   <link rel="stylesheet" media="screen" href="/packs/calendar-8c7ce31a.chunk.css" />
  #   <link rel="stylesheet" media="screen" href="/packs/map-8c7ce31a.chunk.css" />
  #
  #   When using the webpack-dev-server, CSS is inlined so HMR can be turned on for CSS,
  #   including CSS modules
  #   <%= stylesheet_pack_tag 'calendar', 'map' %> # => nil
  #
  # DO:
  #
  #   <%= stylesheet_pack_tag 'calendar', 'map' %>
  #
  # DON'T:
  #
  #   <%= stylesheet_pack_tag 'calendar' %>
  #   <%= stylesheet_pack_tag 'map' %>
  #
  # Early Hints:
  #   By default, HTTP 103 Early Hints are sent automatically when this helper is called,
  #   allowing browsers to preload CSS assets in parallel with Rails rendering.
  #
  #   <%= stylesheet_pack_tag 'application' %>
  #   # Automatically sends early hints for 'application' pack
  #
  #   # Customize handling per pack:
  #   <%= stylesheet_pack_tag 'application', 'vendor',
  #         early_hints: { 'application' => 'preload', 'vendor' => 'prefetch' } %>
  #
  #   # Disable early hints:
  #   <%= stylesheet_pack_tag 'application', early_hints: false %>
  def stylesheet_pack_tag(*names, early_hints: nil, **options)
    return "" if Shakapacker.inlining_css?

    # Collect all packs (queue + direct args)
    all_packs = ((@stylesheet_pack_tag_queue || []) + names).uniq

    # Resolve effective early hints value (nil = use config default)
    effective_hints = resolve_early_hints_value(early_hints, :stylesheet)

    # Send early hints automatically if enabled
    if early_hints_enabled? && effective_hints && effective_hints != "none"
      hints_config = normalize_pack_hints(all_packs, effective_hints)
      send_stylesheet_early_hints_internal(hints_config)
      # Flush accumulated hints (sends the single 103 response)
      flush_early_hints
    elsif early_hints_debug_enabled?
      store = early_hints_store
      store[:debug_buffer] ||= []
      store[:debug_buffer] << "<!-- Shakapacker Early Hints (CSS): SKIPPED (early_hints: #{effective_hints.inspect}) -->"
    end

    requested_packs = sources_from_manifest_entrypoints(names, type: :stylesheet)
    appended_packs = available_sources_from_manifest_entrypoints(@stylesheet_pack_tag_queue || [], type: :stylesheet)

    @stylesheet_pack_tag_loaded = true

    capture do
      # Output debug buffer first
      if early_hints_debug_enabled?
        store = early_hints_store
        if store[:debug_buffer] && store[:debug_buffer].any?
          concat store[:debug_buffer].join("\n").html_safe
          concat "\n"
        end
      end

      render_tags(requested_packs | appended_packs, :stylesheet, options)
    end
  end

  def append_stylesheet_pack_tag(*names)
    if @stylesheet_pack_tag_loaded
      raise "You can only call append_stylesheet_pack_tag before stylesheet_pack_tag helper. " \
      "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helper-append_javascript_pack_tag-prepend_javascript_pack_tag-and-append_stylesheet_pack_tag for the usage guide"
    end

    @stylesheet_pack_tag_queue ||= []
    @stylesheet_pack_tag_queue.concat names

    # prevent rendering Array#to_s representation when used with <%= … %> syntax
    nil
  end

  def append_javascript_pack_tag(*names, defer: true, async: false)
    update_javascript_pack_tag_queue(defer: defer, async: async) do |hash_key|
      javascript_pack_tag_queue[hash_key] |= names
    end
  end

  def prepend_javascript_pack_tag(*names, defer: true, async: false)
    update_javascript_pack_tag_queue(defer: defer, async: async) do |hash_key|
      javascript_pack_tag_queue[hash_key].unshift(*names)
    end
  end

  private

    def update_javascript_pack_tag_queue(defer:, async:)
      if @javascript_pack_tag_loaded
        raise "You can only call #{caller_locations(1..1).first.base_label} before javascript_pack_tag helper. " \
        "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helper-append_javascript_pack_tag-prepend_javascript_pack_tag-and-append_stylesheet_pack_tag for the usage guide"
      end

      # When both async and defer are specified, async takes precedence per HTML5 spec
      hash_key = if async
        :async
      elsif defer
        :deferred
      else
        :sync
      end
      yield(hash_key)

      # prevent rendering Array#to_s representation when used with <%= … %> syntax
      nil
    end

    def javascript_pack_tag_queue
      @javascript_pack_tag_queue ||= {
        async: [],
        deferred: [],
        sync: []
      }
    end

    def sources_from_manifest_entrypoints(names, type:)
      names.map { |name| current_shakapacker_instance.manifest.lookup_pack_with_chunks!(name.to_s, type: type) }.flatten.uniq
    end

    def available_sources_from_manifest_entrypoints(names, type:)
      names.map { |name| current_shakapacker_instance.manifest.lookup_pack_with_chunks(name.to_s, type: type) }.flatten.compact.uniq
    end

    def resolve_path_to_image(name, **options)
      path = name.starts_with?("static/") ? name : "static/#{name}"
      path_to_asset(current_shakapacker_instance.manifest.lookup!(path), options)
    rescue
      path_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
    end

    def lookup_integrity(source)
      (source.respond_to?(:dig) && source.dig("integrity")) || nil
    end

    def lookup_source(source)
      (source.respond_to?(:dig) && source.dig("src")) || source
    end

    # Handles rendering javascript and stylesheet tags with integrity, if that's enabled.
    def render_tags(sources, type, options)
      return unless sources.present? || type.present?

      # Temporarily disable Rails' built-in early hints for ALL tags
      # Rails' javascript_include_tag and stylesheet_link_tag call request.send_early_hints
      # We handle early hints ourselves before render_tags is called
      patched = false
      if respond_to?(:request) && request&.respond_to?(:send_early_hints)
        request.define_singleton_method(:send_early_hints) { |*args| nil }
        patched = true
      end

      begin
        sources.each.with_index do |source, index|
          # Duplicate options per iteration to avoid leaking integrity/crossorigin between tags
          local_options = options.dup
          tag_source = lookup_source(source)

          if current_shakapacker_instance.config.integrity[:enabled]
            integrity = lookup_integrity(source)

            if integrity.present?
              local_options[:integrity] = integrity
              local_options[:crossorigin] = current_shakapacker_instance.config.integrity[:cross_origin]
            end
          end

          if type == :javascript
            concat javascript_include_tag(tag_source, **local_options)
          else
            concat stylesheet_link_tag(tag_source, **local_options)
          end

          concat "\n" unless index == sources.size - 1
        end
      ensure
        # Restore original method by removing the singleton method
        if patched
          request.singleton_class.send(:remove_method, :send_early_hints)
        end
      end
    end

    # Check if early hints are supported by Rails and the request object
    def early_hints_supported?
      request.respond_to?(:send_early_hints)
    end

    # Check if early hints are enabled in configuration
    def early_hints_enabled?
      config = current_shakapacker_instance.config.early_hints rescue nil
      return false unless config
      # Handle both symbol and string keys from YAML config
      enabled = config[:enabled] || config["enabled"]
      enabled == true
    end

    # Check if early hints debug mode is enabled
    def early_hints_debug_enabled?
      config = current_shakapacker_instance.config.early_hints rescue nil
      return false unless config
      # Handle both symbol and string keys from YAML config
      debug = config[:debug] || config["debug"]
      debug == true
    end

    # Resolve the effective early hints value
    # If nil or true, read from config; otherwise use the provided value
    def resolve_early_hints_value(early_hints, asset_type)
      # If explicitly set to false or "none", use that
      return "none" if early_hints == false || early_hints == "none"

      # If nil or true, read from config
      if early_hints.nil? || early_hints == true
        config = current_shakapacker_instance.config.early_hints rescue nil
        return "preload" unless config  # Default fallback

        # Get type-specific config (js/css), handling both symbol and string keys
        type_key = asset_type == :javascript ? "js" : "css"
        value = config[type_key.to_sym] || config[type_key]
        return value || "preload"  # Default to preload if not configured
      end

      # Return provided value as-is (will be normalized later)
      early_hints
    end

    # Normalize pack hints into a hash mapping pack names to validated hint values
    # Converts booleans, validates strings, and ensures only valid values are used
    def normalize_pack_hints(packs, early_hints)
      # Normalize the hint value(s)
      if early_hints.is_a?(Hash)
        # Per-pack configuration
        packs.each_with_object({}) do |pack, result|
          hint_value = early_hints[pack] || early_hints[pack.to_s] || early_hints[pack.to_sym]
          result[pack] = normalize_hint_value(hint_value || "preload")
        end
      else
        # Single value for all packs
        normalized_value = normalize_hint_value(early_hints)
        packs.each_with_object({}) do |pack, result|
          result[pack] = normalized_value
        end
      end
    end

    # Normalize and validate a single hint value
    # Converts false/nil to "none", downcases strings, validates against allowed values
    def normalize_hint_value(value)
      # Convert booleans and nil
      return "none" if value == false || value.nil?
      return "preload" if value == true

      # Downcase and validate string
      str_value = value.to_s.downcase.strip

      # Only allow valid values
      valid_values = ["preload", "prefetch", "none"]
      valid_values.include?(str_value) ? str_value : "none"
    end

    # Generate reason why early hints were skipped
    def early_hints_skip_reason
      unless early_hints_supported?
        return "Rails request.send_early_hints not available (requires Rails 5.2+)"
      end
      unless early_hints_enabled?
        return "early_hints.enabled is false in config/shakapacker.yml"
      end
      "Unknown reason"
    end

    # Build a Link header value for early hints
    # Takes the already-resolved source_path to avoid duplicate lookup_source calls
    def build_link_header(source_path, source, as:, rel: "preload")
      parts = ["<#{source_path}>", "rel=#{rel}", "as=#{as}"]

      # Add crossorigin and integrity if enabled (consistent with render_tags)
      if current_shakapacker_instance.config.integrity[:enabled]
        integrity = lookup_integrity(source)
        if integrity.present?
          parts << "integrity=\"#{integrity}\""
          # Use configured cross_origin value, consistent with render_tags
          cross_origin = current_shakapacker_instance.config.integrity[:cross_origin]
          parts << "crossorigin=\"#{cross_origin}\""
        end
      elsif ["script", "style", "font"].include?(as)
        # When integrity not enabled, scripts, styles, and fonts still need crossorigin for CORS
        parts << "crossorigin=\"anonymous\""
      end

      parts.join("; ")
    end

    # Returns the shared early hints storage from request.env
    # This ensures state is shared across controller/view contexts
    def early_hints_store
      request.env["shakapacker.early_hints"] ||= {}
    end

    # Internal method to accumulate and send early hints
    # Sends only ONE 103 response (browsers ignore subsequent ones)
    # config: { "application" => "preload", "vendor" => "prefetch" }
    # type: :javascript or :stylesheet
    def send_early_hints_internal(config, type:)
      return unless early_hints_supported?

      # Use request.env as shared storage across controller/view contexts
      # This prevents duplicate packs and ensures debug info is preserved
      store = early_hints_store
      store[:sent_packs] ||= { javascript: {}, stylesheet: {} }
      store[:link_buffer] ||= []
      store[:debug_buffer] ||= []

      # If we've already sent the 103 response, just track for debug
      if store[:http_103_sent]
        if early_hints_debug_enabled?
          store[:debug_buffer] << "<!-- Shakapacker Early Hints (#{type.upcase}): Not sent (103 already sent) -->"
          store[:debug_buffer] << "<!--   Packs: #{config.keys.join(', ')} -->"
        end
        return
      end

      # Filter to only new packs for THIS type, and skip "none" values
      new_hints = config.reject { |pack, handling| store[:sent_packs][type].key?(pack) || handling == "none" }

      if early_hints_debug_enabled? && new_hints.empty?
        store[:debug_buffer] << "<!-- Shakapacker Early Hints (#{type.upcase}): All packs already queued -->"
      end

      # Accumulate Link headers for this type
      asset_type = type == :javascript ? "script" : "style"
      new_hints.each do |pack_name, handling|
        # Skip if handling is "none" (extra safety check)
        next if handling == "none"

        begin
          sources = available_sources_from_manifest_entrypoints([pack_name], type: type)
          sources.each do |source|
            source_path = lookup_source(source)
            store[:link_buffer] << build_link_header(source_path, source, as: asset_type, rel: handling)
          end
          # Mark pack as queued for THIS type
          store[:sent_packs][type][pack_name] = handling
        rescue Shakapacker::Manifest::MissingEntryError, NoMethodError => e
          Rails.logger.debug { "Early hints: skipping pack '#{pack_name}' - #{e.class}: #{e.message}" }
        end
      end

      # Note: We DON'T flush here - caller must call flush_early_hints explicitly
      # This allows accumulating multiple calls (JS + CSS) before sending ONE 103
    end

    # Send accumulated early hints as a SINGLE 103 response
    # Browsers only process the first 103, so we send everything at once
    def flush_early_hints
      store = early_hints_store

      # Guard against multiple flushes - only send once per request
      return if store[:http_103_sent]
      return if store[:link_buffer].nil? || store[:link_buffer].empty?

      # Check if response is already committed (headers already sent)
      if respond_to?(:response) && response&.committed?
        Rails.logger.debug { "Early hints: Cannot send 103 - response already committed" }
        return
      end

      # Set flag BEFORE sending to prevent race conditions
      store[:http_103_sent] = true

      # Send the 103 response with error handling
      begin
        request.send_early_hints({ "Link" => store[:link_buffer].join(", ") })
      rescue => e
        Rails.logger.error { "Early hints: Failed to send 103 - #{e.class}: #{e.message}" }
      end

      if early_hints_debug_enabled?
        all_packs = (store[:sent_packs][:javascript].keys + store[:sent_packs][:stylesheet].keys).uniq
        store[:debug_buffer] << "<!-- Shakapacker Early Hints: HTTP/1.1 103 SENT -->"
        store[:debug_buffer] << "<!--   Total Links: #{store[:link_buffer].size} -->"
        store[:debug_buffer] << "<!--   Packs: #{all_packs.join(', ')} -->"
        store[:debug_buffer] << "<!--   JS Packs: #{store[:sent_packs][:javascript].keys.join(', ')} -->"
        store[:debug_buffer] << "<!--   CSS Packs: #{store[:sent_packs][:stylesheet].keys.join(', ')} -->"
        store[:debug_buffer] << "<!--   Headers: -->"
        store[:link_buffer].each do |link|
          store[:debug_buffer] << "<!--     #{link} -->"
        end
        store[:debug_buffer] << "<!--   Note: Browsers only process the FIRST 103 response -->"
        store[:debug_buffer] << "<!--   Note: Puma only supports HTTP/1.1 Early Hints (not HTTP/2) -->"
        store[:debug_buffer] << "<!--   CDN Warning: Most CDNs (Cloudflare, AWS CloudFront, AWS ALB) strip 103 responses. -->"
        store[:debug_buffer] << "<!--   Link headers in the 200 response may still provide some browser hints. -->"
      end
    end

    # Wrapper for JavaScript early hints
    def send_javascript_early_hints_internal(config)
      send_early_hints_internal(config, type: :javascript)
    end

    # Wrapper for stylesheet early hints
    def send_stylesheet_early_hints_internal(config)
      send_early_hints_internal(config, type: :stylesheet)
    end
end
