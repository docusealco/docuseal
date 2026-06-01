# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

module HexaPDF
  module Content

    # == Overview
    #
    # This module contains classes describing graphic objects that can be drawn on a Canvas.
    #
    # Since the PDF specification only provides the most common path creation operators, more
    # complex graphic objects need more than one operator for their creation. By defining this
    # graphic object interface (see below) such complex objects can be drawn in a consistent
    # manner on a Canvas.
    #
    # A graphic object should only use the path creation methods or other graphic objects when it
    # is drawn. Stroking and filling, or optionally clipping, is left to the user.
    #
    # The Canvas class provides a Canvas#draw method that can be used to draw complex graphic
    # objects as well as a Canvas#graphic_object method to retrieve an instance of a graphic object
    # for custom use. The latter method uses graphic object factories that can be registered via a
    # name using the document specific 'graphic_object.map' configuration option.
    #
    # == Implementation of a Graphic Object
    #
    # Graphic objects are usually implemented as classes since this automatically allows using the
    # class itself as the graphic object's factory.
    #
    # A graphic object factory is an object that responds to #configure(**kwargs) and returns a
    # configured graphic object. When the factory is implemented as a class, the #configure method
    # should be a class method returning properly configured instances of the class.
    #
    # A graphic object itself has to respond to two methods:
    #
    # #configure(**kwargs)::
    #     This method is used for re-configuring the graphic object and it should return the
    #     graphic object itself, not a new object.
    #
    # #draw(canvas)::
    #     This method is used for drawing the graphic object on the given Canvas.
    module GraphicObject

      autoload(:Arc, 'hexapdf/content/graphic_object/arc')
      autoload(:EndpointArc, 'hexapdf/content/graphic_object/endpoint_arc')
      autoload(:SolidArc, 'hexapdf/content/graphic_object/solid_arc')
      autoload(:Geom2D, 'hexapdf/content/graphic_object/geom2d')

    end

  end
end
