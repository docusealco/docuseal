module OnnxRuntime
  module Utils
    class << self
      attr_accessor :mutex
    end
    self.mutex = Mutex.new

    def self.check_status(status)
      unless status.null?
        message = api[:GetErrorMessage].call(status).read_string
        api[:ReleaseStatus].call(status)
        raise Error, message
      end
    end

    def self.api
      FFI.api
    end

    def self.unsupported_type(name, type)
      raise Error, "Unsupported #{name} type: #{type}"
    end

    def self.tensor_type_and_shape(tensor_info)
      type = ::FFI::MemoryPointer.new(:int)
      check_status api[:GetTensorElementType].call(tensor_info, type)

      num_dims_ptr = ::FFI::MemoryPointer.new(:size_t)
      check_status api[:GetDimensionsCount].call(tensor_info, num_dims_ptr)
      num_dims = num_dims_ptr.read(:size_t)

      node_dims = ::FFI::MemoryPointer.new(:int64, num_dims)
      check_status api[:GetDimensions].call(tensor_info, node_dims, num_dims)
      dims = node_dims.read_array_of_int64(num_dims)

      symbolic_dims = ::FFI::MemoryPointer.new(:pointer, num_dims)
      check_status api[:GetSymbolicDimensions].call(tensor_info, symbolic_dims, num_dims)
      named_dims = num_dims.times.map { |i| symbolic_dims[i].read_pointer.read_string }
      dims = named_dims.zip(dims).map { |n, d| n.empty? ? d : n }

      [type.read_int, dims]
    end

    def self.node_info(typeinfo)
      onnx_type = ::FFI::MemoryPointer.new(:int)
      check_status api[:GetOnnxTypeFromTypeInfo].call(typeinfo, onnx_type)

      type = FFI::OnnxType[onnx_type.read_int]
      case type
      when :tensor
        # don't free tensor_info
        tensor_info = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:CastTypeInfoToTensorInfo].call(typeinfo, tensor_info)
        type, shape = Utils.tensor_type_and_shape(tensor_info.read_pointer)

        {
          type: "tensor(#{FFI::TensorElementDataType[type]})",
          shape: shape
        }
      when :sequence
        # don't free sequence_info
        sequence_type_info = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:CastTypeInfoToSequenceTypeInfo].call(typeinfo, sequence_type_info)

        nested_type_info = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:GetSequenceElementType].call(sequence_type_info.read_pointer, nested_type_info)
        nested_type_info = ::FFI::AutoPointer.new(nested_type_info.read_pointer, api[:ReleaseTypeInfo])
        v = node_info(nested_type_info)[:type]

        {
          type: "seq(#{v})",
          shape: []
        }
      when :map
        # don't free map_type_info
        map_type_info = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:CastTypeInfoToMapTypeInfo].call(typeinfo, map_type_info)

        # key
        key_type = ::FFI::MemoryPointer.new(:int)
        check_status api[:GetMapKeyType].call(map_type_info.read_pointer, key_type)
        k = FFI::TensorElementDataType[key_type.read_int]

        # value
        value_type_info = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:GetMapValueType].call(map_type_info.read_pointer, value_type_info)
        value_type_info = ::FFI::AutoPointer.new(value_type_info.read_pointer, api[:ReleaseTypeInfo])
        v = node_info(value_type_info)[:type]

        {
          type: "map(#{k},#{v})",
          shape: []
        }
      else
        Utils.unsupported_type("ONNX", type)
      end
    end

    def self.numo_array?(obj)
      defined?(Numo::NArray) && obj.is_a?(Numo::NArray)
    end

    def self.numo_types
      @numo_types ||= {
        float: Numo::SFloat,
        uint8: Numo::UInt8,
        int8: Numo::Int8,
        uint16: Numo::UInt16,
        int16: Numo::Int16,
        int32: Numo::Int32,
        int64: Numo::Int64,
        bool: Numo::UInt8,
        double: Numo::DFloat,
        uint32: Numo::UInt32,
        uint64: Numo::UInt64
      }
    end

    def self.input_shape(input)
      if numo_array?(input)
        input.shape
      else
        shape = []
        s = input
        while s.is_a?(Array)
          shape << s.size
          s = s.first
        end
        shape
      end
    end

    def self.allocator
      @allocator ||= begin
        allocator = ::FFI::MemoryPointer.new(:pointer)
        check_status api[:GetAllocatorWithDefaultOptions].call(allocator)
        allocator.read_pointer # do not free default allocator
      end
    end
  end
end
