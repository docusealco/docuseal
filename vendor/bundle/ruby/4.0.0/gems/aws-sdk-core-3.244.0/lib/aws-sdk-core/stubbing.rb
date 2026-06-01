# frozen_string_literal: true

module Aws
  # @api private
  module Stubbing
    autoload :EmptyStub, 'aws-sdk-core/stubbing/empty_stub'
    autoload :DataApplicator, 'aws-sdk-core/stubbing/data_applicator'
    autoload :StubData, 'aws-sdk-core/stubbing/stub_data'
    autoload :XmlError, 'aws-sdk-core/stubbing/xml_error'

    module Protocols
      autoload :Json, 'aws-sdk-core/stubbing/protocols/json'
      autoload :Rest, 'aws-sdk-core/stubbing/protocols/rest'
      autoload :RestJson, 'aws-sdk-core/stubbing/protocols/rest_json'
      autoload :RestXml, 'aws-sdk-core/stubbing/protocols/rest_xml'
      autoload :Query, 'aws-sdk-core/stubbing/protocols/query'
      autoload :EC2, 'aws-sdk-core/stubbing/protocols/ec2'
      autoload :RpcV2, 'aws-sdk-core/stubbing/protocols/rpc_v2'
      autoload :ApiGateway, 'aws-sdk-core/stubbing/protocols/api_gateway'
    end
  end
end
