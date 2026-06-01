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

    # This module converts the glyphs on a page to a single text string while preserving the layout.
    #
    # The general algorithm is:
    #
    # 1. Collect all individual glyphs with their user space coordinates in
    #    TextRunCollector::TextRun objects.
    #
    # 2. Sort text runs top to bottom and then left to right.
    #
    # 3. Group those text runs into lines based on a "baseline" while also combining neighboring
    #    text runs into larger runs.
    #
    # 4. Render each line into a string by taking into account the page size and the median glyph
    #    width for a text run to column mapping.
    #
    # 5. Add blank lines between text lines based on the page's normal line spacing.
    module SmartTextExtractor

      # This module provides the functionality for collecting the necessary TextRun instances for
      # layouting the text.
      #
      # To use this module include it in a processor class. Then invoke the #collect_text_runs
      # method in the #show_text and #show_text_with_positioning methods.
      #
      # Example:
      #
      #   class CustomProcessor < HexaPDF::Content::Processor
      #     include TextRunCollector
      #
      #     def show_text(str)
      #       collect_text_runs(decode_text_with_positioning(str))
      #     end
      #     alias show_text_with_positioning show_text
      #
      #   end
      #
      # Once the processor has done its job, the collected text runs are available via the
      # #text_runs method. Use them as input for SmartTextExtractor.layout_text_runs.
      module TextRunCollector

        # Represents a single run of continuous glyphs and their combined bounding box in user
        # space.
        TextRun = Struct.new(:string, :left, :bottom, :right, :top) do
          # The "baseline" is approximated with the bottom of the bounding box.
          #
          # This works because HexaPDF uses a font's bounding box instead of the glyph's bounding
          # box for each glyph. So while differently sized glyphs will have different "baseline"
          # values, this is taken into account in the algorithm in the same way as subscript and
          # superscript.
          #
          # Using this "fake" baseline works well enough and avoids additional calculations.
          def baseline = bottom

          # The height of the text run's bounding box.
          def height = top - bottom

          # The width of the text run's bounding box.
          def width = right - left
        end

        # Array with all collected TextRun instances.
        attr_reader :text_runs

        def initialize # :nodoc:
          super
          @text_runs = []
        end

        private

        # Collects all text runs from the glyphs in the +boxes+ array.
        def collect_text_runs(boxes)
          boxes.each do |box|
            llx, lly, lrx, lry, urx, ury, ulx, uly = *box.points
            x_min, x_max = [llx, lrx, ulx, urx].minmax
            y_min, y_max = [lly, lry, uly, ury].minmax
            @text_runs << TextRun.new(+box.string, x_min, y_min, x_max, y_max)
          end
        end
      end

      # This processor class is used when layouting the text through
      # HexaPDF::Type::Page#extract_text.
      class TextRunProcessor < HexaPDF::Content::Processor

        include TextRunCollector

        def show_text(str)
          collect_text_runs(decode_text_with_positioning(str))
        end
        alias show_text_with_positioning show_text

      end

      # Converts an array of TextRun objects into a single string representation, preserving the
      # visual layout.
      #
      # The +page_width+ and +page_height+ arguments specify the width and height of the page from
      # which the text runs were extracted.
      #
      # The remaining keyword arguments can be used to fine-tune the algorithm for one's needs:
      #
      # +line_tolerance_factor+::
      #     The tolerance factor is applied to the median text run height to determine the range
      #     within which two text runs are considered to be on the same line. This ensures that
      #     small differences in the baseline due to, for example, subscript or superscript parts
      #     don't result in multiple lines.
      #
      #     The factor should not be too large to avoid forcing separate visual lines into one line
      #     but also not too small to avoid subscript/superscript begin on separate lines. The
      #     default seems to work quite well.
      #
      # +paragraph_distance_threshold+::
      #     If the number of normal line spacings between two adjacent baselines is at least this
      #     large (but smaller than +large_distance_threshold+), the gap is interpreted as a
      #     paragraph break and a single blank line is inserted.
      #
      # +large_distance_threshold+::
      #     Works like +paragraph_distance_threshold+ and indicates if a number of normal line
      #     spacings is too large for being a paragraph break. A proportional number of blank lines
      #     is inserted in this case.
      #
      #     This is used to represent large parts with non-text content like images.
      def self.layout_text_runs(text_runs, page_width, page_height,
                                line_tolerance_factor: 0.4, paragraph_distance_threshold: 1.35,
                                large_distance_threshold: 3.0)
        return '' if text_runs.empty?

        # Use the median height of all text runs as an approximation of the main font size used on
        # the page. The line tolerance uses a hard floor for small fonts.
        median_height = median(text_runs.map(&:height).sort)
        line_tolerance = [median_height * line_tolerance_factor, 2].max

        # Group the text runs into lines which are sorted top to bottom. Text runs are pre-sorted by
        # baseline from top to bottom and left to right (the latter is done so that consecutive text
        # runs can be combined).
        sorted = text_runs.sort_by {|run| [-run.baseline, run.left] }
        lines = group_into_lines(sorted, line_tolerance)

        # Calculate the normal line spacing, excluding anything too small/big.
        line_distances = lines.map {|l| l.baseline }.each_cons(2).map {|a, b| a - b }.
          select {|d| d >= median_height * 0.5 && d <= median_height * 2 }.sort
        normal_line_spacing = line_distances.empty? ? median_height * 1.2 : median(line_distances)

        # Convert the lines into actual text strings. Blank lines are inserted between the lines
        # based on the normal line spacing.
        output_lines = []
        left_margin = lines.map {|line| line.text_runs[0].left }.min
        glyph_widths = lines.flat_map do |line|
          line.text_runs.flat_map {|run| [run.width.to_f / run.string.length] * run.string.length }
        end.sort
        median_glyph_width = median(glyph_widths)

        lines.each_with_index do |line, index|
          output_lines << text_runs_to_string(line.text_runs, median_glyph_width, left_margin)
          next if index == lines.length - 1

          # Add blank lines as needed.
          ratio = (line.baseline - lines[index + 1].baseline) / normal_line_spacing
          if ratio >= large_distance_threshold
            # Subtract 1 because the newline after the output line already counts as one
            # newline. Also cap at a maximum of 40 to avoid huge gaps.
            [ratio.round - 1, 40].min.times { output_lines << '' }
          elsif ratio >= paragraph_distance_threshold
            output_lines << ''
          end
        end

        output_lines.join("\n")
      end

      # Holds an array of TextRun objects and their median baseline.
      Line = Struct.new(:text_runs, :baseline)

      # Groups a sorted list of TextRuns (sorted by baseline, then left) into lines.
      #
      # Since the text_runs are already sorted, a single run through +sorted_text_runs+ is
      # sufficient. A new line is created if a text run's baseline differs by more than +tolerance+
      # from the current line's (median) baseline.
      #
      # The result is a list of Line objects with their contents sorted left to right.
      def self.group_into_lines(sorted_text_runs, tolerance)
        lines = []
        current_line = []
        current_baseline = sorted_text_runs[0].baseline
        current_baselines = [current_baseline]

        sorted_text_runs.each do |text_run|
          # Try to combine text_runs that share exactly the same height and are next to each
          # other. This avoids potentially garbled output because if two text parts are above each
          # other but end up on the same line, the text runs would be mixed up (think: centered
          # table header where some cells contain two lines).
          if (last = current_line[-1]) && last.bottom == text_run.bottom &&
             last.top == text_run.top && text_run.left - last.right < 1
            last.string << text_run.string
            last.right = text_run.right
          elsif (current_baseline - text_run.baseline).abs <= tolerance
            current_line << text_run
            current_baselines << text_run.baseline
            current_baseline = median(current_baselines)
          else
            lines << Line.new(current_line.sort_by!(&:left), current_baseline)
            current_line = [text_run]
            current_baseline = text_run.baseline
            current_baselines.clear
            current_baselines << current_baseline
          end
        end
        lines << Line.new(current_line.sort_by!(&:left), current_baseline)
      end
      private_class_method :group_into_lines

      # Returns the median value of the given sorted array of numerics.
      def self.median(sorted_array)
        mid = sorted_array.length / 2
        sorted_array.length.odd? ? sorted_array[mid] : (sorted_array[mid - 1] + sorted_array[mid]) / 2.0
      end
      private_class_method :median

      # Renders an array of TextRun objects representing one line to a single string.
      #
      # +median_glyph_width+:: Is used to determine the column for each text run.
      # +left_margin+:: Is removed from the left side to avoid unnecessary indentation.
      def self.text_runs_to_string(text_runs, median_glyph_width, left_margin)
        # Minimum gap to classify as a word boundary
        space_threshold = median_glyph_width * 0.5

        result = +''
        # The column where the last text run ended. Can be different from result.size due to fitting
        # proportional-width fonts to a fixed-column output.
        cursor = 0

        text_runs.each_with_index do |text_run, index|
          target_col = ((text_run.left - left_margin) / median_glyph_width).round
          advance = target_col - cursor

          if advance > 0
            result << ' ' * advance
            cursor += advance
          elsif index >= 1 && text_run.left - text_runs[index - 1].right > space_threshold &&
                result[-1] != ' '
            # Force space even if advance < 0 when the actual spacing between text runs is large
            # enough. This might happen because we are projecting proportional-width fonts to a
            # fixed-column output.
            cursor = target_col
            result << ' '
          end

          result << text_run.string

          # Move cursor to the text run's right edge but at least the text run's character count
          # from the current position. This avoids gaps when there is too much difference between
          # the on-page position and the approximated cursor. However, a one column difference is
          # ignored to account for rounding errors.
          cursor += text_run.string.size
          text_run_right_edge_cursor = ((text_run.right - left_margin) / median_glyph_width).round
          cursor = [text_run_right_edge_cursor, cursor].max if text_run_right_edge_cursor != cursor + 1
        end

        result.rstrip
      end
      private_class_method :text_runs_to_string

    end
  end
end
