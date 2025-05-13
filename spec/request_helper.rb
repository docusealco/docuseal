# frozen_string_literal: true

module RequestHelper
  module_function

  def wait_for_fetch
    page.execute_script(
      <<~JS
        if (!window.fetchInitialized) {
          window.pendingFetchCount = 0;

          const originalFetch = window.fetch;

          window.fetch = function(...args) {
            window.pendingFetchCount++;

            return originalFetch.apply(this, args).finally(() => {
              window.pendingFetchCount--;
            });
          };

          window.fetchInitialized = true;
        }
      JS
    )

    yield

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        break if page.evaluate_script('window.pendingFetchCount') == 0

        sleep 0.1
      end
    end
  end
end
