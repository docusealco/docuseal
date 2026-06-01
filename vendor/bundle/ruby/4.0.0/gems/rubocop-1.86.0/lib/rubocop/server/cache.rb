# frozen_string_literal: true

require 'digest'
require 'pathname'
require 'yaml'
require_relative '../cache_config'
require_relative '../config_finder'
require_relative '../path_util'

#
# This code is based on https://github.com/fohte/rubocop-daemon.
#
# Copyright (c) 2018 Hayato Kawai
#
# The MIT License (MIT)
#
# https://github.com/fohte/rubocop-daemon/blob/master/LICENSE.txt
#
module RuboCop
  module Server
    # Caches the states of server process.
    # @api private
    class Cache
      GEMFILE_NAMES = %w[Gemfile gems.rb].freeze
      LOCKFILE_NAMES = %w[Gemfile.lock gems.locked].freeze

      class << self
        attr_accessor :cache_root_path

        # Searches for Gemfile or gems.rb in the current dir or any parent dirs
        def project_dir
          current_dir = Dir.pwd
          while current_dir != '/'
            return current_dir if GEMFILE_NAMES.any? do |gemfile|
              File.exist?(File.join(current_dir, gemfile))
            end

            current_dir = File.expand_path('..', current_dir)
          end
          # If we can't find a Gemfile, just use the current directory
          Dir.pwd
        end

        def project_dir_cache_key
          @project_dir_cache_key ||= project_dir[1..].tr('/', '+')
        end

        # rubocop:disable Metrics/AbcSize
        def restart_key(args_config_file_path: nil)
          lockfile_path = LOCKFILE_NAMES.map do |lockfile_name|
            Pathname(project_dir).join(lockfile_name)
          end.find(&:exist?)
          version_data = lockfile_path&.read || RuboCop::Version::STRING
          config_data = Pathname(
            args_config_file_path || ConfigFinder.find_config_path(Dir.pwd)
          ).read
          yaml = load_erb_templated_yaml(config_data)

          inherit_from_data = inherit_from_data(yaml)
          require_data = require_data(yaml)

          Digest::SHA1.hexdigest(version_data + config_data + inherit_from_data + require_data)
        end
        # rubocop:enable Metrics/AbcSize

        def dir
          Pathname.new(File.join(cache_path, project_dir_cache_key)).tap do |d|
            d.mkpath unless d.exist?
          end
        end

        def cache_path
          cache_root_dir = if cache_root_path
                             File.join(cache_root_path, 'rubocop_cache')
                           else
                             CacheConfig.root_dir_from_toplevel_config
                           end

          File.expand_path(File.join(cache_root_dir, 'server'))
        end

        def port_path
          dir.join('port')
        end

        def token_path
          dir.join('token')
        end

        def pid_path
          dir.join('pid')
        end

        def lock_path
          dir.join('lock')
        end

        def status_path
          dir.join('status')
        end

        def version_path
          dir.join('version')
        end

        def stderr_path
          dir.join('stderr')
        end

        def pid_running?
          Process.kill(0, pid_path.read.to_i) == 1
        rescue Errno::ESRCH, Errno::ENOENT, Errno::EACCES, Errno::EROFS, Errno::ENAMETOOLONG
          false
        end

        def acquire_lock
          File.open(lock_path, File::CREAT) do |lock_file|
            # flock returns 0 if successful, and false if not.
            flock_result = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
            yield flock_result != false
          end
        end

        def write_port_and_token_files(port:, token:)
          port_path.write(port)
          token_path.write(token)
        end

        def write_pid_file
          pid_path.write(Process.pid)
          yield
        ensure
          dir.rmtree
        end

        def write_status_file(status)
          status_path.write(status)
        end

        def write_version_file(version)
          version_path.write(version)
        end

        def inherit_from_data(yaml)
          return '' unless (inherit_from_paths = yaml['inherit_from'])

          Array(inherit_from_paths).map do |path|
            next if PathUtil.remote_file?(path)

            path = Pathname(path)

            path.exist? ? path.read : ''
          end.join
        end

        def require_data(yaml)
          return '' unless (require_paths = yaml['require'])

          Array(require_paths).map do |path|
            # NOTE: This targets only relative or absolute path specifications.
            # For example, specifications like `require: rubocop-performance`,
            # which can be loaded from `$LOAD_PATH`, are ignored.
            next unless path.start_with?('.', '/')

            # NOTE: `.so` files are not typically specified, so only `.rb` files are targeted.
            path = "#{path}.rb" unless path.end_with?('.rb')
            path = Pathname(path)

            path.exist? ? path.read : ''
          end.join
        end

        private

        def load_erb_templated_yaml(content)
          require 'erb'
          yaml_code = ERB.new(content).result

          require 'yaml'
          YAML.safe_load(yaml_code, permitted_classes: [Regexp, Symbol], aliases: true)
        end
      end
    end
  end
end
