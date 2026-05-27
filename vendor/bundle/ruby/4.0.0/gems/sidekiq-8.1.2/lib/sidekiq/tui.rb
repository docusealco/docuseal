# https://sr.ht/~kerrick/ratatui_ruby/
# https://git.sr.ht/~kerrick/ratatui_ruby/tree/stable/item/examples/
gem "ratatui_ruby", ">=1.4.0"
require "ratatui_ruby"

RatatuiRuby.debug_mode! if !!ENV["DEBUG"]

require "sidekiq/api"
require "sidekiq/paginator"

require_relative "tui/filtering"
require_relative "tui/controls"
require_relative "tui/tabs"

module Sidekiq
  class TUI
    include Sidekiq::Component

    PageOptions = Data.define(:page, :size)

    REFRESH_INTERVAL_SECONDS = 2
    LOCALE_DIRECTORIES = [File.expand_path("#{File.dirname(__FILE__)}/../../web/locales")]

    # language is meant to be a locale code, e.g.
    # LANG=en_US.utf-8
    def initialize(cfg, language: ENV["LANG"] || "en")
      @lang = language
      @config = cfg
      @base_style = nil
      @last_refresh = Time.at(0)
      @fps = Array.new(2) { 0 }
      @previous_fps = 0
      @showing = :main
    end

    def prepare(tui)
      load_locale

      @tui = tui
      @highlight_style = @tui.style(fg: :light_red, modifiers: [:underlined])
      @hotkey_style = @tui.style(modifiers: [:bold, :underlined])
      # eager load tabs
      all
    end

    def run_loop
      # Must log to a file, terminal is now controlled by Ratatui
      config.logger = Logger.new("tui.log")

      loop do
        refresh_data if should_refresh?
        render
        break if handle_input == :quit
      end
    end

    def render
      track_fps do
        if @showing == :main
          @tui.draw do |frame|
            main_area, controls_area = @tui.layout_split(
              frame.area,
              direction: :vertical,
              constraints: [
                @tui.constraint_fill(1),
                @tui.constraint_length(5)
              ]
            )

            # Split main area into tabs and content
            tabs_area, content_area = @tui.layout_split(
              main_area,
              direction: :vertical,
              constraints: [
                @tui.constraint_length(3),
                @tui.constraint_fill(1)
              ]
            )

            all_tabs = all
            tabs = @tui.tabs(
              titles: all_tabs.map { |tab| t(tab.name) },
              selected_index: all_tabs.index(current_tab),
              block: @tui.block(title: " #{Sidekiq::NAME}", borders: [:all], title_style: @tui.style(fg: :light_red, modifiers: [:bold])),
              divider: " | ",
              highlight_style: @highlight_style,
              style: @base_style
            )
            frame.render_widget(tabs, tabs_area)

            render_content_area(frame, content_area)
            render_controls(frame, controls_area)
          end
        end

        if @showing == :help
          @tui.draw do |frame|
            main_area, controls_area = @tui.layout_split(
              frame.area,
              direction: :vertical,
              constraints: [
                @tui.constraint_fill(1),
                @tui.constraint_length(4)
              ]
            )
            content = @tui.block(
              title: " #{Sidekiq::NAME} ",
              borders: [:all],
              title_style: @tui.style(fg: :light_red, modifiers: [:bold]),
              children: [
                # TODO convert to table
                @tui.paragraph(
                  text: [
                    @tui.text_line(spans: ["Welcome to the Sidekiq Terminal UI"], alignment: :center),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "Global hotkeys")
                    ]),
                    @tui.text_line(spans: []),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "Esc", style: @hotkey_style),
                      @tui.text_span(content: ": Close this window")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "←/→", style: @hotkey_style),
                      @tui.text_span(content: ": Move between tabs")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "h/l", style: @hotkey_style),
                      @tui.text_span(content: ": Move to prev/next page of data")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "j/k", style: @hotkey_style),
                      @tui.text_span(content: ": Move to prev/next row in current page")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "x", style: @hotkey_style),
                      @tui.text_span(content: ": Select/deselect current row")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "A", style: @hotkey_style),
                      @tui.text_span(content: ": Select/deselect All rows in current page")
                    ]),
                    @tui.text_line(spans: [
                      @tui.text_span(content: "q", style: @hotkey_style),
                      @tui.text_span(content: ": Quit")
                    ])
                  ]
                )
              ]
            )
            frame.render_widget(content, main_area)
            controls = @tui.block(
              title: t("Controls"),
              borders: [:all],
              children: [
                @tui.paragraph(
                  text: [
                    @tui.text_line(spans: [
                      @tui.text_span(content: "Esc", style: @hotkey_style),
                      @tui.text_span(content: ": Close  ")
                    ])
                  ]
                )
              ]
            )
            frame.render_widget(controls, controls_area)
          end
        end
      end
    end

    def render_content_area(frame, content_area)
      return render_error(frame, content_area, current_tab.error) if current_tab.error

      current_tab.render(@tui, frame, content_area)
    end

    def render_controls(frame, area)
      active_keys = current_tab.controls.filter { |hash| hash[:description] }

      # Split controls into two lines, 8 is arbitrary
      # TODO Dynamically split based on term width?
      first = active_keys[...8]
      lines = []
      lines << @tui.text_line(spans: first.map { |hash|
        [
          @tui.text_span(content: hash[:display] || hash[:code], style: @hotkey_style),
          @tui.text_span(content: ": #{t(hash[:description])}  ")
        ]
      }.flatten)

      last = active_keys[8...]
      lines << if last && last.size > 0
        @tui.text_line(spans: last.map { |hash|
          [
            @tui.text_span(content: hash[:display] || hash[:code], style: @hotkey_style),
            @tui.text_span(content: ": #{t(hash[:description])}  ")
          ]
        }.flatten)
      else
        @tui.text_line(spans: [])
      end

      footer = [
        @tui.text_span(content: "Redis: #{redis_url}    "),
        @tui.text_span(content: "#{t("Now")}: #{Time.now.utc}    "),
        @tui.text_span(content: "#{t("Locale")}: #{@lang}")
      ]

      if current_tab.data[:filter]
        @filter_style = @tui.style(fg: :white, bg: :dark_gray)
        footer += [
          @tui.text_span(content: "   #{t("Filter")}: ", style: @filter_style),
          @tui.text_span(content: current_tab.data[:filter], style: @filter_style),
          @tui.text_span(content: "_", style: @tui.style(fg: :white, bg: :dark_gray, modifiers: [:slow_blink]))
        ]
      end
      footer << @tui.text_span(content: "  FPS: #{previous_fps}") if debugging?
      lines << @tui.text_line(spans: footer)

      controls = @tui.block(title: t("Controls"), borders: [:all],
        children: [@tui.paragraph(text: lines)])
      frame.render_widget(controls, area)
    end

    def handle_input
      # We shouldn't need more than 10 FPS for a data-oriented app.
      # This throttles down our CPU usage. Default is 60 FPS.
      case @tui.poll_event(timeout: 0.1)
      in {type: :key, code: "esc"} if @showing == :help
        @showing = :main
      in {type: :key, code: code} if current_tab.filtering? && code.length == 1
        current_tab.append_to_filter(code)
        current_tab.refresh_data
      in {type: :key, code:, modifiers:}
        control = current_tab.controls.find { |ctrl|
          ctrl[:code] == code &&
            (ctrl[:modifiers] || []) == (modifiers || [])
        }
        return unless control
        control[:action].call(self, current_tab).tap {
          refresh_data if control[:refresh]
        }
      else
        # Ignore other events
      end
    rescue => ex
      logger.error { [ex.message, ex.backtrace] }
    end

    def redis_url
      Sidekiq.redis do |conn|
        conn.config.server_url
      end
    rescue
      "N/A"
    end

    def should_refresh?
      Time.now - @last_refresh >= REFRESH_INTERVAL_SECONDS
    end

    def refresh_data
      # logger.info GC.stat
      current_tab.refresh_data
      @last_refresh = Time.now
    rescue => e
      handle_exception(e)
      current_tab.error = e
    end

    def render_error(frame, area, err)
      header = [@tui.text_line(
        spans: [@tui.text_span(content: err.message, style: @tui.style(modifiers: [:bold]))],
        alignment: :center
      )]
      lines = Array(err.backtrace).map { |line| @tui.text_line(spans: [@tui.text_span(content: line)]) }

      frame.render_widget(
        @tui.paragraph(
          text: header + lines,
          alignment: :left,
          block: @tui.block(title: t("Error"), borders: [:all], border_style: @tui.style(fg: :light_red))
        ),
        area
      )
    end

    def show_help
      @showing = :help
    end

    def all
      @all ||= Tabs::All.map { |kls| kls.new(self) }
    end

    def current_tab
      @current ||= @all.first
    end

    # Navigate tabs to the left or right.
    # @param direction [Symbol] :left or :right
    def navigate(direction)
      index_change = (direction == :right) ? 1 : -1
      @current = @all[(@all.index(current_tab) + index_change) % @all.size]
      @current.reset_data
    end

    public def t(msg, options = nil)
      string = @strings[msg] || msg
      if options.nil?
        string
      else
        string % options
      end
    end

    def load_strings(lang)
      {}.tap do |all|
        find_locale_files(lang).each do |file|
          strs = YAML.safe_load_file(file)
          all.merge! strs[lang]
        end
      end
    end

    def locale_files
      @@locale_files ||= LOCALE_DIRECTORIES.flat_map { |path|
        Dir["#{path}/*.yml"]
      }
    end

    def available_locales
      @@available_locales ||= Set.new(locale_files.map { |path| File.basename(path, ".yml") })
    end

    def find_locale_files(lang)
      locale_files.select { |file| file =~ /\/#{lang}\.yml$/ }
    end

    def load_locale
      require "yaml"
      lang = @lang.split(".").first # "en_US"
      while lang.size > 0
        hash = load_strings(lang)
        if hash.size > 0
          # found a working language dataset
          @lang = lang
          @strings = hash
          Sidekiq.logger.debug { "using the #{lang} locale" }
          break
        end
        # Try "en_US", "en_U", "en_", "en"
        # It's ugly and bruteforce but it works
        lang = lang[..-2]
      end
    end

    def track_fps
      # We hold two fps buckets: one for current second, one for previous second
      idx = Time.now.to_i % 2
      @fps[idx] += 1
      yield
    end

    def previous_fps
      curidx = Time.now.to_i % 2
      prev = (curidx == 1) ? 0 : 1
      if (val = @fps[prev]) != 0
        @previous_fps = val
        @fps[prev] = 0
      end
      @previous_fps
    end

    def debugging?
      !!ENV["DEBUG"]
    end
  end
end
