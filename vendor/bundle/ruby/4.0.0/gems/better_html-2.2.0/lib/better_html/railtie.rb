# frozen_string_literal: true

require "better_html/better_erb"

module BetterHtml
  class Railtie < Rails::Railtie
    initializer "better_html.better_erb.initialization" do
      BetterHtml::BetterErb.prepend!
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_view) do
        next unless ActionView::Base.respond_to?(:annotate_rendered_view_with_filenames)

        BetterHtml.config.annotate_rendered_view_with_filenames = ActionView::Base.annotate_rendered_view_with_filenames
      end
    end
  end
end
