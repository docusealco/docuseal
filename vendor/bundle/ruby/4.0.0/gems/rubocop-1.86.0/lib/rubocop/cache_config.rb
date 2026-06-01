# frozen_string_literal: true

module RuboCop
  # This class represents the cache config of the caching RuboCop runs.
  # @api private
  class CacheConfig
    def self.root_dir
      root = ENV.fetch('RUBOCOP_CACHE_ROOT', nil)
      root ||= yield
      root ||= if ENV.key?('XDG_CACHE_HOME')
                 # Include user ID in the path to make sure the user has write
                 # access.
                 File.join(ENV.fetch('XDG_CACHE_HOME'), Process.uid.to_s)
               else
                 # On FreeBSD, the /home path is a symbolic link to /usr/home
                 # and the $HOME environment variable returns the /home path.
                 #
                 # As $HOME is a built-in environment variable, FreeBSD users
                 # always get a warning message.
                 #
                 # To avoid raising warn log messages on FreeBSD, we retrieve
                 # the real path of the home folder.
                 File.join(File.realpath(Dir.home), '.cache')
               end

      File.join(root, 'rubocop_cache')
    end

    # Lightweight cache root computation that reads CacheRootDirectory from
    # the toplevel config file and environment variables without going through
    # the full ConfigStore/ConfigLoader. This method can be used, for example,
    # before loading configuration files. Please note that this method doesn't
    # take into account any `inherit_from` dependencies.
    def self.root_dir_from_toplevel_config(cache_root_override = nil)
      root_dir do
        next cache_root_override if cache_root_override

        config_path = ConfigFinder.find_config_path(PathUtil.pwd)
        file_contents = File.read(config_path)

        # Returns early if `CacheRootDirectory` is not used before requiring `erb` or `yaml`.
        next unless file_contents.include?('CacheRootDirectory')

        require 'erb'
        require 'yaml'
        yaml_code = ERB.new(file_contents).result
        config_yaml = YAML.safe_load(yaml_code, permitted_classes: [Regexp, Symbol], aliases: true)

        # For compatibility with Ruby 3.0 or lower.
        if Gem::Version.new(Psych::VERSION) < Gem::Version.new('4.0.0')
          config_yaml == false ? nil : config_yaml
        end

        config_yaml&.dig('AllCops', 'CacheRootDirectory')
      end
    end
  end
end
