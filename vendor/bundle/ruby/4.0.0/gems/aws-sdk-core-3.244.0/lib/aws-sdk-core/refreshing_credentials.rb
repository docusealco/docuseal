# frozen_string_literal: true

module Aws
  # Base class used credential classes that can be refreshed. This
  # provides basic refresh logic in a thread-safe manner. Classes mixing in
  # this module are expected to implement a `#refresh` method that populates
  # the following instance variables:
  #
  # * `@credentials` ({Credentials})
  # * `@expiration` (Time)
  #
  module RefreshingCredentials
    SYNC_EXPIRATION_LENGTH = 300 # 5 minutes
    ASYNC_EXPIRATION_LENGTH = 600 # 10 minutes

    CLIENT_EXCLUDE_OPTIONS = Set.new([:before_refresh]).freeze

    # @param [Hash] options
    # @option options [Proc] :before_refresh A Proc called before credentials are refreshed.
    #   It accepts `self` as the only argument.
    def initialize(options = {})
      @mutex = Mutex.new
      @before_refresh = options.delete(:before_refresh) if options.is_a?(Hash)

      @before_refresh.call(self) if @before_refresh
      refresh
    end

    # @return [Credentials]
    def credentials
      refresh_if_near_expiration!
      @credentials
    end

    # Refresh credentials.
    # @return [void]
    def refresh!
      @mutex.synchronize do
        @before_refresh.call(self) if @before_refresh

        refresh
      end
    end

    private

    def sync_expiration_length
      self.class::SYNC_EXPIRATION_LENGTH
    end

    def async_expiration_length
      self.class::ASYNC_EXPIRATION_LENGTH
    end

    # Refreshes credentials asynchronously and synchronously.
    # If we are near to expiration, block while getting new credentials.
    # Otherwise, if we're approaching expiration, use the existing credentials
    # but attempt a refresh in the background.
    def refresh_if_near_expiration!
      # NOTE: This check is an optimization. Rather than acquire the mutex on every #refresh_if_near_expiration
      # call, we check before doing so, and then we check within the mutex to avoid a race condition.
      # See issue: https://github.com/aws/aws-sdk-ruby/issues/2641 for more info.
      if near_expiration?(sync_expiration_length)
        @mutex.synchronize do
          if near_expiration?(sync_expiration_length)
            @before_refresh.call(self) if @before_refresh
            refresh
          end
        end
      elsif @async_refresh && near_expiration?(async_expiration_length)
        unless @mutex.locked?
          Thread.new do
            @mutex.synchronize do
              if near_expiration?(async_expiration_length)
                @before_refresh.call(self) if @before_refresh
                refresh
              end
            end
          end
        end
      end
    end

    def near_expiration?(expiration_length)
      if @expiration
        # Are we within expiration?
        (Time.now.to_i + expiration_length) > @expiration.to_i
      else
        true
      end
    end
  end
end
