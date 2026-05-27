require "active_model"

module ActiveModel::Validations::HelperMethods
  # Strips whitespace from model fields and converts blank values to nil.
  def strip_attributes(options = {})
    StripAttributes.validate_options(options)

    before_validation(options.slice(:if, :unless)) do |record|
      StripAttributes.strip(record, options)
    end
  end
end

module StripAttributes
  VALID_OPTIONS = [:only, :except, :allow_empty, :collapse_spaces, :replace_newlines, :regex, :if, :unless].freeze

  # Unicode invisible and whitespace characters. The POSIX character class
  # [:space:] corresponds to the Unicode class Z ("separator"). We also
  # include the following characters from Unicode class C ("control"), which
  # are spaces or invisible characters that make no sense at the start or end
  # of a string:
  #   U+180E MONGOLIAN VOWEL SEPARATOR
  #   U+200B ZERO WIDTH SPACE
  #   U+200C ZERO WIDTH NON-JOINER
  #   U+200D ZERO WIDTH JOINER
  #   U+2060 WORD JOINER
  #   U+FEFF ZERO WIDTH NO-BREAK SPACE
  MULTIBYTE_WHITE = "\u180E\u200B\u200C\u200D\u2060\uFEFF".freeze
  MULTIBYTE_SPACE = /[[:space:]#{MULTIBYTE_WHITE}]/.freeze
  MULTIBYTE_SPACE_AT_ENDS = /\A#{MULTIBYTE_SPACE}+|#{MULTIBYTE_SPACE}+\z/.freeze
  MULTIBYTE_BLANK = /[[:blank:]#{MULTIBYTE_WHITE}]/.freeze
  MULTIBYTE_BLANK_REPEATED = /#{MULTIBYTE_BLANK}+/.freeze
  MULTIBYTE_SUPPORTED = "\u0020" == " "
  NEWLINES = /[\r\n]+/.freeze

  def self.strip(record_or_string, options = {})
    if record_or_string.respond_to?(:attributes)
      strip_record(record_or_string, options)
    else
      strip_string(record_or_string, options)
    end
  end

  def self.strip_record(record, options = {})
    attributes = narrow(record.attributes, options)

    attributes.each do |attr, value|
      original_value = value
      value = strip_string(value, options)
      record[attr] = value if original_value != value
    end

    record
  end

  def self.strip_string(value, options = {})
    return value unless value.is_a?(String)

    allow_empty      = options[:allow_empty]
    collapse_spaces  = options[:collapse_spaces]
    replace_newlines = options[:replace_newlines]
    regex            = options[:regex]

    value = value.dup
    value.gsub!(regex, "") if regex

    if MULTIBYTE_SUPPORTED && Encoding.compatible?(value, MULTIBYTE_SPACE)
      value.gsub!(MULTIBYTE_SPACE_AT_ENDS, "")
    else
      value.strip!
    end

    value.gsub!(NEWLINES, " ") if replace_newlines

    if collapse_spaces
      if MULTIBYTE_SUPPORTED && Encoding.compatible?(value, MULTIBYTE_BLANK)
        value.gsub!(MULTIBYTE_BLANK_REPEATED, " ")
      else
        value.squeeze!(" ")
      end
    end

    (value.blank? && !allow_empty) ? nil : value
  end

  # Necessary because Rails has removed the narrowing of attributes using :only
  # and :except on Base#attributes
  def self.narrow(attributes, options = {})
    if options[:except]
      except = Array(options[:except]).map(&:to_s)
      attributes.except(*except)
    elsif options[:only]
      only = Array(options[:only]).map(&:to_s)
      attributes.slice(*only)
    else
      attributes
    end
  end

  def self.validate_options(options)
    return if (options.keys - VALID_OPTIONS).empty?
    raise ArgumentError, "Options does not specify #{VALID_OPTIONS} (#{options.keys.inspect})"
  end
end
