# frozen_string_literal: true

module Users
  module_function

  def generate_csv(users)
    headers = %w[email first_name last_name role current_sign_in_at last_sign_in_at updated_at created_at]

    CSVSafe.generate do |csv|
      csv << headers

      users.each { |user| csv << user.values_at(*headers) }
    end
  end
end
