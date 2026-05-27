# Numo::NArray Alternative

[![Gem Version](https://badge.fury.io/rb/numo-narray-alt.svg)](https://badge.fury.io/rb/numo-narray-alt)
[![Build Status](https://github.com/yoshoku/numo-narray-alt/actions/workflows/build.yml/badge.svg)](https://github.com/yoshoku/numo-narray-alt/actions/workflows/build.yml)
[![BSD 3-Clause License](https://img.shields.io/badge/License-BSD%203--Clause-orange.svg)](https://github.com/yoshoku/numo-narray-alt/blob/main/LICENSE)
[![Documentation](https://img.shields.io/badge/api-reference-blue.svg)](https://gemdocs.org/gems/numo-narray-alt/)

Numo::NArray Alternative (numo-narray-alt) is a project forked from
[Numo::NArray](https://github.com/ruby-numo/numo-narray).
The project aims to support the latest Ruby features, release bug fixes as quickly as possible,
and adopt modern development practices.
In addition, module names, class names, and method names remain unchanged for compatibility,
making it a drop-in replacement.
The project owner is also the developer of [Rumale](https://github.com/yoshoku/rumale),
a machine learning library, and may add new features to numo-narray-alt to support the needs of Rumale.

The project owner has the utmost respect for Numo::NArray and its creator,
Prof. [Masahiro Tanaka](https://github.com/masa16).
This project is in no way intended to adversely affect the development of the original Numo::NArray.

## Installation

```shell
$ gem install numo-narray-alt
```

## Usage

The usage is exactly the same as Numo::NArray.

```ruby
irb(main):001> require 'numo/narray'
=> true
irb(main):002> x = Numo::DFloat[[1, 2, 3], [4, 5, 6]]
=>
Numo::DFloat#shape=[2,3]
...
irb(main):003> x.dot(x.transpose)
=>
Numo::DFloat#shape=[2,2]
[[14, 32],
 [32, 77]]
irb(main):004>
```

If you want to explicitly load numo-narray-alt, write the require method as follows:

```ruby
irb(main):001> require 'numo/narray/alt'
=> true
```

## Documentation

- [API Documentation on Gemdocs](https://gemdocs.org/gems/numo-narray-alt/)
- [Major Changes Since Fork](https://github.com/yoshoku/numo-narray-alt/wiki/Major-Changes-Since-Fork)

Since it is compatible with Numo::NArray, the following Numo::NArray documentation is also useful.

- [Comparison with Numpy](https://github.com/ruby-numo/numo-narray/wiki/Comparison-with-Numpy)
- [Numo vs numpy](https://github.com/ruby-numo/numo-narray/wiki/Numo-vs-numpy)
- [100 narray exercises](https://github.com/ruby-numo/numo-narray/wiki/100-narray-exercises)

## Related Projects

Numo::NArray Alternative is used in the following projects:

- [numo-linalg-alt](https://github.com/yoshoku/numo-linalg-alt): Linear algebra library with BLAS/LAPACK.
- [numo-optimize](https://github.com/yoshoku/numo-optimize): Optimization library for minimizing objective functions.
- [numo-random](https://github.com/yoshoku/numo-random): Random number generation library with several distributions.
- [numo-pocketfft](https://github.com/yoshoku/numo-pocketfft): Fourier transform library with pocketfft.
- [numo-libsvm](https://github.com/yoshoku/numo-libsvm): LIBSVM bindings library for numo-narray-alt.
- [numo-liblinear](https://github.com/yoshoku/numo-liblinear): LIBLINEAR bindings library for numo-narray-alt.
- [numo-linalg-randsvd](https://github.com/yoshoku/numo-linalg-randsvd): Randomized SVD library for numo-linalg-alt.
- [rumale](https://github.com/yoshoku/rumale): Machine learning library.

## Development

preparation:

```shell
$ git clone https://github.com/yoshoku/numo-narray-alt
$ cd numo-narray-alt
$ bundle install
```

build and test:

```
$ bundle exec rake compile
$ bundle exec rake test
```

linter:

```shell
$ bundle exec rubocop
$ clang-format --dry-run --Werror --style=file ext/**/*.h ext/**/*.c
```

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Please run `npm install` to set up husky and commitlint for commit message validation:

```shell
$ npm install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yoshoku/numo-narray-alt.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to
the [code of conduct](https://github.com/yoshoku/numo-narray-alt/blob/main/CODE_OF_CONDUCT.md).

## License

This project was originally forked from [Numo::NArray](https://github.com/ruby-numo/numo-narray).
It continues to be licensed under the [BSD-3-Clause License](https://github.com/yoshoku/numo-narray-alt/blob/main/LICENSE).
