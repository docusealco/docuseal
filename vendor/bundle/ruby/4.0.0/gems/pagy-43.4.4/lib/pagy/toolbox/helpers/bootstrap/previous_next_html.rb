# frozen_string_literal: true

class Pagy
  module NumericHelpers
    private

    # Return the enabled/disabled previous/next page anchor tag, embedded in the li tag
    def bootstrap_html_for(which, a_lambda)
      if send(which)
        %(<li class="page-item #{which}">#{
          a_lambda.(send(which), I18n.translate("pagy.#{which}"),
                    classes:    'page-link',
                    aria_label: I18n.translate("pagy.aria_label.#{which}"))}</li>)
      else
        %(<li class="page-item #{which} disabled"><a role="link" class="page-link" aria-disabled="true" aria-label="#{
        I18n.translate("pagy.aria_label.#{which}")}">#{I18n.translate("pagy.#{which}")}</a></li>)
      end
    end
  end
end
