require 'user_agent/comparable'
require 'user_agent/browsers'
require 'user_agent/operating_systems'
require 'user_agent/version'

class UserAgent
  # http://www.texsoft.it/index.php?m=sw.php.useragent
  MATCHER = %r{
    ^['"]*                         # Possible opening quote(s)
    ([^/\s]+)                      # Product
    /?([^\s,]*)                    # Version
    (\s\(([^\)]*)\)|,gzip\(gfe\))? # Comment
  }x.freeze

  DEFAULT_USER_AGENT = "Mozilla/4.0 (compatible)"

  def self.parse(string)
    if string.nil? || string.strip == ""
      string = DEFAULT_USER_AGENT
    end

    agents = Browsers::Base.new
    while m = string.to_s.match(MATCHER)
      agents << new(m[1], m[2], m[4])
      string = string[m[0].length..-1].strip
    end
    Browsers.extend(agents)
  end

  attr_reader :product, :version, :comment

  def initialize(product, version = nil, comment = nil)
    if product
      @product = product
    else
      raise ArgumentError, "expected a value for product"
    end

    if version && !version.empty?
      @version = Version.new(version)
    else
      @version = Version.new
    end

    if comment.respond_to?(:split)
      @comment = comment.split("; ")
    else
      @comment = comment
    end
  end

  include Comparable

  def detect_comment(&block)
    comment && comment.detect(&block)
  end

  # Any comparison between two user agents with different products will
  # always return false.
  def <=>(other)
    if @product == other.product
      @version <=> other.version
    else
      false
    end
  end

  def eql?(other)
    @product == other.product &&
      @version == other.version &&
      @comment == other.comment
  end

  def to_s
    to_str
  end

  def to_str
    if @product && !@version.nil? && @comment
      "#{@product}/#{@version} (#{@comment.join("; ")})"
    elsif @product && !@version.nil?
      "#{@product}/#{@version}"
    elsif @product && @comment
      "#{@product} (#{@comment.join("; ")})"
    else
      @product
    end
  end
end
