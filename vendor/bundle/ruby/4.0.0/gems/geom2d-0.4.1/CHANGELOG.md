## 0.4.1 - 2023-07-31

### Added

* Methods `#to_ary` and `#to_a` for Geom2D::Rectangle


## 0.4.0 - 2023-07-31

### Added

* Class Geom2D::Rectangle for a more compact rectangle representation

### Changed

* Require at least Ruby 2.6


## 0.3.1 - 2019-11-27

### Fixed

- Removed debug statements


## 0.3.0 - 2019-11-27

### Fixed

- Fix compatibility problem with Ruby 2.4


## 0.2.0 - 2018-12-16

### Changed

* Make Segment#intersect ~1.71x faster by avoiding unnecessary object creation
* Refactor and simplify the sorted list implementation used by the polygon
  operations, making the latter ~1.15x faster

### Fixed

* Fix off-by-one error in Polygon#ccw? calculation

## 0.1.0 - 2018-03-28

* Initial release
