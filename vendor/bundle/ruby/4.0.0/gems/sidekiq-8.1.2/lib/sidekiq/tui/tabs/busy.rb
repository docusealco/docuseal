require_relative "base_tab"

module Sidekiq
  class TUI
    module Tabs
      class Busy < BaseTab
        def features
          %i[selectable]
        end

        def controls
          @controls ||= super + [
            {code: "T", modifiers: ["shift"], description: "Terminate", action: ->(tui, tab) { tab.terminate! }},
            {code: "Q", modifiers: ["shift"], description: "Quiet", action: ->(tui, tab) { tab.quiet! }}
          ]
        end

        def quiet!
          each_selection do |id|
            Sidekiq::Process.new("identity" => id).quiet!
          end
        end

        def terminate!
          each_selection do |id|
            Sidekiq::Process.new("identity" => id).stop!
          end
        end

        def refresh_data
          refresh_data_for_stats

          busy = []
          table_row_ids = []

          Sidekiq::ProcessSet.new.each do |p|
            name = "#{p["hostname"]}:#{p["pid"]}"
            name += " ⭐️" if p.leader?
            name += " 🛑" if p.stopping?
            busy << [
              selected?(p) ? "✅" : "",
              name,
              Time.at(p["started_at"]).utc,
              format_memory(p["rss"].to_i),
              number_with_delimiter(p["concurrency"]),
              number_with_delimiter(p["busy"])
            ]
            table_row_ids << p.identity
          end

          @data[:busy] = busy
          @data[:table] = {row_ids: table_row_ids}
        end

        def render(tui, frame, area)
          chunks = tui.layout_split(
            area,
            direction: :vertical,
            constraints: [
              tui.constraint_length(4), # Stats
              tui.constraint_length(4), # Status
              tui.constraint_fill(1)   # Graph
            ]
          )

          render_stats_section(tui, frame, chunks[0])
          render_status_section(tui, frame, chunks[1])
          render_table(tui, frame, chunks[2]) do
            {
              title: t("Processes"),
              header: ["☑️", "Name", "Started", "RSS", "Threads", "Busy"].map { |x| t(x) },
              widths: [
                tui.constraint_length(5),
                tui.constraint_fill(1),
                tui.constraint_length(24),
                tui.constraint_length(10),
                tui.constraint_length(6),
                tui.constraint_length(6)
              ],
              rows: @data[:busy].map.with_index { |cells, idx|
                tui.table_row(
                  cells:,
                  style: idx.even? ? nil : tui.style(bg: :dark_gray)
                )
              }
            }
          end
        end

        def render_status_section(tui, frame, area)
          values = []
          processes = Sidekiq::ProcessSet.new
          workset = Sidekiq::WorkSet.new
          ws = workset.size
          values << (s = processes.size
                     number_with_delimiter(s))
          values << (x = processes.total_concurrency
                     number_with_delimiter(x))
          values << number_with_delimiter(ws)
          values << "#{(x == 0) ? 0 : ((ws / x.to_f) * 100).round(0)}%"
          values << format_memory(processes.total_rss)

          keys = %w[Processes Threads Busy Utilization RSS]
          keys_line = keys.map { |k| t(k).to_s.ljust(12) }.join("  ")
          values_line = values.map { |v| v.to_s.ljust(12) }.join("  ")

          frame.render_widget(
            tui.paragraph(
              text: [keys_line, values_line],
              block: tui.block(title: t("Status"), borders: [:all])
            ),
            area
          )
        end
      end
    end
  end
end
