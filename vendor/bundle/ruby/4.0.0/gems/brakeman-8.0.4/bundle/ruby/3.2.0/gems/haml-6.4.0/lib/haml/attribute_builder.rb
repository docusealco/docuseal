# frozen_string_literal: true
require 'haml/object_ref'

module Haml::AttributeBuilder
  class << self
    def build(escape_attrs, quote, format, object_ref, *hashes)
      hashes << Haml::ObjectRef.parse(object_ref) if object_ref
      buf  = []
      hash = merge_all_attrs(hashes)

      keys = hash.keys.sort!
      keys.each do |key|
        case key
        when 'id'
          buf << " id=#{quote}#{build_id(escape_attrs, *hash[key])}#{quote}"
        when 'class'
          buf << " class=#{quote}#{build_class(escape_attrs, *hash[key])}#{quote}"
        when 'data'
          buf << build_data(escape_attrs, quote, *hash[key])
        when 'aria'
          buf << build_aria(escape_attrs, quote, *hash[key])
        when *Haml::BOOLEAN_ATTRIBUTES, /\Adata-/, /\Aaria-/
          build_boolean!(escape_attrs, quote, format, buf, key, hash[key])
        else
          buf << " #{key}=#{quote}#{escape_html(escape_attrs, hash[key].to_s)}#{quote}"
        end
      end
      buf.join
    end

    def build_id(escape_attrs, *values)
      escape_html(escape_attrs, values.flatten.select { |v| v }.join('_'))
    end

    def build_class(escape_attrs, *values)
      if values.size == 1
        value = values.first
        case
        when value.is_a?(String)
          # noop
        when value.is_a?(Array)
          value = value.flatten.select { |v| v }.map(&:to_s).uniq.join(' ')
        when value
          value = value.to_s
        else
          return ''
        end
        return escape_html(escape_attrs, value)
      end

      classes = []
      values.each do |value|
        case
        when value.is_a?(String)
          classes += value.split(' ')
        when value.is_a?(Array)
          classes += value.flatten.select { |v| v }
        when value
          classes << value.to_s
        end
      end
      escape_html(escape_attrs, classes.map(&:to_s).uniq.join(' '))
    end

    def build_data(escape_attrs, quote, *hashes)
      build_data_attribute(:data, escape_attrs, quote, *hashes)
    end

    def build_aria(escape_attrs, quote, *hashes)
      build_data_attribute(:aria, escape_attrs, quote, *hashes)
    end

    private

    def build_data_attribute(key, escape_attrs, quote, *hashes)
      attrs = []
      if hashes.size > 1 && hashes.all? { |h| h.is_a?(Hash) }
        data_value = merge_all_attrs(hashes)
      else
        data_value = hashes.last
      end
      hash = flatten_attributes(key => data_value)

      hash.sort_by(&:first).each do |key, value|
        case value
        when true
          attrs << " #{key}"
        when nil, false
          # noop
        else
          attrs << " #{key}=#{quote}#{escape_html(escape_attrs, value.to_s)}#{quote}"
        end
      end
      attrs.join
    end

    def flatten_attributes(attributes)
      flattened = {}

      attributes.each do |key, value|
        case value
        when attributes
        when Hash
          flatten_attributes(value).each do |k, v|
            if k.nil?
              flattened[key] = v
            else
              flattened["#{key}-#{k.to_s.tr('_', '-')}"] = v
            end
          end
        else
          flattened[key] = value if value
        end
      end
      flattened
    end

    def merge_all_attrs(hashes)
      merged = {}
      hashes.each do |hash|
        unless hash.is_a?(Hash)
          raise ArgumentError, "Non-hash object is given to attributes!"
        end
        hash.each do |key, value|
          key = key.to_s
          case key
          when 'id', 'class', 'data', 'aria'
            merged[key] ||= []
            merged[key] << value
          else
            merged[key] = value
          end
        end
      end
      merged
    end

    def build_boolean!(escape_attrs, quote, format, buf, key, value)
      case value
      when true
        case format
        when :xhtml
          buf << " #{key}=#{quote}#{key}#{quote}"
        else
          buf << " #{key}"
        end
      when false, nil
        # omitted
      else
        buf << " #{key}=#{quote}#{escape_html(escape_attrs, value)}#{quote}"
      end
    end

    def escape_html(escape_attrs, str)
      if escape_attrs
        Haml::Util.escape_html(str)
      else
        str
      end
    end
  end
end
