## 0.10.1 (2025-09-30)

- Updated ONNX Runtime to 1.23.0

## 0.10.0 (2025-05-11)

- Updated ONNX Runtime to 1.22.0
- Dropped support for Ruby < 3.2

## 0.9.4 (2025-03-08)

- Updated ONNX Runtime to 1.21.0

## 0.9.3 (2024-11-01)

- Updated ONNX Runtime to 1.20.0
- Added experimental `OrtValue` class
- Added experimental `run_with_ort_values` method

## 0.9.2 (2024-09-04)

- Updated ONNX Runtime to 1.19.2
- Added support for CoreML

## 0.9.1 (2024-05-22)

- Updated ONNX Runtime to 1.18.0

## 0.9.0 (2024-02-27)

- Updated ONNX Runtime to 1.17.1

## 0.8.0 (2023-09-20)

- Updated ONNX Runtime to 1.16.0
- Changed inputs and outputs to return symbolic dimension names
- Fixed GPU support
- Dropped support for Ruby < 3
- Dropped support for loading models from binary string (use `StringIO` instead)

## 0.7.7 (2023-07-24)

- Updated ONNX Runtime to 1.15.1
- Fixed error with `dup` and `clone`

## 0.7.6 (2023-05-24)

- Updated ONNX Runtime to 1.15.0

## 0.7.5 (2023-02-11)

- Updated ONNX Runtime to 1.14.0

## 0.7.4 (2022-10-30)

- Updated ONNX Runtime to 1.13.1

## 0.7.3 (2022-07-23)

- Updated ONNX Runtime to 1.12.0

## 0.7.2 (2022-05-04)

- Updated ONNX Runtime to 1.11.1

## 0.7.1 (2022-03-28)

- Added `graph_description` to metadata
- Added `free_dimension_overrides_by_denotation` and `free_dimension_overrides_by_name` options
- Added `profile_file_prefix` option
- Added `session_config_entries` option
- Fixed memory leaks
- Fixed `enable_cpu_mem_arena: false`

## 0.7.0 (2022-03-27)

- Added platform-specific gems
- Added ARM shared library for Linux
- Dropped support for Ruby < 2.7

## 0.6.6 (2022-03-27)

- Updated ONNX Runtime to 1.11.0

## 0.6.5 (2021-12-07)

- Updated ONNX Runtime to 1.10.0

## 0.6.4 (2021-09-22)

- Updated ONNX Runtime to 1.9.0

## 0.6.3 (2021-07-08)

- Updated ONNX Runtime to 1.8.1

## 0.6.2 (2021-06-03)

- Updated ONNX Runtime to 1.8.0

## 0.6.1 (2021-05-17)

- Fixed memory errors

## 0.6.0 (2021-03-14)

- Updated ONNX Runtime to 1.7.0
- OpenMP is no longer required

## 0.5.2 (2020-12-27)

- Updated ONNX Runtime to 1.6.0
- Fixed error with `execution_mode` option
- Fixed error with `bool` input

## 0.5.1 (2020-11-01)

- Updated ONNX Runtime to 1.5.2
- Added support for string output
- Added `output_type` option
- Improved performance for Numo array inputs

## 0.5.0 (2020-10-01)

- Updated ONNX Runtime to 1.5.1
- OpenMP is now required on Mac
- Fixed `mul_1.onnx` example

## 0.4.0 (2020-07-20)

- Updated ONNX Runtime to 1.4.0
- Added `providers` method
- Fixed errors on Windows

## 0.3.3 (2020-06-17)

- Fixed segmentation fault on exit on Linux

## 0.3.2 (2020-06-16)

- Fixed error with FFI 1.13.0+
- Added friendly graph optimization levels

## 0.3.1 (2020-05-18)

- Updated ONNX Runtime to 1.3.0
- Added `custom_metadata_map` to model metadata

## 0.3.0 (2020-03-11)

- Updated ONNX Runtime to 1.2.0
- Added model metadata
- Added `end_profiling` method
- Added support for loading from IO objects
- Improved `input` and `output` for `seq` and `map` types

## 0.2.3 (2020-01-23)

- Updated ONNX Runtime to 1.1.1

## 0.2.2 (2019-12-24)

- Added support for session options
- Added support for run options
- Added `Datasets` module

## 0.2.1 (2019-12-19)

- Updated ONNX Runtime to 1.1.0

## 0.2.0 (2019-10-30)

- Added support for ONNX Runtime 1.0
- Dropped support for ONNX Runtime < 1.0

## 0.1.2 (2019-10-27)

- Added support for Numo::NArray
- Made thread-safe
- Fixed error with JRuby

## 0.1.1 (2019-09-03)

- Packaged ONNX Runtime with gem
- Added support for many more types
- Fixed output order with `output_names` option
- Fixed `File doesn't exist` on Windows

## 0.1.0 (2019-08-26)

- First release
