module Sidekiq
  class TUI
    module Tabs
      module SetTab
        include Sidekiq::Paginator
        include Filtering

        def features
          %i[selectable pageable filterable]
        end

        def controls
          @controls ||= super + [{code: "D", modifiers: ["shift"], display: "D", description: "Delete",
                                  action: ->(tui, tab) { tab.alter_rows!(:delete) }, refresh: true},
            {code: "R", modifiers: ["shift"], display: "R", description: "Retry",
             action: ->(tui, tab) { tab.alter_rows!(:retry) }, refresh: true},
            {code: "E", modifiers: ["shift"], display: "E", description: "Enqueue",
             action: ->(tui, tab) { tab.alter_rows!(:add_to_queue) }, refresh: true},
            {code: "K", modifiers: ["shift"], display: "K", description: "Kill",
             action: ->(tui, tab) { tab.alter_rows!(:kill) }, refresh: true}]
        end

        def alter_rows!(action)
          # log(to_s, @data[:selected])
          set = set_class.new
          each_selection do |id|
            score, jid = id.split("|")
            item = set.fetch(score, jid)&.first
            item&.send(action)
          end
        end

        def refresh_data_for_set
          set = set_class.new
          f = current_filter
          pager, rows, current, total = if f && f.size > 2
            rows = set.scan(f).to_a
            sz = rows.size
            [Sidekiq::TUI::PageOptions.new(1, sz), rows, 1, sz]
          else
            pager = @data.dig(:table, :pager) || Sidekiq::TUI::PageOptions.new(1, 25)
            current, total, items = page(set.name, pager.page, pager.size)
            rows = items.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }
            [pager, rows, current, total]
          end

          @data.merge!(
            table: {pager:, rows:, current_page: current, total:,
                    next_page: (current * pager.size < total) ? pager.page + 1 : nil,
                    row_ids: rows.map { |job| [job.score, job["jid"]].join("|") }}
          )
        end

        def render(tui, frame, area)
          chunks = tui.layout_split(
            area,
            direction: :vertical,
            constraints: [
              tui.constraint_length(4), # Stats
              tui.constraint_fill(1)   # Table
            ]
          )

          render_stats_section(tui, frame, chunks[0])
          render_table(tui, frame, chunks[1]) do
            {
              title: t(name),
              header: ["☑️", "When", "Queue", "Job", "Arguments"].map { |x| t(x) },
              widths: [
                tui.constraint_length(5),
                tui.constraint_length(24),
                tui.constraint_length(20),
                tui.constraint_length(30),
                tui.constraint_fill(1)
              ]
            }.tap do |h|
              rows = @data[:table][:rows].map.with_index { |entry, idx|
                tui.table_row(
                  cells: [
                    selected?(entry) ? "✅" : "",
                    entry.at,
                    entry.queue,
                    entry.display_class,
                    entry.display_args
                  ],
                  style: idx.even? ? nil : tui.style(bg: :dark_gray)
                )
              }
              h[:rows] = rows
            end
          end
        end
      end
    end
  end
end
