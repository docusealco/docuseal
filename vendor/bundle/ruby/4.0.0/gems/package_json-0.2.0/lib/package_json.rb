# frozen_string_literal: true

require_relative "package_json/managers/base"
require_relative "package_json/managers/bun_like"
require_relative "package_json/managers/npm_like"
require_relative "package_json/managers/pnpm_like"
require_relative "package_json/managers/yarn_berry_like"
require_relative "package_json/managers/yarn_classic_like"
require_relative "package_json/version"
require "json"

class PackageJson
  class Error < StandardError; end

  class NotImplementedError < Error; end

  attr_reader :manager, :directory

  def self.fetch_default_fallback_manager
    ENV.fetch("PACKAGE_JSON_FALLBACK_MANAGER", "npm").to_sym
  end

  def self.read(path_to_directory = Dir.pwd, fallback_manager: PackageJson.fetch_default_fallback_manager)
    unless File.exist?("#{path_to_directory}/package.json")
      raise Error, "#{path_to_directory} does not contain a package.json"
    end

    new(path_to_directory, fallback_manager: fallback_manager)
  end

  def initialize(path_to_directory = Dir.pwd, fallback_manager: PackageJson.fetch_default_fallback_manager)
    @directory = File.absolute_path(path_to_directory)

    existed = ensure_package_json_exists

    @manager = new_package_manager(determine_package_manager(fallback_manager))

    # only record the packageManager automatically if we created the package.json
    record_package_manager! unless existed
  end

  def fetch(key, default = (no_default_set_by_user = true; nil))
    contents = read_package_json

    if no_default_set_by_user
      contents.fetch(key)
    else
      contents.fetch(key, default)
    end
  end

  # Merges the hash returned by the passed block into the existing content of the `package.json`
  def merge!
    pj = read_package_json

    write_package_json(pj.merge(yield read_package_json))
  end

  def delete!(key)
    pj = read_package_json

    value = pj.delete(key)

    write_package_json(pj)

    value
  end

  def record_package_manager!
    merge! { { "packageManager" => "#{manager.binary}@#{manager.version}" } }
  end

  private

  def determine_package_manager(fallback_manager)
    package_manager = fetch("packageManager", nil)

    return fallback_manager if package_manager.nil?

    name, version = package_manager.split("@")

    return determine_yarn_version(version) if name == "yarn"

    name.to_sym
  end

  def determine_yarn_version(version)
    raise Error, "a major version must be present for Yarn" if version.nil? || version.empty?

    # check to see if we're meant to be using Yarn v1 based on the versions major component,
    # and accounting for the presence of version constraints like ^, ~, and =
    return :yarn_classic if version.match?(/^[~=^]?1(\.|$)/)

    :yarn_berry
  end

  def new_package_manager(package_manager_name)
    case package_manager_name
    when :npm
      PackageJson::Managers::NpmLike.new(self)
    when :yarn_berry
      PackageJson::Managers::YarnBerryLike.new(self)
    when :yarn_classic
      PackageJson::Managers::YarnClassicLike.new(self)
    when :pnpm
      PackageJson::Managers::PnpmLike.new(self)
    when :bun
      PackageJson::Managers::BunLike.new(self)
    else
      raise Error, "unsupported package manager \"#{package_manager_name}\""
    end
  end

  def package_json_path
    "#{directory}/package.json"
  end

  def ensure_package_json_exists
    return true if File.exist?(package_json_path)

    write_package_json({})

    false
  end

  def read_package_json
    JSON.parse(File.read(package_json_path))
  end

  def write_package_json(contents)
    File.write(package_json_path, "#{JSON.pretty_generate(contents)}\n")
  end
end
