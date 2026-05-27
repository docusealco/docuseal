module Brakeman
  module Logger
    def self.get_logger options, dest = $stderr
      case
      when options[:debug]
        Debug.new(options, dest)
      when options[:quiet]
        Quiet.new(options, dest)
      when options[:report_progress] == false
        Plain.new(options, dest)
      when dest.tty?
        Console.new(options, dest)
      else
        Plain.new(options, dest)
      end
    end

    class Base
      def initialize(options, log_destination = $stderr)
        @dest = log_destination
        @show_timing = options[:debug] || options[:show_timing]
      end

      # Output a message to the log.
      # If newline is `false`, does not output a newline after message.
      def log(message, newline: true)
        if newline
          @dest.puts message
        else
          @dest.write message
        end
      end

      # Notify about important information - use sparingly
      def announce(message); end

      # Notify regarding errors - use sparingly
      def alert(message); end

      # Output debug information
      def debug(message); end

      # Wraps a step in the scanning process
      def context(description, &)
        yield self
      end

      # Wraps a substep (e.g. processing one file)
      def single_context(description, &)
        yield
      end

      # Update progress towards a known total
      def update_progress(current, total, type = 'files'); end

      # Show a spinner
      def spin; end

      # Called on exit
      def cleanup(newline = true); end

      def show_timing? = @show_timing

      # Use ANSI codes to color a string
      def color(message, *)
        if @highline
          @highline.color(message, *)
        else
          message
        end
      end

      def color?
        @highline and @highline.use_color?
      end

      private

      def load_highline(output_color)
        if @dest.tty? or output_color == :force
          Brakeman.load_brakeman_dependency 'highline'
          @highline = HighLine.new
          @highline.use_color = !!output_color
        else
          @highline = nil
        end
      end
    end

    class Plain < Base
      def initialize(options, *)
        super

        load_highline(options[:output_color])
      end

      def announce(message)
        log color(message, :bold, :green)
      end

      def alert(message)
        log color(message, :red)
      end

      def context(description, &)
        log "#{color(description, :green)}..."

        if show_timing?
          time_step(description, &)
        else
          yield
        end
      end

      def time_step(description, &)
        start_t = Time.now
        yield
        duration = Time.now - start_t

        log color(("Completed #{description.to_s.downcase} in %0.2fs" % duration), :gray)
      end
    end

    class Quiet < Base
      def initialize(*)
        super
      end
    end

    class Debug < Plain
      def debug(message)
        log color(message, :gray)
      end

      def context(description, &)
        log "#{description}..."

        time_step(description, &)
      end

      def single_context(description, &)
        debug "Processing #{description}"

        if show_timing?
          # Even in debug, only show timing for each file if asked
          time_step(description, &)
        else
          yield
        end
      end
    end

    class Console < Base
      attr_reader :prefix

      def initialize(options, *)
        super

        load_highline(options[:output_color])
        require 'reline'
        require 'reline/io/ansi'

        @prefix = ''
        @post_fix_pos = 0
        @reline = Reline::ANSI.new
        @reline.output = @dest
        @report_progress = options[:report_progress]
        @spinner = ["⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"]
        @percenter = ["⣀", "⣤", "⣶", "⣿"]
        @spindex = 0
        @last_spin = Time.now
        @reline.hide_cursor
      end

      def announce message
        clear_line
        log color(message, :bold, :green)
        rewrite_prefix
      end

      def alert message
        clear_line
        log color(message, :red)
        rewrite_prefix
      end

      def context(description, &)
        write_prefix description

        time_step(description, &)
      ensure
        clear_prefix
      end

      def time_step(description, &)
        if show_timing?
          start_t = Time.now
          yield
          duration = Time.now - start_t

          write_after color(('%0.2fs' % duration), :gray)
          log ''
        else
          yield
        end
      end

      def update_progress current, total, type = 'files'
        percent = ((current / total.to_f) * 100).to_i
        tenths = [(percent / 10), 0].max

        lead = color(@percenter[percent % 10 / 3], :bold, :red)
        done_blocks = color("⣿" * tenths, :red)
        remaining = color("⣀" * (9 - tenths), :gray)
        write_after "#{done_blocks}#{lead}#{remaining}"
      end

      def write_prefix pref
        set_prefix pref
        rewrite_prefix
      end

      # If an alert was written, redo prefix on next line
      def rewrite_prefix
        log(@prefix, newline: false)
        @reline.erase_after_cursor
      end

      def write_after message
        @reline.move_cursor_column(@post_fix_pos)
        log(message, newline: false)
        @reline.erase_after_cursor
      end

      def set_prefix message
        @prefix = "#{color('»', :bold, :cyan)} #{color(message, :green)}"
        @post_fix_pos = HighLine::Wrapper.actual_length(@prefix) + 1
      end

      def clear_prefix
        @prefix = ''
        @post_fix_pos = 0
        clear_line
      end

      def clear_line
        @reline.move_cursor_column(0)
        @reline.erase_after_cursor
      end

      def spin
        return unless (Time.now - @last_spin) > 0.2

        write_after color(@spinner[@spindex], :bold, :red)
        @spindex = (@spindex + 1) % @spinner.length
        @last_spin = Time.now
      end

      def cleanup(newline = true)
        @reline.show_cursor
        log('') if newline
      end
    end
  end
end
