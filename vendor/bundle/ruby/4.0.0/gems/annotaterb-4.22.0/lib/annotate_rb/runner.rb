# frozen_string_literal: true

module AnnotateRb
  class Runner
    class << self
      attr_reader :runner

      def run(args)
        self.runner = new

        runner.run(args)

        self.runner = nil
      end

      def running?
        !!runner
      end

      private

      attr_writer :runner
    end

    def run(args)
      parser = Parser.new(args, {})

      parsed_options = parser.parse
      remaining_args = parser.remaining_args

      AnnotateRb::ConfigFinder.config_path = parsed_options[:config_path] if parsed_options[:config_path]
      config_file_options = ConfigLoader.load_config
      options = config_file_options.merge(parsed_options)

      @options = Options.from(options, {working_args: remaining_args})
      AnnotateRb::RakeBootstrapper.call

      raise "Didn't specify a command" unless @options[:command]

      @options[:command].call(@options)

      # TODO
    end
  end
end
