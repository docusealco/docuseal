require "rubygems"
require "rspec"
require "rspec/core/rake_task"
require "hoe"
require "rake/clean"

MAINTENANCE = ENV["MAINTENANCE"] == "true"
BUILD_DOCS = MAINTENANCE || ENV["DOCS"] == "true"
TRUSTED_RELEASE = ENV["rubygems_release_gem"] == "true"

Hoe.plugin :halostatue
Hoe.plugin :rubygems

Hoe.plugins.delete :debug
Hoe.plugins.delete :newb
Hoe.plugins.delete :signing
Hoe.plugins.delete :publish unless BUILD_DOCS

if RUBY_VERSION < "1.9"
  class Array # :nodoc:
    def to_h
      Hash[*flatten(1)]
    end
  end

  class Gem::Specification # :nodoc:
    def metadata=(*)
    end

    def default_value(*)
    end
  end

  class Object # :nodoc:
    def caller_locations(*)
      []
    end
  end
end

_spec = Hoe.spec "diff-lcs" do
  developer("Austin Ziegler", "halostatue@gmail.com")

  self.trusted_release = TRUSTED_RELEASE

  require_ruby_version ">= 1.8"

  self.history_file = "CHANGELOG.md"
  self.readme_file = "README.md"
  self.licenses = ["MIT", "Artistic-1.0-Perl", "GPL-2.0-or-later"]

  spec_extras[:metadata] = ->(val) {
    val["rubygems_mfa_required"] = "true"
  }

  extra_dev_deps << ["hoe", "~> 4.0"]
  extra_dev_deps << ["hoe-halostatue", "~> 2.0"]
  extra_dev_deps << ["hoe-rubygems", "~> 1.0"]
  extra_dev_deps << ["rspec", ">= 2.0", "< 4"]
  extra_dev_deps << ["rake", ">= 10.0", "< 14"]
  extra_dev_deps << ["rdoc", ">= 6.3.1", "< 7"]
end

if BUILD_DOCS
  rake_tasks = Rake.application.instance_variable_get(:@tasks)
  tasks = ["publish_docs", "publish_on_announce", "debug_email", "post_blog", "announce"]
  tasks.each do |task|
    rake_tasks.delete(task)
  end
end

desc "Run all specifications"
RSpec::Core::RakeTask.new(:spec) do |t|
  rspec_dirs = %w[spec lib].join(":")
  t.rspec_opts = ["-I#{rspec_dirs}"]
end

task :version do
  require "diff/lcs/version"
  puts Diff::LCS::VERSION
end

Rake::Task["spec"].actions.uniq! { |a| a.source_location }

# standard:disable Style/HashSyntax
task :default => :spec unless Rake::Task["default"].prereqs.include?("spec")
task :test => :spec unless Rake::Task["test"].prereqs.include?("spec")
# standard:enable Style/HashSyntax

if RUBY_VERSION >= "3.0" && RUBY_ENGINE == "ruby"
  namespace :spec do
    desc "Runs test coverage. Only works Ruby 2.0+ and assumes 'simplecov' is installed."
    task :coverage do
      ENV["COVERAGE"] = "true"
      Rake::Task["spec"].execute
    end
  end
end

if MAINTENANCE
  task ruby18: :package do
    require "diff/lcs/version"
    # standard:disable Layout/HeredocIndentation
    puts <<-MESSAGE
You are starting a barebones Ruby 1.8 docker environment for testing.
A snapshot package has been built, so install it with:

    cd diff-lcs
    gem install pkg/diff-lcs-#{Diff::LCS::VERSION}

    MESSAGE
    # standard:enable Layout/HeredocIndentation
    sh "docker run -it --rm -v #{Dir.pwd}:/root/diff-lcs bellbind/docker-ruby18-rails2 bash -l"
  end
end
