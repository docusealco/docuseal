# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS

  # When STS returns an error response, the Ruby SDK constructs and raises an error.
  # These errors all extend Aws::STS::Errors::ServiceError < {Aws::Errors::ServiceError}
  #
  # You can rescue all STS errors using ServiceError:
  #
  #     begin
  #       # do stuff
  #     rescue Aws::STS::Errors::ServiceError
  #       # rescues all STS API errors
  #     end
  #
  #
  # ## Request Context
  # ServiceError objects have a {Aws::Errors::ServiceError#context #context} method that returns
  # information about the request that generated the error.
  # See {Seahorse::Client::RequestContext} for more information.
  #
  # ## Error Classes
  # * {ExpiredTokenException}
  # * {ExpiredTradeInTokenException}
  # * {IDPCommunicationErrorException}
  #    * This error class is not used. `IDPCommunicationError` is used during parsing instead.
  # * {IDPRejectedClaimException}
  #    * This error class is not used. `IDPRejectedClaim` is used during parsing instead.
  # * {InvalidAuthorizationMessageException}
  # * {InvalidIdentityTokenException}
  #    * This error class is not used. `InvalidIdentityToken` is used during parsing instead.
  # * {JWTPayloadSizeExceededException}
  # * {MalformedPolicyDocumentException}
  #    * This error class is not used. `MalformedPolicyDocument` is used during parsing instead.
  # * {OutboundWebIdentityFederationDisabledException}
  # * {PackedPolicyTooLargeException}
  #    * This error class is not used. `PackedPolicyTooLarge` is used during parsing instead.
  # * {RegionDisabledException}
  # * {SessionDurationEscalationException}
  #
  # Additionally, error classes are dynamically generated for service errors based on the error code
  # if they are not defined above.
  module Errors

    extend Aws::Errors::DynamicErrors

    class ExpiredTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::ExpiredTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class ExpiredTradeInTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::ExpiredTradeInTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    # @deprecated This error class is not used during parsing.
    #   Please use `IDPCommunicationError` instead.
    class IDPCommunicationErrorException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::IDPCommunicationErrorException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    # @deprecated This error class is not used during parsing.
    #   Please use `IDPRejectedClaim` instead.
    class IDPRejectedClaimException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::IDPRejectedClaimException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class InvalidAuthorizationMessageException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::InvalidAuthorizationMessageException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    # @deprecated This error class is not used during parsing.
    #   Please use `InvalidIdentityToken` instead.
    class InvalidIdentityTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::InvalidIdentityTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class JWTPayloadSizeExceededException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::JWTPayloadSizeExceededException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    # @deprecated This error class is not used during parsing.
    #   Please use `MalformedPolicyDocument` instead.
    class MalformedPolicyDocumentException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::MalformedPolicyDocumentException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class OutboundWebIdentityFederationDisabledException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::OutboundWebIdentityFederationDisabledException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    # @deprecated This error class is not used during parsing.
    #   Please use `PackedPolicyTooLarge` instead.
    class PackedPolicyTooLargeException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::PackedPolicyTooLargeException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class RegionDisabledException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::RegionDisabledException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

    class SessionDurationEscalationException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::SessionDurationEscalationException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end
    end

  end
end
