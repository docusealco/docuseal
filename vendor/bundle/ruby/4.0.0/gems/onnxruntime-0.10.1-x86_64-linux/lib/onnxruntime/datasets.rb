module OnnxRuntime
  module Datasets
    def self.example(name)
      unless %w(logreg_iris.onnx mul_1.onnx sigmoid.onnx).include?(name)
        raise ArgumentError, "Unable to find example '#{name}'"
      end
      File.expand_path("../../datasets/#{name}", __dir__)
    end
  end
end
