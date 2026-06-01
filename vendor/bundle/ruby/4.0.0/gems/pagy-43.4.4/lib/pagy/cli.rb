# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'rbconfig'
require_relative '../pagy'
require_relative '../../apps/index'

class Pagy
  class CLI
    HOST  = 'localhost'
    PORT  = '8000'

    def start(args = ARGV)
      options = parse_options(args)
      run_command(args, options)
    end

    private

    def parse_options(args)
      options = { env: 'development', host: HOST, port: PORT, quiet: false }

      parser = OptionParser.new do |opts|
        opts.banner = <<~BANNER
          Pagy #{VERSION} (https://ddnexus.github.io/pagy/playground)
          Playground to showcase, clone and develop Pagy APPs

          Usage:
            pagy APP [opts]   Showcase APP from the installed gem
            pagy clone APP    Clone APP to the current dir
            pagy FILE [opts]  Develop app FILE from local path
        BANNER

        opts.summary_indent = '  '
        opts.summary_width  = 18

        opts.separator "\nAPPs"
        PagyApps::INDEX.each do |name, path|
          desc = File.readlines(path)[3].sub('#    ', '').strip
          opts.separator "  #{name.ljust(18)}#{desc}"
        end

        opts.separator "\nRackup options"
        opts.on('-e', '--env ENV', 'Environment')     { |v| options[:env] = v }
        opts.on('-o', '--host HOST', 'Host')          { |v| options[:host] = v }
        opts.on('-p', '--port PORT', 'Port')          { |v| options[:port] = v }
        opts.on('-t', '--threads THREADS', 'Threads') { |v| options[:threads] = v }

        opts.separator "\nOther options"
        opts.on('-q', '--quiet', 'Quiet mode for development') { options[:quiet] = true }
        opts.on('-v', '--version', 'Show version') do
          puts VERSION
          exit
        end
        opts.on('-h', '--help', 'Show this help') do
          puts opts
          exit
        end

        opts.separator "\nExamples"
        opts.separator "  pagy demo          Showcase demo at http://#{HOST}:#{PORT}"
        opts.separator '  pagy clone repro   Clone repro to ./repro.ru (rename it)'
        opts.separator "  pagy ~/myapp.ru    Develop ~/myapp.ru at #{HOST}:#{PORT}"
      end

      begin
        parser.parse!(args)
      rescue OptionParser::InvalidOption => e
        abort e.message
      end

      if args.empty?
        puts parser
        exit
      end

      options
    end

    def run_command(args, options)
      run_from_repo = Pagy::ROOT.join('pagy.gemspec').exist?
      setup_gems(run_from_repo)

      arg = args.shift

      if arg.eql?('clone')
        clone_app(args.shift)
      else
        serve_app(arg, options)
      end
    end

    def clone_app(name)
      abort "Expected APP to be in [#{PagyApps::INDEX.keys.join(', ')}]; got #{name.inspect}" unless PagyApps::INDEX.key?(name)

      if File.exist?(name)
        print "Do you want to overwrite the #{name.inspect} file? (y/n)> "
        answer = gets.chomp
        abort "#{name.inspect} file already present" unless answer.start_with?(/y/i)
      end
      FileUtils.cp(PagyApps::INDEX[name], '.', verbose: true)
    end

    def serve_app(arg, options)
      if PagyApps::INDEX.key?(arg)
        options[:env]   = 'showcase'
        options[:quiet] = true
        # Avoid the creation of './tmp/local_secret.txt' for showcase env
        ENV['SECRET_KEY_BASE'] = 'absolute secret!' if arg.eql?('rails')
        file = PagyApps::INDEX[arg]
      else
        file = arg
      end
      abort "#{file.inspect} app not found" unless File.exist?(file)

      gem_dir = File.expand_path('../..', __dir__)
      rackup  = "rackup -I #{gem_dir}/lib -r pagy -o #{options[:host]} -p #{options[:port]} -E #{options[:env]} #{file}"
      rackup << " -O Threads=#{options[:threads]}" if options[:threads]
      rackup << ' -q' if options[:quiet]

      exec(rackup)
    end

    # Kept as a separate method because mocking 'gemfile' (dsl) is complex otherwise
    def setup_gems(run_from_repo)
      require 'bundler/inline'
      gemfile(!run_from_repo) do
        source 'https://rubygems.org'
        gem 'logger'
        gem 'rackup'
      end
    end
  end
end
