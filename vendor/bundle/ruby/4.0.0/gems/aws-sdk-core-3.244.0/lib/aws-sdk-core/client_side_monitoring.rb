# frozen_string_literal: true

module Aws
  # setup autoloading for ClientSideMonitoring module
  module ClientSideMonitoring
    autoload :RequestMetrics, 'aws-sdk-core/client_side_monitoring/request_metrics'
    autoload :Publisher, 'aws-sdk-core/client_side_monitoring/publisher'
  end
end
