# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # A handful of Amazon S3 operations will respond with a 200 status
      # code but will send an error in the response body. This plugin
      # injects a handler that will parse 200 response bodies for potential
      # errors, allowing them to be retried.
      # @api private
      class Http200Errors < Seahorse::Client::Plugin
        class Handler < Seahorse::Client::Handler
          # A regular expression to match error codes in the response body
          CODE_PATTERN = %r{<Code>(.+?)</Code>}.freeze
          private_constant :CODE_PATTERN

          # A list of encodings we force into UTF-8
          ENCODINGS_TO_FIX = [Encoding::US_ASCII, Encoding::ASCII_8BIT].freeze
          private_constant :ENCODINGS_TO_FIX

          # A regular expression to match detect errors in the response body
          ERROR_PATTERN = /<\?xml\s[^>]*\?>\s*<Error>/.freeze
          private_constant :ERROR_PATTERN

          # A regular expression to match an error message in the response body
          MESSAGE_PATTERN = %r{<Message>(.+?)</Message>}.freeze
          private_constant :MESSAGE_PATTERN

          def call(context)
            @handler.call(context).on(200) do |response|
              return response if streaming_output?(context.operation.output)

              error = check_for_error(context)
              return response unless error

              context.http_response.status_code = 500
              response.data = nil
              response.error = error
            end
          end

          private

          def build_error(context, code, message)
            S3::Errors.error_class(code).new(context, message)
          end

          def check_for_error(context)
            xml = normalize_encoding(context.http_response.body_contents)

            if xml.match?(ERROR_PATTERN)
              error_code = xml.match(CODE_PATTERN)[1]
              error_message = xml.match(MESSAGE_PATTERN)[1]
              build_error(context, error_code, error_message)
            elsif incomplete_xml_body?(xml, context.operation.output)
              Seahorse::Client::NetworkingError.new(
                build_error(context, 'InternalError', 'Empty or incomplete response body')
              )
            end
          end

          # Must have a member in the body and have the start of an XML Tag.
          # Other incomplete xml bodies will result in an XML ParsingError.
          def incomplete_xml_body?(xml, output)
            members_in_body?(output) && !xml.match(/<\w/)
          end

          # Checks if the output shape is a structure shape and has members that
          # are in the body for the case of a payload and a normal structure. A
          # non-structure shape will not have members in the body. In the case
          # of a string or blob, the body contents would have been checked first
          # before this method is called in incomplete_xml_body?.
          def members_in_body?(output)
            shape = resolve_shape(output)

            if structure_shape?(shape)
              shape.members.any? { |_, k| k.location.nil? }
            else
              false
            end
          end

          # Fixes encoding issues when S3 returns UTF-8 content with missing charset in Content-Type header or omits
          # Content-Type header entirely.  Net::HTTP defaults to US-ASCII or ASCII-8BIT when charset is unspecified.
          def normalize_encoding(xml)
            return xml unless xml.is_a?(String) && ENCODINGS_TO_FIX.include?(xml.encoding)

            xml.force_encoding('UTF-8')
          end

          def resolve_shape(output)
            return output.shape unless output[:payload_member]

            output[:payload_member].shape
          end

          # Streaming outputs are not subject to 200 errors.
          def streaming_output?(output)
            if (payload = output[:payload_member])
              # checking ref and shape
              payload['streaming'] || payload.shape['streaming'] || payload.eventstream
            else
              false
            end
          end

          def structure_shape?(shape)
            shape.is_a?(Seahorse::Model::Shapes::StructureShape)
          end
        end

        handler(Handler, step: :sign)
      end
    end
  end
end
