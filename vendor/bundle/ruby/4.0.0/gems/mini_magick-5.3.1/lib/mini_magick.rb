require 'mini_magick/version'
require 'mini_magick/configuration'
require 'mini_magick/utilities'
require 'mini_magick/tool'
require 'mini_magick/image'

module MiniMagick

  Error = Class.new(RuntimeError)
  Invalid = Class.new(StandardError)
  TimeoutError = Class.new(Error)

  extend MiniMagick::Configuration

  ##
  # Checks whether ImageMagick 7 is installed.
  #
  # @return [Boolean]
  def self.imagemagick7?
    return false if graphicsmagick
    return @imagemagick7 if defined?(@imagemagick7)
    @imagemagick7 = !!MiniMagick::Utilities.which("magick")
  end

  %w[animate compare composite conjure convert display identify import mogrify montage stream].each do |tool|
    define_singleton_method(tool) do |**options, &block|
      name = imagemagick7? && tool == "convert" ? "magick" : tool
      MiniMagick::Tool.new(name, **options, &block)
    end
  end

  ##
  # Returns ImageMagick version.
  #
  # @return [String]
  def self.cli_version
    output = MiniMagick.identify(&:version)
    output[/\d+\.\d+\.\d+(-\d+)?/]
  end
end
