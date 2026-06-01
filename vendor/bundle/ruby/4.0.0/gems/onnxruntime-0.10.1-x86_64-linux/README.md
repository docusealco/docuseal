# ONNX Runtime Ruby

:fire: [ONNX Runtime](https://github.com/Microsoft/onnxruntime) - the high performance scoring engine for ML models - for Ruby

Check out [an example](https://ankane.org/tensorflow-ruby)

For transformer models, check out [Informers](https://github.com/ankane/informers)

[![Build Status](https://github.com/ankane/onnxruntime-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/onnxruntime-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "onnxruntime"
```

## Getting Started

Load a model and make predictions

```ruby
model = OnnxRuntime::Model.new("model.onnx")
model.predict({x: [1, 2, 3]})
```

> Download pre-trained models from the [ONNX Model Zoo](https://github.com/onnx/models)

Get inputs

```ruby
model.inputs
```

Get outputs

```ruby
model.outputs
```

Get metadata

```ruby
model.metadata
```

Load a model from a string or other `IO` object

```ruby
io = StringIO.new("...")
model = OnnxRuntime::Model.new(io)
```

Get specific outputs

```ruby
model.predict({x: [1, 2, 3]}, output_names: ["label"])
```

## Session Options

```ruby
OnnxRuntime::Model.new(
  path_or_io,
  enable_cpu_mem_arena: true,
  enable_mem_pattern: true,
  enable_profiling: false,
  execution_mode: :sequential,    # :sequential or :parallel
  free_dimension_overrides_by_denotation: nil,
  free_dimension_overrides_by_name: nil,
  graph_optimization_level: nil,  # :none, :basic, :extended, or :all
  inter_op_num_threads: nil,
  intra_op_num_threads: nil,
  log_severity_level: 2,
  log_verbosity_level: 0,
  logid: nil,
  optimized_model_filepath: nil,
  profile_file_prefix: "onnxruntime_profile_",
  session_config_entries: nil
)
```

## Run Options

```ruby
model.predict(
  input_feed,
  output_names: nil,
  log_severity_level: 2,
  log_verbosity_level: 0,
  logid: nil,
  terminate: false,
  output_type: :ruby       # :ruby or :numo
)
```

## Inference Session API

You can also use the Inference Session API, which follows the [Python API](https://onnxruntime.ai/docs/api/python/api_summary.html).

```ruby
session = OnnxRuntime::InferenceSession.new("model.onnx")
session.run(nil, {x: [1, 2, 3]})
```

The Python example models are included as well.

```ruby
OnnxRuntime::Datasets.example("sigmoid.onnx")
```

## GPU Support

### Linux and Windows

Download the appropriate [GPU release](https://github.com/microsoft/onnxruntime/releases) and set:

```ruby
OnnxRuntime.ffi_lib = "path/to/lib/libonnxruntime.so" # onnxruntime.dll for Windows
```

and use:

```ruby
model = OnnxRuntime::Model.new("model.onnx", providers: ["CUDAExecutionProvider"])
```

### Mac

Use:

```ruby
model = OnnxRuntime::Model.new("model.onnx", providers: ["CoreMLExecutionProvider"])
```

## History

View the [changelog](https://github.com/ankane/onnxruntime-ruby/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/onnxruntime-ruby/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/onnxruntime-ruby/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development and testing:

```sh
git clone https://github.com/ankane/onnxruntime-ruby.git
cd onnxruntime-ruby
bundle install
bundle exec rake vendor:all
bundle exec rake test
```
