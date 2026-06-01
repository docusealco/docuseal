require_relative 'eol_check'

class Brakeman::CheckEOLRails < Brakeman::EOLCheck
  Brakeman::Checks.add self

  @description = "Checks for unsupported versions of Rails"

  def run_check
    return unless tracker.config.rails_version

    check_eol_version :rails, RAILS_EOL_DATES
  end

  # https://rubyonrails.org/maintenance
  # https://endoflife.date/rails
  RAILS_EOL_DATES = {
    ['2.0.0', '2.3.99'] => Date.new(2013, 6, 25),
    ['3.0.0', '3.2.99'] => Date.new(2016, 6, 30),
    ['4.0.0', '4.2.99'] => Date.new(2017, 4, 27),
    ['5.0.0', '5.0.99'] => Date.new(2018, 5, 9),
    ['5.1.0', '5.1.99'] => Date.new(2019, 8, 25),
    ['5.2.0', '5.2.99'] => Date.new(2022, 6, 1),
    ['6.0.0', '6.0.99'] => Date.new(2023, 6, 1),
    ['6.1.0', '6.1.99'] => Date.new(2024, 10, 1),
    ['7.0.0', '7.0.99'] => Date.new(2025, 4, 1),
    ['7.1.0', '7.1.99'] => Date.new(2025, 10, 1),
    ['7.2.0', '7.2.99'] => Date.new(2026, 8, 9),
    ['8.0.0', '8.0.99'] => Date.new(2026, 10, 7),
  }
end
