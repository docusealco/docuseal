# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Requirements

      class GitRequirement
        attr_reader :repo_url, :ref

        def initialize(repo_url, ref)
          @repo_url = repo_url
          @ref = ref
        end

        def prepare
          check_git_available
          clone_or_fetch_if_necessary
          puts "Using repo in #{source_path}"
        end

        def source_path
          @source_path ||= File.join(TwitterCldr::VENDOR_DIR, 'git', repo_name)
        end

        private

        def check_git_available
          `git --version`

          if $?.exitstatus != 0
            raise "Couldn't find git executable. Is it installed?"
          end
        end

        def repo_name
          @repo_name ||= File.basename(repo_url).chomp('.git')
        end

        def clone_or_fetch_if_necessary
          if File.exist?(source_path)
            unless ref_exists?
              in_repo { `git fetch` }
            end
          else
            `git clone #{repo_url} #{source_path}`
          end
        end

        def ref_exists?
          in_repo do
            `git rev-parse --verify --quiet #{ref}`
            $?.exitstatus == 0
          end
        end

        def in_repo(&block)
          Dir.chdir(source_path, &block)
        end
      end

    end
  end
end
