# frozen_string_literal: true

module Params
  class BaseValidator
    InvalidParameterError = Class.new(StandardError)

    def self.call(...)
      validator = new(...)

      validator.call
    rescue InvalidParameterError => e
      Rollbar.warning(e) if defined?(Rollbar)

      raise e unless validator.dry_run?
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      raise e unless Rails.env.production?
    end

    attr_reader :params, :dry_run

    alias dry_run? dry_run

    def initialize(params, dry_run: false)
      @params = params
      @dry_run = dry_run
      @current_path = ''
    end

    def call
      raise NotImplementedError
    end

    def raise_error(message)
      message += " in `#{@current_path}`." if @current_path.present?

      raise InvalidParameterError, message unless dry_run?
    end

    def required(params, keys, message: nil)
      keys = Array.wrap(keys)

      return if keys.any? { |key| params&.dig(key).present? }

      raise_error(message || "#{keys.join(' or ')} is required")
    end

    def type(params, key, type, message: nil)
      return if params.blank?
      return if params[key].blank?

      return if params[key].is_a?(type) || (type == Hash && params[key].is_a?(ActionController::Parameters))

      type = 'Object' if type == Hash

      raise_error(message || "#{key} must be a #{type}")
    end

    def format(params, key, regexp, message: nil)
      return if params.blank?
      return if params[key].blank?
      return if regexp.match?(params[key].to_s)

      raise_error(message || "#{key} must follow the #{regexp.source} format")
    end

    def in_path(params, path = [])
      old_path = @current_path

      @current_path = [old_path, *path].compact_blank.map(&:to_s).join('.')

      param = params.dig(*path)

      yield params.dig(*path) if param

      @current_path = old_path
    end

    def in_path_each(params, path = [])
      old_path = @current_path

      params.dig(*path)&.each_with_index do |item, index|
        @current_path = [old_path, [*path].map(&:to_s).join('.') + "[#{index}]"].compact_blank.join('.')

        yield item if item
      end

      @current_path = old_path
    end

    def boolean(params, key, message: nil)
      return if params.blank?
      return unless params.key?(key)
      return if params[key].nil?

      value = ActiveModel::Type::Boolean.new.cast(params[key])

      return if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      raise_error(message || "#{key} must be true or false")
    end

    def value_in(params, key, values, allow_nil: false, message: nil)
      return if params.blank?
      return if allow_nil && params[key].nil?
      return if values.include?(params[key])

      raise_error(message || "#{key} must be one of #{values.join(', ')}")
    end

    def more_than(params, key, value, message: nil)
      return if params.blank?
      return if params[key].blank?
      return if params[key].to_f > value

      raise_error(message || "#{key} must be more than #{value}")
    end
  end
end
