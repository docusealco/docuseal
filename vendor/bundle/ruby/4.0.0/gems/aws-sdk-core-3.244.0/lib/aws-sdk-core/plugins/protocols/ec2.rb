# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class EC2 < Seahorse::Client::Plugin

        option(:protocol, 'ec2')

        handler(Aws::Query::EC2Handler)
        handler(Xml::ErrorHandler, step: :sign)

      end
    end
  end
end
