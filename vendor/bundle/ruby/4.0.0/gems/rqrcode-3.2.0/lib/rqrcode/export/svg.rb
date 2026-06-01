# frozen_string_literal: true

# This class creates a SVG files.
# Initial code from: https://github.com/samvincent/rqrcode-rails3
module RQRCode
  module Export
    module SVG
      class BaseOutputSVG
        attr_reader :result

        def initialize(qrcode)
          @qrcode = qrcode
          @result = []
        end
      end

      class Path < BaseOutputSVG
        # Direction constants for edge representation
        # Edges stored as [start_x, start_y, direction] arrays instead of Struct
        DIR_UP = 0
        DIR_DOWN = 1
        DIR_LEFT = 2
        DIR_RIGHT = 3

        # Pre-computed end coordinate deltas: [dx, dy] for each direction
        DIR_DELTAS = [
          [0, -1], # UP
          [0, 1],  # DOWN
          [-1, 0], # LEFT
          [1, 0]   # RIGHT
        ].freeze

        # SVG path commands indexed by direction constant
        DIR_PATH_COMMANDS = ["v-", "v", "h-", "h"].freeze

        def build(module_size, options = {})
          color = options[:color]
          offset_x = options[:offset_x].to_i
          offset_y = options[:offset_y].to_i

          modules_array = @qrcode.modules
          module_count = modules_array.length
          matrix_size = module_count + 1

          # Edge matrix stores arrays of [x, y, direction] tuples
          edge_matrix = Array.new(matrix_size) { Array.new(matrix_size) }
          edge_count = 0

          # Process horizontal edges (between vertically adjacent cells)
          (module_count + 1).times do |row_index|
            module_count.times do |col_index|
              above = row_index > 0 && modules_array[row_index - 1][col_index]
              below = row_index < module_count && modules_array[row_index][col_index]

              if above && !below
                # Edge going left at (col+1, row)
                x = col_index + 1
                y = row_index
                (edge_matrix[y][x] ||= []) << [x, y, DIR_LEFT]
                edge_count += 1
              elsif !above && below
                # Edge going right at (col, row)
                x = col_index
                y = row_index
                (edge_matrix[y][x] ||= []) << [x, y, DIR_RIGHT]
                edge_count += 1
              end
            end
          end

          # Process vertical edges (between horizontally adjacent cells)
          module_count.times do |row_index|
            (module_count + 1).times do |col_index|
              left = col_index > 0 && modules_array[row_index][col_index - 1]
              right = col_index < module_count && modules_array[row_index][col_index]

              if left && !right
                # Edge going down at (col, row)
                x = col_index
                y = row_index
                (edge_matrix[y][x] ||= []) << [x, y, DIR_DOWN]
                edge_count += 1
              elsif !left && right
                # Edge going up at (col, row+1)
                x = col_index
                y = row_index + 1
                (edge_matrix[y][x] ||= []) << [x, y, DIR_UP]
                edge_count += 1
              end
            end
          end

          path_parts = []

          # Track search position to avoid re-scanning from beginning
          search_y = 0
          search_x = 0

          while edge_count > 0
            # Find next non-empty cell, starting from last position
            start_edge = nil
            found_y = search_y
            found_x = search_x

            # Continue from where we left off
            (search_y...matrix_size).each do |y|
              start_col = (y == search_y) ? search_x : 0
              (start_col...matrix_size).each do |x|
                cell = edge_matrix[y][x]
                next unless cell && !cell.empty?

                start_edge = cell.first
                found_y = y
                found_x = x
                break
              end
              break if start_edge
            end

            # Update search position for next iteration
            search_y = found_y
            search_x = found_x

            # Build path string directly without intermediate edge_loop array
            path_str = String.new(capacity: 64)
            path_str << "M" << start_edge[0].to_s << " " << start_edge[1].to_s

            current_edge = start_edge
            current_dir = nil
            current_count = 0

            while current_edge
              ex, ey, edir = current_edge

              # Remove edge from matrix
              cell = edge_matrix[ey][ex]
              cell.delete(current_edge)
              edge_matrix[ey][ex] = nil if cell.empty?
              edge_count -= 1

              # Accumulate consecutive edges in same direction
              if edir == current_dir
                current_count += 1
              else
                # Flush previous direction
                path_str << DIR_PATH_COMMANDS[current_dir] << current_count.to_s if current_dir
                current_dir = edir
                current_count = 1
              end

              # Find next edge at end coordinates
              delta = DIR_DELTAS[edir]
              next_x = ex + delta[0]
              next_y = ey + delta[1]
              next_cell = edge_matrix[next_y]&.[](next_x)
              current_edge = next_cell&.first
            end

            # Don't output the last direction segment - close path instead
            path_str << "z"
            path_parts << path_str
          end

          @result << %{<path d="#{path_parts.join}" fill="#{color}" transform="translate(#{offset_x},#{offset_y}) scale(#{module_size})"/>}
        end
      end

      class Rect < BaseOutputSVG
        def build(module_size, options = {})
          # Extract values from options
          color = options[:color]
          offset_x = options[:offset_x].to_i
          offset_y = options[:offset_y].to_i

          @qrcode.modules.each_index do |c|
            @qrcode.modules.each_index do |r|
              next unless @qrcode.checked?(c, r)

              x = r * module_size + offset_x
              y = c * module_size + offset_y
              @result << %(<rect width="#{module_size}" height="#{module_size}" x="#{x}" y="#{y}" fill="#{color}"/>)
            end
          end
        end
      end

      DEFAULT_SVG_ATTRIBUTES = [
        %(version="1.1"),
        %(xmlns="http://www.w3.org/2000/svg"),
        %(xmlns:xlink="http://www.w3.org/1999/xlink"),
        %(xmlns:ev="http://www.w3.org/2001/xml-events")
      ]

      SVG_PATH_COMMANDS = {
        move: "M",
        up: "v-",
        down: "v",
        left: "h-",
        right: "h",
        close: "z"
      }

      #
      # Render the SVG from the Qrcode.
      #
      # Options:
      # offset          - Padding around the QR Code in pixels
      #                   (default 0)
      # offset_x        - X Padding around the QR Code in pixels
      #                   (default offset)
      # offset_y        - Y Padding around the QR Code in pixels
      #                   (default offset)
      # fill            - Background color e.g "ffffff"
      #                   (default none)
      # color           - Foreground color e.g "000"
      #                   (default "000")
      # module_size     - The Pixel size of each module
      #                   (defaults 11)
      # shape_rendering - SVG Attribute: auto | optimizeSpeed | crispEdges | geometricPrecision
      #                   (defaults crispEdges)
      # standalone      - Whether to make this a full SVG file, or only an svg to embed in other svg
      #                   (default true)
      # use_path        - Use <path> to render SVG rather than <rect> to significantly reduce size
      #                   and quality. This will become the default in future versions.
      #                   (default false)
      # viewbox         - replace `width` and `height` in <svg> with a viewBox, allows CSS scaling
      #                   (default false)
      # svg_attributes  - A optional hash of custom <svg> attributes. Existing attributes will remain.
      #                   (default {})
      #
      def as_svg(options = {})
        fill = options[:fill]
        use_path = options[:use_path]
        offset = options[:offset].to_i
        offset_x = options.key?(:offset_x) ? options[:offset_x].to_i : offset
        offset_y = options.key?(:offset_y) ? options[:offset_y].to_i : offset
        color = options[:color] || "000"
        shape_rendering = options[:shape_rendering] || "crispEdges"
        module_size = options[:module_size] || 11
        standalone = options[:standalone].nil? || options[:standalone]
        viewbox = options[:viewbox].nil? ? false : options[:viewbox]
        svg_attributes = options[:svg_attributes] || {}

        # height and width dependent on offset and QR complexity
        width = (@qrcode.module_count * module_size) + (2 * offset_x)
        height = (@qrcode.module_count * module_size) + (2 * offset_y)
        dimension = [width, height].max
        # use dimensions differently if we are using a viewBox
        dimensions_attr = viewbox ? %(viewBox="0 0 #{width} #{height}") : %(width="#{width}" height="#{height}")

        svg_tag_attributes = (DEFAULT_SVG_ATTRIBUTES + [
          dimensions_attr,
          %(shape-rendering="#{shape_rendering}")
        ] + svg_attributes.map { |k, v| %(#{k}="#{v}") }).join(" ")

        xml_tag = %(<?xml version="1.0" standalone="yes"?>)
        open_tag = %(<svg #{svg_tag_attributes}>)
        close_tag = "</svg>"

        # Prefix hexadecimal colors unless using a named color (symbol)
        color = "##{color}" unless color.is_a?(Symbol)

        output_tag = (use_path ? Path : Rect).new(@qrcode)
        output_tag.build(module_size, offset_x: offset_x, offset_y: offset_y, color: color)

        if fill
          # Prefix hexadecimal colors unless using a named color (symbol)
          fill = "##{fill}" unless fill.is_a?(Symbol)
          output_tag.result.unshift %(<rect width="#{dimension}" height="#{dimension}" x="0" y="0" fill="#{fill}"/>)
        end

        if standalone
          output_tag.result.unshift(xml_tag, open_tag)
          output_tag.result << close_tag
        end

        output_tag.result.join
      end
    end
  end
end

RQRCode::QRCode.include RQRCode::Export::SVG
