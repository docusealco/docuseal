require 'brakeman/checks/base_check'

class Brakeman::CheckRansack < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for dangerous use of the Ransack library"

  def run_check
    return unless version_between? "0.0.0", "3.99", tracker.config.gem_version(:ransack)
    check_ransack_calls
  end

  def check_ransack_calls
    tracker.find_call(method: :ransack, nested: true).each do |result|
      next unless original? result

      call = result[:call]
      arg = call.first_arg

      # If an allow list is defined anywhere in the
      # class or super classes, consider it safe
      class_name = result[:chain].first

      next if ransackable_allow_list?(class_name)

      if input = has_immediate_user_input?(arg)
        confidence = if tracker.find_class(class_name).nil?
                       confidence = :low
                     elsif result[:location][:file].relative.include? 'admin'
                       confidence = :medium
                     else
                       confidence = :high
                     end

        message = msg('Unrestricted search using ', msg_code('ransack'), ' library called with ', msg_input(input), '. Limit search by defining ', msg_code('ransackable_attributes'), ' and ', msg_code('ransackable_associations'), ' methods in class or upgrade Ransack to version 4.0.0 or newer')

        warn result: result,
          warning_type: 'Missing Authorization',
          warning_code: :ransack_search,
          message: message,
          user_input: input,
          confidence: confidence,
          cwe_id: [862],
          link: 'https://positive.security/blog/ransack-data-exfiltration'
      end
    end
  end

  def ransackable_allow_list? class_name
    tracker.find_method(:ransackable_attributes, class_name, :class) and
      tracker.find_method(:ransackable_associations, class_name, :class)
  end
end
