# frozen_string_literal: true

module CanCan
  # A general CanCan exception
  class Error < StandardError; end

  # Raised when behavior is not implemented, usually used in an abstract class.
  class NotImplemented < Error; end

  # Raised when removed code is called, an alternative solution is provided in message.
  class ImplementationRemoved < Error; end

  # Raised when using check_authorization without calling authorize!
  class AuthorizationNotPerformed < Error; end

  # Raised when a rule is created with both a block and a hash of conditions
  class BlockAndConditionsError < Error; end

  # Raised when an unexpected argument is passed as an attribute
  class AttributeArgumentError < Error; end

  # Raised when using a wrong association name
  class WrongAssociationName < Error; end

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to ControllerAdditions#authorize! but can be
  # raised manually.
  #
  #   raise CanCan::AccessDenied.new("Not authorized!", :read, Article)
  #
  # The passed message, action, and subject are optional and can later be retrieved when
  # rescuing from the exception.
  #
  #   exception.message # => "Not authorized!"
  #   exception.action # => :read
  #   exception.subject # => Article
  #
  # If the message is not specified (or is nil) it will default to "You are not authorized
  # to access this page." This default can be overridden by setting default_message.
  #
  #   exception.default_message = "Default error message"
  #   exception.message # => "Default error message"
  #
  # See ControllerAdditions#authorize! for more information on rescuing from this exception
  # and customizing the message using I18n.
  class AccessDenied < Error
    attr_reader :action, :subject, :conditions
    attr_writer :default_message

    def initialize(message = nil, action = nil, subject = nil, conditions = nil)
      @message = message
      @action = action
      @subject = subject
      @conditions = conditions
      @default_message = I18n.t(:"unauthorized.default", default: 'You are not authorized to access this page.')
    end

    def to_s
      @message || @default_message
    end

    def inspect
      details = %i[action subject conditions message].map do |attribute|
        value = instance_variable_get "@#{attribute}"
        "#{attribute}: #{value.inspect}" if value.present?
      end.compact.join(', ')
      "#<#{self.class.name} #{details}>"
    end
  end
end
