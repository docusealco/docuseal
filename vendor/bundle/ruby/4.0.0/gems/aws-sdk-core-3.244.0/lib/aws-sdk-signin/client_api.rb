# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::Signin
  # @api private
  module ClientApi

    include Seahorse::Model

    AccessDeniedException = Shapes::StructureShape.new(name: 'AccessDeniedException')
    AccessToken = Shapes::StructureShape.new(name: 'AccessToken')
    AuthorizationCode = Shapes::StringShape.new(name: 'AuthorizationCode')
    ClientId = Shapes::StringShape.new(name: 'ClientId')
    CodeVerifier = Shapes::StringShape.new(name: 'CodeVerifier')
    CreateOAuth2TokenRequest = Shapes::StructureShape.new(name: 'CreateOAuth2TokenRequest')
    CreateOAuth2TokenRequestBody = Shapes::StructureShape.new(name: 'CreateOAuth2TokenRequestBody')
    CreateOAuth2TokenResponse = Shapes::StructureShape.new(name: 'CreateOAuth2TokenResponse')
    CreateOAuth2TokenResponseBody = Shapes::StructureShape.new(name: 'CreateOAuth2TokenResponseBody')
    ExpiresIn = Shapes::IntegerShape.new(name: 'ExpiresIn')
    GrantType = Shapes::StringShape.new(name: 'GrantType')
    IdToken = Shapes::StringShape.new(name: 'IdToken')
    InternalServerException = Shapes::StructureShape.new(name: 'InternalServerException')
    OAuth2ErrorCode = Shapes::StringShape.new(name: 'OAuth2ErrorCode')
    RedirectUri = Shapes::StringShape.new(name: 'RedirectUri')
    RefreshToken = Shapes::StringShape.new(name: 'RefreshToken')
    String = Shapes::StringShape.new(name: 'String')
    TokenType = Shapes::StringShape.new(name: 'TokenType')
    TooManyRequestsError = Shapes::StructureShape.new(name: 'TooManyRequestsError')
    ValidationException = Shapes::StructureShape.new(name: 'ValidationException')

    AccessDeniedException.add_member(:error, Shapes::ShapeRef.new(shape: OAuth2ErrorCode, required: true, location_name: "error"))
    AccessDeniedException.add_member(:message, Shapes::ShapeRef.new(shape: String, required: true, location_name: "message"))
    AccessDeniedException.struct_class = Types::AccessDeniedException

    AccessToken.add_member(:access_key_id, Shapes::ShapeRef.new(shape: String, required: true, location_name: "accessKeyId"))
    AccessToken.add_member(:secret_access_key, Shapes::ShapeRef.new(shape: String, required: true, location_name: "secretAccessKey"))
    AccessToken.add_member(:session_token, Shapes::ShapeRef.new(shape: String, required: true, location_name: "sessionToken"))
    AccessToken.struct_class = Types::AccessToken

    CreateOAuth2TokenRequest.add_member(:token_input, Shapes::ShapeRef.new(shape: CreateOAuth2TokenRequestBody, required: true, location_name: "tokenInput"))
    CreateOAuth2TokenRequest.struct_class = Types::CreateOAuth2TokenRequest
    CreateOAuth2TokenRequest[:payload] = :token_input
    CreateOAuth2TokenRequest[:payload_member] = CreateOAuth2TokenRequest.member(:token_input)

    CreateOAuth2TokenRequestBody.add_member(:client_id, Shapes::ShapeRef.new(shape: ClientId, required: true, location_name: "clientId"))
    CreateOAuth2TokenRequestBody.add_member(:grant_type, Shapes::ShapeRef.new(shape: GrantType, required: true, location_name: "grantType"))
    CreateOAuth2TokenRequestBody.add_member(:code, Shapes::ShapeRef.new(shape: AuthorizationCode, location_name: "code"))
    CreateOAuth2TokenRequestBody.add_member(:redirect_uri, Shapes::ShapeRef.new(shape: RedirectUri, location_name: "redirectUri"))
    CreateOAuth2TokenRequestBody.add_member(:code_verifier, Shapes::ShapeRef.new(shape: CodeVerifier, location_name: "codeVerifier"))
    CreateOAuth2TokenRequestBody.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, location_name: "refreshToken"))
    CreateOAuth2TokenRequestBody.struct_class = Types::CreateOAuth2TokenRequestBody

    CreateOAuth2TokenResponse.add_member(:token_output, Shapes::ShapeRef.new(shape: CreateOAuth2TokenResponseBody, required: true, location_name: "tokenOutput"))
    CreateOAuth2TokenResponse.struct_class = Types::CreateOAuth2TokenResponse
    CreateOAuth2TokenResponse[:payload] = :token_output
    CreateOAuth2TokenResponse[:payload_member] = CreateOAuth2TokenResponse.member(:token_output)

    CreateOAuth2TokenResponseBody.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessToken, required: true, location_name: "accessToken"))
    CreateOAuth2TokenResponseBody.add_member(:token_type, Shapes::ShapeRef.new(shape: TokenType, required: true, location_name: "tokenType"))
    CreateOAuth2TokenResponseBody.add_member(:expires_in, Shapes::ShapeRef.new(shape: ExpiresIn, required: true, location_name: "expiresIn"))
    CreateOAuth2TokenResponseBody.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, required: true, location_name: "refreshToken"))
    CreateOAuth2TokenResponseBody.add_member(:id_token, Shapes::ShapeRef.new(shape: IdToken, location_name: "idToken"))
    CreateOAuth2TokenResponseBody.struct_class = Types::CreateOAuth2TokenResponseBody

    InternalServerException.add_member(:error, Shapes::ShapeRef.new(shape: OAuth2ErrorCode, required: true, location_name: "error"))
    InternalServerException.add_member(:message, Shapes::ShapeRef.new(shape: String, required: true, location_name: "message"))
    InternalServerException.struct_class = Types::InternalServerException

    TooManyRequestsError.add_member(:error, Shapes::ShapeRef.new(shape: OAuth2ErrorCode, required: true, location_name: "error"))
    TooManyRequestsError.add_member(:message, Shapes::ShapeRef.new(shape: String, required: true, location_name: "message"))
    TooManyRequestsError.struct_class = Types::TooManyRequestsError

    ValidationException.add_member(:error, Shapes::ShapeRef.new(shape: OAuth2ErrorCode, required: true, location_name: "error"))
    ValidationException.add_member(:message, Shapes::ShapeRef.new(shape: String, required: true, location_name: "message"))
    ValidationException.struct_class = Types::ValidationException


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2023-01-01"

      api.metadata = {
        "apiVersion" => "2023-01-01",
        "auth" => ["aws.auth#sigv4"],
        "endpointPrefix" => "signin",
        "protocol" => "rest-json",
        "protocols" => ["rest-json"],
        "serviceFullName" => "AWS Sign-In Service",
        "serviceId" => "Signin",
        "signatureVersion" => "v4",
        "signingName" => "signin",
        "uid" => "signin-2023-01-01",
      }

      api.add_operation(:create_o_auth_2_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateOAuth2Token"
        o.http_method = "POST"
        o.http_request_uri = "/v1/token"
        o['authtype'] = "none"
        o['auth'] = ["smithy.api#noAuth"]
        o.input = Shapes::ShapeRef.new(shape: CreateOAuth2TokenRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateOAuth2TokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: TooManyRequestsError)
        o.errors << Shapes::ShapeRef.new(shape: InternalServerException)
        o.errors << Shapes::ShapeRef.new(shape: ValidationException)
        o.errors << Shapes::ShapeRef.new(shape: AccessDeniedException)
      end)
    end

  end
end
