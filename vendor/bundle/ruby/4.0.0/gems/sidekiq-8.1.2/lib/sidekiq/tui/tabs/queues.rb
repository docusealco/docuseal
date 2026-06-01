require_relative "base_tab"

module Sidekiq
  class TUI
    module Tabs
      class Queues < BaseTab
        def features
          %i[selectable]
        end

        def controls
          @controls ||= super + [
            {code: "D", modifiers: ["shift"], display: "D", description: "Delete",
             action: ->(tui, tab) { tab.delete_queue! }, refresh: true},
            {code: "p", description: "Pause/Unpause Queue",
             action: ->(tui, tab) { tab.toggle_pause_queue! }}
          ]
        end

        def delete_queue!
          each_selection do |qname|
            Sidekiq::Queue.new(qname).clear
          end
        end

        def toggle_pause_queue!
          return unless Sidekiq.pro?

          each_selection do |qname|
            queue = Sidekiq::Queue.new(qname)
            if queue.paused?
              queue.unpause!
            else
              queue.pause!
            end
          end
        end

        def refresh_data
          refresh_data_for_stats

          queue_summaries = Sidekiq::Stats.new.queue_summaries.sort_by(&:name)

          selected = Array(@data[:selected])
          queues = queue_summaries.map { |queue_summary|
            row_cells = [
              selected.index(queue_summary.name) ? "✅" : "",
              queue_summary.name,
              queue_summary.size.to_s,
              number_with_delimiter(queue_summary.latency, {precision: 2})
            ]
            row_cells << (queue_summary.paused? ? "✅" : "") if Sidekiq.pro?
            row_cells
          }

          table_row_ids = queue_summaries.map(&:name)

          @data[:queues] = queues
          @data[:table] = {row_ids: table_row_ids}
        end

        def render(tui, frame, area)
          header = ["☑️", "Queue", "Size", "Latency"].map { |x| t(x) }
          header << "Paused?" if Sidekiq.pro?

          chunks = tui.layout_split(
            area,
            direction: :vertical,
            constraints: [
              tui.constraint_length(4), # Stats
              tui.constraint_fill(1) # Table
            ]
          )

          render_stats_section(tui, frame, chunks[0])
          render_table(tui, frame, chunks[1]) do
            {
              title: t(name),
              header:,
              widths: header.map.with_index { |_, idx|
                tui.constraint_length((idx == 1) ? 60 : 10)
              },
              rows: @data[:queues].map.with_index { |cells, idx|
                tui.table_row(
                  cells:,
                  style: idx.even? ? nil : tui.style(bg: :dark_gray)
                )
              }
            }
          end
        end
      end
    end
  end
end
