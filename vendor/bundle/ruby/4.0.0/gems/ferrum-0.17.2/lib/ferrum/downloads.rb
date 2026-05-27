# frozen_string_literal: true

module Ferrum
  class Downloads
    VALID_BEHAVIOR = %i[deny allow allowAndName default].freeze

    def initialize(page)
      @page = page
      @event = Utils::Event.new.tap(&:set)
      @files = {}
    end

    def files
      @files.values
    end

    def wait(timeout = 5)
      @event.reset
      yield if block_given?
      @event.wait(timeout)
      @event.set
    end

    def set_behavior(save_path:, behavior: :allow)
      raise ArgumentError unless VALID_BEHAVIOR.include?(behavior.to_sym)
      raise Error, "supply absolute path for `:save_path` option" unless Pathname.new(save_path.to_s).absolute?

      @page.command("Browser.setDownloadBehavior",
                    browserContextId: @page.context_id,
                    downloadPath: save_path,
                    behavior: behavior,
                    eventsEnabled: true)
    end

    def subscribe
      subscribe_download_will_begin
      subscribe_download_progress
    end

    def subscribe_download_will_begin
      @page.on("Browser.downloadWillBegin") do |params|
        @event.reset
        @files[params["guid"]] = params
      end
    end

    def subscribe_download_progress
      @page.on("Browser.downloadProgress") do |params|
        @files[params["guid"]].merge!(params)

        case params["state"]
        when "completed", "canceled"
          @event.set
        else
          @event.reset
        end
      end
    end
  end
end
