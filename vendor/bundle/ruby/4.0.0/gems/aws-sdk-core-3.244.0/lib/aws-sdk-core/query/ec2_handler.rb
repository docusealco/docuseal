# frozen_string_literal: true

module Aws
  # @api private
  module Query
    class EC2Handler < Aws::Query::Handler

      def apply_params(param_list, params, rules)
        Aws::Query::EC2ParamBuilder.new(param_list).apply(rules, params)
      end

      def parse_xml(context)
        if (rules = context.operation.output)
          parser = Xml::Parser.new(rules)
          parser.parse(xml(context)) do |path, value|
            if path.size == 2 && path.last == 'requestId'
              context.metadata[:request_id] = value
            end
          end
        else
          EmptyStructure.new
        end
      end

    end
  end
end
