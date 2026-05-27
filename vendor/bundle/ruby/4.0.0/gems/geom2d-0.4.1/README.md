# Geom2D - Objects and Algorithms for 2D Geometry in Ruby

This library implements objects for 2D geometry, like points, lines, line segments, arcs, curves and
so on, as well as algorithms for these objects, like line-line intersections and arc approximation
by Bézier curves.


## License

Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>, licensed under the MIT - see the
**LICENSE** file.


## Features

* Objects
  * Point
  * Segment
  * Polygon
  * PolygonSet
  * Rectangle
  * Polyline (TODO)
  * Rectangle (TODO)
  * QuadraticCurve (TODO)
  * QubicCurve (TODO)
  * Arc (TODO)
  * Circle (TODO)
  * Path (TODO)
* Algorithms
  * Segment-Segment Intersection
  * Boolean Operations on PolygonSets

## Usage

~~~ ruby
require 'geom2d'

# Point, can also be interpreted as vector
point1 = Geom2D::Point(2, 2)
point2 = Geom2D::Point([2, 2])   # arrays are fine but not as efficient
point3 = Geom2D::Point(point2)   # copy constructor

# Segment defined by two points or a point and a vector
line1 = Geom2D::Segment(point1, point2)
line2 = Geom2D::Segment(point1, vector: point2)
line3 = Geom2D::Segment([3, 4], [9, 6])   # arrays are also possible

# Segment intersection
line1.intersect(line3)  # => intersection_point
~~~
