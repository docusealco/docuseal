# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

require 'geom2d/algorithms'
require 'geom2d/utils'
require 'geom2d/polygon_set'

module Geom2D
  module Algorithms

    # Performs intersection, union, difference and xor operations on Geom2D::PolygonSet objects.
    #
    # The entry method is PolygonOperation.run.
    #
    # The algorithm is described in the paper "A simple algorithm for Boolean operations on
    # polygons" by Martinez et al (see http://dl.acm.org/citation.cfm?id=2494701). This
    # implementation is based on the public domain code from
    # http://www4.ujaen.es/~fmartin/bool_op.html, which is the original implementation from the
    # authors of the paper.
    class PolygonOperation

      include Utils

      # Represents one event of the sweep line phase, i.e. a (left or right) endpoint of a segment
      # together with processing information.
      class SweepEvent

        include Utils

        # +True+ if the #point is the left endpoint of the segment.
        attr_accessor :left

        # The point of this event, a Geom2D::Point instance.
        attr_reader :point

        # The type of polygon, either :clipping or :subject.
        attr_reader :polygon_type

        # The other event. This event together with the other event represents a segment.
        attr_accessor :other_event

        # The edge type of the event's segment, either :normal, :non_contributing, :same_transition
        # or :different_transition.
        attr_accessor :edge_type

        # +True+ if the segment represents an inside-outside transition from (point.x, -infinity)
        # into the polygon set to which the segment belongs.
        attr_accessor :in_out

        # +True+ if the closest segment downwards from this segment that belongs to the other
        # polygon set represents an inside-outside transition from (point.x, -infinity).
        attr_accessor :other_in_out

        # +True+ if this event's segment is part of the result polygon set.
        attr_accessor :in_result

        # The previous event/segment downwards from this segment that is part of the result polygon
        # set.
        attr_accessor :prev_in_result

        # Creates a new SweepEvent.
        def initialize(left, point, polygon_type, other_event = nil)
          @left = left
          @point = point
          @other_event = other_event
          @polygon_type = polygon_type
          @edge_type = :normal
        end

        # Returns +true+ if this event's line #segment is below the point +p+.
        def below?(p)
          if left
            Algorithms.ccw(@point, @other_event.point, p) > 0
          else
            Algorithms.ccw(@other_event.point, @point, p) > 0
          end
        end

        # Returns +true+ if this event's line #segment is above the point +p+.
        def above?(point)
          !below?(point)
        end

        # Returns +true+ if this event's line segment is vertical.
        def vertical?
          float_equal(@point.x, other_event.point.x)
        end

        # Returns +true+ if this event should be *processed after the given event*.
        #
        # This method is used for sorting events in the event queue of the main algorithm.
        def process_after?(event)
          if (cmp = float_compare(point.x, event.point.x)) != 0
            cmp > 0 # different x-coordinates, true if point.x is greater
          elsif (cmp = float_compare(point.y, event.point.y)) != 0
            cmp > 0 # same x-, different y-coordinates, true if point.y is greater
          elsif left != event.left
            left # same point; one is left, one is right endpoint; true if left endpoint
          elsif Algorithms.ccw(point, other_event.point, event.other_event.point) != 0
            above?(event.other_event.point) # both left or right; not collinear; true if top segment
          else
            polygon_type < event.polygon_type # true if clipping polygon
          end
        end

        # Returns +true+ it this event's segment is below the segment of the other event.
        #
        # This method is used for sorting events in the sweep line status data structure of the main
        # algorithm.
        #
        # This method is intended to be used only on left events!
        def segment_below?(event)
          if self == event
            false
          elsif Algorithms.ccw(point, other_event.point, event.point) != 0 ||
              Algorithms.ccw(point, other_event.point, event.other_event.point) != 0
            # segments are not collinear
            if point == event.point
              below?(event.other_event.point)
            elsif float_compare(point.x, event.point.x) == 0
              float_compare(point.y, event.point.y) < 0
            elsif process_after?(event)
              event.above?(point)
            else
              below?(event.point)
            end
          elsif polygon_type != event.polygon_type
            polygon_type > event.polygon_type
          elsif point == event.point
            object_id < event.object_id # just need any consistency criterion
          else
            process_after?(event)
          end
        end

        # Returns +true+ if this event's segment should be in the result based on the boolean
        # operation.
        def in_result?(operation)
          case edge_type
          when :normal
            case operation
            when :intersection then !other_in_out
            when :union then other_in_out
            when :difference then polygon_type == :subject ? other_in_out : !other_in_out
            when :xor then true
            end
          when :same_transition
            operation == :intersection || operation == :union
          when :different_transition
            operation == :difference
          when :non_contributing
            false
          end
        end

        # Returns this event's line segment (point, other_event.point).
        def segment
          Geom2D::Segment(point, other_event.point)
        end

      end

      # Performs the given operation (:union, :intersection, :difference, :xor) on the subject and
      # clipping polygon sets.
      def self.run(subject, clipping, operation)
        new(subject, clipping, operation).run.result
      end

      # The result of the operation, a Geom2D::PolygonSet.
      attr_reader :result

      # Creates a new boolean operation object, performing the +operation+ (either :intersection,
      # :union, :difference or :xor) on the subject and clipping Geom2D::PolygonSet objects.
      def initialize(subject, clipping, operation)
        @subject = subject
        @clipping = clipping
        @operation = operation

        @result = PolygonSet.new
        @event_queue = Utils::SortedList.new {|a, b| a.process_after?(b) }
        # @sweep_line should really be a sorted data structure with O(log(n)) for insert/search!
        @sweep_line = Utils::SortedList.new {|a, b| a.segment_below?(b) }
        @sorted_events = []
      end

      # Performs the boolean polygon operation.
      def run
        subject_bb = @subject.bbox
        clipping_bb = @clipping.bbox
        min_of_max_x = [subject_bb.max_x, clipping_bb.max_x].min

        return self if trivial_operation(subject_bb, clipping_bb)

        @subject.each_segment {|segment| process_segment(segment, :subject) }
        @clipping.each_segment {|segment| process_segment(segment, :clipping) }

        until @event_queue.empty?
          event = @event_queue.last
          if (@operation == :intersection && event.point.x > min_of_max_x) ||
              (@operation == :difference && event.point.x > subject_bb.max_x)
            connect_edges
            return self
          end
          @sorted_events.push(event)

          @event_queue.pop
          if event.left # the segment hast to be inserted into status line
            prevprev_event, prev_event, next_event = @sweep_line.insert(event)

            compute_event_fields(event, prev_event)
            if next_event && possible_intersection(event, next_event) == 2
              compute_event_fields(event, prev_event)
              compute_event_fields(next_event, event)
            end
            if prev_event && possible_intersection(prev_event, event) == 2
              compute_event_fields(prev_event, prevprev_event)
              compute_event_fields(event, prev_event)
            end
          else # the segment has to be removed from the status line
            event = event.other_event # use left event
            prev_ev, next_ev = @sweep_line.delete(event)
            if prev_ev && next_ev
              possible_intersection(prev_ev, next_ev)
            end
          end
        end
        connect_edges
        self
      end

      private

      # Returns +true+ if the operation is a trivial one, e.g. if one polygon set is empty.
      def trivial_operation(subject_bb, clipping_bb)
        if @subject.nr_of_contours * @clipping.nr_of_contours == 0
          case @operation
          when :difference
            @result = @subject
          when :union, :xor
            @result = (@subject.nr_of_contours == 0 ? @clipping : @subject)
          end
          true
        elsif subject_bb.min_x > clipping_bb.max_x || clipping_bb.min_x > subject_bb.max_x ||
            subject_bb.min_y > clipping_bb.max_y || clipping_bb.min_y > subject_bb.max_y
          case @operation
          when :difference
            @result = @subject
          when :union, :xor
            @result = @subject + @clipping
          end
          true
        else
          false
        end
      end

      # Processes the segment by adding the needed SweepEvent objects into the event queue.
      def process_segment(segment, polygon_type)
        return if segment.degenerate?
        start_point_is_left = (segment.start_point == segment.min)
        e1 = SweepEvent.new(start_point_is_left, segment.start_point, polygon_type)
        e2 = SweepEvent.new(!start_point_is_left, segment.end_point, polygon_type, e1)
        e1.other_event = e2
        @event_queue.push(e1).push(e2)
      end

      # Computes the fields of the sweep event, using information from the previous event.
      #
      # The argument +prev+ is either the previous event or +nil+ if there is no previous event.
      def compute_event_fields(event, prev)
        if prev.nil?
          event.in_out = false
          event.other_in_out = true
        elsif event.polygon_type == prev.polygon_type
          event.in_out = !prev.in_out
          event.other_in_out = prev.other_in_out
        else
          event.in_out = !prev.other_in_out
          event.other_in_out = (prev.vertical? ? !prev.in_out : prev.in_out)
        end

        if prev
          event.prev_in_result = if !prev.in_result?(@operation) || prev.vertical?
                                   prev.prev_in_result
                                 else
                                   prev
                                 end
        end
        event.in_result = event.in_result?(@operation)
      end

      # Checks for possible intersections of the segments of the two events and returns 0 for no
      # intersections, 1 for intersection in one point, 2 if the segments are equal or have the same
      # left endpoint, and 3 for all other cases.
      def possible_intersection(ev1, ev2)
        result = ev1.segment.intersect(ev2.segment)

        result_is_point = result.kind_of?(Geom2D::Point)
        if result.nil? ||
            (result_is_point &&
             (ev1.point == ev2.point || ev1.other_event.point == ev2.other_event.point))
          return 0
        elsif !result_is_point && ev1.polygon_type == ev2.polygon_type
          raise "Edges of the same polygon overlap - not supported"
        end

        if result_is_point
          divide_segment(ev1, result) if ev1.point != result && ev1.other_event.point != result
          divide_segment(ev2, result) if ev2.point != result && ev2.other_event.point != result
          return 1
        end

        events = []
        if ev1.point == ev2.point
          events.push(nil)
        elsif ev1.process_after?(ev2)
          events.push(ev2, ev1)
        else
          events.push(ev1, ev2)
        end
        if ev1.other_event.point == ev2.other_event.point
          events.push(nil)
        elsif ev1.other_event.process_after?(ev2.other_event)
          events.push(ev2.other_event, ev1.other_event)
        else
          events.push(ev1.other_event, ev2.other_event)
        end

        if events.size == 2 || (events.size == 3 && events[2])
          # segments are equal or have the same left endpoint
          ev1.edge_type = :non_contributing
          ev2.edge_type = (ev1.in_out == ev2.in_out ? :same_transition : :different_transition)
          if events.size == 3
            divide_segment(events[2].other_event, events[1].point)
          end
          2
        elsif events.size == 3 # segments have the same right endpoint
          divide_segment(events[0], events[1].point)
          3
        elsif events[0] != events[3].other_event # partial segment overlap
          divide_segment(events[0], events[1].point)
          divide_segment(events[1], events[2].point)
          3
        else # one segments includes the other
          divide_segment(events[0], events[1].point)
          divide_segment(events[3].other_event, events[2].point)
          3
        end
      end

      # Divides the event's segment at the given point (which has to be inside the segment) and adds
      # the resulting events to the event queue.
      def divide_segment(event, point)
        right = SweepEvent.new(false, point, event.polygon_type, event)
        left = SweepEvent.new(true, point, event.polygon_type, event.other_event)
        event.other_event.other_event = left
        event.other_event = right
        @event_queue.push(left).push(right)
      end

      # Connects the edges of the segments that are in the result.
      def connect_edges
        events = @sorted_events.select do |ev|
          (ev.left && ev.in_result) || (!ev.left && ev.other_event.in_result)
        end

        # events may not be fully sorted due to overlapping edges
        events.sort! {|a, b| a.process_after?(b) ? 1 : -1 }
        event_pos = {}
        events.each_with_index do |event, index|
          event_pos[event] = index
          unless event.left
            event_pos[event], event_pos[event.other_event] =
              event_pos[event.other_event], event_pos[event]
          end
        end

        processed = {}
        events.each do |event|
          next if processed[event]

          initial_point = event.point
          polygon = Geom2D::Polygon.new
          @result << polygon
          polygon << initial_point
          while event.other_event.point != initial_point
            processed[event] = true
            processed[event.other_event] = true
            if polygon.nr_of_vertices > 1 &&
                Algorithms.ccw(polygon[-2], polygon[-1], event.other_event.point) == 0
              polygon.pop
            end
            polygon << event.other_event.point
            event = next_event(events, event_pos, processed, event)
          end

          if Algorithms.ccw(polygon[-2], polygon[-1], polygon[0]) == 0
            polygon.pop
          end
          processed[event] = processed[event.other_event] = true
        end
      end

      # Chooses the next event based on the argument.
      def next_event(events, event_pos, processed, event)
        pos = event_pos[event] + 1
        while pos < events.size && events[pos].point == event.other_event.point
          if processed[events[pos]]
            pos += 1
          else
            return events[pos]
          end
        end

        pos = event_pos[event] - 1
        pos -= 1 while processed[events[pos]]
        events[pos]
      end

    end

  end
end
